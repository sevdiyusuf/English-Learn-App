import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converters.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

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
    // Notifications
    @Default(false) bool remindersEnabled,
    String? reminderTime, // "HH:mm" as string
    // Metadata
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
