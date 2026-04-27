import 'cargo_word.dart';
import 'category.dart';

/// Game difficulty level (determines category selection)
enum GameLevel {
  beginner, // Başlangıç: 2 easy + 1 medium
  normal, // Normal: 2 medium + 1 easy
  advanced, // İleri: 2 medium + 1 hard
  expert; // Uzman: 2 hard + 1 medium

  String get displayName {
    switch (this) {
      case GameLevel.beginner:
        return 'Başlangıç';
      case GameLevel.normal:
        return 'Normal';
      case GameLevel.advanced:
        return 'İleri';
      case GameLevel.expert:
        return 'Uzman';
    }
  }
}

/// Speed setting (determines conveyor belt speed)
enum Difficulty {
  normal, // Normal hız
  fast; // Hızlı

  Duration get travelDuration {
    switch (this) {
      case Difficulty.normal:
        return const Duration(milliseconds: 2500);
      case Difficulty.fast:
        return const Duration(milliseconds: 1500);
    }
  }

  String get displayName {
    switch (this) {
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.fast:
        return 'Hızlı';
    }
  }
}

/// Represents a column that can hold up to 4 words
class CargoColumn {
  const CargoColumn({this.words = const []});

  final List<CargoWord> words; // No limit

  CargoColumn copyWith({List<CargoWord>? words}) {
    return CargoColumn(words: words ?? this.words);
  }

  bool get isFull => false; // No limit, always return false
  bool get isEmpty => words.isEmpty;
}

class CargoCategoriesState {
  const CargoCategoriesState({
    this.chosenCategories = const [], // 3 Category objects
    this.selectedGameLevel = GameLevel.beginner, // Default: Başlangıç
    this.selectedDifficulty = Difficulty.normal, // Default: Normal
    this.currentWord,
    this.draggedWord,
    this.remainingOnBelt = const [], // Words yet to be placed
    this.columns = const [], // 3 CargoColumn objects
    this.showSolution = false, // Whether to show category names
    this.isRegrouping = false, // Animation state for regrouping
    this.isRunning = false,
    this.isFinished = false,
    this.hasWon = false,
    this.elapsedTime = Duration.zero, // Time elapsed since game start
    this.finalScore,
    this.finalCorrectCount,
    this.finalWrongCount,
  });

  final List<Category> chosenCategories; // Length 3
  final GameLevel selectedGameLevel; // Game difficulty level
  final Difficulty? selectedDifficulty; // Speed setting
  final CargoWord? currentWord; // Current word on conveyor belt
  final CargoWord? draggedWord; // Word currently being dragged by user
  final List<CargoWord> remainingOnBelt; // Words yet to be placed
  final List<CargoColumn> columns; // Length 3, each with max 4 words
  final bool showSolution; // If true, show category names instead of "?"
  final bool isRegrouping; // Animation state
  final bool isRunning;
  final bool isFinished;
  final bool hasWon;
  final Duration elapsedTime; // Time elapsed since game start
  final int? finalScore; // Score calculated before regrouping
  final int? finalCorrectCount; // Correct count before regrouping
  final int? finalWrongCount; // Wrong count before regrouping

  CargoCategoriesState copyWith({
    List<Category>? chosenCategories,
    GameLevel? selectedGameLevel,
    Difficulty? selectedDifficulty,
    Object? currentWord = _undefined,
    Object? draggedWord = _undefined,
    List<CargoWord>? remainingOnBelt,
    List<CargoColumn>? columns,
    bool? showSolution,
    bool? isRegrouping,
    bool? isRunning,
    bool? isFinished,
    bool? hasWon,
    Duration? elapsedTime,
    int? finalScore,
    int? finalCorrectCount,
    int? finalWrongCount,
  }) {
    return CargoCategoriesState(
      chosenCategories: chosenCategories ?? this.chosenCategories,
      selectedGameLevel: selectedGameLevel ?? this.selectedGameLevel,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      currentWord:
          currentWord == _undefined
              ? this.currentWord
              : currentWord as CargoWord?,
      draggedWord:
          draggedWord == _undefined
              ? this.draggedWord
              : draggedWord as CargoWord?,
      remainingOnBelt: remainingOnBelt ?? this.remainingOnBelt,
      columns: columns ?? this.columns,
      showSolution: showSolution ?? this.showSolution,
      isRegrouping: isRegrouping ?? this.isRegrouping,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
      hasWon: hasWon ?? this.hasWon,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      finalScore: finalScore ?? this.finalScore,
      finalCorrectCount: finalCorrectCount ?? this.finalCorrectCount,
      finalWrongCount: finalWrongCount ?? this.finalWrongCount,
    );
  }

  /// Check if all words are placed (belt empty and all 12 words are in columns)
  bool get canCheck {
    if (remainingOnBelt.isNotEmpty) return false;
    if (currentWord != null) return false;
    if (draggedWord != null) return false;
    if (columns.length != 3) return false;
    // Check if total words in all columns equals 12 (no limit per column)
    final totalWords = columns.fold<int>(0, (sum, col) => sum + col.words.length);
    return totalWords == 12;
  }

  /// Check if game can start (needs speed selection)
  bool get canStartGame {
    return selectedDifficulty != null && !isRunning && !isFinished;
  }

  /// Get total words placed across all columns
  int get totalWordsPlaced {
    return columns.fold<int>(0, (sum, col) => sum + col.words.length);
  }
}

const _undefined = Object();

