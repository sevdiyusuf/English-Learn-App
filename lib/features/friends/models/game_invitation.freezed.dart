// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_invitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameInvitation _$GameInvitationFromJson(Map<String, dynamic> json) {
  return _GameInvitation.fromJson(json);
}

/// @nodoc
mixin _$GameInvitation {
  String get id => throw _privateConstructorUsedError;
  String get fromUid => throw _privateConstructorUsedError;
  String get fromName => throw _privateConstructorUsedError;
  String get toUid => throw _privateConstructorUsedError;
  String get roomId => throw _privateConstructorUsedError;
  String get gameType =>
      throw _privateConstructorUsedError; // 'word_battle' | 'grammar_arena'
  String get status =>
      throw _privateConstructorUsedError; // pending, accepted, rejected
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GameInvitationCopyWith<GameInvitation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameInvitationCopyWith<$Res> {
  factory $GameInvitationCopyWith(
    GameInvitation value,
    $Res Function(GameInvitation) then,
  ) = _$GameInvitationCopyWithImpl<$Res, GameInvitation>;
  @useResult
  $Res call({
    String id,
    String fromUid,
    String fromName,
    String toUid,
    String roomId,
    String gameType,
    String status,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$GameInvitationCopyWithImpl<$Res, $Val extends GameInvitation>
    implements $GameInvitationCopyWith<$Res> {
  _$GameInvitationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUid = null,
    Object? fromName = null,
    Object? toUid = null,
    Object? roomId = null,
    Object? gameType = null,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            fromUid:
                null == fromUid
                    ? _value.fromUid
                    : fromUid // ignore: cast_nullable_to_non_nullable
                        as String,
            fromName:
                null == fromName
                    ? _value.fromName
                    : fromName // ignore: cast_nullable_to_non_nullable
                        as String,
            toUid:
                null == toUid
                    ? _value.toUid
                    : toUid // ignore: cast_nullable_to_non_nullable
                        as String,
            roomId:
                null == roomId
                    ? _value.roomId
                    : roomId // ignore: cast_nullable_to_non_nullable
                        as String,
            gameType:
                null == gameType
                    ? _value.gameType
                    : gameType // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameInvitationImplCopyWith<$Res>
    implements $GameInvitationCopyWith<$Res> {
  factory _$$GameInvitationImplCopyWith(
    _$GameInvitationImpl value,
    $Res Function(_$GameInvitationImpl) then,
  ) = __$$GameInvitationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fromUid,
    String fromName,
    String toUid,
    String roomId,
    String gameType,
    String status,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$GameInvitationImplCopyWithImpl<$Res>
    extends _$GameInvitationCopyWithImpl<$Res, _$GameInvitationImpl>
    implements _$$GameInvitationImplCopyWith<$Res> {
  __$$GameInvitationImplCopyWithImpl(
    _$GameInvitationImpl _value,
    $Res Function(_$GameInvitationImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUid = null,
    Object? fromName = null,
    Object? toUid = null,
    Object? roomId = null,
    Object? gameType = null,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$GameInvitationImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        fromUid:
            null == fromUid
                ? _value.fromUid
                : fromUid // ignore: cast_nullable_to_non_nullable
                    as String,
        fromName:
            null == fromName
                ? _value.fromName
                : fromName // ignore: cast_nullable_to_non_nullable
                    as String,
        toUid:
            null == toUid
                ? _value.toUid
                : toUid // ignore: cast_nullable_to_non_nullable
                    as String,
        roomId:
            null == roomId
                ? _value.roomId
                : roomId // ignore: cast_nullable_to_non_nullable
                    as String,
        gameType:
            null == gameType
                ? _value.gameType
                : gameType // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
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
@JsonSerializable()
class _$GameInvitationImpl implements _GameInvitation {
  const _$GameInvitationImpl({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.roomId,
    required this.gameType,
    this.status = 'pending',
    this.createdAt,
  });

  factory _$GameInvitationImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameInvitationImplFromJson(json);

  @override
  final String id;
  @override
  final String fromUid;
  @override
  final String fromName;
  @override
  final String toUid;
  @override
  final String roomId;
  @override
  final String gameType;
  // 'word_battle' | 'grammar_arena'
  @override
  @JsonKey()
  final String status;
  // pending, accepted, rejected
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'GameInvitation(id: $id, fromUid: $fromUid, fromName: $fromName, toUid: $toUid, roomId: $roomId, gameType: $gameType, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameInvitationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromUid, fromUid) || other.fromUid == fromUid) &&
            (identical(other.fromName, fromName) ||
                other.fromName == fromName) &&
            (identical(other.toUid, toUid) || other.toUid == toUid) &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fromUid,
    fromName,
    toUid,
    roomId,
    gameType,
    status,
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameInvitationImplCopyWith<_$GameInvitationImpl> get copyWith =>
      __$$GameInvitationImplCopyWithImpl<_$GameInvitationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GameInvitationImplToJson(this);
  }
}

abstract class _GameInvitation implements GameInvitation {
  const factory _GameInvitation({
    required final String id,
    required final String fromUid,
    required final String fromName,
    required final String toUid,
    required final String roomId,
    required final String gameType,
    final String status,
    final DateTime? createdAt,
  }) = _$GameInvitationImpl;

  factory _GameInvitation.fromJson(Map<String, dynamic> json) =
      _$GameInvitationImpl.fromJson;

  @override
  String get id;
  @override
  String get fromUid;
  @override
  String get fromName;
  @override
  String get toUid;
  @override
  String get roomId;
  @override
  String get gameType;
  @override // 'word_battle' | 'grammar_arena'
  String get status;
  @override // pending, accepted, rejected
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$GameInvitationImplCopyWith<_$GameInvitationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
