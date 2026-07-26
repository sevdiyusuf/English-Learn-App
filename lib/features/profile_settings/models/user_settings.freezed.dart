// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) {
  return _UserSettings.fromJson(json);
}

/// @nodoc
mixin _$UserSettings {
  // UI
  String get themeMode =>
      throw _privateConstructorUsedError; // 'system' | 'dark' | 'light'
  String get languageCode => throw _privateConstructorUsedError; // 'tr' | 'en'
  // Feedback
  bool get soundEnabled => throw _privateConstructorUsedError;
  bool get vibrationEnabled => throw _privateConstructorUsedError; // Goals
  String get dailyGoalType =>
      throw _privateConstructorUsedError; // 'words' | 'minutes'
  int get dailyGoalValue =>
      throw _privateConstructorUsedError; // 5, 10, 15, etc.
  int get streakGoal => throw _privateConstructorUsedError; // 3, 10, 20, 30, 50
  // Notifications
  bool get remindersEnabled => throw _privateConstructorUsedError;
  String? get reminderTime =>
      throw _privateConstructorUsedError; // "HH:mm" as string
  // Metadata
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
    UserSettings value,
    $Res Function(UserSettings) then,
  ) = _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call({
    String themeMode,
    String languageCode,
    bool soundEnabled,
    bool vibrationEnabled,
    String dailyGoalType,
    int dailyGoalValue,
    int streakGoal,
    bool remindersEnabled,
    String? reminderTime,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  });
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? languageCode = null,
    Object? soundEnabled = null,
    Object? vibrationEnabled = null,
    Object? dailyGoalType = null,
    Object? dailyGoalValue = null,
    Object? streakGoal = null,
    Object? remindersEnabled = null,
    Object? reminderTime = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            themeMode:
                null == themeMode
                    ? _value.themeMode
                    : themeMode // ignore: cast_nullable_to_non_nullable
                        as String,
            languageCode:
                null == languageCode
                    ? _value.languageCode
                    : languageCode // ignore: cast_nullable_to_non_nullable
                        as String,
            soundEnabled:
                null == soundEnabled
                    ? _value.soundEnabled
                    : soundEnabled // ignore: cast_nullable_to_non_nullable
                        as bool,
            vibrationEnabled:
                null == vibrationEnabled
                    ? _value.vibrationEnabled
                    : vibrationEnabled // ignore: cast_nullable_to_non_nullable
                        as bool,
            dailyGoalType:
                null == dailyGoalType
                    ? _value.dailyGoalType
                    : dailyGoalType // ignore: cast_nullable_to_non_nullable
                        as String,
            dailyGoalValue:
                null == dailyGoalValue
                    ? _value.dailyGoalValue
                    : dailyGoalValue // ignore: cast_nullable_to_non_nullable
                        as int,
            streakGoal:
                null == streakGoal
                    ? _value.streakGoal
                    : streakGoal // ignore: cast_nullable_to_non_nullable
                        as int,
            remindersEnabled:
                null == remindersEnabled
                    ? _value.remindersEnabled
                    : remindersEnabled // ignore: cast_nullable_to_non_nullable
                        as bool,
            reminderTime:
                freezed == reminderTime
                    ? _value.reminderTime
                    : reminderTime // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
    _$UserSettingsImpl value,
    $Res Function(_$UserSettingsImpl) then,
  ) = __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String themeMode,
    String languageCode,
    bool soundEnabled,
    bool vibrationEnabled,
    String dailyGoalType,
    int dailyGoalValue,
    int streakGoal,
    bool remindersEnabled,
    String? reminderTime,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  });
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
    _$UserSettingsImpl _value,
    $Res Function(_$UserSettingsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? languageCode = null,
    Object? soundEnabled = null,
    Object? vibrationEnabled = null,
    Object? dailyGoalType = null,
    Object? dailyGoalValue = null,
    Object? streakGoal = null,
    Object? remindersEnabled = null,
    Object? reminderTime = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$UserSettingsImpl(
        themeMode:
            null == themeMode
                ? _value.themeMode
                : themeMode // ignore: cast_nullable_to_non_nullable
                    as String,
        languageCode:
            null == languageCode
                ? _value.languageCode
                : languageCode // ignore: cast_nullable_to_non_nullable
                    as String,
        soundEnabled:
            null == soundEnabled
                ? _value.soundEnabled
                : soundEnabled // ignore: cast_nullable_to_non_nullable
                    as bool,
        vibrationEnabled:
            null == vibrationEnabled
                ? _value.vibrationEnabled
                : vibrationEnabled // ignore: cast_nullable_to_non_nullable
                    as bool,
        dailyGoalType:
            null == dailyGoalType
                ? _value.dailyGoalType
                : dailyGoalType // ignore: cast_nullable_to_non_nullable
                    as String,
        dailyGoalValue:
            null == dailyGoalValue
                ? _value.dailyGoalValue
                : dailyGoalValue // ignore: cast_nullable_to_non_nullable
                    as int,
        streakGoal:
            null == streakGoal
                ? _value.streakGoal
                : streakGoal // ignore: cast_nullable_to_non_nullable
                    as int,
        remindersEnabled:
            null == remindersEnabled
                ? _value.remindersEnabled
                : remindersEnabled // ignore: cast_nullable_to_non_nullable
                    as bool,
        reminderTime:
            freezed == reminderTime
                ? _value.reminderTime
                : reminderTime // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSettingsImpl implements _UserSettings {
  const _$UserSettingsImpl({
    this.themeMode = 'dark',
    this.languageCode = 'tr',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.dailyGoalType = 'words',
    this.dailyGoalValue = 10,
    this.streakGoal = 10,
    this.remindersEnabled = false,
    this.reminderTime,
    @TimestampConverter() this.createdAt,
    @TimestampConverter() this.updatedAt,
  });

  factory _$UserSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSettingsImplFromJson(json);

  // UI
  @override
  @JsonKey()
  final String themeMode;
  // 'system' | 'dark' | 'light'
  @override
  @JsonKey()
  final String languageCode;
  // 'tr' | 'en'
  // Feedback
  @override
  @JsonKey()
  final bool soundEnabled;
  @override
  @JsonKey()
  final bool vibrationEnabled;
  // Goals
  @override
  @JsonKey()
  final String dailyGoalType;
  // 'words' | 'minutes'
  @override
  @JsonKey()
  final int dailyGoalValue;
  // 5, 10, 15, etc.
  @override
  @JsonKey()
  final int streakGoal;
  // 3, 10, 20, 30, 50
  // Notifications
  @override
  @JsonKey()
  final bool remindersEnabled;
  @override
  final String? reminderTime;
  // "HH:mm" as string
  // Metadata
  @override
  @TimestampConverter()
  final DateTime? createdAt;
  @override
  @TimestampConverter()
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'UserSettings(themeMode: $themeMode, languageCode: $languageCode, soundEnabled: $soundEnabled, vibrationEnabled: $vibrationEnabled, dailyGoalType: $dailyGoalType, dailyGoalValue: $dailyGoalValue, streakGoal: $streakGoal, remindersEnabled: $remindersEnabled, reminderTime: $reminderTime, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.languageCode, languageCode) ||
                other.languageCode == languageCode) &&
            (identical(other.soundEnabled, soundEnabled) ||
                other.soundEnabled == soundEnabled) &&
            (identical(other.vibrationEnabled, vibrationEnabled) ||
                other.vibrationEnabled == vibrationEnabled) &&
            (identical(other.dailyGoalType, dailyGoalType) ||
                other.dailyGoalType == dailyGoalType) &&
            (identical(other.dailyGoalValue, dailyGoalValue) ||
                other.dailyGoalValue == dailyGoalValue) &&
            (identical(other.streakGoal, streakGoal) ||
                other.streakGoal == streakGoal) &&
            (identical(other.remindersEnabled, remindersEnabled) ||
                other.remindersEnabled == remindersEnabled) &&
            (identical(other.reminderTime, reminderTime) ||
                other.reminderTime == reminderTime) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    themeMode,
    languageCode,
    soundEnabled,
    vibrationEnabled,
    dailyGoalType,
    dailyGoalValue,
    streakGoal,
    remindersEnabled,
    reminderTime,
    createdAt,
    updatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSettingsImplToJson(this);
  }
}

abstract class _UserSettings implements UserSettings {
  const factory _UserSettings({
    final String themeMode,
    final String languageCode,
    final bool soundEnabled,
    final bool vibrationEnabled,
    final String dailyGoalType,
    final int dailyGoalValue,
    final int streakGoal,
    final bool remindersEnabled,
    final String? reminderTime,
    @TimestampConverter() final DateTime? createdAt,
    @TimestampConverter() final DateTime? updatedAt,
  }) = _$UserSettingsImpl;

  factory _UserSettings.fromJson(Map<String, dynamic> json) =
      _$UserSettingsImpl.fromJson;

  @override // UI
  String get themeMode;
  @override // 'system' | 'dark' | 'light'
  String get languageCode;
  @override // 'tr' | 'en'
  // Feedback
  bool get soundEnabled;
  @override
  bool get vibrationEnabled;
  @override // Goals
  String get dailyGoalType;
  @override // 'words' | 'minutes'
  int get dailyGoalValue;
  @override // 5, 10, 15, etc.
  int get streakGoal;
  @override // 3, 10, 20, 30, 50
  // Notifications
  bool get remindersEnabled;
  @override
  String? get reminderTime;
  @override // "HH:mm" as string
  // Metadata
  @TimestampConverter()
  DateTime? get createdAt;
  @override
  @TimestampConverter()
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
