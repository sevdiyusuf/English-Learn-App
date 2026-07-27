// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModeStatsImpl _$$ModeStatsImplFromJson(Map<String, dynamic> json) =>
    _$ModeStatsImpl(
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (json['wrongAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ModeStatsImplToJson(_$ModeStatsImpl instance) =>
    <String, dynamic>{
      'sessions': instance.sessions,
      'correctAnswers': instance.correctAnswers,
      'wrongAnswers': instance.wrongAnswers,
      'totalQuestions': instance.totalQuestions,
      'totalMinutes': instance.totalMinutes,
    };

_$DailyActivityPointImpl _$$DailyActivityPointImplFromJson(
  Map<String, dynamic> json,
) => _$DailyActivityPointImpl(
  date: DateTime.parse(json['date'] as String),
  practicedWords: (json['practicedWords'] as num?)?.toInt() ?? 0,
  minutes: (json['minutes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$DailyActivityPointImplToJson(
  _$DailyActivityPointImpl instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'practicedWords': instance.practicedWords,
  'minutes': instance.minutes,
};

_$UserStatsImpl _$$UserStatsImplFromJson(
  Map<String, dynamic> json,
) => _$UserStatsImpl(
  totalLearnedWords: (json['totalLearnedWords'] as num?)?.toInt() ?? 0,
  totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
  totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
  currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
  bestStreakDays: (json['bestStreakDays'] as num?)?.toInt() ?? 0,
  lastActivityDate: const TimestampConverter().fromJson(
    json['lastActivityDate'],
  ),
  modeStats:
      (json['modeStats'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, ModeStats.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, ModeStats>{},
  last30Days:
      (json['last30Days'] as List<dynamic>?)
          ?.map((e) => DailyActivityPoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DailyActivityPoint>[],
  hardestWords:
      (json['hardestWords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$$UserStatsImplToJson(_$UserStatsImpl instance) =>
    <String, dynamic>{
      'totalLearnedWords': instance.totalLearnedWords,
      'totalSessions': instance.totalSessions,
      'totalScore': instance.totalScore,
      'currentStreakDays': instance.currentStreakDays,
      'bestStreakDays': instance.bestStreakDays,
      'lastActivityDate': const TimestampConverter().toJson(
        instance.lastActivityDate,
      ),
      'modeStats': instance.modeStats,
      'last30Days': instance.last30Days,
      'hardestWords': instance.hardestWords,
    };
