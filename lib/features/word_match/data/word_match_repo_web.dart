import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/browser_storage_stub.dart'
    if (dart.library.html) '../../../core/utils/browser_storage_web.dart';

import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo_interface.dart';

/// Web implementation using localStorage
class WordMatchRepoWeb implements WordMatchRepoInterface {
  WordMatchRepoWeb() {
    _migrateToStableNamespace();
    _initNextId();
    _checkIntegrity();
  }

  @override
  Future<WordSet?> getSetByCloudId(String cloudId) async {
    final sets = _loadSets();
    try {
      return sets.firstWhere((s) => s.cloudId == cloudId);
    } catch (_) {
      return null;
    }
  }

  // Old Keys (for migration)
  static const String _oldKeySets = 'word_match_sets';
  static const String _oldKeyPairs = 'word_match_pairs';
  static const String _oldKeyNextId = 'word_match_next_id';
  static const String _storageKeyBackupSets =
      'word_match_sets_backup'; // From previous (failed?) attempt

  // New Stable Namespace Keys
  static const String _keyPrefix = 'yuno_wordmatch_';
  static const String _keySets = '${_keyPrefix}sets';
  static const String _keyPairs = '${_keyPrefix}pairs';
  static const String _keyNextId = '${_keyPrefix}next_id';
  static const String _keyMeta = '${_keyPrefix}meta';
  static const String _keyBackupSets = '${_keyPrefix}backup_sets';
  static const String _keyBackupPairs = '${_keyPrefix}backup_pairs';

  final _setsController = StreamController<List<WordSet>>.broadcast();
  final _pairsControllers = <int, StreamController<List<WordPair>>>{};

  int _nextId = 1;

  void _migrateToStableNamespace() {
    try {
      if (getItem(_keyMeta) != null) return;

      debugPrint('Starting migration to stable namespace...');

      // Migrate Sets
      final oldSets = getItem(_oldKeySets);
      if (oldSets != null && oldSets.isNotEmpty) {
        setItem(_keySets, oldSets);
      }

      // Migrate Pairs
      final oldPairs = getItem(_oldKeyPairs);
      if (oldPairs != null && oldPairs.isNotEmpty) {
        setItem(_keyPairs, oldPairs);
      }

      // Migrate NextId
      final oldNextId = getItem(_oldKeyNextId);
      if (oldNextId != null) {
        setItem(_keyNextId, oldNextId);
      }

      // Migrate Backup
      final oldBackup = getItem(_storageKeyBackupSets);
      if (oldBackup != null) {
        setItem(_keyBackupSets, oldBackup);
      }

      // Create Meta
      final meta = {
        'schemaVersion': 1,
        'migratedAt': DateTime.now().toIso8601String(),
        'lastKnownSetCount':
            oldSets != null ? _parseSetsJson(oldSets).length : 0,
      };
      setItem(_keyMeta, json.encode(meta));

      debugPrint('Migration to stable namespace completed.');
    } catch (e) {
      debugPrint('Error during migration: $e');
    }
  }

  void _initNextId() {
    try {
      final nextIdStr = getItem(_keyNextId);
      if (nextIdStr != null) {
        _nextId = int.parse(nextIdStr);
      }
    } catch (e) {
      debugPrint('Error initializing NextId: $e');
    }
  }

  void _checkIntegrity() {
    try {
      final sets = _loadSets();
      if (sets.isEmpty) {
        // Try recovery from backup
        final backupSets = _loadSetsFromBackup();
        if (backupSets.isNotEmpty) {
          debugPrint('Data loss detected! Recovering from backup...');
          _saveSets(backupSets);

          // Also try to recover pairs if possible
          final backupPairsStr = getItem(_keyBackupPairs);
          if (backupPairsStr != null && backupPairsStr.isNotEmpty) {
            setItem(_keyPairs, backupPairsStr);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking integrity: $e');
    }
  }

  List<WordSet> _loadSets() {
    try {
      final jsonStr = getItem(_keySets);
      if (jsonStr == null || jsonStr.isEmpty) {
        return _loadSetsFromBackup();
      }
      return _parseSetsJson(jsonStr);
    } catch (e) {
      debugPrint('Error loading sets, trying backup: $e');
      return _loadSetsFromBackup();
    }
  }

  List<WordSet> _loadSetsFromBackup() {
    try {
      final jsonStr = getItem(_keyBackupSets);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      return _parseSetsJson(jsonStr);
    } catch (e) {
      debugPrint('Error loading backup sets: $e');
      return [];
    }
  }

  List<WordSet> _parseSetsJson(String jsonStr) {
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    return jsonList
        .map(
          (json) =>
              WordSet()
                ..id = json['id'] as int
                ..name = json['name'] as String
                ..createdAt = DateTime.parse(json['createdAt'] as String)
                ..updatedAt = DateTime.parse(json['updatedAt'] as String)
                ..lastPracticedAt =
                    json['lastPracticedAt'] != null
                        ? DateTime.parse(json['lastPracticedAt'] as String)
                        : null
                ..isBuiltin = json['isBuiltin'] as bool? ?? false
                ..cloudId = json['cloudId'] as String?
                ..visibility = SetVisibility.values.firstWhere(
                  (e) => e.name == (json['visibility'] as String?),
                  orElse: () => SetVisibility.private,
                )
                ..sourceSetId = json['sourceSetId'] as String?
                ..sourceOwnerUid = json['sourceOwnerUid'] as String?
                ..importedAt =
                    json['importedAt'] != null
                        ? DateTime.parse(json['importedAt'] as String)
                        : null,
        )
        .toList();
  }

  void _saveSets(List<WordSet> sets) {
    try {
      final jsonList =
          sets
              .map(
                (set) => {
                  'id': set.id,
                  'name': set.name,
                  'createdAt': set.createdAt.toIso8601String(),
                  'updatedAt': set.updatedAt.toIso8601String(),
                  'lastPracticedAt': set.lastPracticedAt?.toIso8601String(),
                  'isBuiltin': set.isBuiltin,
                  'cloudId': set.cloudId,
                  'visibility': set.visibility.name,
                  'sourceSetId': set.sourceSetId,
                  'sourceOwnerUid': set.sourceOwnerUid,
                  'importedAt': set.importedAt?.toIso8601String(),
                },
              )
              .toList();
      final jsonStr = json.encode(jsonList);

      // Save backup
      try {
        setItem(_keyBackupSets, jsonStr);
      } catch (e) {
        debugPrint('Error saving backup sets: $e');
      }

      setItem(_keySets, jsonStr);
      _notifySetsChanged();

      // Update meta
      try {
        final metaStr = getItem(_keyMeta);
        if (metaStr != null) {
          final meta = json.decode(metaStr) as Map<String, dynamic>;
          meta['lastKnownSetCount'] = sets.length;
          meta['lastUpdatedAt'] = DateTime.now().toIso8601String();
          setItem(_keyMeta, json.encode(meta));
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error saving sets: $e');
    }
  }

  List<WordPair> _loadPairs() {
    try {
      final jsonStr = getItem(_keyPairs);
      if (jsonStr == null || jsonStr.isEmpty) {
        return _loadPairsFromBackup();
      }
      return _parsePairsJson(jsonStr);
    } catch (e) {
      debugPrint('Error loading pairs, trying backup: $e');
      return _loadPairsFromBackup();
    }
  }

  List<WordPair> _loadPairsFromBackup() {
    try {
      final jsonStr = getItem(_keyBackupPairs);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      return _parsePairsJson(jsonStr);
    } catch (e) {
      debugPrint('Error loading backup pairs: $e');
      return [];
    }
  }

  List<WordPair> _parsePairsJson(String jsonStr) {
    final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
    final pairs =
        jsonList
            .map(
              (json) =>
                  WordPair()
                    ..id = _normalizeInt(json['id'])
                    ..setId = _normalizeInt(json['setId'])
                    ..english = (json['english'] as String? ?? '').trim()
                    ..turkish = (json['turkish'] as String? ?? '').trim()
                    ..learned = _normalizeBool(json['learned']),
            )
            .where((pair) => pair.english.isNotEmpty && pair.turkish.isNotEmpty)
            .toList();

    // Remove duplicates per SET (same english+turkish in same setId = duplicate).
    // Do NOT dedupe across sets: same word pair can exist in different sets.
    final seenPerSet = <int, Set<String>>{};
    final uniquePairs = <WordPair>[];
    for (final pair in pairs) {
      final key =
          '${pair.english.toLowerCase().trim()}_${pair.turkish.toLowerCase().trim()}';
      final seen = seenPerSet.putIfAbsent(pair.setId, () => <String>{});
      if (!seen.contains(key)) {
        seen.add(key);
        uniquePairs.add(pair);
      }
    }

    return uniquePairs;
  }

  /// Normalize int values (handles String, int, double)
  int _normalizeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Normalize boolean values (handles String, bool, int)
  bool _normalizeBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  void _savePairs(List<WordPair> pairs) {
    try {
      final jsonList =
          pairs
              .map(
                (pair) => {
                  'id': pair.id,
                  'setId': pair.setId,
                  'english': pair.english,
                  'turkish': pair.turkish,
                  'learned': pair.learned,
                },
              )
              .toList();
      final jsonStr = json.encode(jsonList);

      // Save backup
      try {
        setItem(_keyBackupPairs, jsonStr);
      } catch (e) {
        debugPrint('Error saving backup pairs: $e');
      }

      setItem(_keyPairs, jsonStr);
      _notifyPairsChanged();
    } catch (e) {
      debugPrint('Error saving pairs: $e');
    }
  }

  List<WordSet> _currentSortedSets() {
    final sets = _loadSets();
    sets.sort((a, b) {
      if (a.isBuiltin != b.isBuiltin) {
        return a.isBuiltin ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sets;
  }

  List<WordPair> _currentPairsForSet(int setId) {
    return _loadPairs().where((p) => p.setId == setId).toList();
  }

  void _notifySetsChanged() {
    if (_setsController.hasListener && !_setsController.isClosed) {
      _setsController.add(_currentSortedSets());
    }
  }

  void _notifyPairsChanged() {
    final pairs = _loadPairs();
    final pairsBySet = <int, List<WordPair>>{};
    for (final pair in pairs) {
      pairsBySet.putIfAbsent(pair.setId, () => []).add(pair);
    }
    for (final entry in pairsBySet.entries) {
      final controller = _pairsControllers[entry.key];
      if (controller != null && controller.hasListener) {
        controller.add(entry.value);
      }
    }
  }

  int _getNextId() {
    final id = _nextId++;
    setItem(_keyNextId, id.toString());
    return id;
  }

  Stream<List<WordSet>> _watchAllSets() {
    return Stream<List<WordSet>>.multi((controller) {
      controller.add(_currentSortedSets());
      final sub = _setsController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Stream<List<WordSet>> watchSets() {
    return _watchAllSets().map((sets) {
      return sets
          .where(
            (s) =>
                !s.isBuiltin ||
                s.name == WordMatchRepoInterface.wordsFromGamesSetName,
          )
          .toList();
    });
  }

  @override
  Stream<List<WordSet>> watchLevelSets() {
    return _watchAllSets().map((sets) {
      return sets
          .where(
            (s) =>
                s.isBuiltin &&
                s.name != WordMatchRepoInterface.wordsFromGamesSetName,
          )
          .toList();
    });
  }

  @override
  Stream<List<WordPair>> watchPairs(int setId) {
    final existing = _pairsControllers[setId];
    final controller = existing ?? StreamController<List<WordPair>>.broadcast();
    if (existing == null) {
      _pairsControllers[setId] = controller;
    }
    return Stream<List<WordPair>>.multi((multiController) {
      multiController.add(_currentPairsForSet(setId));
      final sub = controller.stream.listen(
        multiController.add,
        onError: multiController.addError,
      );
      multiController.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<List<WordPair>> fetchPairs(int setId) async {
    return _loadPairs().where((p) => p.setId == setId).toList();
  }

  @override
  Future<WordSet?> getSet(int id) async {
    final sets = _loadSets();
    try {
      return sets.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> countSets() async {
    return _loadSets().length;
  }

  @override
  Future<int> countPairs(int setId) async {
    return _loadPairs().where((p) => p.setId == setId).length;
  }

  @override
  Future<Map<int, int>> countPairsForSets(List<int> setIds) async {
    final pairs = _loadPairs();
    final result = <int, int>{};
    for (final setId in setIds) {
      result[setId] = pairs.where((p) => p.setId == setId).length;
    }
    return result;
  }

  @override
  Future<int> createSet(String name) async {
    final sets = _loadSets();
    if (sets.length >= WordMatchRepoInterface.maxSets) {
      throw StateError(
        'Kelime seti limiti (${WordMatchRepoInterface.maxSets}) aşıldı',
      );
    }
    final now = DateTime.now();
    final setName = name.trim();
    if (setName.isEmpty) {
      throw ArgumentError('Set adı boş olamaz');
    }
    final set =
        WordSet()
          ..id = _getNextId()
          ..name = setName
          ..createdAt = now
          ..updatedAt = now
          ..isBuiltin = false;
    sets.add(set);
    _saveSets(sets);
    return set.id;
  }

  @override
  Future<int> mergeSetsIntoNewSet({
    required int baseSetId,
    required int otherSetId,
    required String newName,
  }) async {
    final basePairs = await fetchPairs(baseSetId);
    final otherPairs = await fetchPairs(otherSetId);
    final allPairs = [...basePairs, ...otherPairs];
    final seen = <String>{};
    final merged = <WordPair>[];
    for (final p in allPairs) {
      if (p.english.trim().isEmpty) continue;
      final key =
          '${p.english.toLowerCase().trim()}|${p.turkish.toLowerCase().trim()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      merged.add(
        WordPair()
          ..id = 0
          ..setId = 0
          ..english = p.english.trim()
          ..turkish = p.turkish.trim()
          ..learned = false,
      );
    }
    if (merged.length > WordMatchRepoInterface.maxPairsPerSet) {
      throw StateError(
        'Birleştirilmiş sette en fazla '
        '${WordMatchRepoInterface.maxPairsPerSet} kelime çifti olabilir.',
      );
    }

    if (merged.isEmpty) {
      // Both source sets were empty; still create the new set
      final newId = await createSet(newName);
      return newId;
    }

    // Reserve new set id and new pair ids WITHOUT notifying yet.
    final newId = _getNextId();
    for (final p in merged) {
      p.id = _getNextId();
      p.setId = newId;
    }

    final sets = _loadSets();
    if (sets.length >= WordMatchRepoInterface.maxSets) {
      throw StateError(
        'Kelime seti limiti (${WordMatchRepoInterface.maxSets}) aşıldı',
      );
    }
    final now = DateTime.now();
    final newSet =
        WordSet()
          ..id = newId
          ..name = newName.trim()
          ..createdAt = now
          ..updatedAt = now
          ..isBuiltin = false;
    sets.add(newSet);

    final allPairsNow = _loadPairs();
    allPairsNow.addAll(merged);

    // Save pairs first, then sets, so when _saveSets triggers notify and sync
    // runs, fetchPairs(newId) already sees the merged pairs.
    _savePairs(allPairsNow);

    // Verify pairs were persisted so fetchPairs(newId) will return them
    final verifyPairs = _loadPairs().where((p) => p.setId == newId).toList();
    if (verifyPairs.length != merged.length) {
      debugPrint(
        'Merge verify failed: saved ${verifyPairs.length} pairs for set $newId, expected ${merged.length}',
      );
    }

    _saveSets(sets);
    _notifyPairsChanged();

    return newId;
  }

  @override
  Future<void> renameSet({required int id, required String name}) async {
    final sets = _loadSets();
    final setIndex = sets.indexWhere((s) => s.id == id);
    if (setIndex == -1) {
      throw StateError('Set bulunamadı');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Set adı boş olamaz');
    }
    sets[setIndex]
      ..name = trimmed
      ..updatedAt = DateTime.now().toUtc();
    _saveSets(sets);
  }

  @override
  Future<void> deleteSet(int id) async {
    final sets = _loadSets();
    final set = sets.firstWhere(
      (s) => s.id == id,
      orElse: () => throw StateError('Set bulunamadı'),
    );
    if (set.isBuiltin) {
      throw StateError('Yerleşik setler silinemez');
    }
    sets.removeWhere((s) => s.id == id);
    _saveSets(sets);
    final pairs = _loadPairs();
    pairs.removeWhere((p) => p.setId == id);
    _savePairs(pairs);
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
    // New pairs (ID=0) should always be added if they don't exist
    final sanitizedPairs = <String, WordPair>{};
    final newPairs = <WordPair>[]; // Track new pairs separately

    for (final pair in pairs) {
      if (pair.english.trim().isEmpty) continue;

      final normalizedKey =
          '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';

      final defaultId = WordPair().id;
      // If this is a new pair (ID=0 or default or setId=0 or setId mismatch), track it separately
      if (pair.id == 0 ||
          pair.id == defaultId ||
          pair.setId == 0 ||
          pair.setId != setId) {
        // Only add if it doesn't already exist
        if (!sanitizedPairs.containsKey(normalizedKey)) {
          // Explicitly create a new object with ID to be assigned later (in the loop below)
          // But for now we just add it to newPairs
          newPairs.add(pair);
        }
        continue;
      }

      // For existing pairs, keep the first one (lower ID = older = first added)
      if (!sanitizedPairs.containsKey(normalizedKey)) {
        sanitizedPairs[normalizedKey] =
            WordPair()
              ..id = pair.id
              ..setId = setId
              ..english = pair.english.trim()
              ..turkish = pair.turkish.trim()
              ..learned = pair.learned;
      }
      // Duplicate found - keep the first one (lower ID), but preserve learned status if needed
      else {
        final existing = sanitizedPairs[normalizedKey]!;
        if (pair.learned && !existing.learned) {
          existing.learned = true;
        }
      }
    }

    // Add new pairs (with assigned IDs) to the map
    for (final newPair in newPairs) {
      final normalizedKey =
          '${newPair.english.toLowerCase().trim()}|${newPair.turkish.toLowerCase().trim()}';

      // Only add if not already present
      sanitizedPairs.putIfAbsent(
        normalizedKey,
        () =>
            WordPair()
              ..id = _getNextId()
              ..setId = setId
              ..english = newPair.english.trim()
              ..turkish = newPair.turkish.trim()
              ..learned = newPair.learned,
      );
    }

    final finalPairs = sanitizedPairs.values.toList();

    final sets = _loadSets();
    final setIndex = sets.indexWhere((s) => s.id == setId);
    if (setIndex == -1) {
      throw StateError('Set bulunamadı');
    }
    sets[setIndex]
      ..name = trimmedName
      ..updatedAt = DateTime.now().toUtc();
    _saveSets(sets);

    final allPairs = _loadPairs();
    allPairs.removeWhere((p) => p.setId == setId);
    allPairs.addAll(finalPairs);
    _savePairs(allPairs);
  }

  @override
  Future<void> recordPractice(int setId) async {
    final sets = _loadSets();
    final setIndex = sets.indexWhere((s) => s.id == setId);
    if (setIndex == -1) {
      return;
    }
    sets[setIndex]
      ..lastPracticedAt = DateTime.now()
      ..updatedAt = DateTime.now();
    _saveSets(sets);
  }

  @override
  Future<void> ensureBuiltinSet() async {
    // Deprecated: 'A2 Sınav Hazırlığı' is removed.
  }

  @override
  Future<void> toggleLearned(int pairId, bool learned) async {
    try {
      final pairs = _loadPairs();
      final pairIndex = pairs.indexWhere((p) => p.id == pairId);
      if (pairIndex == -1) {
        throw StateError('Kelime çifti bulunamadı');
      }
      pairs[pairIndex].learned = learned;
      _savePairs(pairs);
      // Explicitly notify all controllers to ensure UI updates
      _notifyPairsChanged();
    } catch (e) {
      debugPrint('Error toggling learned status: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetAllLearned(int setId) async {
    final pairs = _loadPairs();
    for (final pair in pairs) {
      if (pair.setId == setId) {
        pair.learned = false;
      }
    }
    _savePairs(pairs);
  }

  @override
  Future<Map<int, bool>> getLearnedStatuses(int setId) async {
    final pairs = _currentPairsForSet(setId);
    return {for (var p in pairs) p.id: p.learned};
  }

  @override
  Future<void> ensureLevelSets() async {
    final levels = ['a1', 'a2', 'b1', 'b2'];
    final difficulties = ['Easy', 'Medium', 'Hard'];

    final sets = _loadSets();
    bool changed = false;

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

          final existing = sets.firstWhere(
            (s) => s.name == displayName && s.isBuiltin,
            orElse: () => WordSet()..id = -1,
          );

          if (existing.id == -1) {
            final now = DateTime.now();
            final levelSet =
                WordSet()
                  ..id = _nextId++
                  ..name = displayName
                  ..createdAt = now
                  ..updatedAt = now
                  ..isBuiltin = true;

            sets.add(levelSet);
            changed = true;

            final pairs = _loadPairs();
            for (final wordData in wordList) {
              pairs.add(
                WordPair()
                  ..id = _nextId++
                  ..setId = levelSet.id
                  ..english = wordData['en']
                  ..turkish = wordData['tr'],
              );
            }
            _savePairs(pairs);
          }
        }
      } catch (e) {
        debugPrint('Error loading level set $level in Web: $e');
      }
    }

    if (changed) {
      _saveSets(sets);
      _saveNextId();
    }
  }

  String _getDisplayName(String level, String difficulty) {
    final diffTr =
        {'Easy': 'Kolay', 'Medium': 'Orta', 'Hard': 'Zor'}[difficulty];
    return '${level.toUpperCase()} $diffTr';
  }

  void _saveNextId() {
    setItem(_keyNextId, _nextId.toString());
  }

  @override
  Future<void> fixBuiltinSets() async {
    final sets = _loadSets();
    bool changed = false;
    final idsToDelete = <int>[];

    final levels = ['A1', 'A2', 'B1', 'B2'];
    final diffs = ['Kolay', 'Orta', 'Zor'];
    final levelSetNames = <String>[];
    for (final l in levels) {
      for (final d in diffs) {
        levelSetNames.add('$l $d');
      }
    }

    final authorizedNames = [
      WordMatchRepoInterface.wordsFromGamesSetName,
      ...levelSetNames,
    ];

    // 1. Fix unauthorized builtin flags and remove deprecated sets
    for (final set in sets) {
      if (set.name == 'A2 Sınav Hazırlığı') {
        idsToDelete.add(set.id);
        changed = true;
        continue;
      }
      if (set.isBuiltin) {
        if (!authorizedNames.contains(set.name)) {
          set.isBuiltin = false;
          changed = true;
        }
      }
    }

    // 2. Deduplicate and Repair Authorized Sets
    final repairNames = [
      WordMatchRepoInterface.wordsFromGamesSetName,
      ...levelSetNames,
    ];

    for (final name in repairNames) {
      final matches = sets.where((s) => s.name == name).toList();

      if (matches.isEmpty) continue;

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
          changed = true;
        }

        // Delete others
        for (int i = 1; i < matches.length; i++) {
          idsToDelete.add(matches[i].id);
        }
      } else {
        // Only one exists
        final s = matches.first;
        if (!s.isBuiltin) {
          s.isBuiltin = true;
          changed = true;
        }
      }
    }

    if (idsToDelete.isNotEmpty) {
      sets.removeWhere((s) => idsToDelete.contains(s.id));
      changed = true;
    }

    if (changed) {
      _saveSets(sets);
      if (idsToDelete.isNotEmpty) {
        final pairs = _loadPairs();
        final initialLen = pairs.length;
        pairs.removeWhere((p) => idsToDelete.contains(p.setId));
        if (pairs.length != initialLen) {
          _savePairs(pairs);
        }
      }
    }
  }

  @override
  Future<void> ensureInitialUserSet() async {
    final sets = _loadSets();
    // Check if user has any custom sets
    final customSetsCount = sets.where((s) => !s.isBuiltin).length;

    if (customSetsCount > 0) {
      return; // Already has sets
    }

    // Create the default set
    final now = DateTime.now();
    final initialSet = WordSet()
      ..id = _getNextId()
      ..name = 'Kelime Setim 1'
      ..createdAt = now
      ..updatedAt = now
      ..isBuiltin = false;

    sets.add(initialSet);
    _saveSets(sets);
  }

  @override
  Future<void> ensureWordsFromGamesSet() async {
    final sets = _loadSets();
    try {
      // Check by name ONLY to avoid duplicates
      sets.firstWhere((s) => s.name == 'Words from Games');
      // Set already exists
      return;
    } catch (_) {
      // Set doesn't exist, continue to create it
    }

    final now = DateTime.now().toUtc();
    final wordsFromGamesSet =
        WordSet()
          ..id = _getNextId()
          ..name = 'Words from Games'
          ..createdAt = now
          ..updatedAt = now
          ..isBuiltin = true;

    sets.add(wordsFromGamesSet);
    _saveSets(sets);
  }

  @override
  Future<int?> getWordsFromGamesSetId() async {
    final sets = _loadSets();
    try {
      final set = sets.firstWhere(
        (s) => s.name == 'Words from Games' && s.isBuiltin,
      );
      return set.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateSetCloudId(int id, String cloudId) async {
    final sets = _loadSets();
    final index = sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      sets[index].cloudId = cloudId;
      _saveSets(sets);
    }
  }

  @override
  Future<void> updateSetVisibility(int id, SetVisibility visibility) async {
    final sets = _loadSets();
    final index = sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      sets[index]
        ..visibility = visibility
        ..updatedAt = DateTime.now().toUtc();
      _saveSets(sets);
    }
  }

  @override
  Future<void> updateSetMetadata(
    int id, {
    String? sourceSetId,
    String? sourceOwnerUid,
    DateTime? importedAt,
  }) async {
    final sets = _loadSets();
    final index = sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      final set = sets[index];
      if (sourceSetId != null) set.sourceSetId = sourceSetId;
      if (sourceOwnerUid != null) set.sourceOwnerUid = sourceOwnerUid;
      if (importedAt != null) set.importedAt = importedAt;
      set.updatedAt = DateTime.now().toUtc();
      _saveSets(sets);
    }
  }
}
