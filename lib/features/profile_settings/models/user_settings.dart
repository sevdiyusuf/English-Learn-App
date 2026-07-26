import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converters.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

/// Stable persistence values used by onboarding and settings UI.
abstract final class LearningProfileValues {
  static const currentOnboardingVersion = 1;
  static const onboardingIntro = 'intro';
  static const onboardingLevel = 'level';
  static const onboardingGoal = 'goal';
  static const onboardingReview = 'review';

  static const cefrLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
  static const learningGoals = {
    'word_practice',
    'grammar_practice',
    'mini_games',
    'multiplayer',
  };

  static bool isValidStep(String value) => {
    onboardingIntro,
    onboardingLevel,
    onboardingGoal,
    onboardingReview,
  }.contains(value);
}

@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    // UI
    @Default('dark') String themeMode, // 'system' | 'dark' | 'light'
    @Default('tr') String languageCode, // 'tr' | 'en'
    // Feedback
    @Default(true) bool soundEnabled,
    @Default(true) bool vibrationEnabled,

    // Goals
    @Default('words') String dailyGoalType, // 'words' | 'minutes'
    @Default(10) int dailyGoalValue, // 5, 10, 15, etc.
    @Default(10) int streakGoal, // 3, 10, 20, 30, 50
    // First-use learning profile. Values are stable identifiers, not labels.
    @Default(0) int onboardingCompletedVersion,
    @Default(LearningProfileValues.onboardingIntro) String onboardingStep,
    String? cefrLevel,
    String? learningGoal,
    // Notifications
    @Default(false) bool multiplayerNotificationsEnabled,
    @Default(false) bool remindersEnabled,
    String? reminderTime, // "HH:mm" as string
    // Metadata
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
