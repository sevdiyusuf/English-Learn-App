import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/word_echo_word.dart';

class WordEchoService {
  WordEchoService._();
  static final WordEchoService instance = WordEchoService._();

  List<WordEchoWord>? _words;

  Future<void> loadWords() async {
    if (_words != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/word_echo_words.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final wordsList = jsonData['words'] as List<dynamic>;
      _words = wordsList
          .map((word) => WordEchoWord.fromJson(word as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load word echo words: $e');
    }
  }

  List<WordEchoWord> getWords() {
    if (_words == null) {
      throw StateError('Words not loaded. Call loadWords() first.');
    }
    return List.unmodifiable(_words!);
  }

  /// Get 4 random unique words from the word list
  List<WordEchoWord> getRandomWords(int count) {
    final allWords = getWords();
    if (allWords.length < count) {
      throw StateError('Not enough words in the set. Need at least $count words.');
    }

    final random = Random();
    final selected = <WordEchoWord>[];
    final usedIndices = <int>{};

    while (selected.length < count) {
      final index = random.nextInt(allWords.length);
      if (!usedIndices.contains(index)) {
        usedIndices.add(index);
        selected.add(allWords[index]);
      }
    }

    return selected;
  }

  /// Get a random word by its Turkish translation
  WordEchoWord? getWordByTurkish(String turkish) {
    final words = getWords();
    return words.firstWhere(
      (word) => word.turkish.toLowerCase() == turkish.toLowerCase(),
      orElse: () => throw StateError('Word not found: $turkish'),
    );
  }
}
