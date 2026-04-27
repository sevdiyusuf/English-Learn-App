import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/arena_room_repo.dart';
import '../data/worksheet_catalog_repo.dart';
import '../models/arena_models.dart';
import '../../../auth/logic/auth_controller.dart';
import '../../../training/models/training_models.dart';

final arenaRoomRepoProvider = Provider(
  (ref) => ArenaRoomRepository(FirebaseFirestore.instance),
);

final arenaLobbyControllerProvider =
    StateNotifierProvider<ArenaLobbyController, AsyncValue<String?>>((ref) {
      return ArenaLobbyController(
        ref.watch(arenaRoomRepoProvider),
        ref.watch(worksheetCatalogRepoProvider),
        ref,
      );
    });

class ArenaLobbyController extends StateNotifier<AsyncValue<String?>> {
  final ArenaRoomRepository _roomRepo;
  final WorksheetCatalogRepo _catalogRepo;
  final Ref _ref;

  ArenaLobbyController(this._roomRepo, this._catalogRepo, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> createRoom({required String level, String? worksheetId}) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final host = ArenaPlayer(
        id: user.uid,
        name: user.displayName ?? 'Player',
        photoUrl: user.photoUrl,
        isOnline: true,
        lastPing: DateTime.now(),
      );

      final config = ArenaConfig(level: level, worksheetId: worksheetId);
      final roomId = await _roomRepo.createRoom(host: host, config: config);
      state = AsyncValue.data(roomId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> joinRoom(String roomCode) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final guest = ArenaPlayer(
        id: user.uid,
        name: user.displayName ?? 'Player',
        photoUrl: user.photoUrl,
        isOnline: true,
        lastPing: DateTime.now(),
      );

      final roomId = await _roomRepo.joinRoom(roomCode: roomCode, guest: guest);
      state = AsyncValue.data(roomId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRoomConfig(String roomId, ArenaConfig config) async {
    try {
      await _roomRepo.updateConfig(roomId, config);
    } catch (e) {
      // Handle error quietly or log
      print('Error updating config: $e');
    }
  }

  Future<void> startGame(String roomId, ArenaConfig config) async {
    state = const AsyncValue.loading();
    try {
      // First update config to ensure everyone is on the same page
      await _roomRepo.updateConfig(roomId, config);

      WorksheetMetadata? metadata;
      if (config.worksheetId != null) {
        final catalog = await _catalogRepo.getCatalog();
        final list = catalog[config.level];
        metadata = list?.firstWhere(
          (m) => m.worksheetId == config.worksheetId,
          orElse: () => throw Exception('Worksheet not found'),
        );
      } else {
        metadata = await _catalogRepo.getRandomWorksheetForLevel(config.level);
      }

      if (metadata == null) throw Exception('Worksheet not found');

      final worksheet = await _catalogRepo.loadWorksheet(metadata.path);

      final items = worksheet.items;
      final seed = DateTime.now().millisecondsSinceEpoch;
      final random = Random(seed);
      final shuffled = List.of(items)..shuffle(random);
      final count = min(config.questionCount, shuffled.length);
      final selected = shuffled.take(count).toList();
      final questionIds = selected.map((i) => i.id).toList();

      final resolved = ResolvedWorksheet(
        worksheetId: metadata.worksheetId,
        seed: seed,
        questionIds: questionIds,
      );

      final round = ArenaRound(
        index: 0,
        roundStartAt: DateTime.now().add(
          const Duration(seconds: 1),
        ), // 1s delay for countdown
        timeLimitMs: 45000, // 45s per round default
      );

      await _roomRepo.startMatch(roomId, round, resolved);
      state = AsyncValue.data(roomId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
