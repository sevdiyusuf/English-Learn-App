import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/core/utils/operation_id.dart';
import '../data/arena_room_repo.dart';
import '../data/arena_match_repo.dart';
import '../data/worksheet_catalog_repo.dart';
import '../models/arena_models.dart';
import '../../../training/models/training_models.dart';
import '../../../auth/logic/auth_controller.dart';

class ArenaSessionState {
  final ArenaRoom? room;
  final Worksheet? worksheet;
  final Map<String, ArenaAnswer> answers;
  final bool isSubmitting;

  ArenaSessionState({
    this.room,
    this.worksheet,
    this.answers = const {},
    this.isSubmitting = false,
  });

  ArenaSessionState copyWith({
    ArenaRoom? room,
    Worksheet? worksheet,
    Map<String, ArenaAnswer>? answers,
    bool? isSubmitting,
  }) {
    return ArenaSessionState(
      room: room ?? this.room,
      worksheet: worksheet ?? this.worksheet,
      answers: answers ?? this.answers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final arenaSessionControllerProvider = StateNotifierProvider.family<
  ArenaSessionController,
  AsyncValue<ArenaSessionState>,
  String
>((ref, roomId) {
  return ArenaSessionController(
    ref,
    roomId,
    ref.watch(arenaRoomRepoProvider),
    ref.watch(arenaMatchRepoProvider),
    ref.watch(worksheetCatalogRepoProvider),
  );
});

class ArenaSessionController
    extends StateNotifier<AsyncValue<ArenaSessionState>> {
  final Ref _ref;
  final String _roomId;
  final ArenaRoomRepository _roomRepo;
  final ArenaMatchRepository _matchRepo;
  final WorksheetCatalogRepo _catalogRepo;

  StreamSubscription? _roomSub;
  StreamSubscription? _answersSub;
  Timer? _hostTimer;

  ArenaSessionController(
    this._ref,
    this._roomId,
    this._roomRepo,
    this._matchRepo,
    this._catalogRepo,
  ) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _roomSub = _roomRepo
        .watchRoom(_roomId)
        .listen(
          (room) async {
            if (room == null) {
              state = AsyncValue.error('Room not found', StackTrace.current);
              return;
            }

            final currentState = state.value ?? ArenaSessionState();
            Worksheet? worksheet = currentState.worksheet;

            if (worksheet == null && room.resolvedWorksheet != null) {
              try {
                final catalog = await _catalogRepo.getCatalog();
                final list = catalog[room.config.level];
                final metadata = list?.firstWhere(
                  (m) => m.worksheetId == room.resolvedWorksheet!.worksheetId,
                );
                if (metadata != null) {
                  worksheet = await _catalogRepo.loadWorksheet(metadata.path);
                }
              } catch (e) {
                debugPrint('Error loading worksheet: $e');
              }
            }

            state = AsyncValue.data(
              currentState.copyWith(room: room, worksheet: worksheet),
            );

            if (room.round != null) {
              _updateAnswerSubscription(room.round!.index);
              _scheduleTimeoutCheck(room);
            }
          },
          onError: (e, st) {
            state = AsyncValue.error(e, st);
          },
        );
  }

  void _updateAnswerSubscription(int roundIndex) {
    _answersSub?.cancel();
    _answersSub = _matchRepo.watchRoundAnswers(_roomId, roundIndex).listen((
      answers,
    ) {
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(answers: answers));
      }
    });
  }

  void _scheduleTimeoutCheck(ArenaRoom room) {
    if (room.status != ArenaStatus.active || room.round == null) return;
    _hostTimer?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch;
    final end =
        room.round!.roundStartAt.millisecondsSinceEpoch +
        room.round!.timeLimitMs;
    final remaining = end - now;

    if (remaining > 0) {
      _hostTimer = Timer(Duration(milliseconds: remaining + 500), () {
        _checkTimeout(room.round!.index);
      });
    } else {
      _checkTimeout(room.round!.index);
    }
  }

  Future<void> _checkTimeout(int roundIndex) async {
    final s = state.value;
    if (s == null || s.room == null || s.room!.status != ArenaStatus.active) {
      return;
    }
    final user = _ref.read(authControllerProvider).value;
    if (user != null && user.uid == s.room!.hostId) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'resolveArenaTimeout',
        );
        await callable.call({
          'roomId': _roomId,
          'roundIndex': roundIndex,
          'operationId': generateOperationId(),
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error calling resolveArenaTimeout: $e');
        }
      }
    }
  }

  Future<bool> submitAnswer(
    dynamic answerValue,
    int attempt, {
    String? operationId,
  }) async {
    final s = state.value;
    if (s == null ||
        s.room == null ||
        s.worksheet == null ||
        s.room!.round == null) {
      return false;
    }

    final room = s.room!;
    final round = room.round!;
    final user = _ref.read(authControllerProvider).value;
    if (user == null) return false;

    final opId = operationId ?? generateOperationId();

    try {
      state = AsyncValue.data(s.copyWith(isSubmitting: true));
      await _matchRepo.submitAnswer(
        roomId: _roomId,
        playerId: user.uid,
        roundIndex: round.index,
        answerValue: answerValue,
        attempt: attempt,
        operationId: opId,
      );
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return true;
    } catch (e, st) {
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      if (kDebugMode) {
        debugPrint('Error in submitAnswer: $e\n$st');
      }
      return false;
    }
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _answersSub?.cancel();
    _hostTimer?.cancel();
    super.dispose();
  }
}
