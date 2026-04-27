import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../auth/models/app_user.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_providers.dart';
import 'word_match_repo_interface.dart';

/// Handles migration of local (Isar / SharedPreferences / localStorage)
/// Word Match sets into a signed-in Firebase user account.
///
/// Phase 0 hedefi: Misafir / local setler, kullanıcı Google/Email/Apple ile
/// giriş yaptıktan sonra Firestore'daki `users/{uid}/sets` altına kopyalanır.
class WordMatchMigrationService {
  WordMatchMigrationService(this._firestore, this._repo);

  final FirebaseFirestore _firestore;
  final WordMatchRepoInterface _repo;

  CollectionReference<Map<String, dynamic>> _userSetsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('sets');
  }

  /// Migrate all non-builtin local sets for the given user UID.
  ///
  /// - Skips built-in sets.
  /// - Skips sets that have already been migrated for this user
  ///   (based on `localSetId` field in Firestore).
  /// - Handles name collisions by adding " (1)", " (2)", ... suffixes.
  Future<void> migrateLocalSetsForUser(AppUser user) async {
    if (user.isAnonymous || user.isGuestMode) {
      // Anonymous/guest users do not get cloud migration.
      return;
    }

    try {
      // Get local sets with a short timeout to avoid hanging on broken storage.
      final sets = await _repo.watchSets().first.timeout(
        const Duration(seconds: 8),
        onTimeout: () => <WordSet>[],
      );

      if (sets.isEmpty) {
        return;
      }

      // Load existing remote sets once to:
      // - detect which localSetIds were already migrated
      // - track existing names for collision handling
      final existingSnapshot = await _userSetsRef(user.uid).get();
      final existingLocalSetIds = <int>{};
      final existingNames = <String>{};

      for (final doc in existingSnapshot.docs) {
        final data = doc.data();
        final localId = data['localSetId'];
        if (localId is int) {
          existingLocalSetIds.add(localId);
        } else if (localId is num) {
          existingLocalSetIds.add(localId.toInt());
        } else if (localId is String) {
          final parsed = int.tryParse(localId);
          if (parsed != null) {
            existingLocalSetIds.add(parsed);
          }
        }
        final name = data['name'];
        if (name is String && name.isNotEmpty) {
          existingNames.add(name);
        }
      }

      for (final set in sets) {
        if (set.isBuiltin) {
          // Built-in sets are not user-specific; skip.
          continue;
        }

        if (existingLocalSetIds.contains(set.id)) {
          // This local set was already migrated for this user.
          continue;
        }

        // Name collision handling
        final safeName = _generateUniqueName(set.name, existingNames);
        existingNames.add(safeName);

        // Fetch pairs for this set
        final pairs = await _safeFetchPairs(set.id);

        final now = DateTime.now().toUtc();
        final docRef = _userSetsRef(user.uid).doc();

        final data = <String, dynamic>{
          'ownerUid': user.uid,
          'name': safeName,
          'visibility': 'PRIVATE', // Phase 2'de enum ile genişletilecek
          'createdAt': Timestamp.fromDate(set.createdAt.toUtc()),
          'updatedAt': Timestamp.fromDate(set.updatedAt.toUtc()),
          if (set.lastPracticedAt != null)
            'lastPracticedAt': Timestamp.fromDate(set.lastPracticedAt!.toUtc()),
          'pairsCount': pairs.length,
          'isBuiltin': set.isBuiltin,
          'localSetId': set.id,
          'migratedFromLocal': true,
          'migratedAt': Timestamp.fromDate(now),
        };

        await docRef.set(data);

        // Write pairs in a batch for efficiency
        if (pairs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final pair in pairs) {
            final pairRef = docRef.collection('pairs').doc();
            batch.set(pairRef, {
              'english': pair.english,
              'turkish': pair.turkish,
              'learned': pair.learned,
            });
          }
          await batch.commit();
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'WordMatchMigrationService.migrateLocalSetsForUser error: $e',
        );
        debugPrint(stackTrace.toString());
      }
      // Migration is best-effort; never crash auth flow because of this.
    }
  }

  Future<List<WordPair>> _safeFetchPairs(int setId) async {
    try {
      return await _repo.fetchPairs(setId);
    } catch (_) {
      return <WordPair>[];
    }
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
        // Safety guard
        return '$candidate (${DateTime.now().millisecondsSinceEpoch})';
      }
    }
  }
}

/// Async provider that wires together Firestore + local WordMatch repo
/// to create a migration service instance.
final wordMatchMigrationServiceProvider =
    FutureProvider<WordMatchMigrationService>((ref) async {
      final firestore = ref.watch(firestoreProvider);
      final repo = await ref.watch(wordMatchRepoProvider.future);
      return WordMatchMigrationService(firestore, repo);
    });
