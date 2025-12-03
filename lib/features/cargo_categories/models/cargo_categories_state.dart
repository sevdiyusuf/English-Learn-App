import 'cargo_word.dart';

enum Difficulty {
  slow,
  normal,
  fast;

  Duration get travelDuration {
    switch (this) {
      case Difficulty.slow:
        return const Duration(milliseconds: 4000);
      case Difficulty.normal:
        return const Duration(milliseconds: 2500);
      case Difficulty.fast:
        return const Duration(milliseconds: 1500);
    }
  }

  String get displayName {
    switch (this) {
      case Difficulty.slow:
        return 'Yavaş';
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.fast:
        return 'Hızlı';
    }
  }
}

class CargoCategoriesState {
  const CargoCategoriesState({
    this.selectedCategories = const [],
    this.selectedDifficulty,
    this.currentWord,
    this.remainingWords = const [],
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.missedCount = 0,
    this.remainingTime = const Duration(minutes: 1),
    this.isRunning = false,
    this.isFinished = false,
    this.currentWordStartTime,
    this.highlightedCategoryId,
    this.wrongCategoryId,
  });

  final List<String> selectedCategories; // Category IDs (should be exactly 3)
  final Difficulty? selectedDifficulty;
  final CargoWord? currentWord;
  final List<CargoWord> remainingWords;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int missedCount;
  final Duration remainingTime;
  final bool isRunning;
  final bool isFinished;
  final DateTime? currentWordStartTime;
  final String? highlightedCategoryId;
  final String? wrongCategoryId;

  CargoCategoriesState copyWith({
    List<String>? selectedCategories,
    Difficulty? selectedDifficulty,
    CargoWord? currentWord,
    List<CargoWord>? remainingWords,
    int? score,
    int? correctCount,
    int? wrongCount,
    int? missedCount,
    Duration? remainingTime,
    bool? isRunning,
    bool? isFinished,
    DateTime? currentWordStartTime,
    String? highlightedCategoryId,
    String? wrongCategoryId,
  }) {
    return CargoCategoriesState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      currentWord: currentWord,
      remainingWords: remainingWords ?? this.remainingWords,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      missedCount: missedCount ?? this.missedCount,
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
      currentWordStartTime: currentWordStartTime ?? this.currentWordStartTime,
      highlightedCategoryId: highlightedCategoryId,
      wrongCategoryId: wrongCategoryId,
    );
  }

  bool get canStartGame {
    return selectedCategories.length == 3 &&
        selectedDifficulty != null &&
        !isRunning &&
        !isFinished;
  }
}

