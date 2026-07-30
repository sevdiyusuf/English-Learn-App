import '../models/word_pair.dart';
import '../models/word_set.dart';

/// Abstract interface for WordMatchRepo implementations
abstract class WordMatchRepoInterface {
  static const int maxSets = 50;
  static const int maxPairsPerSet = 250;
  static const String wordsFromGamesSetName = 'Words from Games';

  String? get activeOwnerUid;

  Stream<List<WordSet>> watchSets();
  Stream<List<WordSet>> watchLevelSets();
  Stream<List<WordPair>> watchPairs(int setId);
  Future<List<WordPair>> fetchPairs(int setId);
  Future<WordSet?> getSet(int id);
  Future<int> countSets();
  Future<int> countPairs(int setId);
  Future<Map<int, int>> countPairsForSets(List<int> setIds);
  Future<int> createSet(String name);

  /// Merges two sets into a new set (same name as [newName]). Returns the new set id.
  /// Implementations should create the set and copy/deduplicate pairs atomically.
  Future<int> mergeSetsIntoNewSet({
    required int baseSetId,
    required int otherSetId,
    required String newName,
  });

  Future<void> renameSet({required int id, required String name});
  Future<void> deleteSet(int id);
  Future<void> savePairs({
    required int setId,
    required String setName,
    required List<WordPair> pairs,
  });
  Future<void> recordPractice(int setId);
  Future<void> ensureBuiltinSet();
  Future<void> ensureLevelSets();
  Future<void> fixBuiltinSets();
  Future<void> ensureWordsFromGamesSet();
  Future<void> ensureInitialUserSet();
  Future<int?> getWordsFromGamesSetId();
  Future<void> toggleLearned(int pairId, bool learned);
  Future<void> resetAllLearned(int setId);
  Future<Map<int, bool>> getLearnedStatuses(int setId);
  Future<void> updateSetCloudId(int id, String cloudId);
  Future<WordSet?> getSetByCloudId(String cloudId);
  Future<void> updateSetVisibility(int id, SetVisibility visibility);
  Future<void> updateSetOwnerUid(int id, String? ownerUid);
  Future<void> updateSetPendingMigrationUid(int id, String? pendingUid);
  Future<List<WordSet>> getUnmigratedGuestSets();
  Future<List<WordPair>> getUnmigratedGuestPairs(int setId);
  Future<void> updateSetMetadata(
    int id, {
    String? sourceSetId,
    String? sourceOwnerUid,
    DateTime? importedAt,
    String? ownerUid,
    String? pendingMigrationUid,
  });

  // ── Remote-apply path (used exclusively by RemoteWordSetApplier) ─────────
  // These methods do NOT produce Outbox entries.

  /// Creates a new local WordSet from a remote document without triggering
  /// outbox enqueue. Sets ownerUid and cloudId directly.
  Future<int> createSetInternal({
    required String name,
    required String ownerUid,
    required String cloudId,
  });

  /// Renames a WordSet without triggering outbox enqueue.
  Future<void> renameSetInternal({required int id, required String name});

  /// Replaces all pairs for a set without triggering outbox enqueue.
  Future<void> savePairsInternal({
    required int setId,
    required List<WordPair> pairs,
  });

  /// Updates remote-sync metadata on a WordSet:
  /// cloudId, ownerUid, remoteVersion, lastRemoteOperationId,
  /// visibility, sourceSetId, sourceOwnerUid, importedAt,
  /// optionally updatedAt and createdAt (from remote payload).
  Future<void> updateSetRemoteMetadata(
    int setId, {
    required String cloudId,
    required String ownerUid,
    required int remoteVersion,
    required String lastOperationId,
    SetVisibility? visibility,
    String? sourceSetId,
    String? sourceOwnerUid,
    DateTime? importedAt,
    DateTime? updatedAt,
    DateTime? createdAt,
  });

  /// Clears local data (WordSets and Outbox records) belonging to the given uid.
  Future<void> clearUserData(String uid);
}
