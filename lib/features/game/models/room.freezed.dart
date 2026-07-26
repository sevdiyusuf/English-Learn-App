// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Room _$RoomFromJson(Map<String, dynamic> json) {
  return _Room.fromJson(json);
}

/// @nodoc
mixin _$Room {
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get id => throw _privateConstructorUsedError;
  String? get roomCode => throw _privateConstructorUsedError;
  @RoomStatusConverter()
  RoomStatus get status => throw _privateConstructorUsedError;
  List<String> get players => throw _privateConstructorUsedError;
  Map<String, String> get playerNames => throw _privateConstructorUsedError;
  List<String> get activePlayerIds => throw _privateConstructorUsedError;
  int get currentTurnIndex => throw _privateConstructorUsedError;
  String? get currentTurnUid => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get turnDeadlineAt => throw _privateConstructorUsedError;
  int get turnDurationSeconds => throw _privateConstructorUsedError;
  String? get currentWordType =>
      throw _privateConstructorUsedError; // 'verb' or 'adjective' - tracks which word type we're waiting for
  String? get currentVerb =>
      throw _privateConstructorUsedError; // stored verb when waiting for adjective
  String? get winnerUid => throw _privateConstructorUsedError;
  String get hostUid => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError; // Word Battle game mode (Phase 1)
  @GameModeConverter()
  GameMode get gameMode => throw _privateConstructorUsedError;
  bool get locked => throw _privateConstructorUsedError;
  @GameRoomSettingsConverter()
  GameRoomSettings? get settings => throw _privateConstructorUsedError;
  Map<String, int> get scores => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoomCopyWith<Room> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomCopyWith<$Res> {
  factory $RoomCopyWith(Room value, $Res Function(Room) then) =
      _$RoomCopyWithImpl<$Res, Room>;
  @useResult
  $Res call({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    String? roomCode,
    @RoomStatusConverter() RoomStatus status,
    List<String> players,
    Map<String, String> playerNames,
    List<String> activePlayerIds,
    int currentTurnIndex,
    String? currentTurnUid,
    @TimestampConverter() DateTime? turnDeadlineAt,
    int turnDurationSeconds,
    String? currentWordType,
    String? currentVerb,
    String? winnerUid,
    String hostUid,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime? updatedAt,
    @GameModeConverter() GameMode gameMode,
    bool locked,
    @GameRoomSettingsConverter() GameRoomSettings? settings,
    Map<String, int> scores,
  });
}

/// @nodoc
class _$RoomCopyWithImpl<$Res, $Val extends Room>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? roomCode = freezed,
    Object? status = null,
    Object? players = null,
    Object? playerNames = null,
    Object? activePlayerIds = null,
    Object? currentTurnIndex = null,
    Object? currentTurnUid = freezed,
    Object? turnDeadlineAt = freezed,
    Object? turnDurationSeconds = null,
    Object? currentWordType = freezed,
    Object? currentVerb = freezed,
    Object? winnerUid = freezed,
    Object? hostUid = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? gameMode = null,
    Object? locked = null,
    Object? settings = freezed,
    Object? scores = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String?,
            roomCode:
                freezed == roomCode
                    ? _value.roomCode
                    : roomCode // ignore: cast_nullable_to_non_nullable
                        as String?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as RoomStatus,
            players:
                null == players
                    ? _value.players
                    : players // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            playerNames:
                null == playerNames
                    ? _value.playerNames
                    : playerNames // ignore: cast_nullable_to_non_nullable
                        as Map<String, String>,
            activePlayerIds:
                null == activePlayerIds
                    ? _value.activePlayerIds
                    : activePlayerIds // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            currentTurnIndex:
                null == currentTurnIndex
                    ? _value.currentTurnIndex
                    : currentTurnIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            currentTurnUid:
                freezed == currentTurnUid
                    ? _value.currentTurnUid
                    : currentTurnUid // ignore: cast_nullable_to_non_nullable
                        as String?,
            turnDeadlineAt:
                freezed == turnDeadlineAt
                    ? _value.turnDeadlineAt
                    : turnDeadlineAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            turnDurationSeconds:
                null == turnDurationSeconds
                    ? _value.turnDurationSeconds
                    : turnDurationSeconds // ignore: cast_nullable_to_non_nullable
                        as int,
            currentWordType:
                freezed == currentWordType
                    ? _value.currentWordType
                    : currentWordType // ignore: cast_nullable_to_non_nullable
                        as String?,
            currentVerb:
                freezed == currentVerb
                    ? _value.currentVerb
                    : currentVerb // ignore: cast_nullable_to_non_nullable
                        as String?,
            winnerUid:
                freezed == winnerUid
                    ? _value.winnerUid
                    : winnerUid // ignore: cast_nullable_to_non_nullable
                        as String?,
            hostUid:
                null == hostUid
                    ? _value.hostUid
                    : hostUid // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            gameMode:
                null == gameMode
                    ? _value.gameMode
                    : gameMode // ignore: cast_nullable_to_non_nullable
                        as GameMode,
            locked:
                null == locked
                    ? _value.locked
                    : locked // ignore: cast_nullable_to_non_nullable
                        as bool,
            settings:
                freezed == settings
                    ? _value.settings
                    : settings // ignore: cast_nullable_to_non_nullable
                        as GameRoomSettings?,
            scores:
                null == scores
                    ? _value.scores
                    : scores // ignore: cast_nullable_to_non_nullable
                        as Map<String, int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoomImplCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$$RoomImplCopyWith(
    _$RoomImpl value,
    $Res Function(_$RoomImpl) then,
  ) = __$$RoomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    String? roomCode,
    @RoomStatusConverter() RoomStatus status,
    List<String> players,
    Map<String, String> playerNames,
    List<String> activePlayerIds,
    int currentTurnIndex,
    String? currentTurnUid,
    @TimestampConverter() DateTime? turnDeadlineAt,
    int turnDurationSeconds,
    String? currentWordType,
    String? currentVerb,
    String? winnerUid,
    String hostUid,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime? updatedAt,
    @GameModeConverter() GameMode gameMode,
    bool locked,
    @GameRoomSettingsConverter() GameRoomSettings? settings,
    Map<String, int> scores,
  });
}

/// @nodoc
class __$$RoomImplCopyWithImpl<$Res>
    extends _$RoomCopyWithImpl<$Res, _$RoomImpl>
    implements _$$RoomImplCopyWith<$Res> {
  __$$RoomImplCopyWithImpl(_$RoomImpl _value, $Res Function(_$RoomImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? roomCode = freezed,
    Object? status = null,
    Object? players = null,
    Object? playerNames = null,
    Object? activePlayerIds = null,
    Object? currentTurnIndex = null,
    Object? currentTurnUid = freezed,
    Object? turnDeadlineAt = freezed,
    Object? turnDurationSeconds = null,
    Object? currentWordType = freezed,
    Object? currentVerb = freezed,
    Object? winnerUid = freezed,
    Object? hostUid = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? gameMode = null,
    Object? locked = null,
    Object? settings = freezed,
    Object? scores = null,
  }) {
    return _then(
      _$RoomImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String?,
        roomCode:
            freezed == roomCode
                ? _value.roomCode
                : roomCode // ignore: cast_nullable_to_non_nullable
                    as String?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as RoomStatus,
        players:
            null == players
                ? _value._players
                : players // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        playerNames:
            null == playerNames
                ? _value._playerNames
                : playerNames // ignore: cast_nullable_to_non_nullable
                    as Map<String, String>,
        activePlayerIds:
            null == activePlayerIds
                ? _value._activePlayerIds
                : activePlayerIds // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        currentTurnIndex:
            null == currentTurnIndex
                ? _value.currentTurnIndex
                : currentTurnIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        currentTurnUid:
            freezed == currentTurnUid
                ? _value.currentTurnUid
                : currentTurnUid // ignore: cast_nullable_to_non_nullable
                    as String?,
        turnDeadlineAt:
            freezed == turnDeadlineAt
                ? _value.turnDeadlineAt
                : turnDeadlineAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        turnDurationSeconds:
            null == turnDurationSeconds
                ? _value.turnDurationSeconds
                : turnDurationSeconds // ignore: cast_nullable_to_non_nullable
                    as int,
        currentWordType:
            freezed == currentWordType
                ? _value.currentWordType
                : currentWordType // ignore: cast_nullable_to_non_nullable
                    as String?,
        currentVerb:
            freezed == currentVerb
                ? _value.currentVerb
                : currentVerb // ignore: cast_nullable_to_non_nullable
                    as String?,
        winnerUid:
            freezed == winnerUid
                ? _value.winnerUid
                : winnerUid // ignore: cast_nullable_to_non_nullable
                    as String?,
        hostUid:
            null == hostUid
                ? _value.hostUid
                : hostUid // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        gameMode:
            null == gameMode
                ? _value.gameMode
                : gameMode // ignore: cast_nullable_to_non_nullable
                    as GameMode,
        locked:
            null == locked
                ? _value.locked
                : locked // ignore: cast_nullable_to_non_nullable
                    as bool,
        settings:
            freezed == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                    as GameRoomSettings?,
        scores:
            null == scores
                ? _value._scores
                : scores // ignore: cast_nullable_to_non_nullable
                    as Map<String, int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomImpl extends _Room with DiagnosticableTreeMixin {
  const _$RoomImpl({
    @JsonKey(includeFromJson: false, includeToJson: false) this.id,
    this.roomCode,
    @RoomStatusConverter() this.status = RoomStatus.waiting,
    final List<String> players = const <String>[],
    final Map<String, String> playerNames = const <String, String>{},
    final List<String> activePlayerIds = const <String>[],
    this.currentTurnIndex = 0,
    this.currentTurnUid,
    @TimestampConverter() this.turnDeadlineAt,
    this.turnDurationSeconds = 12,
    this.currentWordType,
    this.currentVerb,
    this.winnerUid,
    required this.hostUid,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() this.updatedAt,
    @GameModeConverter() this.gameMode = GameMode.core,
    this.locked = false,
    @GameRoomSettingsConverter() this.settings,
    final Map<String, int> scores = const <String, int>{},
  }) : _players = players,
       _playerNames = playerNames,
       _activePlayerIds = activePlayerIds,
       _scores = scores,
       super._();

  factory _$RoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomImplFromJson(json);

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  @override
  final String? roomCode;
  @override
  @JsonKey()
  @RoomStatusConverter()
  final RoomStatus status;
  final List<String> _players;
  @override
  @JsonKey()
  List<String> get players {
    if (_players is EqualUnmodifiableListView) return _players;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_players);
  }

  final Map<String, String> _playerNames;
  @override
  @JsonKey()
  Map<String, String> get playerNames {
    if (_playerNames is EqualUnmodifiableMapView) return _playerNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_playerNames);
  }

  final List<String> _activePlayerIds;
  @override
  @JsonKey()
  List<String> get activePlayerIds {
    if (_activePlayerIds is EqualUnmodifiableListView) return _activePlayerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activePlayerIds);
  }

  @override
  @JsonKey()
  final int currentTurnIndex;
  @override
  final String? currentTurnUid;
  @override
  @TimestampConverter()
  final DateTime? turnDeadlineAt;
  @override
  @JsonKey()
  final int turnDurationSeconds;
  @override
  final String? currentWordType;
  // 'verb' or 'adjective' - tracks which word type we're waiting for
  @override
  final String? currentVerb;
  // stored verb when waiting for adjective
  @override
  final String? winnerUid;
  @override
  final String hostUid;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime? updatedAt;
  // Word Battle game mode (Phase 1)
  @override
  @JsonKey()
  @GameModeConverter()
  final GameMode gameMode;
  @override
  @JsonKey()
  final bool locked;
  @override
  @GameRoomSettingsConverter()
  final GameRoomSettings? settings;
  final Map<String, int> _scores;
  @override
  @JsonKey()
  Map<String, int> get scores {
    if (_scores is EqualUnmodifiableMapView) return _scores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_scores);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Room(id: $id, roomCode: $roomCode, status: $status, players: $players, playerNames: $playerNames, activePlayerIds: $activePlayerIds, currentTurnIndex: $currentTurnIndex, currentTurnUid: $currentTurnUid, turnDeadlineAt: $turnDeadlineAt, turnDurationSeconds: $turnDurationSeconds, currentWordType: $currentWordType, currentVerb: $currentVerb, winnerUid: $winnerUid, hostUid: $hostUid, createdAt: $createdAt, updatedAt: $updatedAt, gameMode: $gameMode, locked: $locked, settings: $settings, scores: $scores)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Room'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('roomCode', roomCode))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('players', players))
      ..add(DiagnosticsProperty('playerNames', playerNames))
      ..add(DiagnosticsProperty('activePlayerIds', activePlayerIds))
      ..add(DiagnosticsProperty('currentTurnIndex', currentTurnIndex))
      ..add(DiagnosticsProperty('currentTurnUid', currentTurnUid))
      ..add(DiagnosticsProperty('turnDeadlineAt', turnDeadlineAt))
      ..add(DiagnosticsProperty('turnDurationSeconds', turnDurationSeconds))
      ..add(DiagnosticsProperty('currentWordType', currentWordType))
      ..add(DiagnosticsProperty('currentVerb', currentVerb))
      ..add(DiagnosticsProperty('winnerUid', winnerUid))
      ..add(DiagnosticsProperty('hostUid', hostUid))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('updatedAt', updatedAt))
      ..add(DiagnosticsProperty('gameMode', gameMode))
      ..add(DiagnosticsProperty('locked', locked))
      ..add(DiagnosticsProperty('settings', settings))
      ..add(DiagnosticsProperty('scores', scores));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.roomCode, roomCode) ||
                other.roomCode == roomCode) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._players, _players) &&
            const DeepCollectionEquality().equals(
              other._playerNames,
              _playerNames,
            ) &&
            const DeepCollectionEquality().equals(
              other._activePlayerIds,
              _activePlayerIds,
            ) &&
            (identical(other.currentTurnIndex, currentTurnIndex) ||
                other.currentTurnIndex == currentTurnIndex) &&
            (identical(other.currentTurnUid, currentTurnUid) ||
                other.currentTurnUid == currentTurnUid) &&
            (identical(other.turnDeadlineAt, turnDeadlineAt) ||
                other.turnDeadlineAt == turnDeadlineAt) &&
            (identical(other.turnDurationSeconds, turnDurationSeconds) ||
                other.turnDurationSeconds == turnDurationSeconds) &&
            (identical(other.currentWordType, currentWordType) ||
                other.currentWordType == currentWordType) &&
            (identical(other.currentVerb, currentVerb) ||
                other.currentVerb == currentVerb) &&
            (identical(other.winnerUid, winnerUid) ||
                other.winnerUid == winnerUid) &&
            (identical(other.hostUid, hostUid) || other.hostUid == hostUid) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.gameMode, gameMode) ||
                other.gameMode == gameMode) &&
            (identical(other.locked, locked) || other.locked == locked) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            const DeepCollectionEquality().equals(other._scores, _scores));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    roomCode,
    status,
    const DeepCollectionEquality().hash(_players),
    const DeepCollectionEquality().hash(_playerNames),
    const DeepCollectionEquality().hash(_activePlayerIds),
    currentTurnIndex,
    currentTurnUid,
    turnDeadlineAt,
    turnDurationSeconds,
    currentWordType,
    currentVerb,
    winnerUid,
    hostUid,
    createdAt,
    updatedAt,
    gameMode,
    locked,
    settings,
    const DeepCollectionEquality().hash(_scores),
  ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomImplCopyWith<_$RoomImpl> get copyWith =>
      __$$RoomImplCopyWithImpl<_$RoomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomImplToJson(this);
  }
}

abstract class _Room extends Room {
  const factory _Room({
    @JsonKey(includeFromJson: false, includeToJson: false) final String? id,
    final String? roomCode,
    @RoomStatusConverter() final RoomStatus status,
    final List<String> players,
    final Map<String, String> playerNames,
    final List<String> activePlayerIds,
    final int currentTurnIndex,
    final String? currentTurnUid,
    @TimestampConverter() final DateTime? turnDeadlineAt,
    final int turnDurationSeconds,
    final String? currentWordType,
    final String? currentVerb,
    final String? winnerUid,
    required final String hostUid,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() final DateTime? updatedAt,
    @GameModeConverter() final GameMode gameMode,
    final bool locked,
    @GameRoomSettingsConverter() final GameRoomSettings? settings,
    final Map<String, int> scores,
  }) = _$RoomImpl;
  const _Room._() : super._();

  factory _Room.fromJson(Map<String, dynamic> json) = _$RoomImpl.fromJson;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get id;
  @override
  String? get roomCode;
  @override
  @RoomStatusConverter()
  RoomStatus get status;
  @override
  List<String> get players;
  @override
  Map<String, String> get playerNames;
  @override
  List<String> get activePlayerIds;
  @override
  int get currentTurnIndex;
  @override
  String? get currentTurnUid;
  @override
  @TimestampConverter()
  DateTime? get turnDeadlineAt;
  @override
  int get turnDurationSeconds;
  @override
  String? get currentWordType;
  @override // 'verb' or 'adjective' - tracks which word type we're waiting for
  String? get currentVerb;
  @override // stored verb when waiting for adjective
  String? get winnerUid;
  @override
  String get hostUid;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime? get updatedAt;
  @override // Word Battle game mode (Phase 1)
  @GameModeConverter()
  GameMode get gameMode;
  @override
  bool get locked;
  @override
  @GameRoomSettingsConverter()
  GameRoomSettings? get settings;
  @override
  Map<String, int> get scores;
  @override
  @JsonKey(ignore: true)
  _$$RoomImplCopyWith<_$RoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
