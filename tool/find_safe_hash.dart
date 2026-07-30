// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';
import 'package:xxh3/xxh3.dart';

void main() {
  final maxSafeInt = 9007199254740991;
  final minSafeInt = -9007199254740991;

  // Try specific candidates
  final candidates = [
    'WordSet',
    'WordSets',
    'WordMatchSet',
    'WordMatchSets',
    'MyWordSet',
    'MyWordSets',
    'UserWordSet',
    'UserWordSets',
    'PublicWordSet',
    'PublicWordSets',
    'WordList',
    'WordLists',
    'VocabularyList',
    'VocabularyLists',
    'FlashcardDeck',
    'FlashcardDecks',
    'StudySet',
    'StudySets',
    'GameSet',
    'GameSets',
    'PracticeSet',
    'PracticeSets',
  ];

  for (final name in candidates) {
    final bytes = Uint8List.fromList(utf8.encode(name));
    final id = xxh3(bytes);
    if (id <= maxSafeInt && id >= minSafeInt) {
      print('Found safe name: "$name" -> ID: $id');
    }
  }

  // Check DictEntry variations
  for (var i = 0; i <= 5000; i++) {
    final name = 'DictEntry$i';
    final bytes = Uint8List.fromList(utf8.encode(name));
    final id = xxh3(bytes);
    if (id <= maxSafeInt && id >= minSafeInt) {
      print('Found safe name for DictEntry: "$name" -> ID: $id');
    }
  }

  // Check WordPair variations
  for (var i = 0; i <= 500; i++) {
    final name = 'WordPair$i';
    final bytes = Uint8List.fromList(utf8.encode(name));
    final id = xxh3(bytes);
    if (id <= maxSafeInt && id >= minSafeInt) {
      print('Found safe name for WordPair: "$name" -> ID: $id');
    }
  }
}
