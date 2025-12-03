import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../dictionary/load_dictionary.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo.dart';
import 'word_match_repo_interface.dart';
import 'word_match_repo_web.dart';

final appIsarProvider = FutureProvider<Isar?>((ref) async {
  // Retry mechanism for Isar initialization - Android APK needs multiple attempts
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      final isar = await openDictionaryStore();
      if (isar != null) {
        return isar;
      }
      // If null, wait and retry
      if (attempt < 4) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    } catch (e) {
      debugPrint('Isar initialization attempt ${attempt + 1} failed: $e');
      if (attempt < 4) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      } else {
        // Last attempt failed, rethrow
        rethrow;
      }
    }
  }
  return null;
});

final wordMatchRepoProvider = FutureProvider<WordMatchRepoInterface>((
  ref,
) async {
  if (kIsWeb) {
    return WordMatchRepoWeb();
  }
  
  // Wait for Isar to be initialized with proper error handling and verification
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      final isar = await ref.watch(appIsarProvider.future);
      if (isar == null) {
        if (attempt < 4) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        throw StateError('Isar instance could not be initialized on non-web platform');
      }
      
      // Verify Isar is fully initialized by trying multiple queries
      try {
        // Try to access collections to ensure they're initialized
        await isar.wordSets.count();
        await isar.wordPairs.count();
        // Additional delay to ensure collections are fully ready
        await Future.delayed(const Duration(milliseconds: 200));
        debugPrint('Isar verified and ready');
        return WordMatchRepo(isar);
      } catch (e) {
        debugPrint('Isar not ready yet, attempt ${attempt + 1}: $e');
        if (attempt < 4) {
          await Future.delayed(Duration(milliseconds: 800 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Isar initialization attempt ${attempt + 1} failed: $e');
      if (attempt < 4) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      } else {
        throw StateError('Isar initialization failed after 5 attempts: $e');
      }
    }
  }
  throw StateError('Isar initialization failed: max attempts reached');
});
