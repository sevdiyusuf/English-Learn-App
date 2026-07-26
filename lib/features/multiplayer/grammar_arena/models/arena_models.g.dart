// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arena_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArenaConfigImpl _$$ArenaConfigImplFromJson(Map<String, dynamic> json) =>
    _$ArenaConfigImpl(
      level: json['level'] as String,
      worksheetId: json['worksheetId'] as String?,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 12,
    );

Map<String, dynamic> _$$ArenaConfigImplToJson(_$ArenaConfigImpl instance) =>
    <String, dynamic>{
      'level': instance.level,
      'worksheetId': instance.worksheetId,
      'questionCount': instance.questionCount,
    };

_$ArenaPlayerImpl _$$ArenaPlayerImplFromJson(Map<String, dynamic> json) =>
    _$ArenaPlayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      lastPing: const TimestampConverter().fromJson(json['lastPing']),
    );

Map<String, dynamic> _$$ArenaPlayerImplToJson(_$ArenaPlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'photoUrl': instance.photoUrl,
      'score': instance.score,
      'isOnline': instance.isOnline,
      'lastPing': const TimestampConverter().toJson(instance.lastPing),
    };

_$ArenaRoundImpl _$$ArenaRoundImplFromJson(Map<String, dynamic> json) =>
    _$ArenaRoundImpl(
      index: (json['index'] as num).toInt(),
      roundStartAt: DateTime.parse(json['roundStartAt'] as String),
      timeLimitMs: (json['timeLimitMs'] as num).toInt(),
    );

Map<String, dynamic> _$$ArenaRoundImplToJson(_$ArenaRoundImpl instance) =>
    <String, dynamic>{
      'index': instance.index,
      'roundStartAt': instance.roundStartAt.toIso8601String(),
      'timeLimitMs': instance.timeLimitMs,
    };

_$ArenaAnswerImpl _$$ArenaAnswerImplFromJson(Map<String, dynamic> json) =>
    _$ArenaAnswerImpl(
      attempt: (json['attempt'] as num).toInt(),
      isCorrect: json['isCorrect'] as bool,
      pointsAwarded: (json['pointsAwarded'] as num).toInt(),
      clientSentAt: (json['clientSentAt'] as num).toInt(),
    );

Map<String, dynamic> _$$ArenaAnswerImplToJson(_$ArenaAnswerImpl instance) =>
    <String, dynamic>{
      'attempt': instance.attempt,
      'isCorrect': instance.isCorrect,
      'pointsAwarded': instance.pointsAwarded,
      'clientSentAt': instance.clientSentAt,
    };

_$ResolvedWorksheetImpl _$$ResolvedWorksheetImplFromJson(
  Map<String, dynamic> json,
) => _$ResolvedWorksheetImpl(
  worksheetId: json['worksheetId'] as String,
  seed: (json['seed'] as num).toInt(),
  questionIds:
      (json['questionIds'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$$ResolvedWorksheetImplToJson(
  _$ResolvedWorksheetImpl instance,
) => <String, dynamic>{
  'worksheetId': instance.worksheetId,
  'seed': instance.seed,
  'questionIds': instance.questionIds,
};

_$ArenaRoomImpl _$$ArenaRoomImplFromJson(Map<String, dynamic> json) =>
    _$ArenaRoomImpl(
      id: json['id'] as String,
      roomCode: json['roomCode'] as String,
      status: $enumDecode(_$ArenaStatusEnumMap, json['status']),
      hostId: json['hostId'] as String,
      guestId: json['guestId'] as String?,
      config: ArenaConfig.fromJson(json['config'] as Map<String, dynamic>),
      resolvedWorksheet:
          json['resolvedWorksheet'] == null
              ? null
              : ResolvedWorksheet.fromJson(
                json['resolvedWorksheet'] as Map<String, dynamic>,
              ),
      round:
          json['round'] == null
              ? null
              : ArenaRound.fromJson(json['round'] as Map<String, dynamic>),
      hostScore: (json['hostScore'] as num?)?.toInt() ?? 0,
      guestScore: (json['guestScore'] as num?)?.toInt() ?? 0,
      host:
          json['host'] == null
              ? null
              : ArenaPlayer.fromJson(json['host'] as Map<String, dynamic>),
      guest:
          json['guest'] == null
              ? null
              : ArenaPlayer.fromJson(json['guest'] as Map<String, dynamic>),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$$ArenaRoomImplToJson(_$ArenaRoomImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomCode': instance.roomCode,
      'status': _$ArenaStatusEnumMap[instance.status]!,
      'hostId': instance.hostId,
      'guestId': instance.guestId,
      'config': instance.config.toJson(),
      'resolvedWorksheet': instance.resolvedWorksheet?.toJson(),
      'round': instance.round?.toJson(),
      'hostScore': instance.hostScore,
      'guestScore': instance.guestScore,
      'host': instance.host?.toJson(),
      'guest': instance.guest?.toJson(),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$ArenaStatusEnumMap = {
  ArenaStatus.waiting: 'waiting',
  ArenaStatus.active: 'active',
  ArenaStatus.finished: 'finished',
};
