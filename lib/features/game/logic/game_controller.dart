import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/auth_controller.dart';
import '../data/game_repo.dart';
import '../models/game_state.dart';
import '../models/played_word.dart';
import '../models/room.dart';

class GameController extends AutoDisposeFamilyAsyncNotifier<GameState, String> {
  late final GameRepository _repo;
  late final String _roomId;

  StreamSubscription<Room?>? _roomSubscription;
  StreamSubscription<List<PlayedWord>>? _wordsSubscription;
  StreamSubscription<Map<String, bool>>? _usedSubscription;

  @override
  Future<GameState> build(String roomId) async {
    _repo = ref.watch(gameRepositoryProvider);
    _roomId = roomId;

    // Wait for room to be loaded
    Room? room = await _repo
        .watchRoom(roomId)
        .firstWhere((value) => value != null, orElse: () => null);
    if (room == null) {
      throw StateError('Oda bulunamadı');
    }

    // If room is not active, don't wait - let the game page handle redirect
    // This prevents timeout errors when "Yeniden başlat" is clicked
    // The room_lobby_page will wait for room to become active before navigating
    if (room.status != RoomStatus.active) {
      // Return the room as-is, game_page will redirect to lobby
      // This prevents the "Oyun yüklenemedi" error
    }

    final words = await _repo.watchPlayedWords(roomId).first;
    final used = await _repo.watchUsedWords(roomId).first;

    _roomSubscription = _repo.watchRoom(roomId).listen((updatedRoom) {
      if (updatedRoom == null) {
        // Room was deleted - set error state so UI can handle it
        final current = state.value;
        if (current != null) {
          state = AsyncValue.error(
            StateError('Oda bulunamadı veya silinmiş'),
            StackTrace.current,
          );
        }
        return;
      }
      final current = state.value;
      if (current == null) {
        return;
      }
      state = AsyncValue.data(current.copyWith(room: updatedRoom));
    });

    _wordsSubscription = _repo.watchPlayedWords(roomId).listen((played) {
      final current = state.value;
      if (current == null) {
        return;
      }
      state = AsyncValue.data(current.copyWith(playedWords: played));
    });

    _usedSubscription = _repo.watchUsedWords(roomId).listen((usedWords) {
      final current = state.value;
      if (current == null) {
        return;
      }
      state = AsyncValue.data(current.copyWith(usedWords: usedWords));
    });

    ref.onDispose(() {
      _roomSubscription?.cancel();
      _wordsSubscription?.cancel();
      _usedSubscription?.cancel();
    });

    // room is guaranteed to be non-null at this point
    return GameState(room: room, playedWords: words, usedWords: used);
  }

  Future<void> submitVerb({required String verb}) async {
    final normalizedVerb = verb.trim().toLowerCase();
    if (normalizedVerb.isEmpty) {
      throw ArgumentError('Fiil boş olamaz');
    }

    // Optimistic update - add word immediately to UI
    final current = state.value;
    if (current != null) {
      final userUid = ref.read(authControllerProvider).value?.uid;
      if (userUid != null) {
        final optimisticWord = PlayedWord(
          word: normalizedVerb,
          type: WordType.verb,
          byUid: userUid,
          at: DateTime.now(),
        );
        final updatedWords = [...current.playedWords, optimisticWord];
        state = AsyncValue.data(current.copyWith(playedWords: updatedWords));
      }
    }

    // Submit to backend - real data will replace optimistic update
    await _repo.submitVerb(
      roomId: _roomId,
      verb: normalizedVerb,
    );
  }

  Future<void> submitAdjective({required String adjective}) async {
    final normalizedAdjective = adjective.trim().toLowerCase();
    if (normalizedAdjective.isEmpty) {
      throw ArgumentError('Sıfat boş olamaz');
    }

    // Optimistic update - add word immediately to UI
    final current = state.value;
    if (current != null) {
      final userUid = ref.read(authControllerProvider).value?.uid;
      if (userUid != null) {
        final optimisticWord = PlayedWord(
          word: normalizedAdjective,
          type: WordType.adjective,
          byUid: userUid,
          at: DateTime.now(),
        );
        final updatedWords = [...current.playedWords, optimisticWord];
        state = AsyncValue.data(current.copyWith(playedWords: updatedWords));
      }
    }

    // Submit to backend - real data will replace optimistic update
    await _repo.submitAdjective(
      roomId: _roomId,
      adjective: normalizedAdjective,
    );
  }

  // Legacy method for backward compatibility
  Future<void> submitTurn({
    required String verb,
    required String adjective,
  }) async {
    // Use two-phase submission
    await submitVerb(verb: verb);
    await submitAdjective(adjective: adjective);
  }

  Future<void> resolveTimeout() async {
    await _repo.resolveTimeout(roomId: _roomId);
  }

  String? currentTurnUid() {
    return state.value?.room.currentTurnUid;
  }

  bool isCurrentUserTurn() {
    final uid = ref.read(authControllerProvider).value?.uid;
    return uid != null && uid == currentTurnUid();
  }
}

final gameControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<GameController, GameState, String>(
      GameController.new,
    );
