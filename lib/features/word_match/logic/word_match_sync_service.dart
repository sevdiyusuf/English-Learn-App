import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repo.dart';
import '../data/word_match_providers.dart';
import '../data/word_match_repo_interface.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';

final wordMatchSyncProvider = FutureProvider<WordMatchSyncService>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final repo = await ref.watch(wordMatchRepoProvider.future);
  final service = WordMatchSyncService(
    repo,
    authRepo,
    FirebaseFirestore.instance,
  );

  // Start syncing automatically
  service.init();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

class WordMatchSyncService {
  WordMatchSyncService(this._localRepo, this._authRepo, this._firestore);

  final WordMatchRepoInterface _localRepo;
  final AuthRepository _authRepo;
  final FirebaseFirestore _firestore;

  StreamSubscription? _remoteSubscription;
  StreamSubscription? _authSubscription;
  bool _isHandlingRemoteUpdate = false;

  // Retry queue for offline/failed syncs
  final _retryQueue = <int>{};
  Timer? _retryTimer;

  void init() {
    debugPrint('WordMatchSyncService initialized');
    _authSubscription = _authRepo.watchAuthUser().listen((user) {
      if (user != null) {
        debugPrint('User logged in: ${user.uid}, starting sync...');
        _startSync(user.uid);
      } else {
        debugPrint('User logged out, stopping sync...');
        _stopSync();
      }
    });
  }

  void dispose() {
    _stopSync();
    _authSubscription?.cancel();
    debugPrint('WordMatchSyncService disposed');
  }

  void _stopSync() {
    _remoteSubscription?.cancel();
    _retryTimer?.cancel();
    _remoteSubscription = null;
    _retryTimer = null;
    _retryQueue.clear();
  }

  void _startSync(String uid) {
    _stopSync();
    debugPrint('Starting Word Match sync for user: $uid');

    // Start retry timer
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processRetryQueue(uid);
    });

    // 1. Listen to remote changes (Pull)
    final collectionRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('word_match_sets');

    _remoteSubscription = collectionRef.snapshots().listen(
      (snapshot) async {
        debugPrint(
          'Remote changes received: ${snapshot.docChanges.length} changes',
        );
        if (_isHandlingRemoteUpdate) {
          debugPrint('Already handling remote update, skipping...');
          return;
        }
        try {
          _isHandlingRemoteUpdate = true;
          await _handleRemoteChanges(snapshot);
        } catch (e) {
          debugPrint('Error handling remote changes: $e');
        } finally {
          _isHandlingRemoteUpdate = false;
        }
      },
      onError: (e) {
        debugPrint('Error listening to remote changes: $e');
      },
    );

    // 2. Initial sync: Upload local sets that don't have cloudId
    _syncLocalToRemote(uid);
  }

  Future<void> forceSync() async {
    final user = _authRepo.currentUser;
    if (user == null) {
      debugPrint('Cannot force sync: No user logged in');
      return;
    }
    debugPrint('Force sync requested for user: ${user.uid}');
    await _syncLocalToRemote(user.uid);
    await _processRetryQueue(user.uid);
  }

  /// Called by controller when a set is changed locally
  Future<void> syncSet(int localSetId) async {
    if (_isHandlingRemoteUpdate) return;

    final user = _authRepo.currentUser;
    if (user == null) {
      debugPrint('Skipping syncSet: No user logged in');
      return;
    }

    try {
      final set = await _localRepo.getSet(localSetId);
      if (set == null) {
        debugPrint('Skipping syncSet: Set $localSetId not found');
        return;
      }
      if (set.isBuiltin) {
        debugPrint('Skipping syncSet: Set $localSetId is builtin');
        return;
      }

      debugPrint('Syncing set $localSetId to cloud...');
      await _pushSetToCloud(user.uid, set);
      _retryQueue.remove(localSetId); // Remove if successful
      debugPrint('Successfully synced set $localSetId');
    } catch (e) {
      debugPrint('Error syncing set $localSetId: $e');
      _retryQueue.add(localSetId); // Add to retry queue
    }
  }

  Future<void> _processRetryQueue(String uid) async {
    if (_retryQueue.isEmpty) return;

    debugPrint('Processing sync retry queue: ${_retryQueue.length} items');
    final idsToRetry = _retryQueue.toList();
    for (final id in idsToRetry) {
      await syncSet(id);
    }
  }

  Future<void> deleteSetFromCloud(String cloudId) async {
    final user = _authRepo.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('word_match_sets')
          .doc(cloudId)
          .delete();
      debugPrint('Deleted set $cloudId from cloud');
    } catch (e) {
      debugPrint('Error deleting set from cloud: $e');
    }
  }

  Future<void> _handleRemoteChanges(QuerySnapshot snapshot) async {
    for (final doc in snapshot.docChanges) {
      // Skip local writes (we already have the data)
      if (doc.doc.metadata.hasPendingWrites) continue;

      final cloudId = doc.doc.id;
      if (doc.type == DocumentChangeType.added ||
          doc.type == DocumentChangeType.modified) {
        final data = doc.doc.data() as Map<String, dynamic>;
        await _upsertLocalSet(cloudId, data);
      } else if (doc.type == DocumentChangeType.removed) {
        await _deleteLocalSet(cloudId);
      }
    }
  }

  Future<void> _upsertLocalSet(
    String cloudId,
    Map<String, dynamic> data,
  ) async {
    // 1. Check if we have a set with this cloudId
    final existingSet = await _localRepo.getSetByCloudId(cloudId);

    final name = data['name'] as String;
    final remoteUpdatedAtStr = data['updatedAt'] as String?;
    final remoteUpdatedAt =
        remoteUpdatedAtStr != null
            ? DateTime.tryParse(remoteUpdatedAtStr)
            : null;

    // Conflict Resolution: Last Write Wins
    if (existingSet != null && remoteUpdatedAt != null) {
      // If local is newer or same, don't overwrite
      // Allow 1 second difference for clock skew/latency
      // RELAXED CHECK: Only skip if local is significantly newer (> 5 minutes)
      // to prevent blocking legitimate updates due to small clock skews.
      if (existingSet.updatedAt.isAfter(
        remoteUpdatedAt.add(const Duration(minutes: 5)),
      )) {
        debugPrint(
          'Local set is SIGNIFICANTLY newer (>5m), skipping remote update for $cloudId',
        );
        return;
      }
    }

    final pairsList = (data['pairs'] as List<dynamic>?) ?? [];

    // Convert pairs
    final pairs =
        pairsList.map((p) {
          final map = p as Map<String, dynamic>;
          return WordPair()
            ..id =
                0 // Will be assigned by repo
            ..english = map['english'] as String
            ..turkish = map['turkish'] as String
            ..learned = map['learned'] as bool? ?? false;
        }).toList();

    final visibilityStr = data['visibility'] as String?;
    final visibility = SetVisibility.values.firstWhere(
      (e) => e.name == visibilityStr,
      orElse: () => SetVisibility.private,
    );

    final sourceSetId = data['sourceSetId'] as String?;
    final sourceOwnerUid = data['sourceOwnerUid'] as String?;
    final importedAtStr = data['importedAt'] as String?;
    final importedAt =
        importedAtStr != null ? DateTime.tryParse(importedAtStr) : null;

    int setId;
    if (existingSet != null) {
      setId = existingSet.id;
      // Update existing
      if (existingSet.name != name) {
        await _localRepo.renameSet(id: existingSet.id, name: name);
      }
      // Update pairs
      await _localRepo.savePairs(
        setId: existingSet.id,
        setName: name,
        pairs: pairs,
      );
    } else {
      // Create new
      setId = await _localRepo.createSet(name);
      await _localRepo.updateSetCloudId(setId, cloudId);
      await _localRepo.savePairs(setId: setId, setName: name, pairs: pairs);
    }

    // Update metadata
    await _localRepo.updateSetVisibility(setId, visibility);
    await _localRepo.updateSetMetadata(
      setId,
      sourceSetId: sourceSetId,
      sourceOwnerUid: sourceOwnerUid,
      importedAt: importedAt,
    );
  }

  Future<void> _deleteLocalSet(String cloudId) async {
    final existingSet = await _localRepo.getSetByCloudId(cloudId);

    if (existingSet != null) {
      await _localRepo.deleteSet(existingSet.id);
    }
  }

  Future<void> _syncLocalToRemote(String uid) async {
    debugPrint('Starting initial sync (Local -> Remote) for $uid');
    final localSets = await _localRepo.watchSets().first;

    // Get all remote IDs and timestamps
    Map<String, DateTime> remoteSets = {};
    try {
      final collectionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('word_match_sets');
      final snapshot = await collectionRef.get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final updatedAtStr = data['updatedAt'] as String?;
        if (updatedAtStr != null) {
          remoteSets[doc.id] =
              DateTime.tryParse(updatedAtStr) ?? DateTime(1970);
        } else {
          remoteSets[doc.id] = DateTime(1970);
        }
      }
      debugPrint('Found ${remoteSets.length} existing sets in cloud');
    } catch (e) {
      debugPrint('Error fetching remote sets for initial sync: $e');
    }

    int syncedCount = 0;
    for (final set in localSets) {
      if (set.isBuiltin) continue; // Don't sync built-in sets

      bool shouldUpload = false;
      if (set.cloudId == null) {
        debugPrint('Set ${set.id} (${set.name}) has no cloudId, uploading...');
        shouldUpload = true;
      } else if (!remoteSets.containsKey(set.cloudId)) {
        // Has cloudId but missing in remote (Migration case!)
        debugPrint(
          'Set ${set.id} (${set.name}) missing in cloud (${set.cloudId}), re-uploading...',
        );
        shouldUpload = true;
      } else {
        // Check if local is newer
        final remoteUpdatedAt = remoteSets[set.cloudId]!;
        // Use a small buffer for clock skew, but if local is clearly newer, push it.
        // set.updatedAt is Local (from Isar), convert to UTC for comparison with remote (UTC).
        if (set.updatedAt.toUtc().isAfter(
          remoteUpdatedAt.add(const Duration(seconds: 5)),
        )) {
          debugPrint(
            'Set ${set.id} (${set.name}) is newer locally (Local: ${set.updatedAt.toUtc()}, Remote: $remoteUpdatedAt), pushing...',
          );
          shouldUpload = true;
        }
      }

      if (shouldUpload) {
        try {
          await _pushSetToCloud(uid, set);
          syncedCount++;
        } catch (e) {
          debugPrint('Error uploading set ${set.id} during initial sync: $e');
          _retryQueue.add(set.id);
        }
      }
    }
    debugPrint('Initial sync completed. Uploaded $syncedCount sets.');
  }

  Future<void> _pushSetToCloud(String uid, WordSet set) async {
    try {
      final pairs = await _localRepo.fetchPairs(set.id);

      final collectionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('word_match_sets');

      final DocumentReference docRef;
      if (set.cloudId != null) {
        docRef = collectionRef.doc(set.cloudId);
      } else {
        docRef = collectionRef.doc(); // Generate new ID
      }

      final pairsJson =
          pairs
              .map(
                (p) => {
                  'english': p.english,
                  'turkish': p.turkish,
                  'learned': p.learned,
                },
              )
              .toList();

      await docRef.set({
        'name': set.name,
        'createdAt': set.createdAt.toUtc().toIso8601String(),
        'updatedAt': set.updatedAt.toUtc().toIso8601String(),
        'visibility': set.visibility.name,
        'sourceSetId': set.sourceSetId,
        'sourceOwnerUid': set.sourceOwnerUid,
        'importedAt': set.importedAt?.toUtc().toIso8601String(),
        'pairs': pairsJson,
      }, SetOptions(merge: true));

      if (set.cloudId == null) {
        // Update local cloudId
        await _localRepo.updateSetCloudId(set.id, docRef.id);
        debugPrint('Uploaded set ${set.name} to cloud with ID ${docRef.id}');
      } else {
        debugPrint('Updated set ${set.name} on cloud');
      }
    } catch (e) {
      debugPrint('Error uploading set ${set.name}: $e');
      rethrow; // Re-throw to handle in caller
    }
  }
}
