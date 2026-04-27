// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomImpl _$$RoomImplFromJson(Map<String, dynamic> json) => _$RoomImpl(
      roomCode: json['roomCode'] as String?,
      status: json['status'] == null
          ? RoomStatus.waiting
          : const RoomStatusConverter().fromJson(json['status'] as String),
      players: (json['players'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      playerNames: (json['playerNames'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      activePlayerIds: (json['activePlayerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      currentTurnIndex: (json['currentTurnIndex'] as num?)?.toInt() ?? 0,
      currentTurnUid: json['currentTurnUid'] as String?,
      turnDeadlineAt:
          const TimestampConverter().fromJson(json['turnDeadlineAt']),
      turnDurationSeconds: (json['turnDurationSeconds'] as num?)?.toInt() ?? 12,
      currentWordType: json['currentWordType'] as String?,
      currentVerb: json['currentVerb'] as String?,
      winnerUid: json['winnerUid'] as String?,
      hostUid: json['hostUid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      gameMode: json['gameMode'] == null
          ? GameMode.core
          : const GameModeConverter().fromJson(json['gameMode'] as String),
      locked: json['locked'] as bool? ?? false,
      settings: const GameRoomSettingsConverter()
          .fromJson(json['settings'] as Map<String, dynamic>?),
      scores: (json['scores'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
    );

Map<String, dynamic> _$$RoomImplToJson(_$RoomImpl instance) =>
    <String, dynamic>{
      'roomCode': instance.roomCode,
      'status': const RoomStatusConverter().toJson(instance.status),
      'players': instance.players,
      'playerNames': instance.playerNames,
      'activePlayerIds': instance.activePlayerIds,
      'currentTurnIndex': instance.currentTurnIndex,
      'currentTurnUid': instance.currentTurnUid,
      'turnDeadlineAt':
          const TimestampConverter().toJson(instance.turnDeadlineAt),
      'turnDurationSeconds': instance.turnDurationSeconds,
      'currentWordType': instance.currentWordType,
      'currentVerb': instance.currentVerb,
      'winnerUid': instance.winnerUid,
      'hostUid': instance.hostUid,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'gameMode': const GameModeConverter().toJson(instance.gameMode),
      'locked': instance.locked,
      'settings': const GameRoomSettingsConverter().toJson(instance.settings),
      'scores': instance.scores,
    };
