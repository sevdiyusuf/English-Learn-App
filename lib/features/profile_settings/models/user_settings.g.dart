// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSettingsImpl _$$UserSettingsImplFromJson(Map<String, dynamic> json) =>
    _$UserSettingsImpl(
      themeMode: json['themeMode'] as String? ?? 'dark',
      languageCode: json['languageCode'] as String? ?? 'tr',
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      dailyGoalType: json['dailyGoalType'] as String? ?? 'words',
      dailyGoalValue: (json['dailyGoalValue'] as num?)?.toInt() ?? 10,
      streakGoal: (json['streakGoal'] as num?)?.toInt() ?? 10,
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
      reminderTime: json['reminderTime'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$UserSettingsImplToJson(_$UserSettingsImpl instance) =>
    <String, dynamic>{
      'themeMode': instance.themeMode,
      'languageCode': instance.languageCode,
      'soundEnabled': instance.soundEnabled,
      'vibrationEnabled': instance.vibrationEnabled,
      'dailyGoalType': instance.dailyGoalType,
      'dailyGoalValue': instance.dailyGoalValue,
      'streakGoal': instance.streakGoal,
      'remindersEnabled': instance.remindersEnabled,
      'reminderTime': instance.reminderTime,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
