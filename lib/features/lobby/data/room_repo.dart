import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../game/models/room.dart';

class RoomRepository {
  RoomRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  /// Creates a room and returns the document ID (not roomCode)
  Future<String> createRoom({
    required String hostUid,
    required String hostUsername,
    required int turnDurationSeconds,
  }) async {
    // Generate a unique 5-digit room code
    String roomCode = '';
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;
    final random = DateTime.now().millisecondsSinceEpoch;
    
    while (!isUnique && attempts < maxAttempts) {
      // Generate random 5-digit number (10000-99999)
      final baseTime = random + attempts;
      final randomValue = baseTime % 90000;
      roomCode = (10000 + randomValue).toString();
      
      // Check if room code already exists
      final existing = await _roomsRef
          .where('roomCode', isEqualTo: roomCode)
          .where('status', isNotEqualTo: RoomStatus.finished.name)
          .limit(1)
          .get();
      
      if (existing.docs.isEmpty) {
        isUnique = true;
      } else {
        attempts++;
        // Small delay to avoid same timestamp
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    if (!isUnique || roomCode.isEmpty) {
      throw StateError('Benzersiz oda kodu oluşturulamadı. Lütfen tekrar deneyin.');
    }
    
    final doc = _roomsRef.doc();
    await doc.set({
      'roomCode': roomCode,
      'status': RoomStatus.waiting.name,
      'players': [hostUid],
      'playerNames': {hostUid: hostUsername},
      'activePlayerIds': [],
      'currentTurnIndex': 0,
      'currentTurnUid': null,
      'turnDeadlineAt': null,
      'turnDurationSeconds': turnDurationSeconds,
      'winnerUid': null,
      'hostUid': hostUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Return document ID instead of roomCode for navigation
    return doc.id;
  }

  Future<void> joinRoom({
    required String roomCode,
    required String uid,
    required String username,
  }) async {
    // Find room by roomCode
    final rooms = await _roomsRef
        .where('roomCode', isEqualTo: roomCode)
        .where('status', isNotEqualTo: RoomStatus.finished.name)
        .limit(1)
        .get();
    
    if (rooms.docs.isEmpty) {
      throw StateError('Oda bulunamadı. Oda kodunu kontrol edin.');
    }
    
    final roomDoc = rooms.docs.first;
    final roomData = roomDoc.data();
    
    // Check if player is already in room
    final players = List<String>.from(roomData['players'] ?? []);
    if (players.contains(uid)) {
      // Update username if already in room
      await roomDoc.reference.update({
        'playerNames.$uid': username,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    
    await roomDoc.reference.update({
      'players': FieldValue.arrayUnion([uid]),
      'playerNames.$uid': username,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  Future<String?> getRoomIdByCode(String roomCode, {bool includeFinished = false}) async {
    var query = _roomsRef.where('roomCode', isEqualTo: roomCode);
    
    // Only filter by status if we don't want finished rooms
    if (!includeFinished) {
      query = query.where('status', isNotEqualTo: RoomStatus.finished.name);
    }
    
    final rooms = await query.limit(1).get();
    
    if (rooms.docs.isEmpty) {
      return null;
    }
    
    return rooms.docs.first.id;
  }

  Future<void> leaveRoom({required String roomId, required String uid}) async {
    await _roomsRef.doc(roomId).update({
      'players': FieldValue.arrayRemove([uid]),
      'activePlayerIds': FieldValue.arrayRemove([uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
          debugPrint('Snapshot data: ${snapshot.data()}');
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

  Future<void> startGame({required String roomId}) async {
    if (kDebugMode) {
      debugPrint('Starting game for roomId: $roomId');
    }
    try {
      final callable = _functions.httpsCallable('startGame');
      final result = await callable.call({'roomId': roomId});
      if (kDebugMode) {
        debugPrint('Start game result: $result');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error starting game: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> updateTurnDeadline({
    required String roomId,
    required DateTime deadline,
    required String currentTurnUid,
  }) async {
    await _roomsRef.doc(roomId).update({
      'currentTurnUid': currentTurnUid,
      'turnDeadlineAt': Timestamp.fromDate(deadline.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return RoomRepository(firestore, functions);
});
