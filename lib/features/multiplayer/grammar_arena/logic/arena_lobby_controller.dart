import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/core/utils/operation_id.dart';
import '../data/arena_room_repo.dart';
import '../data/worksheet_catalog_repo.dart';
import '../models/arena_models.dart';
import '../../../auth/logic/auth_controller.dart';
import '../../../training/models/training_models.dart';

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

  Future<void> createRoom({
    required String level,
    String? worksheetId,
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
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
      final roomId = await _roomRepo.createRoom(
        host: host,
        config: config,
        operationId: opId,
      );
      state = AsyncValue.data(roomId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> joinRoom(String roomCode, {String? operationId}) async {
    final opId = operationId ?? generateOperationId();
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

      final roomId = await _roomRepo.joinRoom(
        roomCode: roomCode,
        guest: guest,
        operationId: opId,
      );
      state = AsyncValue.data(roomId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRoomConfig(
    String roomId,
    ArenaConfig config, {
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    try {
      await _roomRepo.updateConfig(roomId, config, operationId: opId);
    } catch (e) {
      debugPrint('Error updating config: $e');
    }
  }

  Future<void> startGame(
    String roomId,
    ArenaConfig config, {
    String? operationId,
  }) async {
    final opId = operationId ?? generateOperationId();
    state = const AsyncValue.loading();
    try {
      await _roomRepo.updateConfig(roomId, config, operationId: '${opId}_cfg');

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

      final itemDetails =
          selected
              .map(
                (i) => {
                  'id': i.id,
                  'engine': i.engine.name,
                  'question': i.prompt,
                  'answer': i.answer,
                },
              )
              .toList();

      final resolvedMap = resolved.toJson();
      resolvedMap['items'] = itemDetails;

      final round = ArenaRound(
        index: 0,
        roundStartAt: DateTime.now().add(const Duration(seconds: 1)),
        timeLimitMs: 45000,
      );

      final callableResolved = ResolvedWorksheet.fromJson(resolvedMap);

      await _roomRepo.startMatch(
        roomId,
        round,
        callableResolved,
        operationId: opId,
      );
      state = AsyncValue.data(roomId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
