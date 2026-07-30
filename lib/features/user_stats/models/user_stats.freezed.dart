// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ModeStats _$ModeStatsFromJson(Map<String, dynamic> json) {
  return _ModeStats.fromJson(json);
}

/// @nodoc
mixin _$ModeStats {
  int get sessions => throw _privateConstructorUsedError;
  int get correctAnswers => throw _privateConstructorUsedError;
  int get wrongAnswers => throw _privateConstructorUsedError;
  int get totalQuestions => throw _privateConstructorUsedError;
  int get totalMinutes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ModeStatsCopyWith<ModeStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModeStatsCopyWith<$Res> {
  factory $ModeStatsCopyWith(ModeStats value, $Res Function(ModeStats) then) =
      _$ModeStatsCopyWithImpl<$Res, ModeStats>;
  @useResult
  $Res call({
    int sessions,
    int correctAnswers,
    int wrongAnswers,
    int totalQuestions,
    int totalMinutes,
  });
}

/// @nodoc
class _$ModeStatsCopyWithImpl<$Res, $Val extends ModeStats>
    implements $ModeStatsCopyWith<$Res> {
  _$ModeStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessions = null,
    Object? correctAnswers = null,
    Object? wrongAnswers = null,
    Object? totalQuestions = null,
    Object? totalMinutes = null,
  }) {
    return _then(
      _value.copyWith(
            sessions:
                null == sessions
                    ? _value.sessions
                    : sessions // ignore: cast_nullable_to_non_nullable
                        as int,
            correctAnswers:
                null == correctAnswers
                    ? _value.correctAnswers
                    : correctAnswers // ignore: cast_nullable_to_non_nullable
                        as int,
            wrongAnswers:
                null == wrongAnswers
                    ? _value.wrongAnswers
                    : wrongAnswers // ignore: cast_nullable_to_non_nullable
                        as int,
            totalQuestions:
                null == totalQuestions
                    ? _value.totalQuestions
                    : totalQuestions // ignore: cast_nullable_to_non_nullable
                        as int,
            totalMinutes:
                null == totalMinutes
                    ? _value.totalMinutes
                    : totalMinutes // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModeStatsImplCopyWith<$Res>
    implements $ModeStatsCopyWith<$Res> {
  factory _$$ModeStatsImplCopyWith(
    _$ModeStatsImpl value,
    $Res Function(_$ModeStatsImpl) then,
  ) = __$$ModeStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int sessions,
    int correctAnswers,
    int wrongAnswers,
    int totalQuestions,
    int totalMinutes,
  });
}

/// @nodoc
class __$$ModeStatsImplCopyWithImpl<$Res>
    extends _$ModeStatsCopyWithImpl<$Res, _$ModeStatsImpl>
    implements _$$ModeStatsImplCopyWith<$Res> {
  __$$ModeStatsImplCopyWithImpl(
    _$ModeStatsImpl _value,
    $Res Function(_$ModeStatsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessions = null,
    Object? correctAnswers = null,
    Object? wrongAnswers = null,
    Object? totalQuestions = null,
    Object? totalMinutes = null,
  }) {
    return _then(
      _$ModeStatsImpl(
        sessions:
            null == sessions
                ? _value.sessions
                : sessions // ignore: cast_nullable_to_non_nullable
                    as int,
        correctAnswers:
            null == correctAnswers
                ? _value.correctAnswers
                : correctAnswers // ignore: cast_nullable_to_non_nullable
                    as int,
        wrongAnswers:
            null == wrongAnswers
                ? _value.wrongAnswers
                : wrongAnswers // ignore: cast_nullable_to_non_nullable
                    as int,
        totalQuestions:
            null == totalQuestions
                ? _value.totalQuestions
                : totalQuestions // ignore: cast_nullable_to_non_nullable
                    as int,
        totalMinutes:
            null == totalMinutes
                ? _value.totalMinutes
                : totalMinutes // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModeStatsImpl implements _ModeStats {
  const _$ModeStatsImpl({
    this.sessions = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.totalQuestions = 0,
    this.totalMinutes = 0,
  });

  factory _$ModeStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModeStatsImplFromJson(json);

  @override
  @JsonKey()
  final int sessions;
  @override
  @JsonKey()
  final int correctAnswers;
  @override
  @JsonKey()
  final int wrongAnswers;
  @override
  @JsonKey()
  final int totalQuestions;
  @override
  @JsonKey()
  final int totalMinutes;

  @override
  String toString() {
    return 'ModeStats(sessions: $sessions, correctAnswers: $correctAnswers, wrongAnswers: $wrongAnswers, totalQuestions: $totalQuestions, totalMinutes: $totalMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModeStatsImpl &&
            (identical(other.sessions, sessions) ||
                other.sessions == sessions) &&
            (identical(other.correctAnswers, correctAnswers) ||
                other.correctAnswers == correctAnswers) &&
            (identical(other.wrongAnswers, wrongAnswers) ||
                other.wrongAnswers == wrongAnswers) &&
            (identical(other.totalQuestions, totalQuestions) ||
                other.totalQuestions == totalQuestions) &&
            (identical(other.totalMinutes, totalMinutes) ||
                other.totalMinutes == totalMinutes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    sessions,
    correctAnswers,
    wrongAnswers,
    totalQuestions,
    totalMinutes,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ModeStatsImplCopyWith<_$ModeStatsImpl> get copyWith =>
      __$$ModeStatsImplCopyWithImpl<_$ModeStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModeStatsImplToJson(this);
  }
}

abstract class _ModeStats implements ModeStats {
  const factory _ModeStats({
    final int sessions,
    final int correctAnswers,
    final int wrongAnswers,
    final int totalQuestions,
    final int totalMinutes,
  }) = _$ModeStatsImpl;

  factory _ModeStats.fromJson(Map<String, dynamic> json) =
      _$ModeStatsImpl.fromJson;

  @override
  int get sessions;
  @override
  int get correctAnswers;
  @override
  int get wrongAnswers;
  @override
  int get totalQuestions;
  @override
  int get totalMinutes;
  @override
  @JsonKey(ignore: true)
  _$$ModeStatsImplCopyWith<_$ModeStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DailyActivityPoint _$DailyActivityPointFromJson(Map<String, dynamic> json) {
  return _DailyActivityPoint.fromJson(json);
}

/// @nodoc
mixin _$DailyActivityPoint {
  @TimestampConverter()
  DateTime get date => throw _privateConstructorUsedError;
  int get practicedWords => throw _privateConstructorUsedError;
  int get minutes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DailyActivityPointCopyWith<DailyActivityPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyActivityPointCopyWith<$Res> {
  factory $DailyActivityPointCopyWith(
    DailyActivityPoint value,
    $Res Function(DailyActivityPoint) then,
  ) = _$DailyActivityPointCopyWithImpl<$Res, DailyActivityPoint>;
  @useResult
  $Res call({
    @TimestampConverter() DateTime date,
    int practicedWords,
    int minutes,
  });
}

/// @nodoc
class _$DailyActivityPointCopyWithImpl<$Res, $Val extends DailyActivityPoint>
    implements $DailyActivityPointCopyWith<$Res> {
  _$DailyActivityPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? practicedWords = null,
    Object? minutes = null,
  }) {
    return _then(
      _value.copyWith(
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            practicedWords:
                null == practicedWords
                    ? _value.practicedWords
                    : practicedWords // ignore: cast_nullable_to_non_nullable
                        as int,
            minutes:
                null == minutes
                    ? _value.minutes
                    : minutes // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DailyActivityPointImplCopyWith<$Res>
    implements $DailyActivityPointCopyWith<$Res> {
  factory _$$DailyActivityPointImplCopyWith(
    _$DailyActivityPointImpl value,
    $Res Function(_$DailyActivityPointImpl) then,
  ) = __$$DailyActivityPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @TimestampConverter() DateTime date,
    int practicedWords,
    int minutes,
  });
}

/// @nodoc
class __$$DailyActivityPointImplCopyWithImpl<$Res>
    extends _$DailyActivityPointCopyWithImpl<$Res, _$DailyActivityPointImpl>
    implements _$$DailyActivityPointImplCopyWith<$Res> {
  __$$DailyActivityPointImplCopyWithImpl(
    _$DailyActivityPointImpl _value,
    $Res Function(_$DailyActivityPointImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? practicedWords = null,
    Object? minutes = null,
  }) {
    return _then(
      _$DailyActivityPointImpl(
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        practicedWords:
            null == practicedWords
                ? _value.practicedWords
                : practicedWords // ignore: cast_nullable_to_non_nullable
                    as int,
        minutes:
            null == minutes
                ? _value.minutes
                : minutes // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyActivityPointImpl implements _DailyActivityPoint {
  const _$DailyActivityPointImpl({
    @TimestampConverter() required this.date,
    this.practicedWords = 0,
    this.minutes = 0,
  });

  factory _$DailyActivityPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyActivityPointImplFromJson(json);

  @override
  @TimestampConverter()
  final DateTime date;
  @override
  @JsonKey()
  final int practicedWords;
  @override
  @JsonKey()
  final int minutes;

  @override
  String toString() {
    return 'DailyActivityPoint(date: $date, practicedWords: $practicedWords, minutes: $minutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyActivityPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.practicedWords, practicedWords) ||
                other.practicedWords == practicedWords) &&
            (identical(other.minutes, minutes) || other.minutes == minutes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, date, practicedWords, minutes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyActivityPointImplCopyWith<_$DailyActivityPointImpl> get copyWith =>
      __$$DailyActivityPointImplCopyWithImpl<_$DailyActivityPointImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyActivityPointImplToJson(this);
  }
}

abstract class _DailyActivityPoint implements DailyActivityPoint {
  const factory _DailyActivityPoint({
    @TimestampConverter() required final DateTime date,
    final int practicedWords,
    final int minutes,
  }) = _$DailyActivityPointImpl;

  factory _DailyActivityPoint.fromJson(Map<String, dynamic> json) =
      _$DailyActivityPointImpl.fromJson;

  @override
  @TimestampConverter()
  DateTime get date;
  @override
  int get practicedWords;
  @override
  int get minutes;
  @override
  @JsonKey(ignore: true)
  _$$DailyActivityPointImplCopyWith<_$DailyActivityPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserStats _$UserStatsFromJson(Map<String, dynamic> json) {
  return _UserStats.fromJson(json);
}

/// @nodoc
mixin _$UserStats {
  int get totalLearnedWords => throw _privateConstructorUsedError;
  int get totalSessions => throw _privateConstructorUsedError;
  int get totalScore =>
      throw _privateConstructorUsedError; // Toplam puan (tüm oyunlardan)
  // streak
  int get currentStreakDays => throw _privateConstructorUsedError;
  int get bestStreakDays => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastActivityDate => throw _privateConstructorUsedError; // per-mode stats, keyed by: 'word_match', 'flash_opposites', 'flash_synonym',
  // 'cargo_categories', 'word_echo_classic', 'word_echo_grid', 'multiplayer'
  Map<String, ModeStats> get modeStats =>
      throw _privateConstructorUsedError; // last N days (e.g. 30 days)
  List<DailyActivityPoint> get last30Days =>
      throw _privateConstructorUsedError; // hardest words – top list aggregated from trap words
  List<String> get hardestWords => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserStatsCopyWith<UserStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserStatsCopyWith<$Res> {
  factory $UserStatsCopyWith(UserStats value, $Res Function(UserStats) then) =
      _$UserStatsCopyWithImpl<$Res, UserStats>;
  @useResult
  $Res call({
    int totalLearnedWords,
    int totalSessions,
    int totalScore,
    int currentStreakDays,
    int bestStreakDays,
    @TimestampConverter() DateTime? lastActivityDate,
    Map<String, ModeStats> modeStats,
    List<DailyActivityPoint> last30Days,
    List<String> hardestWords,
  });
}

/// @nodoc
class _$UserStatsCopyWithImpl<$Res, $Val extends UserStats>
    implements $UserStatsCopyWith<$Res> {
  _$UserStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalLearnedWords = null,
    Object? totalSessions = null,
    Object? totalScore = null,
    Object? currentStreakDays = null,
    Object? bestStreakDays = null,
    Object? lastActivityDate = freezed,
    Object? modeStats = null,
    Object? last30Days = null,
    Object? hardestWords = null,
  }) {
    return _then(
      _value.copyWith(
            totalLearnedWords:
                null == totalLearnedWords
                    ? _value.totalLearnedWords
                    : totalLearnedWords // ignore: cast_nullable_to_non_nullable
                        as int,
            totalSessions:
                null == totalSessions
                    ? _value.totalSessions
                    : totalSessions // ignore: cast_nullable_to_non_nullable
                        as int,
            totalScore:
                null == totalScore
                    ? _value.totalScore
                    : totalScore // ignore: cast_nullable_to_non_nullable
                        as int,
            currentStreakDays:
                null == currentStreakDays
                    ? _value.currentStreakDays
                    : currentStreakDays // ignore: cast_nullable_to_non_nullable
                        as int,
            bestStreakDays:
                null == bestStreakDays
                    ? _value.bestStreakDays
                    : bestStreakDays // ignore: cast_nullable_to_non_nullable
                        as int,
            lastActivityDate:
                freezed == lastActivityDate
                    ? _value.lastActivityDate
                    : lastActivityDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            modeStats:
                null == modeStats
                    ? _value.modeStats
                    : modeStats // ignore: cast_nullable_to_non_nullable
                        as Map<String, ModeStats>,
            last30Days:
                null == last30Days
                    ? _value.last30Days
                    : last30Days // ignore: cast_nullable_to_non_nullable
                        as List<DailyActivityPoint>,
            hardestWords:
                null == hardestWords
                    ? _value.hardestWords
                    : hardestWords // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserStatsImplCopyWith<$Res>
    implements $UserStatsCopyWith<$Res> {
  factory _$$UserStatsImplCopyWith(
    _$UserStatsImpl value,
    $Res Function(_$UserStatsImpl) then,
  ) = __$$UserStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalLearnedWords,
    int totalSessions,
    int totalScore,
    int currentStreakDays,
    int bestStreakDays,
    @TimestampConverter() DateTime? lastActivityDate,
    Map<String, ModeStats> modeStats,
    List<DailyActivityPoint> last30Days,
    List<String> hardestWords,
  });
}

/// @nodoc
class __$$UserStatsImplCopyWithImpl<$Res>
    extends _$UserStatsCopyWithImpl<$Res, _$UserStatsImpl>
    implements _$$UserStatsImplCopyWith<$Res> {
  __$$UserStatsImplCopyWithImpl(
    _$UserStatsImpl _value,
    $Res Function(_$UserStatsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalLearnedWords = null,
    Object? totalSessions = null,
    Object? totalScore = null,
    Object? currentStreakDays = null,
    Object? bestStreakDays = null,
    Object? lastActivityDate = freezed,
    Object? modeStats = null,
    Object? last30Days = null,
    Object? hardestWords = null,
  }) {
    return _then(
      _$UserStatsImpl(
        totalLearnedWords:
            null == totalLearnedWords
                ? _value.totalLearnedWords
                : totalLearnedWords // ignore: cast_nullable_to_non_nullable
                    as int,
        totalSessions:
            null == totalSessions
                ? _value.totalSessions
                : totalSessions // ignore: cast_nullable_to_non_nullable
                    as int,
        totalScore:
            null == totalScore
                ? _value.totalScore
                : totalScore // ignore: cast_nullable_to_non_nullable
                    as int,
        currentStreakDays:
            null == currentStreakDays
                ? _value.currentStreakDays
                : currentStreakDays // ignore: cast_nullable_to_non_nullable
                    as int,
        bestStreakDays:
            null == bestStreakDays
                ? _value.bestStreakDays
                : bestStreakDays // ignore: cast_nullable_to_non_nullable
                    as int,
        lastActivityDate:
            freezed == lastActivityDate
                ? _value.lastActivityDate
                : lastActivityDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        modeStats:
            null == modeStats
                ? _value._modeStats
                : modeStats // ignore: cast_nullable_to_non_nullable
                    as Map<String, ModeStats>,
        last30Days:
            null == last30Days
                ? _value._last30Days
                : last30Days // ignore: cast_nullable_to_non_nullable
                    as List<DailyActivityPoint>,
        hardestWords:
            null == hardestWords
                ? _value._hardestWords
                : hardestWords // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserStatsImpl implements _UserStats {
  const _$UserStatsImpl({
    this.totalLearnedWords = 0,
    this.totalSessions = 0,
    this.totalScore = 0,
    this.currentStreakDays = 0,
    this.bestStreakDays = 0,
    @TimestampConverter() this.lastActivityDate,
    final Map<String, ModeStats> modeStats = const <String, ModeStats>{},
    final List<DailyActivityPoint> last30Days = const <DailyActivityPoint>[],
    final List<String> hardestWords = const <String>[],
  }) : _modeStats = modeStats,
       _last30Days = last30Days,
       _hardestWords = hardestWords;

  factory _$UserStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserStatsImplFromJson(json);

  @override
  @JsonKey()
  final int totalLearnedWords;
  @override
  @JsonKey()
  final int totalSessions;
  @override
  @JsonKey()
  final int totalScore;
  // Toplam puan (tüm oyunlardan)
  // streak
  @override
  @JsonKey()
  final int currentStreakDays;
  @override
  @JsonKey()
  final int bestStreakDays;
  @override
  @TimestampConverter()
  final DateTime? lastActivityDate;
  // per-mode stats, keyed by: 'word_match', 'flash_opposites', 'flash_synonym',
  // 'cargo_categories', 'word_echo_classic', 'word_echo_grid', 'multiplayer'
  final Map<String, ModeStats> _modeStats;
  // per-mode stats, keyed by: 'word_match', 'flash_opposites', 'flash_synonym',
  // 'cargo_categories', 'word_echo_classic', 'word_echo_grid', 'multiplayer'
  @override
  @JsonKey()
  Map<String, ModeStats> get modeStats {
    if (_modeStats is EqualUnmodifiableMapView) return _modeStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_modeStats);
  }

  // last N days (e.g. 30 days)
  final List<DailyActivityPoint> _last30Days;
  // last N days (e.g. 30 days)
  @override
  @JsonKey()
  List<DailyActivityPoint> get last30Days {
    if (_last30Days is EqualUnmodifiableListView) return _last30Days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_last30Days);
  }

  // hardest words – top list aggregated from trap words
  final List<String> _hardestWords;
  // hardest words – top list aggregated from trap words
  @override
  @JsonKey()
  List<String> get hardestWords {
    if (_hardestWords is EqualUnmodifiableListView) return _hardestWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hardestWords);
  }

  @override
  String toString() {
    return 'UserStats(totalLearnedWords: $totalLearnedWords, totalSessions: $totalSessions, totalScore: $totalScore, currentStreakDays: $currentStreakDays, bestStreakDays: $bestStreakDays, lastActivityDate: $lastActivityDate, modeStats: $modeStats, last30Days: $last30Days, hardestWords: $hardestWords)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserStatsImpl &&
            (identical(other.totalLearnedWords, totalLearnedWords) ||
                other.totalLearnedWords == totalLearnedWords) &&
            (identical(other.totalSessions, totalSessions) ||
                other.totalSessions == totalSessions) &&
            (identical(other.totalScore, totalScore) ||
                other.totalScore == totalScore) &&
            (identical(other.currentStreakDays, currentStreakDays) ||
                other.currentStreakDays == currentStreakDays) &&
            (identical(other.bestStreakDays, bestStreakDays) ||
                other.bestStreakDays == bestStreakDays) &&
            (identical(other.lastActivityDate, lastActivityDate) ||
                other.lastActivityDate == lastActivityDate) &&
            const DeepCollectionEquality().equals(
              other._modeStats,
              _modeStats,
            ) &&
            const DeepCollectionEquality().equals(
              other._last30Days,
              _last30Days,
            ) &&
            const DeepCollectionEquality().equals(
              other._hardestWords,
              _hardestWords,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalLearnedWords,
    totalSessions,
    totalScore,
    currentStreakDays,
    bestStreakDays,
    lastActivityDate,
    const DeepCollectionEquality().hash(_modeStats),
    const DeepCollectionEquality().hash(_last30Days),
    const DeepCollectionEquality().hash(_hardestWords),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserStatsImplCopyWith<_$UserStatsImpl> get copyWith =>
      __$$UserStatsImplCopyWithImpl<_$UserStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserStatsImplToJson(this);
  }
}

abstract class _UserStats implements UserStats {
  const factory _UserStats({
    final int totalLearnedWords,
    final int totalSessions,
    final int totalScore,
    final int currentStreakDays,
    final int bestStreakDays,
    @TimestampConverter() final DateTime? lastActivityDate,
    final Map<String, ModeStats> modeStats,
    final List<DailyActivityPoint> last30Days,
    final List<String> hardestWords,
  }) = _$UserStatsImpl;

  factory _UserStats.fromJson(Map<String, dynamic> json) =
      _$UserStatsImpl.fromJson;

  @override
  int get totalLearnedWords;
  @override
  int get totalSessions;
  @override
  int get totalScore;
  @override // Toplam puan (tüm oyunlardan)
  // streak
  int get currentStreakDays;
  @override
  int get bestStreakDays;
  @override
  @TimestampConverter()
  DateTime? get lastActivityDate;
  @override // per-mode stats, keyed by: 'word_match', 'flash_opposites', 'flash_synonym',
  // 'cargo_categories', 'word_echo_classic', 'word_echo_grid', 'multiplayer'
  Map<String, ModeStats> get modeStats;
  @override // last N days (e.g. 30 days)
  List<DailyActivityPoint> get last30Days;
  @override // hardest words – top list aggregated from trap words
  List<String> get hardestWords;
  @override
  @JsonKey(ignore: true)
  _$$UserStatsImplCopyWith<_$UserStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
