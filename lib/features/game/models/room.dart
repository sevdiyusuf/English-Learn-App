import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converters.dart';

part 'room.freezed.dart';
part 'room.g.dart';

enum RoomStatus { waiting, active, finished }

/// Word Battle game mode: Theme (pack-based) or Core (dictionary part-of-speech).
enum GameMode { theme, core }

/// Theme Battle settings (temasal kelimeler).
class ThemeGameSettings {
  const ThemeGameSettings({
    required this.difficulty,
    required this.packId,
    required this.packTitle,
  });
  final String difficulty; // easy | medium | hard
  final String packId;
  final String packTitle;

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'packId': packId,
    'packTitle': packTitle,
  };

  static ThemeGameSettings? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final d = json['difficulty'] as String?;
    final id = json['packId'] as String?;
    final title = json['packTitle'] as String?;
    if (d == null || id == null || title == null) return null;
    return ThemeGameSettings(difficulty: d, packId: id, packTitle: title);
  }
}

/// Core English settings (saf İngilizce - part of speech).
class CoreGameSettings {
  const CoreGameSettings({required this.posType});
  final String posType; // verb | adjective | noun | adverb

  Map<String, dynamic> toJson() => {'posType': posType};

  static CoreGameSettings? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final t = json['posType'] as String?;
    if (t == null) return null;
    return CoreGameSettings(posType: t);
  }
}

/// Game setup: either theme or core (one is set when game is locked).
class GameRoomSettings {
  const GameRoomSettings({this.theme, this.core})
    : assert(theme == null || core == null);
  final ThemeGameSettings? theme;
  final CoreGameSettings? core;

  Map<String, dynamic> toJson() => {
    if (theme != null) 'theme': theme!.toJson(),
    if (core != null) 'core': core!.toJson(),
  };

  static GameRoomSettings? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final t = ThemeGameSettings.fromJson(
      json['theme'] is Map ? json['theme'] as Map<String, dynamic>? : null,
    );
    final c = CoreGameSettings.fromJson(
      json['core'] is Map ? json['core'] as Map<String, dynamic>? : null,
    );
    if (t == null && c == null) return null;
    return GameRoomSettings(theme: t, core: c);
  }
}

class RoomStatusConverter extends JsonConverter<RoomStatus, String> {
  const RoomStatusConverter();

  @override
  RoomStatus fromJson(String json) {
    return RoomStatus.values.firstWhere(
      (element) => element.name == json,
      orElse: () => RoomStatus.waiting,
    );
  }

  @override
  String toJson(RoomStatus object) => object.name;
}

class GameModeConverter extends JsonConverter<GameMode, String> {
  const GameModeConverter();

  @override
  GameMode fromJson(String json) {
    final lower = json.toLowerCase();
    return GameMode.values.firstWhere(
      (e) => e.name == lower,
      orElse: () => GameMode.core,
    );
  }

  @override
  String toJson(GameMode object) => object.name.toUpperCase();
}

class GameRoomSettingsConverter
    extends JsonConverter<GameRoomSettings?, Map<String, dynamic>?> {
  const GameRoomSettingsConverter();

  @override
  GameRoomSettings? fromJson(Map<String, dynamic>? json) =>
      GameRoomSettings.fromJson(json);

  @override
  Map<String, dynamic>? toJson(GameRoomSettings? object) => object?.toJson();
}

@freezed
class Room with _$Room {
  const Room._();

  const factory Room({
    @JsonKey(includeFromJson: false, includeToJson: false) String? id,
    String? roomCode,
    @RoomStatusConverter() @Default(RoomStatus.waiting) RoomStatus status,
    @Default(<String>[]) List<String> players,
    @Default(<String, String>{}) Map<String, String> playerNames,
    @Default(<String>[]) List<String> activePlayerIds,
    @Default(0) int currentTurnIndex,
    String? currentTurnUid,
    @TimestampConverter() DateTime? turnDeadlineAt,
    @Default(12) int turnDurationSeconds,
    String?
    currentWordType, // 'verb' or 'adjective' - tracks which word type we're waiting for
    String? currentVerb, // stored verb when waiting for adjective
    String? winnerUid,
    required String hostUid,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? updatedAt,
    // Word Battle game mode (Phase 1)
    @GameModeConverter() @Default(GameMode.core) GameMode gameMode,
    @Default(false) bool locked,
    @GameRoomSettingsConverter() GameRoomSettings? settings,
    @Default(<String, int>{}) Map<String, int> scores,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Room ${doc.id} not found');
    }
    // Convert Firestore Timestamps to proper format before JSON parsing
    final convertedData = Map<String, dynamic>.from(data);

    // Convert Timestamps to DateTime, then to ISO string for generated code
    // createdAt is required, so if it's null or not a Timestamp, use current time as fallback
    if (convertedData['createdAt'] is Timestamp) {
      final dateTime = const TimestampConverter().fromJson(
        convertedData['createdAt'],
      );
      if (dateTime != null) {
        convertedData['createdAt'] = dateTime.toIso8601String();
      } else {
        // Fallback if conversion fails
        convertedData['createdAt'] = DateTime.now().toIso8601String();
      }
    } else if (convertedData['createdAt'] == null) {
      // ServerTimestamp not yet resolved, use current time
      convertedData['createdAt'] = DateTime.now().toIso8601String();
    } else if (convertedData['createdAt'] is! String) {
      // If it's already a DateTime or something else, try to convert
      try {
        final dateTime = const TimestampConverter().fromJson(
          convertedData['createdAt'],
        );
        convertedData['createdAt'] =
            dateTime?.toIso8601String() ?? DateTime.now().toIso8601String();
      } catch (_) {
        convertedData['createdAt'] = DateTime.now().toIso8601String();
      }
    }

    // For nullable fields, converter handles it directly
    if (convertedData['updatedAt'] is Timestamp) {
      convertedData['updatedAt'] = const TimestampConverter().fromJson(
        convertedData['updatedAt'],
      );
    }
    if (convertedData['turnDeadlineAt'] is Timestamp) {
      convertedData['turnDeadlineAt'] = const TimestampConverter().fromJson(
        convertedData['turnDeadlineAt'],
      );
    }

    try {
      return Room.fromJson(convertedData).copyWith(id: doc.id);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error creating Room from Firestore data: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('Converted data: $convertedData');
      }
      rethrow;
    }
  }
}
