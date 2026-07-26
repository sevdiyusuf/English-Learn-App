import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/utils/operation_id.dart';
import '../../game/models/room.dart';

class RoomRepository {
  RoomRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  /// Creates a room via server callable function and returns the document ID
  Future<String> createRoom({
    required String hostUid,
    required String hostUsername,
    required int turnDurationSeconds,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('createRoom');
      final result = await callable.call<Map<String, dynamic>>({
        'turnDurationSeconds': turnDurationSeconds,
        'username': hostUsername,
        'operationId': opId,
      });

      final roomId = result.data['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) {
        throw StateError('Oda oluşturulamadı.');
      }
      return roomId;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error creating room via callable: $e\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Joins a room via server callable function
  Future<void> joinRoom({
    required String roomCode,
    required String uid,
    required String username,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('joinRoom');
      await callable.call<Map<String, dynamic>>({
        'roomCode': roomCode,
        'username': username,
        'operationId': opId,
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error joining room via callable: $e\n$stackTrace');
      }
      rethrow;
    }
  }

  Future<String?> getRoomIdByCode(
    String roomCode, {
    bool includeFinished = false,
  }) async {
    var query = _roomsRef.where('roomCode', isEqualTo: roomCode);

    if (!includeFinished) {
      query = query.where('status', isNotEqualTo: RoomStatus.finished.name);
    }

    final rooms = await query.limit(1).get();
    if (rooms.docs.isEmpty) {
      return null;
    }
    return rooms.docs.first.id;
  }

  /// Leaves a room via server callable function
  Future<void> leaveRoom({
    required String roomId,
    required String uid,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('leaveRoom');
      await callable.call<Map<String, dynamic>>({
        'roomId': roomId,
        'operationId': opId,
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error leaving room via callable: $e\n$stackTrace');
      }
      rethrow;
    }
  }

  Stream<Room?> watchRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      try {
        return Room.fromFirestore(snapshot);
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error parsing room ${snapshot.id}: $e');
          debugPrint('Stack trace: $stackTrace');
        }
        rethrow;
      }
    });
  }

  Stream<Room?> watchRoomByCode(String roomCode) {
    return _roomsRef
        .where('roomCode', isEqualTo: roomCode)
        .where('status', isNotEqualTo: RoomStatus.finished.name)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          try {
            return Room.fromFirestore(snapshot.docs.first);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              debugPrint('Error parsing room by code $roomCode: $e');
              debugPrint('Stack trace: $stackTrace');
            }
            rethrow;
          }
        });
  }

  /// Starts the game via server callable function
  Future<void> startGame({
    required String roomId,
    GameMode? gameMode,
    GameRoomSettings? settings,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    if (kDebugMode) {
      debugPrint('Starting game for roomId: $roomId gameMode: $gameMode');
    }
    try {
      final callable = _functions.httpsCallable('startGame');
      final payload = <String, dynamic>{'roomId': roomId, 'operationId': opId};
      if (gameMode != null) {
        payload['gameMode'] = gameMode.name.toUpperCase();
      }
      if (settings != null) {
        payload['settings'] = settings.toJson();
      }
      await callable.call(payload);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error starting game: $e\n$stackTrace');
      }
      rethrow;
    }
  }
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return RoomRepository(firestore, functions);
});
