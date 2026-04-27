import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converters.dart';

part 'user_stats.freezed.dart';
part 'user_stats.g.dart';

@freezed
class ModeStats with _$ModeStats {
  const factory ModeStats({
    @Default(0) int sessions,
    @Default(0) int correctAnswers,
    @Default(0) int wrongAnswers,
    @Default(0) int totalQuestions,
    @Default(0) int totalMinutes,
  }) = _ModeStats;

  factory ModeStats.fromJson(Map<String, dynamic> json) =>
      _$ModeStatsFromJson(json);
}

@freezed
class DailyActivityPoint with _$DailyActivityPoint {
  const factory DailyActivityPoint({
    @TimestampConverter() required DateTime date,
    @Default(0) int practicedWords,
    @Default(0) int minutes,
  }) = _DailyActivityPoint;

  factory DailyActivityPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityPointFromJson(json);
}

@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    @Default(0) int totalLearnedWords,
    @Default(0) int totalSessions,
    @Default(0) int totalScore, // Toplam puan (tüm oyunlardan)
    // streak
    @Default(0) int currentStreakDays,
    @Default(0) int bestStreakDays,
    @TimestampConverter() DateTime? lastActivityDate,
    // per-mode stats, keyed by: 'word_match', 'flash_opposites', 'flash_synonym',
    // 'cargo_categories', 'word_echo_classic', 'word_echo_grid', 'multiplayer'
    @Default(<String, ModeStats>{}) Map<String, ModeStats> modeStats,
    // last N days (e.g. 30 days)
    @Default(<DailyActivityPoint>[]) List<DailyActivityPoint> last30Days,
    // hardest words – top list aggregated from trap words
    @Default(<String>[]) List<String> hardestWords,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}
