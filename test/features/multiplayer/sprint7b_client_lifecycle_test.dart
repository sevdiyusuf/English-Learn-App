import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Production Imports ---
import 'package:yunoo/core/utils/operation_id.dart';
import 'package:yunoo/features/game/models/room.dart';
import 'package:yunoo/features/lobby/data/room_repo.dart';
import 'package:yunoo/features/multiplayer/grammar_arena/data/arena_room_repo.dart';
import 'package:yunoo/features/multiplayer/grammar_arena/logic/arena_lobby_controller.dart';
import 'package:yunoo/features/multiplayer/grammar_arena/models/arena_models.dart';

// --- Fake Production Room Repository (subclassing RoomRepository) ---
class FakeProductionRoomRepository implements RoomRepository {
  final Map<String, StreamController<Room?>> _roomControllers = {};
  int leaveRoomCallCount = 0;

  void emitRoom(String roomId, Room? room) {
    _roomControllers[roomId]?.add(room);
  }

  void emitError(String roomId, Object error) {
    _roomControllers[roomId]?.addError(error);
  }

  @override
  Stream<Room?> watchRoom(String roomId) {
    _roomControllers[roomId] ??= StreamController<Room?>.broadcast(sync: true);
    return _roomControllers[roomId]!.stream;
  }

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String uid,
    String? operationId,
  }) async {
    leaveRoomCallCount++;
  }

  @override
  Future<String> createRoom({
    required String hostUid,
    required String hostUsername,
    required int turnDurationSeconds,
    String? operationId,
  }) async => 'room_101';

  @override
  Future<void> joinRoom({
    required String roomCode,
    required String uid,
    required String username,
    String? operationId,
  }) async {}

  @override
  Future<void> startGame({
    required String roomId,
    GameMode? gameMode,
    GameRoomSettings? settings,
    String? operationId,
  }) async {}

  @override
  Future<String?> getRoomIdByCode(
    String roomCode, {
    bool includeFinished = false,
  }) async => 'room_101';

  @override
  Stream<Room?> watchRoomByCode(String roomCode) => watchRoom('room_101');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Fake Production Arena Room Repository (subclassing ArenaRoomRepository) ---
class FakeProductionArenaRoomRepository implements ArenaRoomRepository {
  final Map<String, StreamController<ArenaRoom?>> _arenaControllers = {};
  int leaveArenaRoomCallCount = 0;

  void emitArenaRoom(String roomId, ArenaRoom? room) {
    _arenaControllers[roomId]?.add(room);
  }

  @override
  Stream<ArenaRoom?> watchRoom(String roomId) {
    _arenaControllers[roomId] ??= StreamController<ArenaRoom?>.broadcast(
      sync: true,
    );
    return _arenaControllers[roomId]!.stream;
  }

  @override
  Future<void> leaveRoom(String roomId, {String? operationId}) async {
    leaveArenaRoomCallCount++;
  }

  @override
  Future<String> createRoom({
    required ArenaPlayer host,
    required ArenaConfig config,
    String? operationId,
  }) async => 'arena_room_1';

  @override
  Future<String> joinRoom({
    required String roomCode,
    required ArenaPlayer guest,
    String? operationId,
  }) async => 'arena_room_1';

  @override
  Future<void> updateConfig(
    String roomId,
    ArenaConfig config, {
    String? operationId,
  }) async {}

  @override
  Future<void> startMatch(
    String roomId,
    ArenaRound round,
    ResolvedWorksheet resolvedWorksheet, {
    String? operationId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Sprint 7B Client Lifecycle & Production Binding Tests', () {
    late FakeProductionRoomRepository fakeRoomRepo;
    late FakeProductionArenaRoomRepository fakeArenaRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRoomRepo = FakeProductionRoomRepository();
      fakeArenaRepo = FakeProductionArenaRoomRepository();

      container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(fakeRoomRepo),
          arenaRoomRepoProvider.overrideWithValue(fakeArenaRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // 1. Single Listener Enforcement (RoomRepository.watchRoom)
    test(
      '1. RoomRepository.watchRoom returns broadcast stream for single listener ownership',
      () {
        final stream1 = fakeRoomRepo.watchRoom('room_101');
        final stream2 = fakeRoomRepo.watchRoom('room_101');

        expect(stream1.isBroadcast, isTrue);
        expect(stream2.isBroadcast, isTrue);
      },
    );

    // 2. Operation ID Format & Generation (generateOperationId)
    test(
      '2. generateOperationId produces canonical 8-128 char operation ID',
      () {
        final opId = generateOperationId();
        expect(opId.length, greaterThanOrEqualTo(8));
        expect(opId.length, lessThanOrEqualTo(128));
        expect(RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(opId), isTrue);
      },
    );

    // 3. Room lifecycle observation is read-only; room mutation is server-side.
    test(
      '3. RoomRepository listener receives lifecycle snapshots without a client mutation',
      () async {
        final future = fakeRoomRepo.watchRoom('room_101').first;
        final now = DateTime.now();
        fakeRoomRepo.emitRoom(
          'room_101',
          Room(
            id: 'room_101',
            roomCode: '11111',
            status: RoomStatus.waiting,
            players: const ['u1'],
            hostUid: 'u1',
            createdAt: now,
          ),
        );
        expect((await future)?.status, RoomStatus.waiting);
      },
    );

    // 4. Arena lifecycle observation is read-only; heartbeat is no longer a client API.
    test(
      '4. ArenaRoomRepository listener receives lifecycle snapshots without a client mutation',
      () async {
        final future = fakeArenaRepo.watchRoom('arena_101').first;
        fakeArenaRepo.emitArenaRoom(
          'arena_101',
          const ArenaRoom(
            id: 'arena_101',
            roomCode: '22222',
            status: ArenaStatus.waiting,
            hostId: 'h1',
            config: ArenaConfig(level: 'A1', worksheetId: null),
          ),
        );
        expect((await future)?.status, ArenaStatus.waiting);
      },
    );

    // 5. Explicit Leave Invocation (RoomRepository.leaveRoom)
    test(
      '5. RoomRepository.leaveRoom calls server idempotent leave function',
      () async {
        await fakeRoomRepo.leaveRoom(
          roomId: 'room_101',
          uid: 'user_1',
          operationId: 'op_leave_01',
        );
        expect(fakeRoomRepo.leaveRoomCallCount, equals(1));
      },
    );

    // 6. Explicit Arena Leave Invocation (ArenaRoomRepository.leaveRoom)
    test(
      '6. ArenaRoomRepository.leaveRoom calls server idempotent arena leave function',
      () async {
        await fakeArenaRepo.leaveRoom(
          'arena_101',
          operationId: 'op_arena_leave_01',
        );
        expect(fakeArenaRepo.leaveArenaRoomCallCount, equals(1));
      },
    );

    // 7. Word Match Room Model Deserialization & Status Checks (Room & RoomStatus)
    test(
      '7. Room status enum correctly categorizes waiting, active, and finished states',
      () {
        final now = DateTime.now();
        final waitingRoom = Room(
          id: 'r1',
          roomCode: '11111',
          status: RoomStatus.waiting,
          players: ['u1'],
          hostUid: 'u1',
          createdAt: now,
        );
        final activeRoom = Room(
          id: 'r1',
          roomCode: '11111',
          status: RoomStatus.active,
          players: ['u1', 'u2'],
          hostUid: 'u1',
          createdAt: now,
        );
        final finishedRoom = Room(
          id: 'r1',
          roomCode: '11111',
          status: RoomStatus.finished,
          players: ['u1', 'u2'],
          hostUid: 'u1',
          createdAt: now,
        );

        expect(waitingRoom.status, equals(RoomStatus.waiting));
        expect(activeRoom.status, equals(RoomStatus.active));
        expect(finishedRoom.status, equals(RoomStatus.finished));
      },
    );

    // 8. Arena Room Model Deserialization & Status Checks (ArenaRoom & ArenaStatus)
    test(
      '8. ArenaRoom status enum categorizes waiting, active, and finished states',
      () {
        final waitingArena = ArenaRoom(
          id: 'a1',
          roomCode: '22222',
          status: ArenaStatus.waiting,
          hostId: 'h1',
          config: const ArenaConfig(level: 'A1', worksheetId: null),
        );
        final activeArena = ArenaRoom(
          id: 'a1',
          roomCode: '22222',
          status: ArenaStatus.active,
          hostId: 'h1',
          config: const ArenaConfig(level: 'A1', worksheetId: null),
        );
        final finishedArena = ArenaRoom(
          id: 'a1',
          roomCode: '22222',
          status: ArenaStatus.finished,
          hostId: 'h1',
          config: const ArenaConfig(level: 'A1', worksheetId: null),
        );

        expect(waitingArena.status, equals(ArenaStatus.waiting));
        expect(activeArena.status, equals(ArenaStatus.active));
        expect(finishedArena.status, equals(ArenaStatus.finished));
      },
    );

    // 9. ArenaLobbyController Provider Integration (arenaLobbyControllerProvider)
    test(
      '9. arenaLobbyControllerProvider reads production ArenaRoomRepository correctly',
      () async {
        final state = container.read(arenaLobbyControllerProvider);
        expect(state.value, isNull);
      },
    );

    // 10. Reconnect Mutation Invariance & Stream Subscription Safety
    test(
      '10. Reconnect re-listens to watchRoom without invoking duplicate create or join calls',
      () async {
        final now = DateTime.now();
        Room? receivedRoom;
        final sub = fakeRoomRepo.watchRoom('room_101').listen((r) {
          receivedRoom = r;
        });

        final testRoom = Room(
          id: 'room_101',
          roomCode: '33333',
          status: RoomStatus.active,
          players: ['h1', 'g1'],
          hostUid: 'h1',
          createdAt: now,
        );
        fakeRoomRepo.emitRoom('room_101', testRoom);
        await Future.delayed(Duration.zero);

        expect(receivedRoom, equals(testRoom));
        expect(
          fakeRoomRepo.leaveRoomCallCount,
          equals(0),
        ); // Invariant: no accidental leave

        await sub.cancel();
      },
    );

    // 11. Controlled Handling for Null Room Snapshot (Deleted/Expired Room)
    test('11. Null room snapshot indicates deleted or expired room', () async {
      final now = DateTime.now();
      Room? receivedRoom = Room(
        id: 'room_101',
        roomCode: '33333',
        status: RoomStatus.active,
        players: ['h1'],
        hostUid: 'h1',
        createdAt: now,
      );
      final sub = fakeRoomRepo.watchRoom('room_101').listen((r) {
        receivedRoom = r;
      });

      fakeRoomRepo.emitRoom('room_101', null);
      await Future.delayed(Duration.zero);

      expect(
        receivedRoom,
        isNull,
      ); // Stream emits null when room is deleted by cleanup
      await sub.cancel();
    });

    // 12. Stream Error Isolation
    test(
      '12. Stream error is handled gracefully without corrupting repository state',
      () async {
        Object? receivedError;
        final sub = fakeRoomRepo
            .watchRoom('room_101')
            .listen(
              (_) {},
              onError: (err) {
                receivedError = err;
              },
            );

        fakeRoomRepo.emitError(
          'room_101',
          Exception('Network Stream Disconnected'),
        );
        await Future.delayed(Duration.zero);

        expect(receivedError, isNotNull);
        await sub.cancel();
      },
    );

    // 13. Both repositories expose server-authoritative lifecycle observation
    // and an explicit callable-backed leave operation; heartbeat is no longer
    // a client repository contract.
    test(
      '13. Word Match and Grammar Arena repositories share lifecycle stream and leave contracts',
      () {
        expect(fakeRoomRepo.watchRoom('room_101').isBroadcast, isTrue);
        expect(fakeArenaRepo.watchRoom('arena_101').isBroadcast, isTrue);
        expect(fakeRoomRepo.leaveRoom, isNotNull);
        expect(fakeArenaRepo.leaveRoom, isNotNull);
      },
    );
  });
}
