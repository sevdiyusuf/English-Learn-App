// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'irregular_verb.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

IrregularVerb _$IrregularVerbFromJson(Map<String, dynamic> json) {
  return _IrregularVerb.fromJson(json);
}

/// @nodoc
mixin _$IrregularVerb {
  @JsonKey(name: 'base_form')
  String get v1 => throw _privateConstructorUsedError;
  @JsonKey(name: 'v2')
  String get v2 => throw _privateConstructorUsedError;
  @JsonKey(name: 'v3')
  String get v3 => throw _privateConstructorUsedError;
  @JsonKey(name: 'meaning_tr')
  String get meaningTr => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IrregularVerbCopyWith<IrregularVerb> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IrregularVerbCopyWith<$Res> {
  factory $IrregularVerbCopyWith(
    IrregularVerb value,
    $Res Function(IrregularVerb) then,
  ) = _$IrregularVerbCopyWithImpl<$Res, IrregularVerb>;
  @useResult
  $Res call({
    @JsonKey(name: 'base_form') String v1,
    @JsonKey(name: 'v2') String v2,
    @JsonKey(name: 'v3') String v3,
    @JsonKey(name: 'meaning_tr') String meaningTr,
  });
}

/// @nodoc
class _$IrregularVerbCopyWithImpl<$Res, $Val extends IrregularVerb>
    implements $IrregularVerbCopyWith<$Res> {
  _$IrregularVerbCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? v1 = null,
    Object? v2 = null,
    Object? v3 = null,
    Object? meaningTr = null,
  }) {
    return _then(
      _value.copyWith(
            v1:
                null == v1
                    ? _value.v1
                    : v1 // ignore: cast_nullable_to_non_nullable
                        as String,
            v2:
                null == v2
                    ? _value.v2
                    : v2 // ignore: cast_nullable_to_non_nullable
                        as String,
            v3:
                null == v3
                    ? _value.v3
                    : v3 // ignore: cast_nullable_to_non_nullable
                        as String,
            meaningTr:
                null == meaningTr
                    ? _value.meaningTr
                    : meaningTr // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IrregularVerbImplCopyWith<$Res>
    implements $IrregularVerbCopyWith<$Res> {
  factory _$$IrregularVerbImplCopyWith(
    _$IrregularVerbImpl value,
    $Res Function(_$IrregularVerbImpl) then,
  ) = __$$IrregularVerbImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'base_form') String v1,
    @JsonKey(name: 'v2') String v2,
    @JsonKey(name: 'v3') String v3,
    @JsonKey(name: 'meaning_tr') String meaningTr,
  });
}

/// @nodoc
class __$$IrregularVerbImplCopyWithImpl<$Res>
    extends _$IrregularVerbCopyWithImpl<$Res, _$IrregularVerbImpl>
    implements _$$IrregularVerbImplCopyWith<$Res> {
  __$$IrregularVerbImplCopyWithImpl(
    _$IrregularVerbImpl _value,
    $Res Function(_$IrregularVerbImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? v1 = null,
    Object? v2 = null,
    Object? v3 = null,
    Object? meaningTr = null,
  }) {
    return _then(
      _$IrregularVerbImpl(
        v1:
            null == v1
                ? _value.v1
                : v1 // ignore: cast_nullable_to_non_nullable
                    as String,
        v2:
            null == v2
                ? _value.v2
                : v2 // ignore: cast_nullable_to_non_nullable
                    as String,
        v3:
            null == v3
                ? _value.v3
                : v3 // ignore: cast_nullable_to_non_nullable
                    as String,
        meaningTr:
            null == meaningTr
                ? _value.meaningTr
                : meaningTr // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IrregularVerbImpl extends _IrregularVerb {
  const _$IrregularVerbImpl({
    @JsonKey(name: 'base_form') required this.v1,
    @JsonKey(name: 'v2') required this.v2,
    @JsonKey(name: 'v3') required this.v3,
    @JsonKey(name: 'meaning_tr') required this.meaningTr,
  }) : super._();

  factory _$IrregularVerbImpl.fromJson(Map<String, dynamic> json) =>
      _$$IrregularVerbImplFromJson(json);

  @override
  @JsonKey(name: 'base_form')
  final String v1;
  @override
  @JsonKey(name: 'v2')
  final String v2;
  @override
  @JsonKey(name: 'v3')
  final String v3;
  @override
  @JsonKey(name: 'meaning_tr')
  final String meaningTr;

  @override
  String toString() {
    return 'IrregularVerb(v1: $v1, v2: $v2, v3: $v3, meaningTr: $meaningTr)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IrregularVerbImpl &&
            (identical(other.v1, v1) || other.v1 == v1) &&
            (identical(other.v2, v2) || other.v2 == v2) &&
            (identical(other.v3, v3) || other.v3 == v3) &&
            (identical(other.meaningTr, meaningTr) ||
                other.meaningTr == meaningTr));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, v1, v2, v3, meaningTr);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IrregularVerbImplCopyWith<_$IrregularVerbImpl> get copyWith =>
      __$$IrregularVerbImplCopyWithImpl<_$IrregularVerbImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IrregularVerbImplToJson(this);
  }
}

abstract class _IrregularVerb extends IrregularVerb {
  const factory _IrregularVerb({
    @JsonKey(name: 'base_form') required final String v1,
    @JsonKey(name: 'v2') required final String v2,
    @JsonKey(name: 'v3') required final String v3,
    @JsonKey(name: 'meaning_tr') required final String meaningTr,
  }) = _$IrregularVerbImpl;
  const _IrregularVerb._() : super._();

  factory _IrregularVerb.fromJson(Map<String, dynamic> json) =
      _$IrregularVerbImpl.fromJson;

  @override
  @JsonKey(name: 'base_form')
  String get v1;
  @override
  @JsonKey(name: 'v2')
  String get v2;
  @override
  @JsonKey(name: 'v3')
  String get v3;
  @override
  @JsonKey(name: 'meaning_tr')
  String get meaningTr;
  @override
  @JsonKey(ignore: true)
  _$$IrregularVerbImplCopyWith<_$IrregularVerbImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
