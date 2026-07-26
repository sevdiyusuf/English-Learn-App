import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/app/di.dart';
import 'package:yunoo/core/utils/operation_id.dart';
import '../models/arena_models.dart';

final arenaRoomRepoProvider = Provider(
  (ref) => ArenaRoomRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  ),
);

class ArenaRoomRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ArenaRoomRepository(this._firestore, this._functions);

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('arena_rooms');

  Future<String> createRoom({
    required ArenaPlayer host,
    required ArenaConfig config,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('createArenaRoom');
      final res = await callable.call<Map<String, dynamic>>({
        'level': config.level,
        'worksheetId': config.worksheetId,
        'questionCount': config.questionCount,
        'player': host.toJson(),
        'operationId': opId,
      });

      final roomId = res.data['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) {
        throw StateError('Arena odası oluşturulamadı');
      }
      return roomId;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error creating arena room: $e\n$st');
      }
      rethrow;
    }
  }

  Future<String> joinRoom({
    required String roomCode,
    required ArenaPlayer guest,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('joinArenaRoom');
      final res = await callable.call<Map<String, dynamic>>({
        'roomCode': roomCode,
        'player': guest.toJson(),
        'operationId': opId,
      });

      final roomId = res.data['roomId'] as String?;
      if (roomId == null || roomId.isEmpty) {
        throw StateError('Arena odasına katılınamadı');
      }
      return roomId;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error joining arena room: $e\n$st');
      }
      rethrow;
    }
  }

  Stream<ArenaRoom?> watchRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      try {
        return ArenaRoom.fromJson(snapshot.data()!);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Error parsing ArenaRoom snapshot: $e\n$st');
        }
        return null;
      }
    });
  }

  Future<void> leaveRoom(String roomId, {String? operationId}) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('leaveArenaRoom');
      await callable.call({'roomId': roomId, 'operationId': opId});
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error leaving arena room: $e\n$st');
      }
      rethrow;
    }
  }

  Future<void> startMatch(
    String roomId,
    ArenaRound round,
    ResolvedWorksheet resolvedWorksheet, {
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('startArenaMatch');
      await callable.call({
        'roomId': roomId,
        'resolvedWorksheet': resolvedWorksheet.toJson(),
        'operationId': opId,
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error starting arena match: $e\n$st');
      }
      rethrow;
    }
  }

  Future<void> updateConfig(
    String roomId,
    ArenaConfig config, {
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      final callable = _functions.httpsCallable('updateArenaConfig');
      await callable.call({
        'roomId': roomId,
        'config': config.toJson(),
        'operationId': opId,
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error updating arena config: $e\n$st');
      }
      rethrow;
    }
  }
}
