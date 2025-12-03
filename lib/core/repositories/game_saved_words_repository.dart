import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/word_match/data/word_match_providers.dart';
import '../../features/word_match/models/word_pair.dart';

/// Repository for saving words from games to the "Words from Games" set
abstract class GameSavedWordsRepository {
  /// Saves a word pair to the "Words from Games" set
  /// Returns true if the word was saved successfully, false if it already exists
  Future<bool> saveToWordsFromGames({
    required String english,
    required String turkish,
    String? sourceGame,
  });
  
  /// Removes duplicate word pairs from the "Words from Games" set
  /// Returns the number of duplicates removed
  Future<int> removeDuplicatesFromWordsFromGames();
}

class GameSavedWordsRepositoryImpl implements GameSavedWordsRepository {
  GameSavedWordsRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  Future<bool> saveToWordsFromGames({
    required String english,
    required String turkish,
    String? sourceGame,
  }) async {
    try {
      // Get the repository instance
      final repo = await _ref.read(wordMatchRepoProvider.future);
      
      // Ensure "Words from Games" set exists
      await repo.ensureWordsFromGamesSet();
      
      // Get the set ID
      final setId = await repo.getWordsFromGamesSetId();
      if (setId == null) {
        throw StateError('Words from Games set could not be found or created');
      }
      
      // Check if the word pair already exists (case-insensitive, trimmed)
      final existingPairs = await repo.fetchPairs(setId);
      final normalizedEnglish = english.toLowerCase().trim();
      final normalizedTurkish = turkish.toLowerCase().trim();
      final normalizedKey = '$normalizedEnglish|$normalizedTurkish';
      
      // Check if word already exists
      final alreadyExists = existingPairs.any(
        (pair) =>
            pair.english.toLowerCase().trim() == normalizedEnglish &&
            pair.turkish.toLowerCase().trim() == normalizedTurkish,
      );
      
      if (alreadyExists) {
        return false; // Word already exists
      }
      
      // Remove duplicates from existing pairs (keep first occurrence = lower ID)
      final deduplicatedExisting = <String, WordPair>{};
      for (final pair in existingPairs) {
        final key = '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';
        // Keep the first occurrence (lower ID = older)
        if (!deduplicatedExisting.containsKey(key)) {
          deduplicatedExisting[key] = pair;
        }
      }
      
      // Double-check: if new word exists in deduplicated map, return false
      if (deduplicatedExisting.containsKey(normalizedKey)) {
        return false; // Word already exists
      }
      
      // Create the new word pair (ID=0, will be assigned by savePairs)
      final newPair = WordPair()
        ..id = 0 // Will be assigned by savePairs
        ..setId = setId
        ..english = english.trim()
        ..turkish = turkish.trim()
        ..learned = false;
      
      // Combine existing deduplicated pairs with new pair
      final allPairs = <WordPair>[
        ...deduplicatedExisting.values,
        newPair,
      ];
      
      // Save all pairs back (savePairs will handle ID assignment and final deduplication)
      await repo.savePairs(
        setId: setId,
        setName: 'Words from Games',
        pairs: allPairs,
      );
      
      return true; // Successfully saved
    } catch (e) {
      // Log error and rethrow
      throw StateError('Failed to save word to Words from Games: $e');
    }
  }
  
  @override
  Future<int> removeDuplicatesFromWordsFromGames() async {
    try {
      // Get the repository instance
      final repo = await _ref.read(wordMatchRepoProvider.future);
      
      // Get the set ID
      final setId = await repo.getWordsFromGamesSetId();
      if (setId == null) {
        throw StateError('Words from Games set could not be found');
      }
      
      // Get all pairs
      final existingPairs = await repo.fetchPairs(setId);
      final originalCount = existingPairs.length;
      
      // Remove duplicates (case-insensitive, keep first occurrence)
      final normalizedPairs = <String, WordPair>{};
      for (final pair in existingPairs) {
        final key = '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';
        // Keep the first occurrence (or the one with higher ID if same)
        if (!normalizedPairs.containsKey(key) || pair.id > normalizedPairs[key]!.id) {
          normalizedPairs[key] = pair;
        }
      }
      
      final deduplicatedPairs = normalizedPairs.values.toList();
      final removedCount = originalCount - deduplicatedPairs.length;
      
      // Save deduplicated pairs back
      if (removedCount > 0) {
        await repo.savePairs(
          setId: setId,
          setName: 'Words from Games',
          pairs: deduplicatedPairs,
        );
      }
      
      return removedCount;
    } catch (e) {
      throw StateError('Failed to remove duplicates from Words from Games: $e');
    }
  }
}

/// Provider for GameSavedWordsRepository
final gameSavedWordsRepositoryProvider =
    Provider<GameSavedWordsRepository>((ref) {
  return GameSavedWordsRepositoryImpl(ref);
});

