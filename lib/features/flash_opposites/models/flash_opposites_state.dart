import 'package:flutter/material.dart';

import '../logic/adaptive_difficulty_helper.dart';
import '../models/opposite_word.dart';

class FlashOppositesState {
  const FlashOppositesState({
    this.currentWord,
    this.options = const [],
    this.selectedOption,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.passCount = 0,
    this.isGameActive = false,
    this.isGameFinished = false,
    this.hasPassUsed = false,
    this.currentQuestionStartTime,
    this.fallingWordsPositions = const {},
    this.wordColors = const {},
    this.livesLeft = 3,
    this.streak = 0,
    this.stage,
    this.maxStage,
    this.lastDifficulty,
    this.showLevelUpBanner = false,
    this.gameStartTime,
    this.elapsedDuration = Duration.zero,
  });

  final OppositeWord? currentWord;
  final List<String> options;
  final String? selectedOption;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int passCount;
  final bool isGameActive;
  final bool isGameFinished;
  final bool hasPassUsed;
  final DateTime? currentQuestionStartTime;
  final Map<String, double> fallingWordsPositions;
  final Map<String, Color> wordColors;
  final int livesLeft;
  final int streak;
  final AdaptiveStage? stage;
  final AdaptiveStage? maxStage;
  final DifficultyLevel? lastDifficulty;
  final bool showLevelUpBanner;
  final DateTime? gameStartTime;
  final Duration elapsedDuration;

  FlashOppositesState copyWith({
    OppositeWord? currentWord,
    List<String>? options,
    String? selectedOption,
    int? score,
    int? correctCount,
    int? wrongCount,
    int? passCount,
    bool? isGameActive,
    bool? isGameFinished,
    bool? hasPassUsed,
    DateTime? currentQuestionStartTime,
    Map<String, double>? fallingWordsPositions,
    Map<String, Color>? wordColors,
    int? livesLeft,
    int? streak,
    AdaptiveStage? stage,
    AdaptiveStage? maxStage,
    DifficultyLevel? lastDifficulty,
    bool? showLevelUpBanner,
    DateTime? gameStartTime,
    Duration? elapsedDuration,
  }) {
    return FlashOppositesState(
      currentWord: currentWord ?? this.currentWord,
      options: options ?? this.options,
      selectedOption: selectedOption,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      passCount: passCount ?? this.passCount,
      isGameActive: isGameActive ?? this.isGameActive,
      isGameFinished: isGameFinished ?? this.isGameFinished,
      hasPassUsed: hasPassUsed ?? this.hasPassUsed,
      currentQuestionStartTime:
          currentQuestionStartTime ?? this.currentQuestionStartTime,
      fallingWordsPositions:
          fallingWordsPositions ?? this.fallingWordsPositions,
      wordColors: wordColors ?? this.wordColors,
      livesLeft: livesLeft ?? this.livesLeft,
      streak: streak ?? this.streak,
      stage: stage ?? this.stage,
      maxStage: maxStage ?? this.maxStage,
      lastDifficulty: lastDifficulty ?? this.lastDifficulty,
      showLevelUpBanner: showLevelUpBanner ?? this.showLevelUpBanner,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
    );
  }
}
