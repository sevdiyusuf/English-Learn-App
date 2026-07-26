import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/synonym_word.dart';

class SynonymService {
  SynonymService._();
  static final SynonymService instance = SynonymService._();

  Map<String, List<SynonymWord>>? _synonymsByLevel;
  List<String>? _wrongAnswers;

  Future<void> loadData() async {
    if (_synonymsByLevel != null && _wrongAnswers != null) {
      return; // Already loaded
    }

    try {
      final jsonString = await rootBundle.loadString('assets/synonym.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      _synonymsByLevel = <String, List<SynonymWord>>{};
      for (final level in ['easy', 'medium', 'upper', 'expert']) {
        if (jsonMap[level] != null) {
          final list =
              (jsonMap[level] as List<dynamic>)
                  .map(
                    (item) =>
                        SynonymWord.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
          _synonymsByLevel![level] = list;
        }
      }

      if (jsonMap['wrong_answers'] != null) {
        _wrongAnswers =
            (jsonMap['wrong_answers'] as List<dynamic>)
                .map((item) => item as String)
                .toList();
      } else {
        _wrongAnswers = [];
      }

      if (kDebugMode) {
        debugPrint('Loaded synonyms data: ${_synonymsByLevel?.length} levels');
        debugPrint('Wrong answers count: ${_wrongAnswers?.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading synonym.json: $e');
      }
      rethrow;
    }
  }

  List<SynonymWord> getWordsByLevel(String level) {
    if (_synonymsByLevel == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }
    return _synonymsByLevel![level] ?? [];
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
}
