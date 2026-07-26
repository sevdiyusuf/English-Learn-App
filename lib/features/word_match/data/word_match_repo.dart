import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../../sync/data/outbox_repository.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo_interface.dart';

class WordMatchRepo implements WordMatchRepoInterface {
  WordMatchRepo(this._isar, {this.activeOwnerUid, OutboxRepository? outboxRepo})
    : _outboxRepo = outboxRepo;

  final Isar _isar;
  final OutboxRepository? _outboxRepo;
  @override
  final String? activeOwnerUid;

  static const String wordsFromGamesSetName =
      WordMatchRepoInterface.wordsFromGamesSetName;

  bool _matchesScope(WordSet? set) {
    if (set == null) return false;
    if (set.isBuiltin) return true;
    return set.ownerUid == activeOwnerUid;
  }

  @override
  Stream<List<WordSet>> watchSets() {
    final QueryBuilder<WordSet, WordSet, QAfterFilterCondition> query;
    if (activeOwnerUid == null) {
      query = _isar.wordSets
          .filter()
          .isBuiltinEqualTo(false)
          .ownerUidIsNull()
          .or()
          .isBuiltinEqualTo(true);
    } else {
      query = _isar.wordSets
          .filter()
          .isBuiltinEqualTo(false)
          .ownerUidEqualTo(activeOwnerUid)
          .or()
          .isBuiltinEqualTo(true);
    }
    return query.sortByUpdatedAtDesc().watch(fireImmediately: true);
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
  Stream<List<WordPair>> watchPairs(int setId) async* {
    final set = await getSet(setId);
    if (set == null) {
      yield [];
      return;
    }
    yield* _isar.wordPairs
        .filter()
        .setIdEqualTo(setId)
        .watch(fireImmediately: true);
  }

  @override
  Future<List<WordPair>> fetchPairs(int setId) async {
    final set = await getSet(setId);
    if (set == null) return [];
    return _isar.wordPairs.filter().setIdEqualTo(setId).findAll();
  }

  @override
  Future<WordSet?> getSet(int id) async {
    final set = await _isar.wordSets.get(id);
    if (_matchesScope(set)) return set;
    return null;
  }

  @override
  Future<int> countSets() async {
    final QueryBuilder<WordSet, WordSet, QAfterFilterCondition> customQuery;
    if (activeOwnerUid == null) {
      customQuery =
          _isar.wordSets.filter().isBuiltinEqualTo(false).ownerUidIsNull();
    } else {
      customQuery = _isar.wordSets
          .filter()
          .isBuiltinEqualTo(false)
          .ownerUidEqualTo(activeOwnerUid);
    }
    return customQuery
        .or()
        .group(
          (q) => q.isBuiltinEqualTo(true).nameEqualTo(wordsFromGamesSetName),
        )
        .count();
  }

  @override
  Future<int> countPairs(int setId) async {
    final set = await getSet(setId);
    if (set == null) return 0;
    return _isar.wordPairs.filter().setIdEqualTo(setId).count();
  }

  @override
  Future<Map<int, int>> countPairsForSets(List<int> setIds) async {
    final result = <int, int>{};
    for (final id in setIds) {
      final set = await getSet(id);
      if (set != null) {
        result[id] = await countPairs(id);
      }
    }
    return result;
  }

  @override
  Future<WordSet?> getSetByCloudId(String cloudId) async {
    final set =
        await _isar.wordSets.filter().cloudIdEqualTo(cloudId).findFirst();
    if (_matchesScope(set)) return set;
    return null;
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
          ..isBuiltin = false
          ..ownerUid = activeOwnerUid;

    return _isar.writeTxn(() async {
      final id = await _isar.wordSets.put(set);
      // Atomically enqueue create to outbox (guest sets are not enqueued)
      final outbox = _outboxRepo;
      if (activeOwnerUid != null && outbox != null) {
        final payload = <String, dynamic>{
          'name': setName,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'visibility': set.visibility.name,
          'pairs': <dynamic>[],
        };
        await outbox.enqueueCreateInsideTxn(
          ownerUid: activeOwnerUid,
          entityType: 'word_set',
          entityId: id.toString(),
          payload: payload,
        );
      }
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
            ..isBuiltin = false
            ..ownerUid = activeOwnerUid;
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
    final set = await getSet(id);
    if (set == null) {
      throw StateError('Set bulunamadı');
    }
    if (set.isBuiltin) {
      throw StateError('Yerleşik setler değiştirilemez');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Set adı boş olamaz');
    }
    final now = DateTime.now().toUtc();
    final updated =
        set
          ..name = trimmed
          ..updatedAt = now;
    await _isar.writeTxn(() async {
      await _isar.wordSets.put(updated);
      // Atomically enqueue update to outbox
      final outbox = _outboxRepo;
      if (activeOwnerUid != null && outbox != null) {
        final existingPairs =
            await _isar.wordPairs.filter().setIdEqualTo(id).findAll();
        final pairsJson =
            existingPairs
                .map(
                  (p) => {
                    'english': p.english,
                    'turkish': p.turkish,
                    'learned': p.learned,
                  },
                )
                .toList();
        final payload = <String, dynamic>{
          'name': trimmed,
          'updatedAt': now.toIso8601String(),
          'pairs': pairsJson,
        };
        await outbox.enqueueUpdateInsideTxn(
          ownerUid: activeOwnerUid,
          entityType: 'word_set',
          entityId: id.toString(),
          payload: payload,
          remoteVersion: updated.remoteVersion,
        );
      }
    });
  }

  @override
  Future<void> deleteSet(int id) async {
    final set = await getSet(id);
    if (set == null) {
      throw StateError('Set bulunamadı');
    }
    if (set.isBuiltin) {
      throw StateError('Yerleşik setler silinemez');
    }
    await _isar.writeTxn(() async {
      await _isar.wordPairs.filter().setIdEqualTo(id).deleteAll();
      await _isar.wordSets.delete(id);
      // Atomically enqueue delete (tombstone) to outbox
      final outbox = _outboxRepo;
      if (activeOwnerUid != null && outbox != null) {
        await outbox.enqueueDeleteInsideTxn(
          ownerUid: activeOwnerUid,
          entityType: 'word_set',
          entityId: id.toString(),
          remoteVersion: set.remoteVersion,
        );
      }
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

      final isNewPair = pair.id == 0 || pair.id == Isar.autoIncrement;
      pair.setId = setId;

      final normalizedKey =
          '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';

      // Skip if we already have this pair (deduplication)
      if (sanitizedPairsMap.containsKey(normalizedKey)) {
        continue;
      }

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
      // Verify set exists and matches scope
      final set = await getSet(setId);
      if (set == null) {
        throw StateError('Set bulunamadı');
      }
      if (set.isBuiltin) {
        throw StateError('Yerleşik setler değiştirilemez');
      }

      // Update set metadata
      final now = DateTime.now();
      set
        ..name = trimmedName
        ..updatedAt = now;
      await _isar.wordSets.put(set);

      // Delete all existing pairs for this set
      await _isar.wordPairs.filter().setIdEqualTo(setId).deleteAll();

      // Insert pairs one-by-one so each gets a unique auto-increment ID.
      // putAll() with multiple objects all having id==Isar.autoIncrement can
      // cause only one to be stored (same ID assigned to all).
      for (final pair in sanitizedPairs) {
        await _isar.wordPairs.put(pair);
      }

      // Atomically enqueue update to outbox
      final outbox = _outboxRepo;
      if (activeOwnerUid != null && outbox != null) {
        final pairsJson =
            sanitizedPairs
                .map(
                  (p) => {
                    'english': p.english,
                    'turkish': p.turkish,
                    'learned': p.learned,
                  },
                )
                .toList();
        final payload = <String, dynamic>{
          'name': trimmedName,
          'updatedAt': now.toUtc().toIso8601String(),
          'pairs': pairsJson,
        };
        await outbox.enqueueUpdateInsideTxn(
          ownerUid: activeOwnerUid,
          entityType: 'word_set',
          entityId: setId.toString(),
          payload: payload,
          remoteVersion: set.remoteVersion,
        );
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
        debugPrint('Error loading level set $level: $e');
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

  /// Ensures the initial user set "Kelime Setim 1" exists if the user has no custom sets.
  @override
  Future<void> ensureInitialUserSet() async {
    await _isar.writeTxn(() async {
      final existingSets =
          await _isar.wordSets.filter().isBuiltinEqualTo(false).findAll();
      final scopedCustomSets =
          existingSets.where((s) => _matchesScope(s)).toList();

      if (scopedCustomSets.isNotEmpty) {
        return;
      }

      final now = DateTime.now();
      final initialSet =
          WordSet()
            ..name = 'Kelime Setim 1'
            ..createdAt = now
            ..updatedAt = now
            ..isBuiltin = false
            ..ownerUid = activeOwnerUid;

      await _isar.wordSets.put(initialSet);
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
    if (set == null || set.isBuiltin) return;
    if (set.ownerUid == activeOwnerUid ||
        (set.ownerUid == null &&
            (set.pendingMigrationUid == null ||
                set.pendingMigrationUid == activeOwnerUid))) {
      set.cloudId = cloudId;
      await _isar.writeTxn(() async {
        await _isar.wordSets.put(set);
      });
    }
  }

  @override
  Future<void> updateSetVisibility(int id, SetVisibility visibility) async {
    final set = await getSet(id);
    if (set == null || set.isBuiltin) return;
    set.visibility = visibility;
    set.updatedAt = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      await _isar.wordSets.put(set);
    });
  }

  @override
  Future<void> updateSetOwnerUid(int id, String? ownerUid) async {
    final set = await _isar.wordSets.get(id);
    if (set == null || set.isBuiltin) {
      throw StateError('Set bulunamadı veya yerel sahiplik değiştirilemez');
    }
    // Only guest sets (ownerUid == null) can be migrated to activeOwnerUid
    if (set.ownerUid != null ||
        ownerUid == null ||
        ownerUid != activeOwnerUid) {
      throw StateError('Geçersiz sahiplik transferi');
    }
    set.ownerUid = ownerUid;
    set.pendingMigrationUid = null;
    await _isar.writeTxn(() async {
      await _isar.wordSets.put(set);
    });
  }

  @override
  Future<void> updateSetPendingMigrationUid(int id, String? pendingUid) async {
    final set = await _isar.wordSets.get(id);
    if (set == null || set.isBuiltin || set.ownerUid != null) {
      throw StateError('Set bulunamadı veya migrasyon durumu değiştirilemez');
    }
    if (set.pendingMigrationUid != null &&
        set.pendingMigrationUid != pendingUid &&
        activeOwnerUid != null) {
      throw StateError('Geçersiz migrasyon sahibi');
    }
    if (pendingUid != null &&
        activeOwnerUid != null &&
        pendingUid != activeOwnerUid) {
      throw StateError('Geçersiz migrasyon sahibi');
    }
    set.pendingMigrationUid = pendingUid;
    await _isar.writeTxn(() async {
      await _isar.wordSets.put(set);
    });
  }

  @override
  Future<List<WordSet>> getUnmigratedGuestSets() async {
    return _isar.wordSets
        .filter()
        .isBuiltinEqualTo(false)
        .ownerUidIsNull()
        .findAll();
  }

  @override
  Future<List<WordPair>> getUnmigratedGuestPairs(int setId) async {
    final set = await _isar.wordSets.get(setId);
    if (set == null || set.isBuiltin || set.ownerUid != null) {
      return [];
    }
    return _isar.wordPairs.filter().setIdEqualTo(setId).findAll();
  }

  @override
  Future<void> updateSetMetadata(
    int id, {
    String? sourceSetId,
    String? sourceOwnerUid,
    DateTime? importedAt,
    String? ownerUid,
    String? pendingMigrationUid,
  }) async {
    final set = await getSet(id);
    if (set != null && !set.isBuiltin) {
      if (sourceSetId != null) set.sourceSetId = sourceSetId;
      if (sourceOwnerUid != null) set.sourceOwnerUid = sourceOwnerUid;
      if (importedAt != null) set.importedAt = importedAt;
      if (ownerUid != null && ownerUid == activeOwnerUid) {
        set.ownerUid = ownerUid;
      }
      if (pendingMigrationUid != null) {
        set.pendingMigrationUid = pendingMigrationUid;
      }
      set.updatedAt = DateTime.now().toUtc();
      await _isar.writeTxn(() async {
        await _isar.wordSets.put(set);
      });
    }
  }

  // ── Remote-apply path (no Outbox) ────────────────────────────────────────

  @override
  Future<int> createSetInternal({
    required String name,
    required String ownerUid,
    required String cloudId,
  }) async {
    final now = DateTime.now().toUtc();
    final set =
        WordSet()
          ..name = name.isEmpty ? cloudId : name
          ..createdAt = now
          ..updatedAt = now
          ..isBuiltin = false
          ..ownerUid = ownerUid
          ..cloudId = cloudId;
    return _isar.writeTxn(() async {
      return _isar.wordSets.put(set);
    });
  }

  @override
  Future<void> renameSetInternal({
    required int id,
    required String name,
  }) async {
    final set = await _isar.wordSets.get(id);
    if (set == null || set.isBuiltin) return;
    set
      ..name = name
      ..updatedAt = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      await _isar.wordSets.put(set);
    });
  }

  @override
  Future<void> savePairsInternal({
    required int setId,
    required List<WordPair> pairs,
  }) async {
    await _isar.writeTxn(() async {
      await _isar.wordPairs.filter().setIdEqualTo(setId).deleteAll();
      for (final pair in pairs) {
        pair
          ..id = Isar.autoIncrement
          ..setId = setId;
        await _isar.wordPairs.put(pair);
      }
    });
  }

  @override
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
  }) async {
    final set = await _isar.wordSets.get(setId);
    if (set == null) return;
    set
      ..cloudId = cloudId
      ..ownerUid = ownerUid
      ..remoteVersion = remoteVersion
      ..lastRemoteOperationId = lastOperationId;
    if (visibility != null) set.visibility = visibility;
    if (sourceSetId != null) set.sourceSetId = sourceSetId;
    if (sourceOwnerUid != null) set.sourceOwnerUid = sourceOwnerUid;
    if (importedAt != null) set.importedAt = importedAt;
    if (updatedAt != null) set.updatedAt = updatedAt;
    if (createdAt != null) set.createdAt = createdAt;
    await _isar.writeTxn(() async {
      await _isar.wordSets.put(set);
    });
  }

  @override
  Future<void> clearUserData(String uid) async {
    await _isar.writeTxn(() async {
      final sets = await _isar.wordSets.filter().ownerUidEqualTo(uid).findAll();
      for (final set in sets) {
        final pairs =
            await _isar.wordPairs.filter().setIdEqualTo(set.id).findAll();
        final pairIds = pairs.map((p) => p.id).toList();
        await _isar.wordPairs.deleteAll(pairIds);
      }
      final setIds = sets.map((s) => s.id).toList();
      await _isar.wordSets.deleteAll(setIds);
    });

    if (_outboxRepo != null) {
      await _outboxRepo.clearUserData(uid);
    }
  }
}
