import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/auth_controller.dart';
import '../../game/models/room.dart';
import '../data/room_repo.dart';

class RoomController extends StateNotifier<AsyncValue<void>> {
  RoomController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  RoomRepository get _repo => _ref.read(roomRepositoryProvider);

  Future<String> createRoom({
    required String username,
    required int turnDurationSeconds,
  }) async {
    state = const AsyncLoading();
    try {
      final user =
          await _ref
              .read(authControllerProvider.notifier)
              .ensureAnonymousGuestSignedIn();
      final roomCode = await _repo.createRoom(
        hostUid: user.uid,
        hostUsername: username.trim(),
        turnDurationSeconds: turnDurationSeconds,
      );
      state = const AsyncValue.data(null);
      return roomCode;
    } on Object catch (err, stack) {
      state = AsyncError(err, stack);
      rethrow;
    }
  }

  Future<void> joinRoom({
    required String roomCode,
    required String username,
  }) async {
    state = const AsyncLoading();
    try {
      final user =
          await _ref
              .read(authControllerProvider.notifier)
              .ensureAnonymousGuestSignedIn();
      await _repo.joinRoom(
        roomCode: roomCode.trim(),
        uid: user.uid,
        username: username.trim(),
      );
      state = const AsyncValue.data(null);
    } on Object catch (err, stack) {
      state = AsyncError(err, stack);
      rethrow;
    }
  }

  Future<void> leaveRoom({required String roomId}) async {
    state = const AsyncLoading();
    try {
      final authState = _ref.read(authControllerProvider);
      final user = authState.value;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      // Check if roomId is a roomCode (5 digits) or document ID
      final isRoomCode = RegExp(r'^\d{5}$').hasMatch(roomId);
      String actualRoomId;
      if (isRoomCode) {
        // Get document ID from roomCode
        final docId = await _repo.getRoomIdByCode(roomId);
        if (docId == null) {
          throw StateError('Oda bulunamadı');
        }
        actualRoomId = docId;
      } else {
        actualRoomId = roomId;
      }
      await _repo.leaveRoom(roomId: actualRoomId, uid: user.uid);
      state = const AsyncValue.data(null);
    } on Object catch (err, stack) {
      state = AsyncError(err, stack);
      rethrow;
    }
  }

  /// [gameMode] and [settings] must be set by host in lobby before starting (Theme Battle or Core English).
  Future<void> startGame({
    required String roomId,
    GameMode? gameMode,
    GameRoomSettings? settings,
  }) async {
    state = const AsyncLoading();
    try {
      if (roomId.isEmpty) {
        throw StateError('Oda ID boş olamaz');
      }

      final isRoomCode = RegExp(r'^\d{5}$').hasMatch(roomId);
      String actualRoomId;

      if (isRoomCode) {
        final docId = await _repo.getRoomIdByCode(roomId);
        if (docId == null) {
          throw StateError('Oda bulunamadı. Oda kodu: $roomId');
        }
        actualRoomId = docId;
      } else {
        actualRoomId = roomId;
      }

      await _repo.startGame(
        roomId: actualRoomId,
        gameMode: gameMode,
        settings: settings,
      );
      state = const AsyncValue.data(null);
    } on Object catch (err, stack) {
      state = AsyncError(err, stack);
      rethrow;
    }
  }
}

final roomControllerProvider =
    StateNotifierProvider<RoomController, AsyncValue<void>>((ref) {
      return RoomController(ref);
    });

final roomStreamProvider = StreamProvider.autoDispose.family<Room?, String>((
  ref,
  roomCode,
) {
  final repo = ref.watch(roomRepositoryProvider);
  // Try to find room by code first
  return repo.watchRoomByCode(roomCode);
});

// Stream provider that works with roomId (document ID) - works for finished rooms too
final roomStreamByIdProvider = StreamProvider.autoDispose.family<Room?, String>(
  (ref, roomId) {
    final repo = ref.watch(roomRepositoryProvider);
    // Watch room directly by ID (works for finished rooms too)
    return repo.watchRoom(roomId);
  },
);
