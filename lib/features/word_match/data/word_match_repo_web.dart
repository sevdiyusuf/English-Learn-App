import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/utils/browser_storage_stub.dart'
    if (dart.library.html) '../../../core/utils/browser_storage_web.dart';

import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo_interface.dart';

/// Web implementation using localStorage
class WordMatchRepoWeb implements WordMatchRepoInterface {
  WordMatchRepoWeb() {
    _init();
  }

  static const String _storageKeySets = 'word_match_sets';
  static const String _storageKeyPairs = 'word_match_pairs';
  static const String _storageKeyNextId = 'word_match_next_id';

  final _setsController = StreamController<List<WordSet>>.broadcast();
  final _pairsControllers = <int, StreamController<List<WordPair>>>{};

  int _nextId = 1;

  void _init() {
    try {
      final nextIdStr = getItem(_storageKeyNextId);
      if (nextIdStr != null) {
        _nextId = int.parse(nextIdStr);
      }
    } catch (e) {
      debugPrint('Error initializing WordMatchRepoWeb: $e');
    }
  }

  List<WordSet> _loadSets() {
    try {
      final jsonStr = getItem(_storageKeySets);
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
                  ..isBuiltin = json['isBuiltin'] as bool? ?? false,
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading sets: $e');
      return [];
    }
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
                },
              )
              .toList();
      setItem(_storageKeySets, json.encode(jsonList));
      _notifySetsChanged();
    } catch (e) {
      debugPrint('Error saving sets: $e');
    }
  }

  List<WordPair> _loadPairs() {
    try {
      final jsonStr = getItem(_storageKeyPairs);
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
      setItem(_storageKeyPairs, json.encode(jsonList));
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
    setItem(_storageKeyNextId, id.toString());
    return id;
  }

  @override
  Stream<List<WordSet>> watchSets() {
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
      ..updatedAt = DateTime.now();
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
      
      final normalizedKey = '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';
      
      // If this is a new pair (ID=0), track it separately
      if (pair.id == 0) {
        // Only add if it doesn't already exist
        if (!sanitizedPairs.containsKey(normalizedKey)) {
          newPairs.add(pair);
        }
        continue;
      }
      
      // For existing pairs, keep the first one (lower ID = older = first added)
      if (!sanitizedPairs.containsKey(normalizedKey)) {
        sanitizedPairs[normalizedKey] = WordPair()
          ..id = pair.id
          ..setId = setId
          ..english = pair.english.trim()
          ..turkish = pair.turkish.trim()
          ..learned = pair.learned;
      } else {
        // Duplicate found - keep the first one (lower ID), but preserve learned status if needed
        final existing = sanitizedPairs[normalizedKey]!;
        if (pair.learned && !existing.learned) {
          // Update learned status if new one is learned
          existing.learned = true;
        }
      }
    }
    
    // Add new pairs (with assigned IDs) to the map
    for (final newPair in newPairs) {
      final normalizedKey = '${newPair.english.toLowerCase().trim()}|${newPair.turkish.toLowerCase().trim()}';
      sanitizedPairs[normalizedKey] = WordPair()
        ..id = _getNextId()
        ..setId = setId
        ..english = newPair.english.trim()
        ..turkish = newPair.turkish.trim()
        ..learned = newPair.learned;
    }
    
    final finalPairs = sanitizedPairs.values.toList();

    final sets = _loadSets();
    final setIndex = sets.indexWhere((s) => s.id == setId);
    if (setIndex == -1) {
      throw StateError('Set bulunamadı');
    }
    sets[setIndex]
      ..name = trimmedName
      ..updatedAt = DateTime.now();
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
    final sets = _loadSets();
    final existing =
        sets
            .where((s) => s.name == 'A2 Sınav Hazırlığı' && s.isBuiltin)
            .firstOrNull;
    if (existing != null) {
      return;
    }

    final now = DateTime.now();
    final builtinSet =
        WordSet()
          ..id = _getNextId()
          ..name = 'A2 Sınav Hazırlığı'
          ..createdAt = now
          ..updatedAt = now
          ..isBuiltin = true;

    sets.add(builtinSet);
    _saveSets(sets);

    final pairs = _getBuiltinWordPairs(builtinSet.id);
    final allPairs = _loadPairs();
    allPairs.addAll(pairs);
    _savePairs(allPairs);
  }

  List<WordPair> _getBuiltinWordPairs(int setId) {
    final pairs = <WordPair>[];
    final wordList = [
      ['be crazy about', 'bir şeye bayılmak / çok düşkün olmak'],
      ['bargain', 'pazarlık, kelepir ürün'],
      ['consumer', 'tüketici'],
      ['prefer', 'tercih etmek'],
      ['expert', 'uzman'],
      ['jewelry store', 'kuyumcu'],
      ['estate agent\'s', 'emlakçı'],
      ['pharmacy', 'eczane'],
      ['tailors', 'terziler'],
      ['cosmopolitan', 'kozmopolit (çok kültürlü)'],
      ['cozy', 'samimi, sıcak, rahat'],
      ['a stroll', 'yürüyüş'],
      ['on a budget', 'kısıtlı bütçeyle'],
      ['authentic', 'otantik, özgün'],
      ['emission', 'salınım, yayma (özellikle gaz)'],
      ['affordable', 'uygun fiyatlı'],
      ['cheap', 'ucuz'],
      ['unforgettable', 'unutulmaz'],
      ['journey', 'yolculuk'],
      ['slow down', 'yavaşlamak'],
      ['tram', 'tramvay'],
      ['on the way', 'yolda'],
      ['take the train', 'trene binmek'],
      ['drive to work', 'işe arabayla gitmek'],
      ['fuel', 'yakıt'],
      ['direction', 'yön'],
      ['select', 'seçmek'],
      ['zoom', 'yakınlaştırmak / zoom yapmak'],
      ['represent', 'temsil etmek'],
      ['reporter', 'muhabir'],
      ['eye witness', 'görgü tanığı'],
      ['emergency services', 'acil servisler'],
      ['emergency', 'acil durum'],
      ['incident', 'olay'],
      ['hood', 'kaput (araba), kapüşon'],
      ['stuff (v.)', 'doldurmak / tıkmak'],
      ['fortune', 'servet, talih'],
      ['mystery', 'gizem'],
      ['shock', 'şok'],
      ['advert', 'reklam'],
      ['luxury', 'lüks'],
      ['discount', 'indirim'],
      ['professional', 'profesyonel'],
      ['small ad', 'küçük ilan'],
      ['formal', 'resmi'],
      ['nervous', 'gergin, endişeli'],
      ['refuse', 'reddetmek'],
      ['fail', 'başarısız olmak'],
      ['arrive', 'varmak'],
      ['glad', 'memnun, mutlu'],
      ['janitor', 'kapıcı, hademe'],
      ['overtime', 'fazla mesai'],
      ['shifts', 'vardiyalar'],
      ['appointment', 'randevu'],
      ['catering firm', 'yemek/hizmet şirketi'],
      ['exciting', 'heyecan verici'],
      ['boring', 'sıkıcı'],
      ['interesting', 'ilginç'],
      ['tiring', 'yorucu'],
      ['repetitive', 'tekrarlı'],
      ['challenging', 'zorlayıcı'],
      ['skilled', 'becerili'],
      ['unskilled', 'beceriksiz'],
      ['stressful', 'stresli'],
      ['well-paid', 'iyi maaşlı'],
      ['badly-paid', 'kötü maaşlı'],
      ['crime', 'suç'],
      ['serious', 'ciddi'],
      ['petty', 'küçük, önemsiz (suçlar için)'],
      ['everyday', 'günlük'],
      ['equipment', 'ekipman'],
      ['get ready', 'hazırlanmak'],
      ['pack', 'eşyaları toplamak'],
      ['to be good at', 'bir şeyde iyi olmak'],
      ['to be nervous about', 'bir şey hakkında gergin olmak'],
      ['get back', 'geri dönmek'],
      ['identity', 'kimlik'],
      ['confirm', 'doğrulamak'],
      ['attend', 'katılmak'],
      ['documents', 'belgeler'],
      ['requires', 'gerektirir'],
      ['declare', 'beyan etmek'],
      ['confiscate', 'el koymak'],
      ['import', 'ithalat'],
      ['export', 'ihracat'],
      ['regulations', 'yönetmelikler / kurallar'],
      ['luxurious', 'çok lüks'],
      ['ancient', 'antik'],
      ['genuine', 'gerçek, hakiki'],
      ['effective', 'etkili'],
      ['contemporary', 'çağdaş'],
      ['church', 'kilise'],
      ['monastery', 'manastır'],
      ['palace', 'saray'],
      ['explore', 'keşfetmek'],
      ['impressive', 'etkileyici'],
      ['common', 'yaygın'],
      ['injury', 'yaralanma'],
      ['choking', 'boğulma'],
      ['at risk', 'risk altında'],
      ['poisoning', 'zehirlenme'],
      ['preventative medicine', 'önleyici tıp'],
      ['supplement', 'takviye'],
      ['natural remedy', 'doğal tedavi / doğal ilaç'],
      ['deficiency', 'eksiklik'],
      ['G.P. (general practitioner)', 'pratisyen hekim'],
      ['tent', 'çadır'],
      ['sleeping bag', 'uyku tulumu'],
      ['camping stove', 'kamp ocağı'],
      ['compass', 'pusula'],
      ['map', 'harita'],
      ['first aid kit', 'ilk yardım çantası'],
      ['bandage', 'bandaj'],
      ['myth', 'mit'],
      ['grave', 'mezar'],
      ['coffin', 'tabut'],
      ['suspect', 'şüphelenmek'],
      ['repel', 'püskürtmek, itmek'],
      ['ceremony', 'tören'],
      ['responsible for', 'sorumlu'],
      ['bless', 'kutsamak'],
      ['tradition', 'gelenek'],
      ['infidelity', 'sadakatsizlik'],
      ['study', 'çalışma'],
      ['achieve', 'başarmak'],
      ['reward', 'ödüllendirmek'],
      ['raise', 'yükseltmek / artırmak'],
      ['sponsor', 'desteklemek, sponsor olmak'],
      ['apologize', 'özür dilemek'],
      ['editor', 'editör'],
      ['proposal', 'teklif, öneri'],
      ['briefing', 'bilgilendirme toplantısı'],
      ['put up with', 'katlanmak'],
      ['disturb', 'rahatsız etmek'],
      ['realize', 'fark etmek'],
      ['volume', 'ses seviyesi'],
      ['relieved', 'rahatlamış'],
      ['honest', 'dürüst'],
      ['mean', 'kötü / cimri'],
      ['kind', 'kibar, nazik'],
      ['friendly', 'arkadaş canlısı'],
      ['helpful', 'yardımsever'],
      ['shy', 'utangaç'],
      ['funny', 'komik'],
      ['polite', 'nazik'],
      ['rude', 'kaba'],
      ['brave', 'cesur'],
      ['lazy', 'tembel'],
      ['hard-working', 'çalışkan'],
      ['clever', 'zeki'],
      ['confident', 'kendine güvenen'],
      ['patient', 'sabırlı'],
      ['quiet', 'sessiz'],
      ['talkative', 'konuşkan'],
      ['generous', 'cömert'],
      ['careful', 'dikkatli'],
    ];

    for (final entry in wordList) {
      pairs.add(
        WordPair()
          ..id = _getNextId()
          ..setId = setId
          ..english = entry[0]
          ..turkish = entry[1]
          ..learned = false,
      );
    }

    return pairs;
  }

  @override
  Future<void> toggleLearned(int pairId, bool learned) async {
    final pairs = _loadPairs();
    final pairIndex = pairs.indexWhere((p) => p.id == pairId);
    if (pairIndex == -1) {
      throw StateError('Kelime çifti bulunamadı');
    }
    pairs[pairIndex].learned = learned;
    _savePairs(pairs);
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
    final pairs = _loadPairs()
        .where((p) => p.setId == setId)
        .toList();
    return {for (final pair in pairs) pair.id: pair.learned};
  }

  @override
  Future<void> ensureWordsFromGamesSet() async {
    final sets = _loadSets();
    try {
      sets.firstWhere(
        (s) => s.name == 'Words from Games' && s.isBuiltin,
      );
      // Set already exists
      return;
    } catch (_) {
      // Set doesn't exist, continue to create it
    }

    final now = DateTime.now();
    final wordsFromGamesSet = WordSet()
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
}
