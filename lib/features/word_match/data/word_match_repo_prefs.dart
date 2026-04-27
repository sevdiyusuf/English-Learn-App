import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo_interface.dart';

/// SharedPreferences implementation as fallback when Isar fails on Android APK
class WordMatchRepoPrefs implements WordMatchRepoInterface {
  WordMatchRepoPrefs() {
    _initPrefs();
  }

  static const String _storageKeySets = 'word_match_sets';
  static const String _storageKeyPairs = 'word_match_pairs';
  static const String _storageKeyNextId = 'word_match_next_id';

  final _setsController = StreamController<List<WordSet>>.broadcast();
  final _pairsControllers = <int, StreamController<List<WordPair>>>{};

  int _nextId = 1;
  SharedPreferences? _prefs;
  final _initCompleter = Completer<void>();

  void _initPrefs() {
    // Async initialization in background
    SharedPreferences.getInstance()
        .then((prefs) {
          _prefs = prefs;
          final nextIdStr = prefs.getString(_storageKeyNextId);
          if (nextIdStr != null) {
            _nextId = int.parse(nextIdStr);
          }
          if (!_initCompleter.isCompleted) {
            _initCompleter.complete();
          }
        })
        .catchError((e) {
          debugPrint('Error initializing WordMatchRepoPrefs: $e');
          if (!_initCompleter.isCompleted) {
            _initCompleter.complete();
          }
        });
  }

  Future<SharedPreferences> _getPrefs() async {
    // Wait for initialization if not complete
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<WordSet>> _loadSets() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_storageKeySets);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
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
                    (e) => e.index == (json['visibility'] as int? ?? 0),
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
    } catch (e) {
      debugPrint('Error loading sets: $e');
      return [];
    }
  }

  @override
  Future<WordSet?> getSetByCloudId(String cloudId) async {
    final sets = await _loadSets();
    try {
      return sets.firstWhere((s) => s.cloudId == cloudId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSets(List<WordSet> sets) async {
    try {
      final prefs = await _getPrefs();
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
                  'visibility': set.visibility.index,
                  'sourceSetId': set.sourceSetId,
                  'sourceOwnerUid': set.sourceOwnerUid,
                  'importedAt': set.importedAt?.toIso8601String(),
                },
              )
              .toList();
      await prefs.setString(_storageKeySets, json.encode(jsonList));
      _notifySetsChanged();
    } catch (e) {
      debugPrint('Error saving sets: $e');
    }
  }

  Future<List<WordPair>> _loadPairs() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_storageKeyPairs);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
      return jsonList
          .map(
            (json) =>
                WordPair()
                  ..id = json['id'] as int
                  ..setId = json['setId'] as int
                  ..english = json['english'] as String
                  ..turkish = json['turkish'] as String
                  ..learned = json['learned'] as bool? ?? false,
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading pairs: $e');
      return [];
    }
  }

  Future<void> _savePairs(List<WordPair> pairs) async {
    try {
      final prefs = await _getPrefs();
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
      await prefs.setString(_storageKeyPairs, json.encode(jsonList));
      _notifyPairsChanged();
    } catch (e) {
      debugPrint('Error saving pairs: $e');
    }
  }

  Future<List<WordSet>> _currentSortedSets() async {
    final sets = await _loadSets();
    sets.sort((a, b) {
      if (a.isBuiltin != b.isBuiltin) {
        return a.isBuiltin ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sets;
  }

  Future<List<WordPair>> _currentPairsForSet(int setId) async {
    final pairs = await _loadPairs();
    return pairs.where((p) => p.setId == setId).toList();
  }

  void _notifySetsChanged() {
    _currentSortedSets().then((sets) {
      if (_setsController.hasListener && !_setsController.isClosed) {
        _setsController.add(sets);
      }
    });
  }

  void _notifyPairsChanged() {
    _loadPairs().then((pairs) {
      final pairsBySet = <int, List<WordPair>>{};
      for (final pair in pairs) {
        pairsBySet.putIfAbsent(pair.setId, () => []).add(pair);
      }
      for (final entry in pairsBySet.entries) {
        final controller = _pairsControllers[entry.key];
        if (controller != null &&
            controller.hasListener &&
            !controller.isClosed) {
          controller.add(entry.value);
        }
      }
    });
  }

  int _getNextId() {
    final id = _nextId++;
    _getPrefs().then((prefs) {
      prefs.setString(_storageKeyNextId, id.toString());
    });
    return id;
  }

  Stream<List<WordSet>> _watchAllSets() {
    return Stream<List<WordSet>>.multi((controller) {
      _currentSortedSets().then((sets) {
        controller.add(sets);
        final sub = _setsController.stream.listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = () => sub.cancel();
      });
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
      _currentPairsForSet(setId).then((pairs) {
        multiController.add(pairs);
        final sub = controller.stream.listen(
          multiController.add,
          onError: multiController.addError,
        );
        multiController.onCancel = () => sub.cancel();
      });
    });
  }

  @override
  Future<List<WordPair>> fetchPairs(int setId) async {
    final pairs = await _loadPairs();
    return pairs.where((p) => p.setId == setId).toList();
  }

  @override
  Future<WordSet?> getSet(int id) async {
    final sets = await _loadSets();
    try {
      return sets.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> countSets() async {
    return (await _loadSets()).length;
  }

  @override
  Future<int> countPairs(int setId) async {
    final pairs = await _loadPairs();
    return pairs.where((p) => p.setId == setId).length;
  }

  @override
  Future<Map<int, int>> countPairsForSets(List<int> setIds) async {
    final pairs = await _loadPairs();
    final result = <int, int>{};
    for (final setId in setIds) {
      result[setId] = pairs.where((p) => p.setId == setId).length;
    }
    return result;
  }

  @override
  Future<int> createSet(String name) async {
    final sets = await _loadSets();
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
    await _saveSets(sets);
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
    final newId = await createSet(newName);
    for (final p in merged) {
      p.setId = newId;
    }
    await savePairs(setId: newId, setName: newName.trim(), pairs: merged);
    return newId;
  }

  @override
  Future<void> renameSet({required int id, required String name}) async {
    final sets = await _loadSets();
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
      ..updatedAt = DateTime.now();
    await _saveSets(sets);
  }

  @override
  Future<void> deleteSet(int id) async {
    final sets = await _loadSets();
    final set = sets.firstWhere(
      (s) => s.id == id,
      orElse: () => throw StateError('Set bulunamadı'),
    );
    if (set.isBuiltin) {
      throw StateError('Yerleşik setler silinemez');
    }
    sets.removeWhere((s) => s.id == id);
    await _saveSets(sets);
    final pairs = await _loadPairs();
    pairs.removeWhere((p) => p.setId == id);
    await _savePairs(pairs);

    _pairsControllers[id]?.close();
    _pairsControllers.remove(id);
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
    final sanitizedPairs = <String, WordPair>{};
    final newPairs = <WordPair>[];

    for (final pair in pairs) {
      if (pair.english.trim().isEmpty) continue;

      final normalizedKey =
          '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';

      if (pair.id == 0 || pair.setId != setId) {
        if (!sanitizedPairs.containsKey(normalizedKey)) {
          // Treat as new pair to be assigned a new ID
          newPairs.add(pair);
        }
        continue;
      }

      if (!sanitizedPairs.containsKey(normalizedKey)) {
        sanitizedPairs[normalizedKey] =
            WordPair()
              ..id = pair.id
              ..setId = setId
              ..english = pair.english.trim()
              ..turkish = pair.turkish.trim()
              ..learned = pair.learned;
      } else {
        final existing = sanitizedPairs[normalizedKey]!;
        if (pair.learned && !existing.learned) {
          existing.learned = true;
        }
      }
    }

    for (final newPair in newPairs) {
      final normalizedKey =
          '${newPair.english.toLowerCase().trim()}|${newPair.turkish.toLowerCase().trim()}';
      sanitizedPairs[normalizedKey] =
          WordPair()
            ..id = _getNextId()
            ..setId = setId
            ..english = newPair.english.trim()
            ..turkish = newPair.turkish.trim()
            ..learned = newPair.learned;
    }

    final finalPairs = sanitizedPairs.values.toList();

    final sets = await _loadSets();
    final setIndex = sets.indexWhere((s) => s.id == setId);
    if (setIndex == -1) {
      throw StateError('Set bulunamadı');
    }
    sets[setIndex]
      ..name = trimmedName
      ..updatedAt = DateTime.now();
    await _saveSets(sets);

    final allPairs = await _loadPairs();
    allPairs.removeWhere((p) => p.setId == setId);
    allPairs.addAll(finalPairs);
    await _savePairs(allPairs);
  }

  @override
  Future<void> recordPractice(int setId) async {
    final sets = await _loadSets();
    final setIndex = sets.indexWhere((s) => s.id == setId);
    if (setIndex == -1) {
      return;
    }
    sets[setIndex]
      ..lastPracticedAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await _saveSets(sets);
  }

  @override
  Future<void> ensureBuiltinSet() async {
    // Deprecated: 'A2 Sınav Hazırlığı' is removed.
  }

  @override
  Future<void> ensureLevelSets() async {
    final levels = ['a1', 'a2', 'b1', 'b2'];
    final difficulties = ['Easy', 'Medium', 'Hard'];

    final sets = await _currentSortedSets();
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

            final pairs = await _loadPairs();
            for (final wordData in wordList) {
              pairs.add(
                WordPair()
                  ..id = _nextId++
                  ..setId = levelSet.id
                  ..english = wordData['en']
                  ..turkish = wordData['tr'],
              );
            }
            await _savePairs(pairs);
          }
        }
      } catch (e) {
        debugPrint('Error loading level set $level in Prefs: $e');
      }
    }

    if (changed) {
      await _saveSets(sets);
      await _saveNextId();
    }
  }

  String _getDisplayName(String level, String difficulty) {
    final diffTr =
        {'Easy': 'Kolay', 'Medium': 'Orta', 'Hard': 'Zor'}[difficulty];
    return '${level.toUpperCase()} $diffTr';
  }

  Future<void> _saveNextId() async {
    final prefs = await _getPrefs();
    await prefs.setString(_storageKeyNextId, _nextId.toString());
  }

  @override
  Future<void> fixBuiltinSets() async {
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
    final sets = await _currentSortedSets();
    bool changed = false;
    final idsToDelete = <int>[];

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

    if (idsToDelete.isNotEmpty) {
      for (final id in idsToDelete) {
        await deleteSet(id);
      }
      idsToDelete.clear();
    }

    // 2. Deduplicate and Repair Authorized Sets
    final repairNames = [
      WordMatchRepoInterface.wordsFromGamesSetName,
      ...levelSetNames,
    ];
    for (final name in repairNames) {
      final matches = sets.where((s) => s.name == name).toList();
      if (matches.length > 1) {
        matches.sort((a, b) {
          if (a.isBuiltin && !b.isBuiltin) return -1;
          if (!a.isBuiltin && b.isBuiltin) return 1;
          return a.id.compareTo(b.id);
        });

        final keep = matches.first;
        if (!keep.isBuiltin) {
          keep.isBuiltin = true;
          changed = true;
        }

        for (int i = 1; i < matches.length; i++) {
          idsToDelete.add(matches[i].id);
        }
      } else if (matches.length == 1) {
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
      await _saveSets(sets);
      if (idsToDelete.isNotEmpty) {
        final pairs = await _loadPairs();
        final initialLen = pairs.length;
        pairs.removeWhere((p) => idsToDelete.contains(p.setId));
        if (pairs.length != initialLen) {
          await _savePairs(pairs);
        }
      }
    }
  }

  @override
  Future<void> ensureWordsFromGamesSet() async {
    final sets = await _loadSets();
    try {
      sets.firstWhere((s) => s.name == 'Words from Games');
      return;
    } catch (_) {
      // Not found, continue to create
    }

    final now = DateTime.now();
    final wordsFromGamesSet =
        WordSet()
          ..id = _getNextId()
          ..name = 'Words from Games'
          ..createdAt = now
          ..updatedAt = now
          ..isBuiltin = true;

    sets.add(wordsFromGamesSet);
    await _saveSets(sets);
  }

  @override
  Future<int?> getWordsFromGamesSetId() async {
    final sets = await _loadSets();
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
  Future<void> toggleLearned(int pairId, bool learned) async {
    final pairs = await _loadPairs();
    final pairIndex = pairs.indexWhere((p) => p.id == pairId);
    if (pairIndex == -1) {
      throw StateError('Kelime çifti bulunamadı');
    }
    pairs[pairIndex].learned = learned;
    await _savePairs(pairs);
  }

  @override
  Future<void> resetAllLearned(int setId) async {
    final pairs = await _loadPairs();
    for (final pair in pairs) {
      if (pair.setId == setId) {
        pair.learned = false;
      }
    }
    await _savePairs(pairs);
  }

  @override
  Future<Map<int, bool>> getLearnedStatuses(int setId) async {
    final pairs = await _currentPairsForSet(setId);
    return {for (var p in pairs) p.id: p.learned};
  }

  @override
  Future<void> updateSetCloudId(int id, String cloudId) async {
    final sets = await _loadSets();
    final index = sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      sets[index].cloudId = cloudId;
      await _saveSets(sets);
    }
  }

  @override
  Future<void> updateSetVisibility(int id, SetVisibility visibility) async {
    final sets = await _loadSets();
    final index = sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      sets[index]
        ..visibility = visibility
        ..updatedAt = DateTime.now().toUtc();
      await _saveSets(sets);
    }
  }

  @override
  Future<void> updateSetMetadata(
    int id, {
    String? sourceSetId,
    String? sourceOwnerUid,
    DateTime? importedAt,
  }) async {
    final sets = await _loadSets();
    final index = sets.indexWhere((s) => s.id == id);
    if (index != -1) {
      final set = sets[index];
      if (sourceSetId != null) set.sourceSetId = sourceSetId;
      if (sourceOwnerUid != null) set.sourceOwnerUid = sourceOwnerUid;
      if (importedAt != null) set.importedAt = importedAt;
      set.updatedAt = DateTime.now().toUtc();
      await _saveSets(sets);
    }
  }
}
