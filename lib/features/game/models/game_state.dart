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
}
