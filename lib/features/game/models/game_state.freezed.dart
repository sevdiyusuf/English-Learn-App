// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GameState {
  Room get room => throw _privateConstructorUsedError;
  List<PlayedWord> get playedWords => throw _privateConstructorUsedError;
  Map<String, bool> get usedWords => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call({
    Room room,
    List<PlayedWord> playedWords,
    Map<String, bool> usedWords,
  });

  $RoomCopyWith<$Res> get room;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? room = null,
    Object? playedWords = null,
    Object? usedWords = null,
  }) {
    return _then(
      _value.copyWith(
            room:
                null == room
                    ? _value.room
                    : room // ignore: cast_nullable_to_non_nullable
                        as Room,
            playedWords:
                null == playedWords
                    ? _value.playedWords
                    : playedWords // ignore: cast_nullable_to_non_nullable
                        as List<PlayedWord>,
            usedWords:
                null == usedWords
                    ? _value.usedWords
                    : usedWords // ignore: cast_nullable_to_non_nullable
                        as Map<String, bool>,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $RoomCopyWith<$Res> get room {
    return $RoomCopyWith<$Res>(_value.room, (value) {
      return _then(_value.copyWith(room: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
    _$GameStateImpl value,
    $Res Function(_$GameStateImpl) then,
  ) = __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Room room,
    List<PlayedWord> playedWords,
    Map<String, bool> usedWords,
  });

  @override
  $RoomCopyWith<$Res> get room;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
    _$GameStateImpl _value,
    $Res Function(_$GameStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? room = null,
    Object? playedWords = null,
    Object? usedWords = null,
  }) {
    return _then(
      _$GameStateImpl(
        room:
            null == room
                ? _value.room
                : room // ignore: cast_nullable_to_non_nullable
                    as Room,
        playedWords:
            null == playedWords
                ? _value._playedWords
                : playedWords // ignore: cast_nullable_to_non_nullable
                    as List<PlayedWord>,
        usedWords:
            null == usedWords
                ? _value._usedWords
                : usedWords // ignore: cast_nullable_to_non_nullable
                    as Map<String, bool>,
      ),
    );
  }
}

/// @nodoc

class _$GameStateImpl extends _GameState {
  const _$GameStateImpl({
    required this.room,
    final List<PlayedWord> playedWords = const <PlayedWord>[],
    final Map<String, bool> usedWords = const <String, bool>{},
  }) : _playedWords = playedWords,
       _usedWords = usedWords,
       super._();

  @override
  final Room room;
  final List<PlayedWord> _playedWords;
  @override
  @JsonKey()
  List<PlayedWord> get playedWords {
    if (_playedWords is EqualUnmodifiableListView) return _playedWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playedWords);
  }

  final Map<String, bool> _usedWords;
  @override
  @JsonKey()
  Map<String, bool> get usedWords {
    if (_usedWords is EqualUnmodifiableMapView) return _usedWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_usedWords);
  }

  @override
  String toString() {
    return 'GameState(room: $room, playedWords: $playedWords, usedWords: $usedWords)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.room, room) || other.room == room) &&
            const DeepCollectionEquality().equals(
              other._playedWords,
              _playedWords,
            ) &&
            const DeepCollectionEquality().equals(
              other._usedWords,
              _usedWords,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    room,
    const DeepCollectionEquality().hash(_playedWords),
    const DeepCollectionEquality().hash(_usedWords),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);
}

abstract class _GameState extends GameState {
  const factory _GameState({
    required final Room room,
    final List<PlayedWord> playedWords,
    final Map<String, bool> usedWords,
  }) = _$GameStateImpl;
  const _GameState._() : super._();

  @override
  Room get room;
  @override
  List<PlayedWord> get playedWords;
  @override
  Map<String, bool> get usedWords;
  @override
  @JsonKey(ignore: true)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
