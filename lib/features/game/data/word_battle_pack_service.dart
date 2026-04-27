import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// One theme pack from easy/medium/hard pack JSON.
class WordBattlePack {
  const WordBattlePack({
    required this.id,
    required this.title,
    required this.words,
  });
  final String id;
  final String title;
  final List<String> words;

  static WordBattlePack fromJson(Map<String, dynamic> json) {
    final words =
        (json['words'] as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        [];
    return WordBattlePack(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      words: words,
    );
  }
}

/// Level for theme packs: easy, medium, hard.
const List<String> kWordBattleDifficulties = ['easy', 'medium', 'hard'];

const Map<String, String> _packAssetPaths = {
  'easy': 'assets/word_battle/easy_pack.json',
  'medium': 'assets/word_battle/medium_pack.json',
  'hard': 'assets/word_battle/hard_pack.json',
};

final _random = Random();

/// Loads theme packs from assets and picks random theme.
class WordBattlePackService {
  WordBattlePackService._();
  static final WordBattlePackService instance = WordBattlePackService._();

  final Map<String, List<WordBattlePack>> _cache = {};

  /// Loads packs for [difficulty] (easy | medium | hard). Cached.
  Future<List<WordBattlePack>> getPacks(String difficulty) async {
    final key = difficulty.toLowerCase();
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final path = _packAssetPaths[key];
    if (path == null) {
      return [];
    }
    final jsonStr = await rootBundle.loadString(path);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final packsList = json['packs'] as List<dynamic>? ?? [];
    final packs =
        packsList
            .map((e) => WordBattlePack.fromJson(e as Map<String, dynamic>))
            .toList();
    _cache[key] = packs;
    return packs;
  }

  /// Picks a random pack for [difficulty]. Uses same [Random] seed if [seed] provided.
  Future<WordBattlePack?> pickRandomPack(String difficulty, {int? seed}) async {
    final packs = await getPacks(difficulty);
    if (packs.isEmpty) return null;
    final rnd = seed != null ? Random(seed) : _random;
    return packs[rnd.nextInt(packs.length)];
  }
}
