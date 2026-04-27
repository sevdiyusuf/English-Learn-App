import 'package:freezed_annotation/freezed_annotation.dart';

import 'played_word.dart';
import 'room.dart';

part 'game_state.freezed.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    required Room room,
    @Default(<PlayedWord>[]) List<PlayedWord> playedWords,
    @Default(<String, bool>{}) Map<String, bool> usedWords,
  }) = _GameState;

  const GameState._();

  Map<String, int> get computedScores {
    // If backend provides scores, use them
    if (room.scores.isNotEmpty) {
      return room.scores;
    }

    // Otherwise calculate locally: 10 points per word
    final scores = <String, int>{};
    for (final word in playedWords) {
      final current = scores[word.byUid] ?? 0;
      scores[word.byUid] = current + 10;
    }
    return scores;
  }
}
