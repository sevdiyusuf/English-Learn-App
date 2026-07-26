// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'played_word.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlayedWord _$PlayedWordFromJson(Map<String, dynamic> json) {
  return _PlayedWord.fromJson(json);
}

/// @nodoc
mixin _$PlayedWord {
  String get word => throw _privateConstructorUsedError;
  @WordTypeConverter()
  WordType get type => throw _privateConstructorUsedError;
  String get byUid => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlayedWordCopyWith<PlayedWord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayedWordCopyWith<$Res> {
  factory $PlayedWordCopyWith(
    PlayedWord value,
    $Res Function(PlayedWord) then,
  ) = _$PlayedWordCopyWithImpl<$Res, PlayedWord>;
  @useResult
  $Res call({
    String word,
    @WordTypeConverter() WordType type,
    String byUid,
    @TimestampConverter() DateTime at,
  });
}

/// @nodoc
class _$PlayedWordCopyWithImpl<$Res, $Val extends PlayedWord>
    implements $PlayedWordCopyWith<$Res> {
  _$PlayedWordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? type = null,
    Object? byUid = null,
    Object? at = null,
  }) {
    return _then(
      _value.copyWith(
            word:
                null == word
                    ? _value.word
                    : word // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as WordType,
            byUid:
                null == byUid
                    ? _value.byUid
                    : byUid // ignore: cast_nullable_to_non_nullable
                        as String,
            at:
                null == at
                    ? _value.at
                    : at // ignore: cast_nullable_to_non_nullable
                        as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayedWordImplCopyWith<$Res>
    implements $PlayedWordCopyWith<$Res> {
  factory _$$PlayedWordImplCopyWith(
    _$PlayedWordImpl value,
    $Res Function(_$PlayedWordImpl) then,
  ) = __$$PlayedWordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String word,
    @WordTypeConverter() WordType type,
    String byUid,
    @TimestampConverter() DateTime at,
  });
}

/// @nodoc
class __$$PlayedWordImplCopyWithImpl<$Res>
    extends _$PlayedWordCopyWithImpl<$Res, _$PlayedWordImpl>
    implements _$$PlayedWordImplCopyWith<$Res> {
  __$$PlayedWordImplCopyWithImpl(
    _$PlayedWordImpl _value,
    $Res Function(_$PlayedWordImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? type = null,
    Object? byUid = null,
    Object? at = null,
  }) {
    return _then(
      _$PlayedWordImpl(
        word:
            null == word
                ? _value.word
                : word // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as WordType,
        byUid:
            null == byUid
                ? _value.byUid
                : byUid // ignore: cast_nullable_to_non_nullable
                    as String,
        at:
            null == at
                ? _value.at
                : at // ignore: cast_nullable_to_non_nullable
                    as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayedWordImpl implements _PlayedWord {
  const _$PlayedWordImpl({
    required this.word,
    @WordTypeConverter() required this.type,
    required this.byUid,
    @TimestampConverter() required this.at,
  });

  factory _$PlayedWordImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayedWordImplFromJson(json);

  @override
  final String word;
  @override
  @WordTypeConverter()
  final WordType type;
  @override
  final String byUid;
  @override
  @TimestampConverter()
  final DateTime at;

  @override
  String toString() {
    return 'PlayedWord(word: $word, type: $type, byUid: $byUid, at: $at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayedWordImpl &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.byUid, byUid) || other.byUid == byUid) &&
            (identical(other.at, at) || other.at == at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, word, type, byUid, at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayedWordImplCopyWith<_$PlayedWordImpl> get copyWith =>
      __$$PlayedWordImplCopyWithImpl<_$PlayedWordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayedWordImplToJson(this);
  }
}

abstract class _PlayedWord implements PlayedWord {
  const factory _PlayedWord({
    required final String word,
    @WordTypeConverter() required final WordType type,
    required final String byUid,
    @TimestampConverter() required final DateTime at,
  }) = _$PlayedWordImpl;

  factory _PlayedWord.fromJson(Map<String, dynamic> json) =
      _$PlayedWordImpl.fromJson;

  @override
  String get word;
  @override
  @WordTypeConverter()
  WordType get type;
  @override
  String get byUid;
  @override
  @TimestampConverter()
  DateTime get at;
  @override
  @JsonKey(ignore: true)
  _$$PlayedWordImplCopyWith<_$PlayedWordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
