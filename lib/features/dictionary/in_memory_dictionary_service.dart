import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'dictionary_service.dart';

/// In-memory dictionary service (for web platform)
class InMemoryDictionaryService implements DictionaryService {
  InMemoryDictionaryService._(this._dictionary);

  final Map<String, Set<String>> _dictionary;

  static Future<InMemoryDictionaryService> create() async {
    try {
      if (kDebugMode) {
        debugPrint('Creating in-memory dictionary for web...');
      }

      // Load JSON string with error handling
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/word_battle/dictionary.json');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error loading dictionary.json: $e');
        }
        throw Exception('Failed to load dictionary.json asset: $e');
      }

      if (jsonString.isEmpty) {
        throw Exception('Dictionary JSON file is empty');
      }

      if (kDebugMode) {
        debugPrint('Dictionary JSON loaded, length: ${jsonString.length}');
      }

      // Parse JSON with error handling
      dynamic decodedJson;
      try {
        decodedJson = json.decode(jsonString);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing dictionary JSON: $e');
        }
        throw Exception('Failed to parse dictionary.json: $e');
      }

      if (decodedJson is! List<dynamic>) {
        throw Exception(
          'Dictionary JSON is not a list: ${decodedJson.runtimeType}',
        );
      }

      final jsonList = decodedJson;

      if (kDebugMode) {
        debugPrint('Parsed ${jsonList.length} dictionary entries');
      }

      final dictionary = <String, Set<String>>{};
      int validEntries = 0;
      int invalidEntries = 0;

      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          try {
            final word = (item['word'] as String?)?.toLowerCase().trim();
            final type = (item['type'] as String?)?.toLowerCase().trim();
            if (word != null &&
                type != null &&
                word.isNotEmpty &&
                type.isNotEmpty) {
              dictionary.putIfAbsent(type, () => <String>{}).add(word);
              validEntries++;
            } else {
              invalidEntries++;
            }
          } catch (e) {
            invalidEntries++;
            if (kDebugMode && invalidEntries <= 5) {
              debugPrint('Invalid dictionary entry: $item, error: $e');
            }
          }
        } else {
          invalidEntries++;
        }
      }

      if (kDebugMode) {
        debugPrint(
          'Processed entries: $validEntries valid, $invalidEntries invalid',
        );
      }

      if (dictionary.isEmpty) {
        throw Exception(
          'Dictionary is empty after parsing (valid entries: $validEntries, invalid: $invalidEntries)',
        );
      }

      if (kDebugMode) {
        final totalWords = dictionary.values.fold(
          0,
          (sum, words) => sum + words.length,
        );
        debugPrint(
          'Dictionary loaded successfully: ${dictionary.length} types, $totalWords words',
        );
      }

      return InMemoryDictionaryService._(dictionary);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('========================================');
        debugPrint('Error creating in-memory dictionary: $e');
        debugPrint('Error type: ${e.runtimeType}');
        debugPrint('Stack trace:');
        debugPrint(stackTrace.toString());
        debugPrint('========================================');
      }
      // Re-throw with more context for debugging
      throw Exception('Failed to create dictionary service: $e');
    }
  }

  @override
  Future<bool> validateWord({
    required String word,
    required String type,
  }) async {
    final normalizedWord = word.toLowerCase().trim();
    final normalizedType = type.toLowerCase().trim();

    final words = _dictionary[normalizedType];
    if (words == null) {
      return false;
    }

    return words.contains(normalizedWord);
  }
}
