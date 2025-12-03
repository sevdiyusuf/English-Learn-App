import '../models/word_pair.dart';
import '../models/word_set.dart';

/// Abstract interface for WordMatchRepo implementations
abstract class WordMatchRepoInterface {
  static const int maxSets = 50;
  static const int maxPairsPerSet = 50;

  Stream<List<WordSet>> watchSets();
  Stream<List<WordPair>> watchPairs(int setId);
  Future<List<WordPair>> fetchPairs(int setId);
  Future<WordSet?> getSet(int id);
  Future<int> countSets();
  Future<int> countPairs(int setId);
  Future<Map<int, int>> countPairsForSets(List<int> setIds);
  Future<int> createSet(String name);
  Future<void> renameSet({required int id, required String name});
  Future<void> deleteSet(int id);
  Future<void> savePairs({
    required int setId,
    required String setName,
    required List<WordPair> pairs,
  });
  Future<void> recordPractice(int setId);
  Future<void> ensureBuiltinSet();
  Future<void> ensureWordsFromGamesSet();
  Future<int?> getWordsFromGamesSetId();
  Future<void> toggleLearned(int pairId, bool learned);
  Future<void> resetAllLearned(int setId);
  Future<Map<int, bool>> getLearnedStatuses(int setId);
}
