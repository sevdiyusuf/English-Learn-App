import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo_interface.dart';

class WordMatchRepo implements WordMatchRepoInterface {
  WordMatchRepo(this._isar);

  final Isar _isar;

  static const String wordsFromGamesSetName =
      WordMatchRepoInterface.wordsFromGamesSetName;

  @override
  Stream<List<WordSet>> watchSets() {
    return _isar.wordSets
        .filter()
        .isBuiltinEqualTo(false)
        .or()
        .nameEqualTo(wordsFromGamesSetName)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<WordSet>> watchLevelSets() {
    return _isar.wordSets
        .filter()
        .isBuiltinEqualTo(true)
        .not()
        .nameEqualTo(wordsFromGamesSetName)
        .watch(fireImmediately: true);
  }

  @override
  Stream<List<WordPair>> watchPairs(int setId) {
    return _isar.wordPairs
        .filter()
        .setIdEqualTo(setId)
        .watch(fireImmediately: true);
  }

  @override
  Future<List<WordPair>> fetchPairs(int setId) {
    return _isar.wordPairs.filter().setIdEqualTo(setId).findAll();
  }

  @override
  Future<WordSet?> getSet(int id) => _isar.wordSets.get(id);

  @override
  Future<int> countSets() => _isar.wordSets.count();

  @override
  Future<int> countPairs(int setId) =>
      _isar.wordPairs.filter().setIdEqualTo(setId).count();

  @override
  Future<Map<int, int>> countPairsForSets(List<int> setIds) async {
    final result = <int, int>{};
    for (final id in setIds) {
      result[id] = await countPairs(id);
    }
    return result;
  }

  @override
  Future<WordSet?> getSetByCloudId(String cloudId) {
    return _isar.wordSets.filter().cloudIdEqualTo(cloudId).findFirst();
  }

  @override
  Future<int> createSet(String name) async {
    final setCount = await countSets();
    if (setCount >= WordMatchRepoInterface.maxSets) {
      throw StateError(
        'Kelime seti limiti (${WordMatchRepoInterface.maxSets}) aşıldı',
      );
    }
    final now = DateTime.now().toUtc();
    final setName = name.trim();
    if (setName.isEmpty) {
      throw ArgumentError('Set adı boş olamaz');
    }
    final set =
        WordSet()
          ..name = setName
          ..createdAt = now
          ..updatedAt = now
          ..isBuiltin = false;
    return _isar.writeTxn(() async {
      final id = await _isar.wordSets.put(set);
      return id;
    });
  }

  /// Merge two sets into a new set. Reads pairs outside txn; in txn creates set
  /// and inserts pairs with explicitly assigned ids so every pair is stored.
  @override
  Future<int> mergeSetsIntoNewSet({
    required int baseSetId,
    required int otherSetId,
    required String newName,
  }) async {
    if (baseSetId == otherSetId) {
      throw ArgumentError('Aynı seti kendiyle birleştiremezsiniz');
    }
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Set adı boş olamaz');
    }

    // 1) Read pairs OUTSIDE write transaction (avoid any txn read/write interaction)
    final basePairs =
        await _isar.wordPairs.filter().setIdEqualTo(baseSetId).findAll();
    final otherPairs =
        await _isar.wordPairs.filter().setIdEqualTo(otherSetId).findAll();
    final allPairs = [...basePairs, ...otherPairs];

    final seen = <String>{};
    final toInsert = <WordPair>[];
    for (final p in allPairs) {
      if (p.english.trim().isEmpty) continue;
      final key =
          '${p.english.toLowerCase().trim()}|${p.turkish.toLowerCase().trim()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      toInsert.add(
        WordPair()
          ..setId = 0
          ..english = p.english.trim()
          ..turkish = p.turkish.trim()
          ..learned = false,
      );
    }

    if (toInsert.length > WordMatchRepoInterface.maxPairsPerSet) {
      throw StateError(
        'Birleştirilmiş sette en fazla '
        '${WordMatchRepoInterface.maxPairsPerSet} kelime çifti olabilir.',
      );
    }

    if (toInsert.isEmpty) {
      // Only create empty set
      return createSet(trimmedName);
    }

    // 2) Get current max id so we can assign unique ids (read outside txn)
    int nextId = 1;
    final existingIds = await _isar.wordPairs.where().findAll();
    for (final o in existingIds) {
      if (o.id >= nextId) nextId = o.id + 1;
    }

    // 3) Assign explicit id and newSetId to each pair
    final newSetId = await _isar.writeTxn(() async {
      final setCount = await _isar.wordSets.count();
      if (setCount >= WordMatchRepoInterface.maxSets) {
        throw StateError(
          'Kelime seti limiti (${WordMatchRepoInterface.maxSets}) aşıldı',
        );
      }
      final now = DateTime.now().toUtc();
      final newSet =
          WordSet()
            ..name = trimmedName
            ..createdAt = now
            ..updatedAt = now
            ..isBuiltin = false;
      final id = await _isar.wordSets.put(newSet);

      for (final p in toInsert) {
        p.id = nextId++;
        p.setId = id;
      }
      await _isar.wordPairs.putAll(toInsert);
      return id;
    });

    return newSetId;
  }

  @override
  Future<void> renameSet({required int id, required String name}) async {
    final set = await _isar.wordSets.get(id);
    if (set == null) {
      throw StateError('Set bulunamadı');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Set adı boş olamaz');
    }
    final updated =
        set
          ..name = trimmed
          ..updatedAt = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      await _isar.wordSets.put(updated);
    });
  }

  @override
  Future<void> deleteSet(int id) async {
    await _isar.writeTxn(() async {
      final set = await _isar.wordSets.get(id);
      if (set == null) {
        throw StateError('Set bulunamadı');
      }
      if (set.isBuiltin) {
        throw StateError('Yerleşik setler silinemez');
      }
      await _isar.wordPairs.filter().setIdEqualTo(id).deleteAll();
      await _isar.wordSets.delete(id);
    });
  }

  @override
  Future<void> savePairs({
    required int setId,
    required String setName,
    required List<WordPair> pairs,
  }) async {
    if (pairs.length > WordMatchRepoInterface.maxPairsPerSet) {
      throw StateError(
        'Bir sette en fazla ${WordMatchRepoInterface.maxPairsPerSet} çift olabilir',
      );
    }
    final trimmedName = setName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Set adı boş olamaz');
    }

    // Sanitize and remove duplicates (case-insensitive)
    // IMPORTANT: Process pairs in order - first occurrence wins
    final sanitizedPairsMap = <String, WordPair>{};

    for (final pair in pairs) {
      if (pair.english.trim().isEmpty) continue;

      final normalizedKey =
          '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';

      // Skip if we already have this pair (deduplication)
      if (sanitizedPairsMap.containsKey(normalizedKey)) {
        continue;
      }

      // Determine if this is a new pair or an existing one
      final isNewPair =
          pair.id == 0 ||
          pair.id == Isar.autoIncrement ||
          pair.setId == 0 ||
          pair.setId != setId;

      if (isNewPair) {
        // Create a completely NEW WordPair instance for new pairs
        // This ensures Isar treats it as a brand new object
        sanitizedPairsMap[normalizedKey] =
            WordPair()
              ..id =
                  Isar
                      .autoIncrement // Let Isar assign new ID
              ..setId =
                  setId // Set to the target set ID
              ..english = pair.english.trim()
              ..turkish = pair.turkish.trim()
              ..learned = pair.learned; // Preserve learned status if provided
      } else {
        // For existing pairs, create a copy with the same ID but ensure setId matches
        sanitizedPairsMap[normalizedKey] =
            WordPair()
              ..id =
                  pair
                      .id // Keep existing ID
              ..setId =
                  setId // Ensure setId matches (might have changed)
              ..english = pair.english.trim()
              ..turkish = pair.turkish.trim()
              ..learned = pair.learned; // Preserve learned status
      }
    }

    final sanitizedPairs = sanitizedPairsMap.values.toList(growable: false);

    // Perform all operations in a single transaction for atomicity
    await _isar.writeTxn(() async {
      // Verify set exists
      final set = await _isar.wordSets.get(setId);
      if (set == null) {
        throw StateError('Set bulunamadı');
      }

      // Update set metadata
      set
        ..name = trimmedName
        ..updatedAt = DateTime.now();
      await _isar.wordSets.put(set);

      // Delete all existing pairs for this set
      await _isar.wordPairs.filter().setIdEqualTo(setId).deleteAll();

      // Insert pairs one-by-one so each gets a unique auto-increment ID.
      // putAll() with multiple objects all having id==Isar.autoIncrement can
      // cause only one to be stored (same ID assigned to all).
      for (final pair in sanitizedPairs) {
        await _isar.wordPairs.put(pair);
      }
    });
  }

  @override
  Future<void> recordPractice(int setId) async {
    await _isar.writeTxn(() async {
      final set = await _isar.wordSets.get(setId);
      if (set == null) {
        return;
      }
      set
        ..lastPracticedAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await _isar.wordSets.put(set);
    });
  }

  /// Ensures the built-in A2 exam prep set exists.
  /// Called on first app launch or when Word Match module is first accessed.
  @override
  Future<void> ensureBuiltinSet() async {
    // Deprecated: 'A2 Sınav Hazırlığı' is removed.
    // Level sets are now handled by ensureLevelSets().
  }

  @override
  Future<void> ensureLevelSets() async {
    final levels = ['a1', 'a2', 'b1', 'b2'];
    final difficulties = ['Easy', 'Medium', 'Hard'];

    for (final level in levels) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/word_sets/${level}_set.json',
        );
        final Map<String, dynamic> data = json.decode(jsonString);

        for (final difficulty in difficulties) {
          final key = '${level.toUpperCase()}_$difficulty';
          if (!data.containsKey(key)) continue;

          final List<dynamic> wordList = data[key];
          final String displayName = _getDisplayName(level, difficulty);

          await _isar.writeTxn(() async {
            final existing =
                await _isar.wordSets
                    .filter()
                    .nameEqualTo(displayName)
                    .isBuiltinEqualTo(true)
                    .findFirst();

            if (existing == null) {
              final now = DateTime.now();
              final levelSet =
                  WordSet()
                    ..name = displayName
                    ..createdAt = now
                    ..updatedAt = now
                    ..isBuiltin = true;

              final setId = await _isar.wordSets.put(levelSet);

              final pairs = <WordPair>[];
              for (final wordData in wordList) {
                pairs.add(
                  WordPair()
                    ..setId = setId
                    ..english = wordData['en']
                    ..turkish = wordData['tr'],
                );
              }
              await _isar.wordPairs.putAll(pairs);
            }
          });
        }
      } catch (e) {
        print('Error loading level set $level: $e');
      }
    }
  }

  String _getDisplayName(String level, String difficulty) {
    final diffTr =
        {'Easy': 'Kolay', 'Medium': 'Orta', 'Hard': 'Zor'}[difficulty];
    return '${level.toUpperCase()} $diffTr';
  }

  @override
  Future<void> fixBuiltinSets() async {
    await _isar.writeTxn(() async {
      final sets = await _isar.wordSets.where().findAll();

      final levels = ['A1', 'A2', 'B1', 'B2'];
      final diffs = ['Kolay', 'Orta', 'Zor'];
      final levelSetNames = <String>[];
      for (final l in levels) {
        for (final d in diffs) {
          levelSetNames.add('$l $d');
        }
      }

      final authorizedNames = [wordsFromGamesSetName, ...levelSetNames];

      // 1. Fix unauthorized builtin flags and remove deprecated sets
      for (final set in sets) {
        if (set.name == 'A2 Sınav Hazırlığı') {
          // Explicitly delete the deprecated set
          await deleteSet(set.id);
          continue;
        }
        if (set.isBuiltin) {
          if (!authorizedNames.contains(set.name)) {
            set.isBuiltin = false;
            await _isar.wordSets.put(set);
          }
        }
      }

      // 2. Deduplicate and Repair Authorized Sets
      for (final name in authorizedNames) {
        final matches = sets.where((s) => s.name == name).toList();
        if (matches.length > 1) {
          // Prioritize: isBuiltin=true, then ID order
          matches.sort((a, b) {
            if (a.isBuiltin && !b.isBuiltin) return -1;
            if (!a.isBuiltin && b.isBuiltin) return 1;
            return a.id.compareTo(b.id);
          });

          // Keep first
          final keep = matches.first;
          if (!keep.isBuiltin) {
            keep.isBuiltin = true;
            await _isar.wordSets.put(keep);
          }

          // Delete others
          for (int i = 1; i < matches.length; i++) {
            final toDelete = matches[i];
            await _isar.wordSets.delete(toDelete.id);
            await _isar.wordPairs
                .filter()
                .setIdEqualTo(toDelete.id)
                .deleteAll();
          }
        } else if (matches.length == 1) {
          final s = matches.first;
          if (!s.isBuiltin) {
            s.isBuiltin = true;
            await _isar.wordSets.put(s);
          }
        }
      }
    });
  }

  @override
  Future<void> toggleLearned(int pairId, bool learned) async {
    await _isar.writeTxn(() async {
      final pair = await _isar.wordPairs.get(pairId);
      if (pair == null) {
        throw StateError('Kelime çifti bulunamadı');
      }
      pair.learned = learned;
      await _isar.wordPairs.put(pair);
    });
  }

  @override
  Future<void> resetAllLearned(int setId) async {
    await _isar.writeTxn(() async {
      final pairs =
          await _isar.wordPairs.filter().setIdEqualTo(setId).findAll();
      for (final pair in pairs) {
        pair.learned = false;
      }
      await _isar.wordPairs.putAll(pairs);
    });
  }

  @override
  Future<Map<int, bool>> getLearnedStatuses(int setId) async {
    final pairs = await _isar.wordPairs.filter().setIdEqualTo(setId).findAll();
    return {for (final pair in pairs) pair.id: pair.learned};
  }

  /// Ensures the "Words from Games" set exists.
  /// This set is used to store words saved from various minigames.
  @override
  Future<void> ensureWordsFromGamesSet() async {
    await _isar.writeTxn(() async {
      // Check if "Words from Games" set already exists by name
      final existing =
          await _isar.wordSets
              .filter()
              .nameEqualTo(wordsFromGamesSetName)
              .findFirst();
      if (existing != null) {
        return; // Already exists
      }

      // Create the "Words from Games" set
      final now = DateTime.now();
      final wordsFromGamesSet =
          WordSet()
            ..name = wordsFromGamesSetName
            ..createdAt = now
            ..updatedAt = now
            ..isBuiltin = true;

      await _isar.wordSets.put(wordsFromGamesSet);
    });
  }

  /// Gets the ID of the "Words from Games" set.
  /// Returns null if the set doesn't exist.
  @override
  Future<int?> getWordsFromGamesSetId() async {
    final set =
        await _isar.wordSets
            .filter()
            .nameEqualTo(wordsFromGamesSetName)
            .isBuiltinEqualTo(true)
            .findFirst();
    return set?.id;
  }

  @override
  Future<void> updateSetCloudId(int id, String cloudId) async {
    final set = await _isar.wordSets.get(id);
    if (set != null) {
      set.cloudId = cloudId;
      await _isar.writeTxn(() async {
        await _isar.wordSets.put(set);
      });
    }
  }

  @override
  Future<void> updateSetVisibility(int id, SetVisibility visibility) async {
    final set = await _isar.wordSets.get(id);
    if (set != null) {
      set.visibility = visibility;
      set.updatedAt = DateTime.now().toUtc();
      await _isar.writeTxn(() async {
        await _isar.wordSets.put(set);
      });
    }
  }

  @override
  Future<void> updateSetMetadata(
    int id, {
    String? sourceSetId,
    String? sourceOwnerUid,
    DateTime? importedAt,
  }) async {
    final set = await _isar.wordSets.get(id);
    if (set != null) {
      if (sourceSetId != null) set.sourceSetId = sourceSetId;
      if (sourceOwnerUid != null) set.sourceOwnerUid = sourceOwnerUid;
      if (importedAt != null) set.importedAt = importedAt;
      set.updatedAt = DateTime.now().toUtc();
      await _isar.writeTxn(() async {
        await _isar.wordSets.put(set);
      });
    }
  }
}
