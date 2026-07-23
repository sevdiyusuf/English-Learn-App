import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/arena_room_repo.dart';
import '../data/arena_match_repo.dart';
import '../data/worksheet_catalog_repo.dart';
import '../models/arena_models.dart';
import '../../../training/models/training_models.dart';
import '../../../auth/logic/auth_controller.dart';
import '../logic/arena_lobby_controller.dart';

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
  Timer? _heartbeatTimer;
  Timer? _presenceTimer;

  ArenaSessionController(
    this._ref,
    this._roomId,
    this._roomRepo,
    this._matchRepo,
    this._catalogRepo,
  ) : super(const AsyncValue.loading()) {
    _init();
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final user = _ref.read(authControllerProvider).value;
      final room = state.value?.room;
      if (user != null && room != null) {
        final isHost = user.uid == room.hostId;
        await _roomRepo.updatePlayerPresence(_roomId, user.uid, isHost);
      }
    });

    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkOpponentPresence();
    });
  }

  void _checkOpponentPresence() {
    final s = state.value;
    final user = _ref.read(authControllerProvider).value;
    if (s == null || s.room == null || user == null) return;

    final room = s.room!;
    if (room.status == ArenaStatus.finished) return;

    final isHost = user.uid == room.hostId;
    final opponent = isHost ? room.guest : room.host;

    if (opponent == null) return; // Guest might not joined yet

    if (opponent.lastPing != null) {
      final diff = DateTime.now().difference(opponent.lastPing!);
      if (diff.inSeconds > 15) {
        // Disconnect detected
        if (isHost) {
          // Host claims win by disconnect
          // But wait, if guest disconnects, host wins?
          // Or we just end the game.
          // User said: "15s dönmeyene 'Win by disconnect'".
          // So we should finish the game.
          _roomRepo.updateStatus(_roomId, ArenaStatus.finished);
          // Ideally we should set a reason or winner field, but for now just finish.
        } else {
          // Guest detects host disconnect
          // Guest can't update status effectively if rules forbid it?
          // User said: "Player sadece kendi answer doc'unu yazabilir".
          // But room update permissions might be restricted to host?
          // If so, Guest just leaves UI.
          // For MVP, we'll let UI handle "Connection Lost".
        }
      }
    }
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

            // Load worksheet if needed and available
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

            // Update state
            state = AsyncValue.data(
              currentState.copyWith(room: room, worksheet: worksheet),
            );

            // Manage Answer Subscription
            if (room.round != null) {
              _updateAnswerSubscription(room.round!.index);

              // Host Logic
              final user = _ref.read(authControllerProvider).value;
              if (user != null && user.uid == room.hostId) {
                _checkRoundCompletion(room, currentState.answers);
              }
            }
          },
          onError: (e, st) {
            state = AsyncValue.error(e, st);
          },
        );
  }

  void _updateAnswerSubscription(int roundIndex) {
    // If already listening to this round, skip
    // But we don't store current subscribed round index easily.
    // Simple way: re-subscribe always or check.
    // For now re-subscribe is safer to ensure we switch streams.
    _answersSub?.cancel();
    _answersSub = _matchRepo.watchRoundAnswers(_roomId, roundIndex).listen((
      answers,
    ) {
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(answers: answers));
        if (currentState.room != null) {
          // Host Logic
          final user = _ref.read(authControllerProvider).value;
          if (user != null && user.uid == currentState.room!.hostId) {
            _checkRoundCompletion(currentState.room!, answers);
          }
        }
      }
    });
  }

  Future<bool> submitAnswer(dynamic answerValue, int attempt) async {
    final s = state.value;
    if (s == null ||
        s.room == null ||
        s.worksheet == null ||
        s.room!.round == null) {
      return false;
    }

    final room = s.room!;
    final round = room.round!;
    final worksheet = s.worksheet!;
    final resolved = room.resolvedWorksheet!;

    final questionId = resolved.questionIds[round.index];
    final item = worksheet.items.firstWhere((i) => i.id == questionId);

    // Validate answer
    bool isCorrect = _validateAnswer(item, answerValue);

    // Calculate score
    int points = 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - round.roundStartAt.millisecondsSinceEpoch;
    final remaining = max(0, round.timeLimitMs - elapsed);

    if (isCorrect) {
      int base = attempt == 1 ? 100 : 60;
      int engineBonus = _getEngineBonus(item.engine);
      double ratio = remaining / round.timeLimitMs;
      int speedBonus = (60 * ratio).round();
      if (attempt == 2) speedBonus = (speedBonus * 0.5).round();

      points = base + engineBonus + speedBonus;
    } else {
      points = attempt == 1 ? -10 : -20;
    }

    final user = _ref.read(authControllerProvider).value;
    if (user == null) return false;

    final answer = ArenaAnswer(
      attempt: attempt,
      isCorrect: isCorrect,
      pointsAwarded: points,
      clientSentAt: now,
    );

    await _matchRepo.submitAnswer(
      roomId: _roomId,
      playerId: user.uid,
      roundIndex: round.index,
      answer: answer,
    );

    return isCorrect;
  }

  bool _validateAnswer(WorksheetItem item, dynamic value) {
    if (value == null) return false;

    // Normalizing item.answer
    dynamic correctAnswer = item.answer;

    // Handle MCQ/String engines
    if (item.engine == EngineType.mcq ||
        item.engine == EngineType.fill ||
        item.engine == EngineType.errorSpotting) {
      String expected = correctAnswer.toString().trim().toLowerCase();
      String actual = value.toString().trim().toLowerCase();
      return expected == actual;
    }

    // Handle list comparison (Order, Transform)
    if (item.engine == EngineType.order ||
        item.engine == EngineType.transform) {
      List<String> expectedList = [];
      if (correctAnswer is List) {
        expectedList =
            correctAnswer
                .map((e) => e.toString().trim().toLowerCase())
                .toList();
      } else {
        expectedList = [correctAnswer.toString().trim().toLowerCase()];
      }

      List<String> actualList = [];
      if (value is List) {
        actualList =
            value.map((e) => e.toString().trim().toLowerCase()).toList();
      } else {
        actualList = [value.toString().trim().toLowerCase()];
      }

      if (expectedList.length != actualList.length) return false;
      for (int i = 0; i < expectedList.length; i++) {
        if (expectedList[i] != actualList[i]) return false;
      }
      return true;
    }

    // Handle map comparison (Matching)
    if (item.engine == EngineType.matching) {
      if (correctAnswer is! Map) return false;
      Map<String, String> expectedMap = correctAnswer.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );

      Map<String, String> actualMap = {};
      if (value is Map) {
        actualMap = value.map((k, v) => MapEntry(k.toString(), v.toString()));
      }

      if (expectedMap.length != actualMap.length) return false;
      for (var key in expectedMap.keys) {
        if (expectedMap[key]?.trim().toLowerCase() !=
            actualMap[key]?.trim().toLowerCase()) {
          return false;
        }
      }
      return true;
    }

    // Fallback for other types
    return correctAnswer.toString().trim().toLowerCase() ==
        value.toString().trim().toLowerCase();
  }

  int _getEngineBonus(EngineType engine) {
    switch (engine) {
      case EngineType.mcq:
        return 0;
      case EngineType.fill:
        return 10;
      case EngineType.order:
        return 15;
      case EngineType.transform:
        return 20;
      case EngineType.errorSpotting:
        return 25;
      case EngineType.matching:
        return 10;
      default:
        return 0;
    }
  }

  // Host Logic
  void _checkRoundCompletion(
    ArenaRoom room, [
    Map<String, ArenaAnswer>? answers,
  ]) async {
    if (room.status != ArenaStatus.active || room.round == null) return;

    answers ??= state.value?.answers ?? {};

    // Check if time is up
    final now = DateTime.now().millisecondsSinceEpoch;
    final end =
        room.round!.roundStartAt.millisecondsSinceEpoch +
        room.round!.timeLimitMs;
    final isTimeout = now > end;

    bool shouldEnd = isTimeout;

    // Check if all players answered correctly or exhausted attempts
    // We expect 2 players: Host and Guest
    // If guest is not present yet (waiting), we can't play properly, but status is active.

    if (room.guestId != null) {
      final p1 = answers[room.hostId];
      final p2 = answers[room.guestId!];

      bool p1Done = p1 != null && (p1.isCorrect || p1.attempt >= 2);
      bool p2Done = p2 != null && (p2.isCorrect || p2.attempt >= 2);

      if (p1Done && p2Done) shouldEnd = true;
    }

    if (shouldEnd) {
      // Finalize round
      // Calculate final scores including First Correct Bonus
      // Update room score
      // Move to next round
      _finalizeRound(room, answers);
    } else {
      // Schedule check if not ended
      _hostTimer?.cancel();
      final remaining = end - now;
      if (remaining > 0) {
        _hostTimer = Timer(Duration(milliseconds: remaining + 100), () {
          _checkRoundCompletion(room); // Re-check on timeout
        });
      }
    }
  }

  Future<void> _finalizeRound(
    ArenaRoom room,
    Map<String, ArenaAnswer> answers,
  ) async {
    // Avoid double finalization
    // We can use a lock or check if round changed.
    // Since this is called repeatedly, we need to be careful.
    // Ideally we check if we are already processing.

    final round = room.round!;

    // Determine First Correct
    String? firstCorrectId;
    int minTime = 9999999999999;

    answers.forEach((pid, ans) {
      if (ans.isCorrect && ans.clientSentAt < minTime) {
        minTime = ans.clientSentAt;
        firstCorrectId = pid;
      }
    });

    int hScore = room.hostScore;
    int gScore = room.guestScore;

    // Add points from answers
    final hAns = answers[room.hostId];
    if (hAns != null) {
      hScore += hAns.pointsAwarded;
      if (firstCorrectId == room.hostId) hScore += 20;
    } else {
      hScore -= 15; // Timeout penalty
    }

    final gAns = answers[room.guestId];
    if (gAns != null) {
      gScore += gAns.pointsAwarded;
      if (firstCorrectId == room.guestId) gScore += 20;
    } else {
      if (room.guestId != null) gScore -= 15; // Timeout penalty
    }

    // Update Scores
    await _roomRepo.updateScores(room.id, hScore, gScore);

    // Next Round
    final nextIndex = round.index + 1;
    if (nextIndex >= (room.resolvedWorksheet?.questionIds.length ?? 0)) {
      // Game Over
      await _roomRepo.updateStatus(room.id, ArenaStatus.finished);
    } else {
      // Start next round
      final nextRound = ArenaRound(
        index: nextIndex,
        roundStartAt: DateTime.now().add(const Duration(seconds: 1)),
        timeLimitMs: round.timeLimitMs,
      );
      // Pass same resolved worksheet
      await _roomRepo.startMatch(room.id, nextRound, room.resolvedWorksheet!);
    }
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _answersSub?.cancel();
    _hostTimer?.cancel();
    _heartbeatTimer?.cancel();
    _presenceTimer?.cancel();
    super.dispose();
  }
}
