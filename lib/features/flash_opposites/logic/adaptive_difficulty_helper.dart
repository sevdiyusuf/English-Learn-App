/// Adaptive difficulty system helper
/// Shared logic for Flash Opposites and Flash Synonym
library;

enum AdaptiveStage {
  easy,          // 0 - only easy
  easyMedium,    // 1 - mix of easy + medium
  medium,        // 2 - only medium
  mediumUpper,   // 3 - mix of medium + upper
  upper,         // 4 - only upper
  upperExpert,   // 5 - mix of upper + expert
  expert,        // 6 - only expert
}

enum DifficultyLevel {
  easy,
  medium,
  upper,
  expert,
}

class AdaptiveDifficultyHelper {
  /// Maps user-selected level to starting adaptive stage
  static AdaptiveStage getInitialStage(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return AdaptiveStage.easy;
      case 'medium':
        return AdaptiveStage.medium;
      case 'upper':
        return AdaptiveStage.upper;
      case 'expert':
        return AdaptiveStage.expert;
      default:
        return AdaptiveStage.easy;
    }
  }

  /// Gets the maximum stage allowed based on starting difficulty
  static AdaptiveStage getMaxStage(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return AdaptiveStage.mediumUpper;
      case 'medium':
        return AdaptiveStage.upper;
      case 'upper':
        return AdaptiveStage.upperExpert;
      case 'expert':
        return AdaptiveStage.expert;
      default:
        return AdaptiveStage.mediumUpper;
    }
  }

  /// Gets the next stage in the progression sequence
  static AdaptiveStage getNextStage(AdaptiveStage currentStage) {
    switch (currentStage) {
      case AdaptiveStage.easy:
        return AdaptiveStage.easyMedium;
      case AdaptiveStage.easyMedium:
        return AdaptiveStage.medium;
      case AdaptiveStage.medium:
        return AdaptiveStage.mediumUpper;
      case AdaptiveStage.mediumUpper:
        return AdaptiveStage.upper;
      case AdaptiveStage.upper:
        return AdaptiveStage.upperExpert;
      case AdaptiveStage.upperExpert:
        return AdaptiveStage.expert;
      case AdaptiveStage.expert:
        return AdaptiveStage.expert; // Stay at top
    }
  }

  /// Gets stage display name for notifications
  static String getStageDisplayName(AdaptiveStage stage) {
    switch (stage) {
      case AdaptiveStage.easy:
        return 'Kolay';
      case AdaptiveStage.easyMedium:
        return 'Kolay-Orta';
      case AdaptiveStage.medium:
        return 'Orta';
      case AdaptiveStage.mediumUpper:
        return 'Orta-İleri';
      case AdaptiveStage.upper:
        return 'İleri';
      case AdaptiveStage.upperExpert:
        return 'İleri-Uzman';
      case AdaptiveStage.expert:
        return 'Uzman';
    }
  }

  /// Picks the next difficulty based on current stage and last used difficulty
  static DifficultyLevel pickNextDifficulty(
    AdaptiveStage stage,
    DifficultyLevel? lastDifficulty,
  ) {
    switch (stage) {
      case AdaptiveStage.easy:
        return DifficultyLevel.easy;

      case AdaptiveStage.easyMedium:
        // Alternate between easy and medium
        if (lastDifficulty == null || lastDifficulty == DifficultyLevel.medium) {
          return DifficultyLevel.easy;
        } else {
          return DifficultyLevel.medium;
        }

      case AdaptiveStage.medium:
        return DifficultyLevel.medium;

      case AdaptiveStage.mediumUpper:
        // Alternate between medium and upper
        if (lastDifficulty == null || lastDifficulty == DifficultyLevel.upper) {
          return DifficultyLevel.medium;
        } else {
          return DifficultyLevel.upper;
        }

      case AdaptiveStage.upper:
        return DifficultyLevel.upper;

      case AdaptiveStage.upperExpert:
        // Alternate between upper and expert
        if (lastDifficulty == null || lastDifficulty == DifficultyLevel.expert) {
          return DifficultyLevel.upper;
        } else {
          return DifficultyLevel.expert;
        }

      case AdaptiveStage.expert:
        return DifficultyLevel.expert;
    }
  }

  /// Gets score for a difficulty level
  static int getScoreForDifficulty(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 10;
      case DifficultyLevel.medium:
        return 15;
      case DifficultyLevel.upper:
        return 20;
      case DifficultyLevel.expert:
        return 25;
    }
  }

  /// Converts string level to DifficultyLevel enum
  static DifficultyLevel stringToDifficultyLevel(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'medium':
        return DifficultyLevel.medium;
      case 'upper':
        return DifficultyLevel.upper;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.easy;
    }
  }

  /// Converts DifficultyLevel enum to string
  static String difficultyLevelToString(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 'easy';
      case DifficultyLevel.medium:
        return 'medium';
      case DifficultyLevel.upper:
        return 'upper';
      case DifficultyLevel.expert:
        return 'expert';
    }
  }
}

