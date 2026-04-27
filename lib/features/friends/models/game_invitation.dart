import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_invitation.freezed.dart';
part 'game_invitation.g.dart';

@freezed
class GameInvitation with _$GameInvitation {
  const factory GameInvitation({
    required String id,
    required String fromUid,
    required String fromName,
    required String toUid,
    required String roomId,
    required String gameType, // 'word_battle' | 'grammar_arena'
    @Default('pending') String status, // pending, accepted, rejected
    DateTime? createdAt,
  }) = _GameInvitation;

  factory GameInvitation.fromJson(Map<String, dynamic> json) =>
      _$GameInvitationFromJson(json);
}
