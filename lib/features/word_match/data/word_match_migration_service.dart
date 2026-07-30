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

/// Handles migration of local guest (ownerUid == null) Word Match sets
/// into a signed-in Firebase user account.
///
/// Canonical path: `users/{uid}/word_match_sets`
class WordMatchMigrationService {
  WordMatchMigrationService(this._firestore, this._repo);

  final FirebaseFirestore _firestore;
  final WordMatchRepoInterface _repo;

  CollectionReference<Map<String, dynamic>> _userSetsRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('word_match_sets');
  }

  /// Migrate all non-builtin guest local sets (ownerUid == null) for the given user UID.
  ///
  /// - Skips built-in sets.
  /// - Skips sets that already have a non-null ownerUid.
  /// - Assigns a persistent cloudId locally before uploading so retries reuse the document ID.
  /// - Only updates local ownerUid to user.uid after remote write succeeds.
  Future<void> migrateLocalSetsForUser(AppUser user) async {
    if (user.isAnonymous || user.isGuestMode) {
      // Anonymous/guest users do not get cloud migration.
      return;
    }

    try {
      // Get unmigrated guest sets (isBuiltin == false && ownerUid == null)
      final guestSets = await _repo.getUnmigratedGuestSets().timeout(
        const Duration(seconds: 8),
        onTimeout: () => <WordSet>[],
      );

      if (guestSets.isEmpty) {
        return;
      }

      for (final set in guestSets) {
        if (set.isBuiltin || set.ownerUid != null) {
          continue;
        }

        // Target UID Security: If migration was initiated for another user account, skip.
        if (set.pendingMigrationUid != null &&
            set.pendingMigrationUid != user.uid) {
          debugPrint(
            'Skipping set ${set.id}: pending migration for ${set.pendingMigrationUid}, active user is ${user.uid}',
          );
          continue;
        }

        // Set pendingMigrationUid locally for current user before proceeding
        if (set.pendingMigrationUid == null) {
          await _repo.updateSetPendingMigrationUid(set.id, user.uid);
        }

        // Fetch pairs using dedicated unmigrated guest pairs API.
        // If pair reading fails, DO NOT perform remote write and DO NOT change ownerUid.
        final List<WordPair> pairs;
        try {
          pairs = await _repo.getUnmigratedGuestPairs(set.id);
        } catch (e) {
          debugPrint(
            'Failed to read guest pairs for set ${set.id}: $e. Aborting migration for this set.',
          );
          continue;
        }

        // Determine or retrieve persistent cloud document ID
        String? cloudId = set.cloudId;
        final DocumentReference<Map<String, dynamic>> docRef;
        if (cloudId == null || cloudId.isEmpty) {
          docRef = _userSetsRef(user.uid).doc();
          cloudId = docRef.id;
          // Save cloudId locally first so retries reuse the exact same doc ID
          await _repo.updateSetCloudId(set.id, cloudId);
        } else {
          docRef = _userSetsRef(user.uid).doc(cloudId);
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

        final payload = <String, dynamic>{
          'name': set.name,
          'createdAt': set.createdAt.toUtc().toIso8601String(),
          'updatedAt': set.updatedAt.toUtc().toIso8601String(),
          'visibility': set.visibility.name,
          'sourceSetId': set.sourceSetId,
          'sourceOwnerUid': set.sourceOwnerUid,
          'importedAt': set.importedAt?.toUtc().toIso8601String(),
          'pairs': pairsJson,
        };

        try {
          await docRef.set(payload, SetOptions(merge: true));
          // Update ownerUid locally ONLY after remote write succeeds (also clears pendingMigrationUid)
          await _repo.updateSetOwnerUid(set.id, user.uid);
          debugPrint(
            'Successfully migrated guest set ${set.id} (${set.name}) to cloud ID $cloudId for user ${user.uid}',
          );
        } catch (e) {
          debugPrint(
            'Failed to migrate guest set ${set.id} (${set.name}) to cloud: $e',
          );
          // Set remains ownerUid == null; retry on next login for user.uid will reuse same cloudId
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
}

/// Async provider that wires together Firestore + local WordMatch repo
/// to create a migration service instance.
final wordMatchMigrationServiceProvider =
    FutureProvider<WordMatchMigrationService>((ref) async {
      final firestore = ref.watch(firestoreProvider);
      final repo = await ref.watch(wordMatchRepoProvider.future);
      return WordMatchMigrationService(firestore, repo);
    });
