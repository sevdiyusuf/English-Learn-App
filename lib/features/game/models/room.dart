import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converters.dart';

part 'room.freezed.dart';
part 'room.g.dart';

enum RoomStatus { waiting, active, finished }

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

@freezed
class Room with _$Room {
  const Room._();

  const factory Room({
    // ignore: invalid_annotation_target
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
    String? currentWordType, // 'verb' or 'adjective' - tracks which word type we're waiting for
    String? currentVerb, // stored verb when waiting for adjective
    String? winnerUid,
    required String hostUid,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? updatedAt,
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
      final dateTime = const TimestampConverter().fromJson(convertedData['createdAt']);
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
        final dateTime = const TimestampConverter().fromJson(convertedData['createdAt']);
        convertedData['createdAt'] = dateTime?.toIso8601String() ?? DateTime.now().toIso8601String();
      } catch (_) {
        convertedData['createdAt'] = DateTime.now().toIso8601String();
      }
    }
    
    // For nullable fields, converter handles it directly
    if (convertedData['updatedAt'] is Timestamp) {
      convertedData['updatedAt'] = const TimestampConverter().fromJson(convertedData['updatedAt']);
    }
    if (convertedData['turnDeadlineAt'] is Timestamp) {
      convertedData['turnDeadlineAt'] = const TimestampConverter().fromJson(convertedData['turnDeadlineAt']);
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
