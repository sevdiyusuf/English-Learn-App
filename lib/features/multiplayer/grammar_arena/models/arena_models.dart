import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converters.dart';

part 'arena_models.freezed.dart';
part 'arena_models.g.dart';

@freezed
class ArenaConfig with _$ArenaConfig {
  @JsonSerializable(explicitToJson: true)
  const factory ArenaConfig({
    required String level,
    required String? worksheetId,
    @Default(12) int questionCount,
  }) = _ArenaConfig;

  factory ArenaConfig.fromJson(Map<String, dynamic> json) =>
      _$ArenaConfigFromJson(json);
}

@freezed
class ArenaPlayer with _$ArenaPlayer {
  @JsonSerializable(explicitToJson: true)
  const factory ArenaPlayer({
    required String id,
    required String name,
    String? photoUrl,
    @Default(0) int score,
    @Default(false) bool isOnline,
    @TimestampConverter() DateTime? lastPing,
  }) = _ArenaPlayer;

  factory ArenaPlayer.fromJson(Map<String, dynamic> json) =>
      _$ArenaPlayerFromJson(json);
}

extension ArenaPlayerCallableExtension on ArenaPlayer {
  /// Converts [ArenaPlayer] into a narrow JSON/callable-safe payload.
  ///
  /// Excludes server-authoritative fields (`id`/`uid`, `score`, `isOnline`, `lastPing`)
  /// and non-JSON-encodable types (`Timestamp`).
  Map<String, dynamic> toCallablePayload() {
    return <String, dynamic>{'name': name, 'photoUrl': photoUrl};
  }
}

@freezed
class ArenaRound with _$ArenaRound {
  @JsonSerializable(explicitToJson: true)
  const factory ArenaRound({
    required int index,
    @TimestampConverter() required DateTime roundStartAt,
    required int timeLimitMs,
  }) = _ArenaRound;

  factory ArenaRound.fromJson(Map<String, dynamic> json) =>
      _$ArenaRoundFromJson(json);
}

@freezed
class ArenaAnswer with _$ArenaAnswer {
  @JsonSerializable(explicitToJson: true)
  const factory ArenaAnswer({
    required int attempt,
    required bool isCorrect,
    required int pointsAwarded,
    required int clientSentAt,
  }) = _ArenaAnswer;

  factory ArenaAnswer.fromJson(Map<String, dynamic> json) =>
      _$ArenaAnswerFromJson(json);
}

@freezed
class ResolvedWorksheet with _$ResolvedWorksheet {
  @JsonSerializable(explicitToJson: true)
  const factory ResolvedWorksheet({
    required String worksheetId,
    required int seed,
    required List<String> questionIds,
  }) = _ResolvedWorksheet;

  factory ResolvedWorksheet.fromJson(Map<String, dynamic> json) =>
      _$ResolvedWorksheetFromJson(json);
}

enum ArenaStatus { waiting, active, finished }

@freezed
class ArenaRoom with _$ArenaRoom {
  @JsonSerializable(explicitToJson: true)
  const factory ArenaRoom({
    required String id,
    required String roomCode,
    required ArenaStatus status,
    required String hostId,
    String? guestId,
    required ArenaConfig config,
    ResolvedWorksheet? resolvedWorksheet,
    ArenaRound? round,
    @Default(0) int hostScore,
    @Default(0) int guestScore,
    ArenaPlayer? host,
    ArenaPlayer? guest,
    @TimestampConverter() DateTime? createdAt,
  }) = _ArenaRoom;

  factory ArenaRoom.fromJson(Map<String, dynamic> json) =>
      _$ArenaRoomFromJson(json);
}
