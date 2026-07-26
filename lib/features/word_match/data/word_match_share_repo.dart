import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../auth/models/app_user.dart';
import '../models/word_pair.dart';
import 'word_match_providers.dart';
import 'word_match_repo_interface.dart';

/// Lightweight DTO for a shared word set stored in Firestore `shares/{shareId}`.
class SharedWordSet {
  SharedWordSet({
    required this.shareId,
    required this.ownerUid,
    required this.setName,
    required this.pairs,
    required this.createdAt,
  });

  final String shareId;
  final String ownerUid;
  final String setName;
  final List<SharedWordPair> pairs;
  final DateTime createdAt;
}

class SharedWordPair {
  SharedWordPair({required this.front, required this.back});

  final String front;
  final String back;
}

/// Repository handling Firestore-backed sharing for Word Match sets.
///
/// This is designed to work even when the user has only anonymous auth.
class WordMatchShareRepository {
  WordMatchShareRepository(this._firestore, this._functions, this._repo);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final WordMatchRepoInterface _repo;

  CollectionReference<Map<String, dynamic>> get _sharesRef =>
      _firestore.collection('shares');

  /// Create a share document for a local set (Isar / prefs / web storage).
  ///
  /// Returns a short `shareId` that can be used in a link like `/s/{shareId}`.
  Future<String> createShareForLocalSet({
    required AppUser owner,
    required int localSetId,
  }) async {
    // Load set + pairs from local repo
    final set = await _repo.getSet(localSetId);
    if (set == null) {
      throw StateError('Set bulunamadı');
    }
    final pairs = await _repo.fetchPairs(localSetId);

    final payloadPairs = pairs
        .where(
          (p) => p.english.trim().isNotEmpty && p.turkish.trim().isNotEmpty,
        )
        .take(WordMatchRepoInterface.maxPairsPerSet)
        .map((p) => {'front': p.english.trim(), 'back': p.turkish.trim()})
        .toList(growable: false);

    final response = await _functions
        .httpsCallable('publishWordMatchShare')
        .call<Map<String, dynamic>>({
          'setName': set.name,
          'pairs': payloadPairs,
        });
    return response.data['shareId'] as String;
  }

  Future<void> removeShare(String shareId) async {
    await _functions
        .httpsCallable('removeWordMatchShare')
        .call({'shareId': shareId});
  }

  /// Load a shared set from Firestore. Returns null if not found.
  Future<SharedWordSet?> getSharedSet(String shareId) async {
    try {
      final doc = await _sharesRef.doc(shareId).get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data();
      if (data == null) {
        return null;
      }

      if (data['status'] != 'published' || data['visibility'] != 'public') {
        return null;
      }
      final ownerUid = (data['ownerUid'] as String?) ?? '';
      final setName = (data['setName'] as String?) ?? 'Paylaşılan Set';
      final createdAtRaw = data['createdAt'];
      DateTime createdAt;
      if (createdAtRaw is Timestamp) {
        createdAt = createdAtRaw.toDate();
      } else if (createdAtRaw is String) {
        createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }

      final rawPairs = data['pairs'];
      final pairs = <SharedWordPair>[];
      if (rawPairs is List) {
        for (final item in rawPairs) {
          if (item is Map<String, dynamic>) {
            final front = (item['front'] as String?) ?? '';
            final back = (item['back'] as String?) ?? '';
            if (front.trim().isEmpty || back.trim().isEmpty) continue;
            pairs.add(SharedWordPair(front: front.trim(), back: back.trim()));
          }
        }
      }

      return SharedWordSet(
        shareId: shareId,
        ownerUid: ownerUid,
        setName: setName,
        pairs: pairs,
        createdAt: createdAt,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error loading shared set $shareId: $e');
        debugPrint(stackTrace.toString());
      }
      rethrow;
    }
  }

  /// Import a shared set into the local Word Match repository.
  ///
  /// Returns the new local setId.
  Future<int> importSharedSetToLocal({required SharedWordSet shared}) async {
    // Determine a unique local name (avoid collisions with existing sets)
    final existingSets = await _repo.watchSets().first;
    final existingNames = existingSets.map((s) => s.name).toSet();
    final uniqueName = _generateUniqueName(shared.setName, existingNames);

    // Create the new set
    final newSetId = await _repo.createSet(uniqueName);

    // Convert to WordPair list
    final pairs = shared.pairs
        .take(WordMatchRepoInterface.maxPairsPerSet)
        .map(
          (p) =>
              WordPair()
                ..id = 0
                ..setId = newSetId
                ..english = p.front
                ..turkish = p.back,
        )
        .toList(growable: false);

    await _repo.savePairs(setId: newSetId, setName: uniqueName, pairs: pairs);

    // Save metadata
    await _repo.updateSetMetadata(
      newSetId,
      sourceSetId: shared.shareId,
      sourceOwnerUid: shared.ownerUid,
      importedAt: DateTime.now().toUtc(),
    );

    return newSetId;
  }

  /// Fetch visible sets for a user.
  Future<List<SharedWordSet>> fetchUserSets({
    required String targetUid,
    required bool isFriend,
  }) async {
    final sets = <SharedWordSet>[];

    try {
      // Fetch PUBLIC
      final publicSnap =
          await _firestore
              .collection('users')
              .doc(targetUid)
              .collection('word_match_sets')
              .where('visibility', isEqualTo: 'public')
              .get();

      sets.addAll(_mapSnapshotsToSharedSets(publicSnap, targetUid));

      if (isFriend) {
        final friendSnap =
            await _firestore
                .collection('users')
                .doc(targetUid)
                .collection('word_match_sets')
                .where('visibility', isEqualTo: 'friendsOnly')
                .get();
        sets.addAll(_mapSnapshotsToSharedSets(friendSnap, targetUid));
      }
    } catch (e) {
      debugPrint('Error fetching user sets: $e');
    }

    return sets;
  }

  List<SharedWordSet> _mapSnapshotsToSharedSets(
    QuerySnapshot<Map<String, dynamic>> snap,
    String ownerUid,
  ) {
    return snap.docs.map((doc) {
      final data = doc.data();
      final pairsList = (data['pairs'] as List<dynamic>?) ?? [];
      final pairs =
          pairsList.map((p) {
            final map = p as Map<String, dynamic>;
            return SharedWordPair(
              front: map['english'] as String,
              back: map['turkish'] as String,
            );
          }).toList();

      return SharedWordSet(
        shareId: doc.id,
        ownerUid: ownerUid,
        setName: data['name'] as String? ?? 'Untitled',
        pairs: pairs,
        createdAt:
            DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  String _generateUniqueName(String baseName, Set<String> existingNames) {
    var candidate = baseName.trim().isEmpty ? 'Set' : baseName.trim();
    if (!existingNames.contains(candidate)) {
      return candidate;
    }
    var index = 1;
    while (true) {
      final withSuffix = '$candidate ($index)';
      if (!existingNames.contains(withSuffix)) {
        return withSuffix;
      }
      index++;
      if (index > 1000) {
        return '$candidate (${DateTime.now().millisecondsSinceEpoch})';
      }
    }
  }
}

/// Async provider for the share repository (needs local repo instance).
final wordMatchShareRepositoryProvider =
    FutureProvider<WordMatchShareRepository>((ref) async {
      final firestore = ref.watch(firestoreProvider);
      final repo = await ref.watch(wordMatchRepoProvider.future);
      final functions = ref.watch(firebaseFunctionsProvider);
      return WordMatchShareRepository(firestore, functions, repo);
    });
