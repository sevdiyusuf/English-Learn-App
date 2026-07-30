import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/opposite_word.dart';

class OppositesService {
  OppositesService._();
  static final OppositesService instance = OppositesService._();

  Map<String, List<OppositeWord>>? _oppositesByLevel;
  List<String>? _wrongAnswers; // Old format support
  List<Map<String, String>>?
  _wrongAnswersWithTranslate; // New format with translate

  Future<void> loadData() async {
    if (_oppositesByLevel != null &&
        _wrongAnswers != null &&
        _wrongAnswersWithTranslate != null) {
      return; // Already loaded
    }

    try {
      final jsonString = await rootBundle.loadString('assets/opposites.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      _oppositesByLevel = <String, List<OppositeWord>>{};
      for (final level in ['easy', 'medium', 'upper', 'expert']) {
        if (jsonMap[level] != null) {
          final list =
              (jsonMap[level] as List<dynamic>)
                  .map(
                    (item) =>
                        OppositeWord.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
          _oppositesByLevel![level] = list;
        }
      }

      if (jsonMap['wrong_answers'] != null) {
        final wrongAnswersList = jsonMap['wrong_answers'] as List<dynamic>;

        // Check if it's new format (objects with word and translate) or old format (strings)
        if (wrongAnswersList.isNotEmpty && wrongAnswersList[0] is Map) {
          // New format: list of objects with "word" and "translate"
          _wrongAnswersWithTranslate =
              wrongAnswersList.map((item) {
                final map = item as Map<String, dynamic>;
                return <String, String>{
                  'word': map['word'] as String,
                  'translate': map['translate'] as String,
                };
              }).toList();
          // Also create string list for backward compatibility
          _wrongAnswers =
              _wrongAnswersWithTranslate!.map((item) => item['word']!).toList();
        } else {
          // Old format: list of strings
          _wrongAnswers =
              wrongAnswersList.map((item) => item as String).toList();
          _wrongAnswersWithTranslate = [];
        }
      } else {
        _wrongAnswers = [];
        _wrongAnswersWithTranslate = [];
      }

      if (kDebugMode) {
        debugPrint(
          'Loaded opposites data: ${_oppositesByLevel?.length} levels',
        );
        debugPrint('Wrong answers count: ${_wrongAnswers?.length}');
        debugPrint(
          'Wrong answers with translate count: ${_wrongAnswersWithTranslate?.length}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading opposites.json: $e');
      }
      rethrow;
    }
  }

  List<OppositeWord> getWordsByLevel(String level) {
    if (_oppositesByLevel == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }
    return _oppositesByLevel![level] ?? [];
  }

  List<String> getWrongAnswers(int count, {List<String>? exclude}) {
    if (_wrongAnswers == null || _wrongAnswers!.isEmpty) {
      return [];
    }

    final excludeSet = exclude?.toSet() ?? <String>{};
    final available =
        _wrongAnswers!.where((w) => !excludeSet.contains(w)).toList();

    if (available.length <= count) {
      return available;
    }

    final random = Random();
    final selected = <String>[];
    final usedIndices = <int>{};

    while (selected.length < count && usedIndices.length < available.length) {
      final index = random.nextInt(available.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        selected.add(available[index]);
      }
    }

    return selected;
  }

  /// Get wrong answers with translate (new format)
  /// Returns list of maps with 'word' and 'translate' keys
  List<Map<String, String>> getWrongAnswersWithTranslate(
    int count, {
    List<String>? exclude,
  }) {
    if (_wrongAnswersWithTranslate == null ||
        _wrongAnswersWithTranslate!.isEmpty) {
      return [];
    }

    final excludeSet = exclude?.toSet() ?? <String>{};
    final available =
        _wrongAnswersWithTranslate!
            .where((item) => !excludeSet.contains(item['word']))
            .toList();

    if (available.length <= count) {
      return available;
    }

    final random = Random();
    final selected = <Map<String, String>>[];
    final usedIndices = <int>{};

    while (selected.length < count && usedIndices.length < available.length) {
      final index = random.nextInt(available.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        selected.add(available[index]);
      }
    }

    return selected;
  }
}
