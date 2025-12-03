import 'package:isar/isar.dart';

import '../models/word_pair.dart';
import '../models/word_set.dart';
import 'word_match_repo_interface.dart';

class WordMatchRepo implements WordMatchRepoInterface {
  WordMatchRepo(this._isar);

  final Isar _isar;

  static const String builtinSetId = 'builtin_a2_exam_prep';
  static const String wordsFromGamesSetName = 'Words from Games';

  @override
  Stream<List<WordSet>> watchSets() {
    return _isar.wordSets
        .where()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true)
        .map((sets) {
          // Sort manually: built-in sets first, then by updatedAt
          final sorted = List<WordSet>.from(sets);
          sorted.sort((a, b) {
            if (a.isBuiltin != b.isBuiltin) {
              return a.isBuiltin ? -1 : 1; // built-in first
            }
            return b.updatedAt.compareTo(a.updatedAt); // newest first
          });
          return sorted;
        });
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
  Future<int> createSet(String name) async {
    final setCount = await countSets();
    if (setCount >= WordMatchRepoInterface.maxSets) {
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
          ..name = setName
          ..createdAt = now
          ..updatedAt = now;
    return _isar.writeTxn(() async {
      final id = await _isar.wordSets.put(set);
      return id;
    });
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
          ..updatedAt = DateTime.now();
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
    // New pairs (ID=0) should always be added if they don't exist
    final sanitizedPairsMap = <String, WordPair>{};
    final newPairs = <WordPair>[]; // Track new pairs separately
    
    for (final pair in pairs) {
      if (pair.english.trim().isEmpty) continue;
      
      final normalizedKey = '${pair.english.toLowerCase().trim()}|${pair.turkish.toLowerCase().trim()}';
      
      // If this is a new pair (ID=0), track it separately
      if (pair.id == 0) {
        // Only add if it doesn't already exist
        if (!sanitizedPairsMap.containsKey(normalizedKey)) {
          newPairs.add(pair);
        }
        continue;
      }
      
      // For existing pairs, keep the first one (lower ID = older = first added)
      if (!sanitizedPairsMap.containsKey(normalizedKey)) {
        sanitizedPairsMap[normalizedKey] = WordPair()
          ..id = pair.id // Mevcut ID'yi koru (yeni pair'ler için Isar otomatik atar)
          ..setId = setId
          ..english = pair.english.trim()
          ..turkish = pair.turkish.trim();
      }
      // Duplicate found - keep the first one (already in map)
    }
    
    // Add new pairs to the map (Isar will assign IDs automatically)
    for (final newPair in newPairs) {
      final normalizedKey = '${newPair.english.toLowerCase().trim()}|${newPair.turkish.toLowerCase().trim()}';
      sanitizedPairsMap[normalizedKey] = WordPair()
        ..id = 0 // Isar will assign ID automatically
        ..setId = setId
        ..english = newPair.english.trim()
        ..turkish = newPair.turkish.trim();
    }
    
    final sanitizedPairs = sanitizedPairsMap.values.toList(growable: false);

    await _isar.writeTxn(() async {
      final set = await _isar.wordSets.get(setId);
      if (set == null) {
        throw StateError('Set bulunamadı');
      }
      set
        ..name = trimmedName
        ..updatedAt = DateTime.now();
      await _isar.wordSets.put(set);

      await _isar.wordPairs.filter().setIdEqualTo(setId).deleteAll();
      await _isar.wordPairs.putAll(sanitizedPairs);
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
    await _isar.writeTxn(() async {
      // Check if built-in set already exists by name
      final existing =
          await _isar.wordSets
              .filter()
              .nameEqualTo('A2 Sınav Hazırlığı')
              .isBuiltinEqualTo(true)
              .findFirst();
      if (existing != null) {
        return; // Already exists
      }

      // Create the built-in set
      final now = DateTime.now();
      final builtinSet =
          WordSet()
            ..name = 'A2 Sınav Hazırlığı'
            ..createdAt = now
            ..updatedAt = now
            ..isBuiltin = true;

      final setId = await _isar.wordSets.put(builtinSet);

      // Add all word pairs
      final pairs = _getBuiltinWordPairs(setId);
      await _isar.wordPairs.putAll(pairs);
    });
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
          ..setId = setId
          ..english = entry[0]
          ..turkish = entry[1],
      );
    }

    return pairs;
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
      final pairs = await _isar.wordPairs
          .filter()
          .setIdEqualTo(setId)
          .findAll();
      for (final pair in pairs) {
        pair.learned = false;
      }
      await _isar.wordPairs.putAll(pairs);
    });
  }

  @override
  Future<Map<int, bool>> getLearnedStatuses(int setId) async {
    final pairs = await _isar.wordPairs
        .filter()
        .setIdEqualTo(setId)
        .findAll();
    return {for (final pair in pairs) pair.id: pair.learned};
  }

  /// Ensures the "Words from Games" set exists.
  /// This set is used to store words saved from various minigames.
  @override
  Future<void> ensureWordsFromGamesSet() async {
    await _isar.writeTxn(() async {
      // Check if "Words from Games" set already exists by name
      final existing = await _isar.wordSets
          .filter()
          .nameEqualTo(wordsFromGamesSetName)
          .isBuiltinEqualTo(true)
          .findFirst();
      if (existing != null) {
        return; // Already exists
      }

      // Create the "Words from Games" set
      final now = DateTime.now();
      final wordsFromGamesSet = WordSet()
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
    final set = await _isar.wordSets
        .filter()
        .nameEqualTo(wordsFromGamesSetName)
        .isBuiltinEqualTo(true)
        .findFirst();
    return set?.id;
  }
}
