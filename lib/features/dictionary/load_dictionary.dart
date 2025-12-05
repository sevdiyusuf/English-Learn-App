import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../word_match/models/word_pair.dart';
import '../word_match/models/word_set.dart';
import 'models/dict_entry.dart';

const _isarInstanceName = 'dictionary';

Future<Isar?> openDictionaryStore() async {
  if (kIsWeb) {
    // Isar 3.x doesn't support web. Return null for web platform.
    debugPrint('Web platform detected: Isar is not supported on web');
    return null;
  }

  try {
    final existing = Isar.getInstance(_isarInstanceName);
    if (existing != null) {
      debugPrint('Using existing Isar instance');
      return existing;
    }

    final dir = await getApplicationSupportDirectory();
    final dirPath = dir.path;
    debugPrint('Non-web platform, using directory: $dirPath');

    debugPrint('Opening Isar database...');

    final isar = await Isar.open(
      [DictEntrySchema, WordSetSchema, WordPairSchema],
      name: _isarInstanceName,
      directory: dirPath,
      inspector: false,
    );

    debugPrint('Isar database opened successfully');

    // APK'da collections'ların tamamen başlatılması için daha uzun bekleme ve doğrulama
    // Retry mekanizması ile collections'ların hazır olduğundan emin ol
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        // Wait progressively longer for each attempt
        await Future.delayed(Duration(milliseconds: 200 + (attempt * 100)));

        // Verify collections are accessible (using extension methods from generated files)
        // Try to access collections to ensure they're initialized
        await isar.wordSets.count();
        await isar.wordPairs.count();
        await isar.dictEntrys.count();

        debugPrint('Isar collections verified on attempt ${attempt + 1}');
        break; // Success, exit retry loop
      } catch (e) {
        debugPrint(
          'Warning: Isar collections not ready yet, attempt ${attempt + 1}: $e',
        );
        if (attempt == 9) {
          // Last attempt failed, but continue anyway - might work later
          debugPrint(
            'Isar collections verification failed after 10 attempts, but continuing...',
          );
        }
      }
    }

    debugPrint('Seeding dictionary if empty...');

    await _seedDictionaryIfEmpty(isar);

    debugPrint('Dictionary seeding completed');

    return isar;
  } catch (e, stackTrace) {
    debugPrint('Error opening Isar database: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> _seedDictionaryIfEmpty(Isar isar) async {
  try {
    debugPrint('Checking dictionary entry count...');
    final count = await isar.dictEntrys.count();
    debugPrint('Dictionary entry count: $count');

    if (count > 0) {
      debugPrint('Dictionary already seeded, skipping...');
      return;
    }

    debugPrint('Loading dictionary.json from assets...');
    final jsonString = await rootBundle.loadString('assets/dictionary.json');
    debugPrint('Dictionary.json loaded, length: ${jsonString.length}');

    debugPrint('Parsing JSON...');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    debugPrint('JSON parsed, entries count: ${jsonList.length}');

    debugPrint('Mapping entries...');
    final entries = jsonList
        .whereType<Map<String, dynamic>>()
        .map((map) {
          try {
            final word = (map['word'] as String?)?.toLowerCase().trim();
            final type = (map['type'] as String?)?.toLowerCase().trim();
            if (word != null &&
                type != null &&
                word.isNotEmpty &&
                type.isNotEmpty) {
              return DictEntry()
                ..word = word
                ..type = type;
            }
            return null;
          } catch (e) {
            debugPrint('Error mapping dictionary entry: $e, map: $map');
            return null;
          }
        })
        .whereType<DictEntry>()
        .toList(growable: false);
    debugPrint('Entries mapped, count: ${entries.length}');

    debugPrint('Writing entries to Isar database...');
    await isar.writeTxn(() async {
      await isar.dictEntrys.putAll(entries);
    });
    debugPrint('Entries written to database successfully');
  } catch (e, stackTrace) {
    debugPrint('Error seeding dictionary: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
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
