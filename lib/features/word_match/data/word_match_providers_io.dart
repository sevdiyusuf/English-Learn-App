import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/auth_repo.dart';
import '../../dictionary/load_dictionary.dart';
import '../../dictionary/models/dict_entry.dart';
import '../../sync/models/local_schema_metadata.dart';
import '../../sync/models/outbox_item.dart';
import '../../sync/models/sync_checkpoint.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo.dart';
import 'word_match_repo_interface.dart';
import 'word_match_repo_prefs.dart';
import 'word_match_repo_web.dart';

// Persistent flag to remember if Isar failed - stored in SharedPreferences
Future<bool> _checkIsarFailedFlag() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isar_failed') ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> _setIsarFailedFlag(bool failed) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isar_failed', failed);
  } catch (_) {
    // Ignore errors
  }
}

final appIsarProvider = FutureProvider<Isar?>((ref) async {
  // Check persistent flag - if Isar failed before, don't try again
  final isarFailed = await _checkIsarFailedFlag();
  if (isarFailed) {
    debugPrint('Isar failed before (persistent flag), skipping initialization');
    return null; // Will trigger fallback
  }

  // With singleton pattern in openDictionaryStore, we don't need aggressive retries
  // Just try a few times with delays if collections aren't ready yet
  Exception? lastError;
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      debugPrint('Isar initialization attempt ${attempt + 1}/5');
      final isar = await openDictionaryStore();
      if (isar == null) {
        throw StateError('openDictionaryStore returned null');
      }

      // Verify collections are ready
      try {
        await isar.wordSets.count();
        await isar.wordPairs.count();
        await isar.dictEntrys.count();
        await isar.outboxItems.count();
        await isar.localSchemaMetadatas.count();
        await isar.syncCheckpoints.count();
        debugPrint(
          'Isar successfully initialized and verified on attempt ${attempt + 1}',
        );
        return isar;
      } catch (e, stackTrace) {
        debugPrint(
          'Isar collections not ready after opening, attempt ${attempt + 1}: $e',
        );
        debugPrint('Stack trace: $stackTrace');
        lastError = e is Exception ? e : Exception(e.toString());

        // Collections might need more time to initialize
        if (attempt < 4) {
          // Wait progressively longer for collections to become ready
          await Future.delayed(Duration(milliseconds: 500 + (attempt * 300)));
          continue;
        }
        // Last attempt - collections never initialized, throw error
        debugPrint('ERROR: Collections never initialized after 5 attempts');
        throw StateError(
          'Isar collections never initialized after 5 attempts. '
          'Error: $e\n\n'
          'Bu, Android APK\'da Isar native libraries\'in düzgün yüklenmediğini gösterir.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Isar initialization attempt ${attempt + 1} failed: $e');
      debugPrint('Stack trace: $stackTrace');

      // Check if error is "already opened" - this means another call succeeded
      if (e.toString().contains('already been opened') ||
          e.toString().contains('already opened')) {
        debugPrint('Instance was opened by another call, retrieving it...');
        await Future.delayed(const Duration(milliseconds: 500));
        final existing = Isar.getInstance('dictionary');
        if (existing != null) {
          debugPrint('Retrieved existing Isar instance');
          return existing;
        }
      }

      lastError = e is Exception ? e : Exception(e.toString());
      if (attempt < 4) {
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 1000 + (attempt * 500)));
      } else {
        // Last attempt failed - mark as failed persistently
        await _setIsarFailedFlag(true);
        debugPrint(
          'Isar failed permanently, will use SharedPreferences fallback',
        );
        throw StateError(
          'Isar initialization failed after 5 attempts. Last error: $e',
        );
      }
    }
  }

  // All attempts failed - mark as failed persistently
  await _setIsarFailedFlag(true);
  throw StateError(
    'Isar instance could not be initialized after 5 attempts. Last error: $lastError',
  );
});

final wordMatchRepoProvider = FutureProvider<WordMatchRepoInterface>((
  ref,
) async {
  final authUser = ref.watch(authRepositoryProvider).currentUser;
  final String? activeOwnerUid =
      (authUser != null && !authUser.isAnonymous) ? authUser.uid : null;

  try {
    if (kIsWeb) {
      debugPrint(
        "⚠️ Web platformu algılandı. Isar beklenmeden fallback'e geçiliyor.",
      );
      throw Exception("Web platformunda Isar desteklenmiyor.");
    }

    final isar = await ref
        .read(appIsarProvider.future)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Isar loading timed out');
          },
        );

    if (isar == null) {
      await _setIsarFailedFlag(true);
      debugPrint('Isar instance is null, using fallback');
      if (kIsWeb) return WordMatchRepoWeb(activeOwnerUid: activeOwnerUid);
      return WordMatchRepoPrefs(activeOwnerUid: activeOwnerUid);
    }

    debugPrint('Isar instance received, verifying collections...');

    for (var verifyAttempt = 0; verifyAttempt < 3; verifyAttempt++) {
      try {
        if (verifyAttempt > 0) {
          await Future.delayed(const Duration(milliseconds: 300));
        }

        await Future.wait<int>([
          isar.wordSets.count().timeout(
            const Duration(seconds: 1),
            onTimeout: () => throw TimeoutException('wordSets.count timeout'),
          ),
          isar.wordPairs.count().timeout(
            const Duration(seconds: 1),
            onTimeout: () => throw TimeoutException('wordPairs.count timeout'),
          ),
          isar.dictEntrys.count().timeout(
            const Duration(seconds: 1),
            onTimeout: () => throw TimeoutException('dictEntrys.count timeout'),
          ),
        ]);

        debugPrint(
          'Collections verified successfully on attempt ${verifyAttempt + 1}',
        );

        if (kIsWeb) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final migrated = prefs.getBool('web_isar_migration_v1') ?? false;
            if (!migrated) {
              debugPrint('Starting Web LocalStorage -> Isar migration...');
              final oldRepo = WordMatchRepoWeb(activeOwnerUid: activeOwnerUid);
              final sets = await oldRepo.watchSets().first.timeout(
                const Duration(seconds: 2),
                onTimeout: () => [],
              );

              if (sets.isNotEmpty) {
                await isar.writeTxn(() async {
                  for (final set in sets) {
                    final existingSet = await isar.wordSets.get(set.id);
                    if (existingSet != null) {
                      continue;
                    }

                    await isar.wordSets.put(set);
                    final pairs = await oldRepo.fetchPairs(set.id);
                    await isar.wordPairs.putAll(pairs);
                  }
                });
                debugPrint(
                  'Web migration: Copied ${sets.length} sets to Isar.',
                );
              }
              await prefs.setBool('web_isar_migration_v1', true);
              debugPrint('Web migration completed successfully.');
            }
          } catch (e) {
            debugPrint('Web migration failed: $e');
            debugPrint(
              'Fallback: Returning WordMatchRepoWeb (LocalStorage) due to migration failure.',
            );
            return WordMatchRepoWeb(activeOwnerUid: activeOwnerUid);
          }
        }

        return WordMatchRepo(isar, activeOwnerUid: activeOwnerUid);
      } catch (e) {
        debugPrint(
          'Collections verification attempt ${verifyAttempt + 1}/3 failed: $e',
        );
        if (verifyAttempt == 2) {
          debugPrint(
            'WARNING: Isar collections could not be initialized after 3 attempts',
          );
          await _setIsarFailedFlag(true);
          debugPrint('Falling back to storage implementation...');
          if (kIsWeb) return WordMatchRepoWeb(activeOwnerUid: activeOwnerUid);
          return WordMatchRepoPrefs(activeOwnerUid: activeOwnerUid);
        }
      }
    }

    if (kIsWeb) return WordMatchRepoWeb(activeOwnerUid: activeOwnerUid);
    return WordMatchRepoPrefs(activeOwnerUid: activeOwnerUid);
  } catch (e) {
    debugPrint('WordMatchRepo initialization failed: $e');
    if (kIsWeb) return WordMatchRepoWeb(activeOwnerUid: activeOwnerUid);
    return WordMatchRepoPrefs(activeOwnerUid: activeOwnerUid);
  }
});

final preBuiltSetsProvider = StreamProvider<List<WordSet>>((ref) async* {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  await repo.ensureLevelSets();
  yield* repo.watchLevelSets();
});
