// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameInvitationImpl _$$GameInvitationImplFromJson(Map<String, dynamic> json) =>
    _$GameInvitationImpl(
      id: json['id'] as String,
      fromUid: json['fromUid'] as String,
      fromName: json['fromName'] as String,
      toUid: json['toUid'] as String,
      roomId: json['roomId'] as String,
      gameType: json['gameType'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$GameInvitationImplToJson(
        _$GameInvitationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUid': instance.fromUid,
      'fromName': instance.fromName,
      'toUid': instance.toUid,
      'roomId': instance.roomId,
      'gameType': instance.gameType,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
