import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../word_match/models/word_pair.dart';
import '../word_match/models/word_set.dart';
import 'models/dict_entry.dart';

const _isarInstanceName = 'dictionary';

// Singleton pattern: prevent concurrent initialization
Completer<Isar?>? _initializationCompleter;
bool _isInitializing = false;

Future<Isar?> openDictionaryStore() async {
  // Check if instance already exists
  final existing = Isar.getInstance(_isarInstanceName);
  if (existing != null) {
    debugPrint('Found existing Isar instance, verifying...');

    // Try to warm up collections with transaction
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (attempt > 0) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

        // Warmup via transaction
        await existing.writeTxn(() async {
          await existing.wordSets.count();
          await existing.wordPairs.count();
          await existing.dictEntrys.count();
        });

        // Verify outside transaction
        await Future.delayed(const Duration(milliseconds: 300));
        await existing.wordSets.count();
        await existing.wordPairs.count();
        await existing.dictEntrys.count();

        debugPrint('Existing instance is valid and ready');
        return existing;
      } catch (e) {
        if (e.toString().contains('has not been initialized')) {
          debugPrint(
            'Existing instance collections not ready, attempt ${attempt + 1}/5',
          );
          if (attempt == 4) {
            // Last attempt failed - instance is broken, need to close and reopen
            debugPrint(
              'Existing instance is broken, will try to close and reopen',
            );
            try {
              await existing.close(deleteFromDisk: false);
              await Future.delayed(const Duration(seconds: 1));
              // Continue to create new instance
            } catch (closeError) {
              debugPrint('Error closing broken instance: $closeError');
              // Continue anyway
            }
            break;
          }
          continue;
        }
        // Other error - instance might be working
        debugPrint('Existing instance verification error: $e');
        return existing;
      }
    }
  }

  // WEB İÇİN ÖZEL KORUMA
  if (kIsWeb) {
    debugPrint("⚠️ Web platformu algılandı. WASM dosyası eksik olduğu için Isar ATLANIYOR.");
    // Burada Isar'ı hiç açmıyoruz veya sadece bellek içi (in-memory) açmayı deniyoruz.
    // Eğer illa açman gerekiyorsa WASM olmadan açılmaz.
    // Bu yüzden burayı boş bırakıp uygulamanın çökmesini engelliyoruz.
    return null;
  }

  // If initialization is already in progress, wait for it
  if (_isInitializing && _initializationCompleter != null) {
    debugPrint('Isar initialization already in progress, waiting...');
    try {
      return await _initializationCompleter!.future;
    } catch (e) {
      debugPrint('Waited initialization failed: $e');
      _isInitializing = false;
      _initializationCompleter = null;
    }
  }

  // Start new initialization
  _isInitializing = true;
  _initializationCompleter = Completer<Isar?>();

  try {
    // Double-check: maybe another thread opened it
    final doubleCheck = Isar.getInstance(_isarInstanceName);
    if (doubleCheck != null) {
      debugPrint('Instance was opened by another thread');
      _isInitializing = false;
      _initializationCompleter!.complete(doubleCheck);
      _initializationCompleter = null;
      return doubleCheck;
    }

    String dirPath = '';
    if (!kIsWeb) {
      debugPrint('Getting application support directory...');
      final dir = await getApplicationSupportDirectory();
      dirPath = dir.path;
      debugPrint('Directory: $dirPath');

      // Ensure directory exists
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (e) {
        debugPrint('Warning: Could not create directory: $e');
      }
    }

    debugPrint('Opening Isar database...');
    if (!kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    Isar isar;
    try {
      isar = await Isar.open(
        [DictEntrySchema, WordSetSchema, WordPairSchema],
        name: _isarInstanceName,
        directory: dirPath,
        inspector: !kIsWeb, // Inspector not supported on web in some versions
      );
      debugPrint('Isar opened successfully');
    } catch (e, stackTrace) {
      debugPrint('ERROR: Failed to open Isar: $e');
      debugPrint('Stack trace: $stackTrace');

      // Check if error is "already opened"
      if (e.toString().contains('already been opened') ||
          e.toString().contains('already opened')) {
        final existingInstance = Isar.getInstance(_isarInstanceName);
        if (existingInstance != null) {
          debugPrint('Retrieved existing instance after error');
          _isInitializing = false;
          _initializationCompleter!.complete(existingInstance);
          _initializationCompleter = null;
          return existingInstance;
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      final retryExisting = Isar.getInstance(_isarInstanceName);
      if (retryExisting != null) {
        debugPrint('Found instance after retry delay');
        _isInitializing = false;
        _initializationCompleter!.complete(retryExisting);
        _initializationCompleter = null;
        return retryExisting;
      }

      throw StateError('Failed to open Isar database: $e');
    }

    // CRITICAL: Force collections initialization via multiple methods
    // Android APK'da native library loading çok yavaş olabilir
    if (!kIsWeb) {
      debugPrint('Initializing collections...');

      // İlk olarak native library'lerin yüklenmesi için uzun bir bekleme
      debugPrint('Waiting for native libraries to load (Android APK)...');
      await Future.delayed(const Duration(seconds: 3));

      // Method 1: Transaction warmup (most reliable)
      // APK için daha fazla deneme ve daha uzun bekleme süreleri
      bool collectionsInitialized = false;
      for (var attempt = 0; attempt < 20; attempt++) {
        try {
          if (attempt > 0) {
            // Her attempt'te daha uzun bekle (APK için)
            await Future.delayed(
              Duration(milliseconds: 1000 + (attempt * 300)),
            );
          }

          debugPrint('Warmup attempt ${attempt + 1}/20: Transaction...');

          // Use collection() method directly instead of extension getters
          // This forces initialization on Android APK
          await isar.writeTxn(() async {
            // Use collection() method directly - more reliable than extension getters
            final wordSetsCol = isar.collection<WordSet>();
            final wordPairsCol = isar.collection<WordPair>();
            final dictEntrysCol = isar.collection<DictEntry>();

            // Access collections via collection() method
            await wordSetsCol.count();
            await wordPairsCol.count();
            await dictEntrysCol.count();

            // Also try extension getters to ensure both work
            await isar.wordSets.count();
            await isar.wordPairs.count();
            await isar.dictEntrys.count();
          });

          // Verify outside transaction - APK için daha uzun bekleme
          await Future.delayed(const Duration(milliseconds: 500));
          await isar.wordSets.count();
          collectionsInitialized = true;
          debugPrint('Collections initialized successfully!');
          break;
        } catch (e) {
          debugPrint('Warmup attempt ${attempt + 1} failed: $e');
        }
      }

      if (!collectionsInitialized) {
        debugPrint(
          'WARNING: Collections warmup failed after 20 attempts. Returning anyway, but might crash.',
        );
      }
    } else {
      // Web warmup (lighter)
      try {
        await isar.wordSets.count();
        await isar.wordPairs.count();
        await isar.dictEntrys.count();
        debugPrint('Web collections ready');
      } catch (e) {
        debugPrint('Web warmup warning: $e');
      }
    }

    try {
      debugPrint('Seeding dictionary if empty...');
      await _seedDictionaryIfEmpty(isar);
      debugPrint('Dictionary seeding completed');
    } catch (e) {
      debugPrint('Dictionary seeding failed safely (non-blocking fallback): $e');
    }

    _isInitializing = false;
    _initializationCompleter!.complete(isar);
    _initializationCompleter = null;

    return isar;
  } catch (e, stackTrace) {
    debugPrint('Error opening Isar database: $e');
    debugPrint('Stack trace: $stackTrace');

    _isInitializing = false;

    if (_initializationCompleter != null &&
        !_initializationCompleter!.isCompleted) {
      _initializationCompleter!.completeError(e, stackTrace);
    }
    _initializationCompleter = null;

    rethrow;
  }
}

Future<void> _seedDictionaryIfEmpty(Isar isar) async {
  try {
    final count = await isar.dictEntrys.count();
    debugPrint('Dictionary entry count: $count');

    if (count > 0) {
      debugPrint('Dictionary already seeded');
      return;
    }

    debugPrint('Loading dictionary.json...');
    String? jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/word_battle/dictionary.json');
    } catch (e) {
      debugPrint('Warning: Failed to load dictionary asset (non-blocking): $e');
      return;
    }

    debugPrint('Dictionary.json loaded, length: ${jsonString.length}');
    debugPrint('Parsing and mapping JSON in background (non-blocking UI)...');

    // Run heavy JSON decoding and mapping in background compute/microtask isolate
    final entries = await compute(_parseDictionaryJson, jsonString);
    debugPrint('Entries mapped in background: ${entries.length}');

    debugPrint('Writing entries to database...');
    await isar.writeTxn(() async {
      await isar.dictEntrys.putAll(entries);
    });
    debugPrint('Entries written successfully');
  } catch (e, stackTrace) {
    debugPrint('Error seeding dictionary (non-blocking): $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

List<DictEntry> _parseDictionaryJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
  final entries = <DictEntry>[];
  for (final map in jsonList) {
    if (map is Map<String, dynamic>) {
      final word = (map['word'] as String?)?.toLowerCase().trim();
      final type = (map['type'] as String?)?.toLowerCase().trim();
      if (word != null && type != null && word.isNotEmpty && type.isNotEmpty) {
        entries.add(DictEntry()..word = word..type = type);
      }
    }
  }
  return entries;
}

Future<bool> validateWord({
  required Isar isar,
  required String word,
  required String type,
}) async {
  final normalizedWord = word.toLowerCase().trim();
  final normalizedType = type.toLowerCase().trim();

  final found =
      await isar.dictEntrys
          .filter()
          .wordEqualTo(normalizedWord)
          .and()
          .typeEqualTo(normalizedType)
          .findFirst();

  return found != null;
}
