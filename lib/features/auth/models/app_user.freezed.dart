// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppUser {
  String get uid => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  bool get isAnonymous => throw _privateConstructorUsedError;
  bool get isGuestMode => throw _privateConstructorUsedError;
  String? get providerId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppUserCopyWith<AppUser> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppUserCopyWith<$Res> {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) then) =
      _$AppUserCopyWithImpl<$Res, AppUser>;
  @useResult
  $Res call({
    String uid,
    String? displayName,
    String? email,
    String? photoUrl,
    bool isAnonymous,
    bool isGuestMode,
    String? providerId,
  });
}

/// @nodoc
class _$AppUserCopyWithImpl<$Res, $Val extends AppUser>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = freezed,
    Object? email = freezed,
    Object? photoUrl = freezed,
    Object? isAnonymous = null,
    Object? isGuestMode = null,
    Object? providerId = freezed,
  }) {
    return _then(
      _value.copyWith(
            uid:
                null == uid
                    ? _value.uid
                    : uid // ignore: cast_nullable_to_non_nullable
                        as String,
            displayName:
                freezed == displayName
                    ? _value.displayName
                    : displayName // ignore: cast_nullable_to_non_nullable
                        as String?,
            email:
                freezed == email
                    ? _value.email
                    : email // ignore: cast_nullable_to_non_nullable
                        as String?,
            photoUrl:
                freezed == photoUrl
                    ? _value.photoUrl
                    : photoUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            isAnonymous:
                null == isAnonymous
                    ? _value.isAnonymous
                    : isAnonymous // ignore: cast_nullable_to_non_nullable
                        as bool,
            isGuestMode:
                null == isGuestMode
                    ? _value.isGuestMode
                    : isGuestMode // ignore: cast_nullable_to_non_nullable
                        as bool,
            providerId:
                freezed == providerId
                    ? _value.providerId
                    : providerId // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppUserImplCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$$AppUserImplCopyWith(
    _$AppUserImpl value,
    $Res Function(_$AppUserImpl) then,
  ) = __$$AppUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String? displayName,
    String? email,
    String? photoUrl,
    bool isAnonymous,
    bool isGuestMode,
    String? providerId,
  });
}

/// @nodoc
class __$$AppUserImplCopyWithImpl<$Res>
    extends _$AppUserCopyWithImpl<$Res, _$AppUserImpl>
    implements _$$AppUserImplCopyWith<$Res> {
  __$$AppUserImplCopyWithImpl(
    _$AppUserImpl _value,
    $Res Function(_$AppUserImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = freezed,
    Object? email = freezed,
    Object? photoUrl = freezed,
    Object? isAnonymous = null,
    Object? isGuestMode = null,
    Object? providerId = freezed,
  }) {
    return _then(
      _$AppUserImpl(
        uid:
            null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                    as String,
        displayName:
            freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                    as String?,
        email:
            freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                    as String?,
        photoUrl:
            freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        isAnonymous:
            null == isAnonymous
                ? _value.isAnonymous
                : isAnonymous // ignore: cast_nullable_to_non_nullable
                    as bool,
        isGuestMode:
            null == isGuestMode
                ? _value.isGuestMode
                : isGuestMode // ignore: cast_nullable_to_non_nullable
                    as bool,
        providerId:
            freezed == providerId
                ? _value.providerId
                : providerId // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$AppUserImpl extends _AppUser {
  const _$AppUserImpl({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isAnonymous = false,
    this.isGuestMode = false,
    this.providerId,
  }) : super._();

  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? email;
  @override
  final String? photoUrl;
  @override
  @JsonKey()
  final bool isAnonymous;
  @override
  @JsonKey()
  final bool isGuestMode;
  @override
  final String? providerId;

  @override
  String toString() {
    return 'AppUser(uid: $uid, displayName: $displayName, email: $email, photoUrl: $photoUrl, isAnonymous: $isAnonymous, isGuestMode: $isGuestMode, providerId: $providerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppUserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.isAnonymous, isAnonymous) ||
                other.isAnonymous == isAnonymous) &&
            (identical(other.isGuestMode, isGuestMode) ||
                other.isGuestMode == isGuestMode) &&
            (identical(other.providerId, providerId) ||
                other.providerId == providerId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    displayName,
    email,
    photoUrl,
    isAnonymous,
    isGuestMode,
    providerId,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      __$$AppUserImplCopyWithImpl<_$AppUserImpl>(this, _$identity);
}

abstract class _AppUser extends AppUser {
  const factory _AppUser({
    required final String uid,
    final String? displayName,
    final String? email,
    final String? photoUrl,
    final bool isAnonymous,
    final bool isGuestMode,
    final String? providerId,
  }) = _$AppUserImpl;
  const _AppUser._() : super._();

  @override
  String get uid;
  @override
  String? get displayName;
  @override
  String? get email;
  @override
  String? get photoUrl;
  @override
  bool get isAnonymous;
  @override
  bool get isGuestMode;
  @override
  String? get providerId;
  @override
  @JsonKey(ignore: true)
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
