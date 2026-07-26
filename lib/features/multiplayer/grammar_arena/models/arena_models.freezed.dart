// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'arena_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ArenaConfig _$ArenaConfigFromJson(Map<String, dynamic> json) {
  return _ArenaConfig.fromJson(json);
}

/// @nodoc
mixin _$ArenaConfig {
  String get level => throw _privateConstructorUsedError;
  String? get worksheetId => throw _privateConstructorUsedError;
  int get questionCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArenaConfigCopyWith<ArenaConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArenaConfigCopyWith<$Res> {
  factory $ArenaConfigCopyWith(
    ArenaConfig value,
    $Res Function(ArenaConfig) then,
  ) = _$ArenaConfigCopyWithImpl<$Res, ArenaConfig>;
  @useResult
  $Res call({String level, String? worksheetId, int questionCount});
}

/// @nodoc
class _$ArenaConfigCopyWithImpl<$Res, $Val extends ArenaConfig>
    implements $ArenaConfigCopyWith<$Res> {
  _$ArenaConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? worksheetId = freezed,
    Object? questionCount = null,
  }) {
    return _then(
      _value.copyWith(
            level:
                null == level
                    ? _value.level
                    : level // ignore: cast_nullable_to_non_nullable
                        as String,
            worksheetId:
                freezed == worksheetId
                    ? _value.worksheetId
                    : worksheetId // ignore: cast_nullable_to_non_nullable
                        as String?,
            questionCount:
                null == questionCount
                    ? _value.questionCount
                    : questionCount // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ArenaConfigImplCopyWith<$Res>
    implements $ArenaConfigCopyWith<$Res> {
  factory _$$ArenaConfigImplCopyWith(
    _$ArenaConfigImpl value,
    $Res Function(_$ArenaConfigImpl) then,
  ) = __$$ArenaConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String level, String? worksheetId, int questionCount});
}

/// @nodoc
class __$$ArenaConfigImplCopyWithImpl<$Res>
    extends _$ArenaConfigCopyWithImpl<$Res, _$ArenaConfigImpl>
    implements _$$ArenaConfigImplCopyWith<$Res> {
  __$$ArenaConfigImplCopyWithImpl(
    _$ArenaConfigImpl _value,
    $Res Function(_$ArenaConfigImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? worksheetId = freezed,
    Object? questionCount = null,
  }) {
    return _then(
      _$ArenaConfigImpl(
        level:
            null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                    as String,
        worksheetId:
            freezed == worksheetId
                ? _value.worksheetId
                : worksheetId // ignore: cast_nullable_to_non_nullable
                    as String?,
        questionCount:
            null == questionCount
                ? _value.questionCount
                : questionCount // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ArenaConfigImpl implements _ArenaConfig {
  const _$ArenaConfigImpl({
    required this.level,
    required this.worksheetId,
    this.questionCount = 12,
  });

  factory _$ArenaConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArenaConfigImplFromJson(json);

  @override
  final String level;
  @override
  final String? worksheetId;
  @override
  @JsonKey()
  final int questionCount;

  @override
  String toString() {
    return 'ArenaConfig(level: $level, worksheetId: $worksheetId, questionCount: $questionCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArenaConfigImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.worksheetId, worksheetId) ||
                other.worksheetId == worksheetId) &&
            (identical(other.questionCount, questionCount) ||
                other.questionCount == questionCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, level, worksheetId, questionCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArenaConfigImplCopyWith<_$ArenaConfigImpl> get copyWith =>
      __$$ArenaConfigImplCopyWithImpl<_$ArenaConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArenaConfigImplToJson(this);
  }
}

abstract class _ArenaConfig implements ArenaConfig {
  const factory _ArenaConfig({
    required final String level,
    required final String? worksheetId,
    final int questionCount,
  }) = _$ArenaConfigImpl;

  factory _ArenaConfig.fromJson(Map<String, dynamic> json) =
      _$ArenaConfigImpl.fromJson;

  @override
  String get level;
  @override
  String? get worksheetId;
  @override
  int get questionCount;
  @override
  @JsonKey(ignore: true)
  _$$ArenaConfigImplCopyWith<_$ArenaConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArenaPlayer _$ArenaPlayerFromJson(Map<String, dynamic> json) {
  return _ArenaPlayer.fromJson(json);
}

/// @nodoc
mixin _$ArenaPlayer {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastPing => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArenaPlayerCopyWith<ArenaPlayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArenaPlayerCopyWith<$Res> {
  factory $ArenaPlayerCopyWith(
    ArenaPlayer value,
    $Res Function(ArenaPlayer) then,
  ) = _$ArenaPlayerCopyWithImpl<$Res, ArenaPlayer>;
  @useResult
  $Res call({
    String id,
    String name,
    String? photoUrl,
    int score,
    bool isOnline,
    @TimestampConverter() DateTime? lastPing,
  });
}

/// @nodoc
class _$ArenaPlayerCopyWithImpl<$Res, $Val extends ArenaPlayer>
    implements $ArenaPlayerCopyWith<$Res> {
  _$ArenaPlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? score = null,
    Object? isOnline = null,
    Object? lastPing = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            photoUrl:
                freezed == photoUrl
                    ? _value.photoUrl
                    : photoUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            score:
                null == score
                    ? _value.score
                    : score // ignore: cast_nullable_to_non_nullable
                        as int,
            isOnline:
                null == isOnline
                    ? _value.isOnline
                    : isOnline // ignore: cast_nullable_to_non_nullable
                        as bool,
            lastPing:
                freezed == lastPing
                    ? _value.lastPing
                    : lastPing // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ArenaPlayerImplCopyWith<$Res>
    implements $ArenaPlayerCopyWith<$Res> {
  factory _$$ArenaPlayerImplCopyWith(
    _$ArenaPlayerImpl value,
    $Res Function(_$ArenaPlayerImpl) then,
  ) = __$$ArenaPlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? photoUrl,
    int score,
    bool isOnline,
    @TimestampConverter() DateTime? lastPing,
  });
}

/// @nodoc
class __$$ArenaPlayerImplCopyWithImpl<$Res>
    extends _$ArenaPlayerCopyWithImpl<$Res, _$ArenaPlayerImpl>
    implements _$$ArenaPlayerImplCopyWith<$Res> {
  __$$ArenaPlayerImplCopyWithImpl(
    _$ArenaPlayerImpl _value,
    $Res Function(_$ArenaPlayerImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? score = null,
    Object? isOnline = null,
    Object? lastPing = freezed,
  }) {
    return _then(
      _$ArenaPlayerImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        photoUrl:
            freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        score:
            null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                    as int,
        isOnline:
            null == isOnline
                ? _value.isOnline
                : isOnline // ignore: cast_nullable_to_non_nullable
                    as bool,
        lastPing:
            freezed == lastPing
                ? _value.lastPing
                : lastPing // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ArenaPlayerImpl implements _ArenaPlayer {
  const _$ArenaPlayerImpl({
    required this.id,
    required this.name,
    this.photoUrl,
    this.score = 0,
    this.isOnline = false,
    @TimestampConverter() this.lastPing,
  });

  factory _$ArenaPlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArenaPlayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? photoUrl;
  @override
  @JsonKey()
  final int score;
  @override
  @JsonKey()
  final bool isOnline;
  @override
  @TimestampConverter()
  final DateTime? lastPing;

  @override
  String toString() {
    return 'ArenaPlayer(id: $id, name: $name, photoUrl: $photoUrl, score: $score, isOnline: $isOnline, lastPing: $lastPing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArenaPlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastPing, lastPing) ||
                other.lastPing == lastPing));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, photoUrl, score, isOnline, lastPing);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArenaPlayerImplCopyWith<_$ArenaPlayerImpl> get copyWith =>
      __$$ArenaPlayerImplCopyWithImpl<_$ArenaPlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArenaPlayerImplToJson(this);
  }
}

abstract class _ArenaPlayer implements ArenaPlayer {
  const factory _ArenaPlayer({
    required final String id,
    required final String name,
    final String? photoUrl,
    final int score,
    final bool isOnline,
    @TimestampConverter() final DateTime? lastPing,
  }) = _$ArenaPlayerImpl;

  factory _ArenaPlayer.fromJson(Map<String, dynamic> json) =
      _$ArenaPlayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get photoUrl;
  @override
  int get score;
  @override
  bool get isOnline;
  @override
  @TimestampConverter()
  DateTime? get lastPing;
  @override
  @JsonKey(ignore: true)
  _$$ArenaPlayerImplCopyWith<_$ArenaPlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArenaRound _$ArenaRoundFromJson(Map<String, dynamic> json) {
  return _ArenaRound.fromJson(json);
}

/// @nodoc
mixin _$ArenaRound {
  int get index => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get roundStartAt => throw _privateConstructorUsedError;
  int get timeLimitMs => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArenaRoundCopyWith<ArenaRound> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArenaRoundCopyWith<$Res> {
  factory $ArenaRoundCopyWith(
    ArenaRound value,
    $Res Function(ArenaRound) then,
  ) = _$ArenaRoundCopyWithImpl<$Res, ArenaRound>;
  @useResult
  $Res call({
    int index,
    @TimestampConverter() DateTime roundStartAt,
    int timeLimitMs,
  });
}

/// @nodoc
class _$ArenaRoundCopyWithImpl<$Res, $Val extends ArenaRound>
    implements $ArenaRoundCopyWith<$Res> {
  _$ArenaRoundCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? roundStartAt = null,
    Object? timeLimitMs = null,
  }) {
    return _then(
      _value.copyWith(
            index:
                null == index
                    ? _value.index
                    : index // ignore: cast_nullable_to_non_nullable
                        as int,
            roundStartAt:
                null == roundStartAt
                    ? _value.roundStartAt
                    : roundStartAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            timeLimitMs:
                null == timeLimitMs
                    ? _value.timeLimitMs
                    : timeLimitMs // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ArenaRoundImplCopyWith<$Res>
    implements $ArenaRoundCopyWith<$Res> {
  factory _$$ArenaRoundImplCopyWith(
    _$ArenaRoundImpl value,
    $Res Function(_$ArenaRoundImpl) then,
  ) = __$$ArenaRoundImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int index,
    @TimestampConverter() DateTime roundStartAt,
    int timeLimitMs,
  });
}

/// @nodoc
class __$$ArenaRoundImplCopyWithImpl<$Res>
    extends _$ArenaRoundCopyWithImpl<$Res, _$ArenaRoundImpl>
    implements _$$ArenaRoundImplCopyWith<$Res> {
  __$$ArenaRoundImplCopyWithImpl(
    _$ArenaRoundImpl _value,
    $Res Function(_$ArenaRoundImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? roundStartAt = null,
    Object? timeLimitMs = null,
  }) {
    return _then(
      _$ArenaRoundImpl(
        index:
            null == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                    as int,
        roundStartAt:
            null == roundStartAt
                ? _value.roundStartAt
                : roundStartAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        timeLimitMs:
            null == timeLimitMs
                ? _value.timeLimitMs
                : timeLimitMs // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ArenaRoundImpl implements _ArenaRound {
  const _$ArenaRoundImpl({
    required this.index,
    @TimestampConverter() required this.roundStartAt,
    required this.timeLimitMs,
  });

  factory _$ArenaRoundImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArenaRoundImplFromJson(json);

  @override
  final int index;
  @override
  @TimestampConverter()
  final DateTime roundStartAt;
  @override
  final int timeLimitMs;

  @override
  String toString() {
    return 'ArenaRound(index: $index, roundStartAt: $roundStartAt, timeLimitMs: $timeLimitMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArenaRoundImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.roundStartAt, roundStartAt) ||
                other.roundStartAt == roundStartAt) &&
            (identical(other.timeLimitMs, timeLimitMs) ||
                other.timeLimitMs == timeLimitMs));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, index, roundStartAt, timeLimitMs);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArenaRoundImplCopyWith<_$ArenaRoundImpl> get copyWith =>
      __$$ArenaRoundImplCopyWithImpl<_$ArenaRoundImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArenaRoundImplToJson(this);
  }
}

abstract class _ArenaRound implements ArenaRound {
  const factory _ArenaRound({
    required final int index,
    @TimestampConverter() required final DateTime roundStartAt,
    required final int timeLimitMs,
  }) = _$ArenaRoundImpl;

  factory _ArenaRound.fromJson(Map<String, dynamic> json) =
      _$ArenaRoundImpl.fromJson;

  @override
  int get index;
  @override
  @TimestampConverter()
  DateTime get roundStartAt;
  @override
  int get timeLimitMs;
  @override
  @JsonKey(ignore: true)
  _$$ArenaRoundImplCopyWith<_$ArenaRoundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArenaAnswer _$ArenaAnswerFromJson(Map<String, dynamic> json) {
  return _ArenaAnswer.fromJson(json);
}

/// @nodoc
mixin _$ArenaAnswer {
  int get attempt => throw _privateConstructorUsedError;
  bool get isCorrect => throw _privateConstructorUsedError;
  int get pointsAwarded => throw _privateConstructorUsedError;
  int get clientSentAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArenaAnswerCopyWith<ArenaAnswer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArenaAnswerCopyWith<$Res> {
  factory $ArenaAnswerCopyWith(
    ArenaAnswer value,
    $Res Function(ArenaAnswer) then,
  ) = _$ArenaAnswerCopyWithImpl<$Res, ArenaAnswer>;
  @useResult
  $Res call({int attempt, bool isCorrect, int pointsAwarded, int clientSentAt});
}

/// @nodoc
class _$ArenaAnswerCopyWithImpl<$Res, $Val extends ArenaAnswer>
    implements $ArenaAnswerCopyWith<$Res> {
  _$ArenaAnswerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attempt = null,
    Object? isCorrect = null,
    Object? pointsAwarded = null,
    Object? clientSentAt = null,
  }) {
    return _then(
      _value.copyWith(
            attempt:
                null == attempt
                    ? _value.attempt
                    : attempt // ignore: cast_nullable_to_non_nullable
                        as int,
            isCorrect:
                null == isCorrect
                    ? _value.isCorrect
                    : isCorrect // ignore: cast_nullable_to_non_nullable
                        as bool,
            pointsAwarded:
                null == pointsAwarded
                    ? _value.pointsAwarded
                    : pointsAwarded // ignore: cast_nullable_to_non_nullable
                        as int,
            clientSentAt:
                null == clientSentAt
                    ? _value.clientSentAt
                    : clientSentAt // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ArenaAnswerImplCopyWith<$Res>
    implements $ArenaAnswerCopyWith<$Res> {
  factory _$$ArenaAnswerImplCopyWith(
    _$ArenaAnswerImpl value,
    $Res Function(_$ArenaAnswerImpl) then,
  ) = __$$ArenaAnswerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int attempt, bool isCorrect, int pointsAwarded, int clientSentAt});
}

/// @nodoc
class __$$ArenaAnswerImplCopyWithImpl<$Res>
    extends _$ArenaAnswerCopyWithImpl<$Res, _$ArenaAnswerImpl>
    implements _$$ArenaAnswerImplCopyWith<$Res> {
  __$$ArenaAnswerImplCopyWithImpl(
    _$ArenaAnswerImpl _value,
    $Res Function(_$ArenaAnswerImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attempt = null,
    Object? isCorrect = null,
    Object? pointsAwarded = null,
    Object? clientSentAt = null,
  }) {
    return _then(
      _$ArenaAnswerImpl(
        attempt:
            null == attempt
                ? _value.attempt
                : attempt // ignore: cast_nullable_to_non_nullable
                    as int,
        isCorrect:
            null == isCorrect
                ? _value.isCorrect
                : isCorrect // ignore: cast_nullable_to_non_nullable
                    as bool,
        pointsAwarded:
            null == pointsAwarded
                ? _value.pointsAwarded
                : pointsAwarded // ignore: cast_nullable_to_non_nullable
                    as int,
        clientSentAt:
            null == clientSentAt
                ? _value.clientSentAt
                : clientSentAt // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ArenaAnswerImpl implements _ArenaAnswer {
  const _$ArenaAnswerImpl({
    required this.attempt,
    required this.isCorrect,
    required this.pointsAwarded,
    required this.clientSentAt,
  });

  factory _$ArenaAnswerImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArenaAnswerImplFromJson(json);

  @override
  final int attempt;
  @override
  final bool isCorrect;
  @override
  final int pointsAwarded;
  @override
  final int clientSentAt;

  @override
  String toString() {
    return 'ArenaAnswer(attempt: $attempt, isCorrect: $isCorrect, pointsAwarded: $pointsAwarded, clientSentAt: $clientSentAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArenaAnswerImpl &&
            (identical(other.attempt, attempt) || other.attempt == attempt) &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect) &&
            (identical(other.pointsAwarded, pointsAwarded) ||
                other.pointsAwarded == pointsAwarded) &&
            (identical(other.clientSentAt, clientSentAt) ||
                other.clientSentAt == clientSentAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, attempt, isCorrect, pointsAwarded, clientSentAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArenaAnswerImplCopyWith<_$ArenaAnswerImpl> get copyWith =>
      __$$ArenaAnswerImplCopyWithImpl<_$ArenaAnswerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArenaAnswerImplToJson(this);
  }
}

abstract class _ArenaAnswer implements ArenaAnswer {
  const factory _ArenaAnswer({
    required final int attempt,
    required final bool isCorrect,
    required final int pointsAwarded,
    required final int clientSentAt,
  }) = _$ArenaAnswerImpl;

  factory _ArenaAnswer.fromJson(Map<String, dynamic> json) =
      _$ArenaAnswerImpl.fromJson;

  @override
  int get attempt;
  @override
  bool get isCorrect;
  @override
  int get pointsAwarded;
  @override
  int get clientSentAt;
  @override
  @JsonKey(ignore: true)
  _$$ArenaAnswerImplCopyWith<_$ArenaAnswerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ResolvedWorksheet _$ResolvedWorksheetFromJson(Map<String, dynamic> json) {
  return _ResolvedWorksheet.fromJson(json);
}

/// @nodoc
mixin _$ResolvedWorksheet {
  String get worksheetId => throw _privateConstructorUsedError;
  int get seed => throw _privateConstructorUsedError;
  List<String> get questionIds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ResolvedWorksheetCopyWith<ResolvedWorksheet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResolvedWorksheetCopyWith<$Res> {
  factory $ResolvedWorksheetCopyWith(
    ResolvedWorksheet value,
    $Res Function(ResolvedWorksheet) then,
  ) = _$ResolvedWorksheetCopyWithImpl<$Res, ResolvedWorksheet>;
  @useResult
  $Res call({String worksheetId, int seed, List<String> questionIds});
}

/// @nodoc
class _$ResolvedWorksheetCopyWithImpl<$Res, $Val extends ResolvedWorksheet>
    implements $ResolvedWorksheetCopyWith<$Res> {
  _$ResolvedWorksheetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? worksheetId = null,
    Object? seed = null,
    Object? questionIds = null,
  }) {
    return _then(
      _value.copyWith(
            worksheetId:
                null == worksheetId
                    ? _value.worksheetId
                    : worksheetId // ignore: cast_nullable_to_non_nullable
                        as String,
            seed:
                null == seed
                    ? _value.seed
                    : seed // ignore: cast_nullable_to_non_nullable
                        as int,
            questionIds:
                null == questionIds
                    ? _value.questionIds
                    : questionIds // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ResolvedWorksheetImplCopyWith<$Res>
    implements $ResolvedWorksheetCopyWith<$Res> {
  factory _$$ResolvedWorksheetImplCopyWith(
    _$ResolvedWorksheetImpl value,
    $Res Function(_$ResolvedWorksheetImpl) then,
  ) = __$$ResolvedWorksheetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String worksheetId, int seed, List<String> questionIds});
}

/// @nodoc
class __$$ResolvedWorksheetImplCopyWithImpl<$Res>
    extends _$ResolvedWorksheetCopyWithImpl<$Res, _$ResolvedWorksheetImpl>
    implements _$$ResolvedWorksheetImplCopyWith<$Res> {
  __$$ResolvedWorksheetImplCopyWithImpl(
    _$ResolvedWorksheetImpl _value,
    $Res Function(_$ResolvedWorksheetImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? worksheetId = null,
    Object? seed = null,
    Object? questionIds = null,
  }) {
    return _then(
      _$ResolvedWorksheetImpl(
        worksheetId:
            null == worksheetId
                ? _value.worksheetId
                : worksheetId // ignore: cast_nullable_to_non_nullable
                    as String,
        seed:
            null == seed
                ? _value.seed
                : seed // ignore: cast_nullable_to_non_nullable
                    as int,
        questionIds:
            null == questionIds
                ? _value._questionIds
                : questionIds // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ResolvedWorksheetImpl implements _ResolvedWorksheet {
  const _$ResolvedWorksheetImpl({
    required this.worksheetId,
    required this.seed,
    required final List<String> questionIds,
  }) : _questionIds = questionIds;

  factory _$ResolvedWorksheetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResolvedWorksheetImplFromJson(json);

  @override
  final String worksheetId;
  @override
  final int seed;
  final List<String> _questionIds;
  @override
  List<String> get questionIds {
    if (_questionIds is EqualUnmodifiableListView) return _questionIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_questionIds);
  }

  @override
  String toString() {
    return 'ResolvedWorksheet(worksheetId: $worksheetId, seed: $seed, questionIds: $questionIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResolvedWorksheetImpl &&
            (identical(other.worksheetId, worksheetId) ||
                other.worksheetId == worksheetId) &&
            (identical(other.seed, seed) || other.seed == seed) &&
            const DeepCollectionEquality().equals(
              other._questionIds,
              _questionIds,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    worksheetId,
    seed,
    const DeepCollectionEquality().hash(_questionIds),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ResolvedWorksheetImplCopyWith<_$ResolvedWorksheetImpl> get copyWith =>
      __$$ResolvedWorksheetImplCopyWithImpl<_$ResolvedWorksheetImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ResolvedWorksheetImplToJson(this);
  }
}

abstract class _ResolvedWorksheet implements ResolvedWorksheet {
  const factory _ResolvedWorksheet({
    required final String worksheetId,
    required final int seed,
    required final List<String> questionIds,
  }) = _$ResolvedWorksheetImpl;

  factory _ResolvedWorksheet.fromJson(Map<String, dynamic> json) =
      _$ResolvedWorksheetImpl.fromJson;

  @override
  String get worksheetId;
  @override
  int get seed;
  @override
  List<String> get questionIds;
  @override
  @JsonKey(ignore: true)
  _$$ResolvedWorksheetImplCopyWith<_$ResolvedWorksheetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArenaRoom _$ArenaRoomFromJson(Map<String, dynamic> json) {
  return _ArenaRoom.fromJson(json);
}

/// @nodoc
mixin _$ArenaRoom {
  String get id => throw _privateConstructorUsedError;
  String get roomCode => throw _privateConstructorUsedError;
  ArenaStatus get status => throw _privateConstructorUsedError;
  String get hostId => throw _privateConstructorUsedError;
  String? get guestId => throw _privateConstructorUsedError;
  ArenaConfig get config => throw _privateConstructorUsedError;
  ResolvedWorksheet? get resolvedWorksheet =>
      throw _privateConstructorUsedError;
  ArenaRound? get round => throw _privateConstructorUsedError;
  int get hostScore => throw _privateConstructorUsedError;
  int get guestScore => throw _privateConstructorUsedError;
  ArenaPlayer? get host => throw _privateConstructorUsedError;
  ArenaPlayer? get guest => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArenaRoomCopyWith<ArenaRoom> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArenaRoomCopyWith<$Res> {
  factory $ArenaRoomCopyWith(ArenaRoom value, $Res Function(ArenaRoom) then) =
      _$ArenaRoomCopyWithImpl<$Res, ArenaRoom>;
  @useResult
  $Res call({
    String id,
    String roomCode,
    ArenaStatus status,
    String hostId,
    String? guestId,
    ArenaConfig config,
    ResolvedWorksheet? resolvedWorksheet,
    ArenaRound? round,
    int hostScore,
    int guestScore,
    ArenaPlayer? host,
    ArenaPlayer? guest,
    @TimestampConverter() DateTime? createdAt,
  });

  $ArenaConfigCopyWith<$Res> get config;
  $ResolvedWorksheetCopyWith<$Res>? get resolvedWorksheet;
  $ArenaRoundCopyWith<$Res>? get round;
  $ArenaPlayerCopyWith<$Res>? get host;
  $ArenaPlayerCopyWith<$Res>? get guest;
}

/// @nodoc
class _$ArenaRoomCopyWithImpl<$Res, $Val extends ArenaRoom>
    implements $ArenaRoomCopyWith<$Res> {
  _$ArenaRoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? roomCode = null,
    Object? status = null,
    Object? hostId = null,
    Object? guestId = freezed,
    Object? config = null,
    Object? resolvedWorksheet = freezed,
    Object? round = freezed,
    Object? hostScore = null,
    Object? guestScore = null,
    Object? host = freezed,
    Object? guest = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            roomCode:
                null == roomCode
                    ? _value.roomCode
                    : roomCode // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as ArenaStatus,
            hostId:
                null == hostId
                    ? _value.hostId
                    : hostId // ignore: cast_nullable_to_non_nullable
                        as String,
            guestId:
                freezed == guestId
                    ? _value.guestId
                    : guestId // ignore: cast_nullable_to_non_nullable
                        as String?,
            config:
                null == config
                    ? _value.config
                    : config // ignore: cast_nullable_to_non_nullable
                        as ArenaConfig,
            resolvedWorksheet:
                freezed == resolvedWorksheet
                    ? _value.resolvedWorksheet
                    : resolvedWorksheet // ignore: cast_nullable_to_non_nullable
                        as ResolvedWorksheet?,
            round:
                freezed == round
                    ? _value.round
                    : round // ignore: cast_nullable_to_non_nullable
                        as ArenaRound?,
            hostScore:
                null == hostScore
                    ? _value.hostScore
                    : hostScore // ignore: cast_nullable_to_non_nullable
                        as int,
            guestScore:
                null == guestScore
                    ? _value.guestScore
                    : guestScore // ignore: cast_nullable_to_non_nullable
                        as int,
            host:
                freezed == host
                    ? _value.host
                    : host // ignore: cast_nullable_to_non_nullable
                        as ArenaPlayer?,
            guest:
                freezed == guest
                    ? _value.guest
                    : guest // ignore: cast_nullable_to_non_nullable
                        as ArenaPlayer?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $ArenaConfigCopyWith<$Res> get config {
    return $ArenaConfigCopyWith<$Res>(_value.config, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $ResolvedWorksheetCopyWith<$Res>? get resolvedWorksheet {
    if (_value.resolvedWorksheet == null) {
      return null;
    }

    return $ResolvedWorksheetCopyWith<$Res>(_value.resolvedWorksheet!, (value) {
      return _then(_value.copyWith(resolvedWorksheet: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $ArenaRoundCopyWith<$Res>? get round {
    if (_value.round == null) {
      return null;
    }

    return $ArenaRoundCopyWith<$Res>(_value.round!, (value) {
      return _then(_value.copyWith(round: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $ArenaPlayerCopyWith<$Res>? get host {
    if (_value.host == null) {
      return null;
    }

    return $ArenaPlayerCopyWith<$Res>(_value.host!, (value) {
      return _then(_value.copyWith(host: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $ArenaPlayerCopyWith<$Res>? get guest {
    if (_value.guest == null) {
      return null;
    }

    return $ArenaPlayerCopyWith<$Res>(_value.guest!, (value) {
      return _then(_value.copyWith(guest: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArenaRoomImplCopyWith<$Res>
    implements $ArenaRoomCopyWith<$Res> {
  factory _$$ArenaRoomImplCopyWith(
    _$ArenaRoomImpl value,
    $Res Function(_$ArenaRoomImpl) then,
  ) = __$$ArenaRoomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String roomCode,
    ArenaStatus status,
    String hostId,
    String? guestId,
    ArenaConfig config,
    ResolvedWorksheet? resolvedWorksheet,
    ArenaRound? round,
    int hostScore,
    int guestScore,
    ArenaPlayer? host,
    ArenaPlayer? guest,
    @TimestampConverter() DateTime? createdAt,
  });

  @override
  $ArenaConfigCopyWith<$Res> get config;
  @override
  $ResolvedWorksheetCopyWith<$Res>? get resolvedWorksheet;
  @override
  $ArenaRoundCopyWith<$Res>? get round;
  @override
  $ArenaPlayerCopyWith<$Res>? get host;
  @override
  $ArenaPlayerCopyWith<$Res>? get guest;
}

/// @nodoc
class __$$ArenaRoomImplCopyWithImpl<$Res>
    extends _$ArenaRoomCopyWithImpl<$Res, _$ArenaRoomImpl>
    implements _$$ArenaRoomImplCopyWith<$Res> {
  __$$ArenaRoomImplCopyWithImpl(
    _$ArenaRoomImpl _value,
    $Res Function(_$ArenaRoomImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? roomCode = null,
    Object? status = null,
    Object? hostId = null,
    Object? guestId = freezed,
    Object? config = null,
    Object? resolvedWorksheet = freezed,
    Object? round = freezed,
    Object? hostScore = null,
    Object? guestScore = null,
    Object? host = freezed,
    Object? guest = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ArenaRoomImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        roomCode:
            null == roomCode
                ? _value.roomCode
                : roomCode // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as ArenaStatus,
        hostId:
            null == hostId
                ? _value.hostId
                : hostId // ignore: cast_nullable_to_non_nullable
                    as String,
        guestId:
            freezed == guestId
                ? _value.guestId
                : guestId // ignore: cast_nullable_to_non_nullable
                    as String?,
        config:
            null == config
                ? _value.config
                : config // ignore: cast_nullable_to_non_nullable
                    as ArenaConfig,
        resolvedWorksheet:
            freezed == resolvedWorksheet
                ? _value.resolvedWorksheet
                : resolvedWorksheet // ignore: cast_nullable_to_non_nullable
                    as ResolvedWorksheet?,
        round:
            freezed == round
                ? _value.round
                : round // ignore: cast_nullable_to_non_nullable
                    as ArenaRound?,
        hostScore:
            null == hostScore
                ? _value.hostScore
                : hostScore // ignore: cast_nullable_to_non_nullable
                    as int,
        guestScore:
            null == guestScore
                ? _value.guestScore
                : guestScore // ignore: cast_nullable_to_non_nullable
                    as int,
        host:
            freezed == host
                ? _value.host
                : host // ignore: cast_nullable_to_non_nullable
                    as ArenaPlayer?,
        guest:
            freezed == guest
                ? _value.guest
                : guest // ignore: cast_nullable_to_non_nullable
                    as ArenaPlayer?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ArenaRoomImpl implements _ArenaRoom {
  const _$ArenaRoomImpl({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.hostId,
    this.guestId,
    required this.config,
    this.resolvedWorksheet,
    this.round,
    this.hostScore = 0,
    this.guestScore = 0,
    this.host,
    this.guest,
    @TimestampConverter() this.createdAt,
  });

  factory _$ArenaRoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArenaRoomImplFromJson(json);

  @override
  final String id;
  @override
  final String roomCode;
  @override
  final ArenaStatus status;
  @override
  final String hostId;
  @override
  final String? guestId;
  @override
  final ArenaConfig config;
  @override
  final ResolvedWorksheet? resolvedWorksheet;
  @override
  final ArenaRound? round;
  @override
  @JsonKey()
  final int hostScore;
  @override
  @JsonKey()
  final int guestScore;
  @override
  final ArenaPlayer? host;
  @override
  final ArenaPlayer? guest;
  @override
  @TimestampConverter()
  final DateTime? createdAt;

  @override
  String toString() {
    return 'ArenaRoom(id: $id, roomCode: $roomCode, status: $status, hostId: $hostId, guestId: $guestId, config: $config, resolvedWorksheet: $resolvedWorksheet, round: $round, hostScore: $hostScore, guestScore: $guestScore, host: $host, guest: $guest, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArenaRoomImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.roomCode, roomCode) ||
                other.roomCode == roomCode) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.hostId, hostId) || other.hostId == hostId) &&
            (identical(other.guestId, guestId) || other.guestId == guestId) &&
            (identical(other.config, config) || other.config == config) &&
            (identical(other.resolvedWorksheet, resolvedWorksheet) ||
                other.resolvedWorksheet == resolvedWorksheet) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.hostScore, hostScore) ||
                other.hostScore == hostScore) &&
            (identical(other.guestScore, guestScore) ||
                other.guestScore == guestScore) &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.guest, guest) || other.guest == guest) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    roomCode,
    status,
    hostId,
    guestId,
    config,
    resolvedWorksheet,
    round,
    hostScore,
    guestScore,
    host,
    guest,
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArenaRoomImplCopyWith<_$ArenaRoomImpl> get copyWith =>
      __$$ArenaRoomImplCopyWithImpl<_$ArenaRoomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArenaRoomImplToJson(this);
  }
}

abstract class _ArenaRoom implements ArenaRoom {
  const factory _ArenaRoom({
    required final String id,
    required final String roomCode,
    required final ArenaStatus status,
    required final String hostId,
    final String? guestId,
    required final ArenaConfig config,
    final ResolvedWorksheet? resolvedWorksheet,
    final ArenaRound? round,
    final int hostScore,
    final int guestScore,
    final ArenaPlayer? host,
    final ArenaPlayer? guest,
    @TimestampConverter() final DateTime? createdAt,
  }) = _$ArenaRoomImpl;

  factory _ArenaRoom.fromJson(Map<String, dynamic> json) =
      _$ArenaRoomImpl.fromJson;

  @override
  String get id;
  @override
  String get roomCode;
  @override
  ArenaStatus get status;
  @override
  String get hostId;
  @override
  String? get guestId;
  @override
  ArenaConfig get config;
  @override
  ResolvedWorksheet? get resolvedWorksheet;
  @override
  ArenaRound? get round;
  @override
  int get hostScore;
  @override
  int get guestScore;
  @override
  ArenaPlayer? get host;
  @override
  ArenaPlayer? get guest;
  @override
  @TimestampConverter()
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ArenaRoomImplCopyWith<_$ArenaRoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
