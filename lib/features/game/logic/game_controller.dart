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

  /// Submit single word for THEME or CORE mode.
  Future<void> submitWord({required String word}) async {
    final current = state.value;
    if (current == null) throw StateError('Oyun durumu mevcut değil');

    final userUid = ref.read(authControllerProvider).value?.uid;
    if (userUid == null) throw StateError('Kullanıcı oturumu açılmamış');

    // Extra check: Is it really this user's turn?
    if (current.room.currentTurnUid != userUid) {
      throw StateError('Sıra sizde değil!');
    }

    // Normalize: trim, lowercase, remove extra spaces
    final normalized = word.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalized.isEmpty) {
      throw ArgumentError('Kelime boş olamaz');
    }

    // Optimistic update
    final type = current.room.currentWordType ?? 'word';
    final wordType =
        type == 'verb'
            ? WordType.verb
            : type == 'adjective'
            ? WordType.adjective
            : type == 'noun'
            ? WordType.noun
            : type == 'adverb'
            ? WordType.adverb
            : WordType.word;
    final optimisticWord = PlayedWord(
      word: normalized,
      type: wordType,
      byUid: userUid,
      at: DateTime.now(),
    );
    
    // Create updated room state for optimistic UI (optional but good)
    // We don't change currentTurnUid here because that's server-side logic
    // but we can update playedWords
    final updatedWords = [...current.playedWords, optimisticWord];
    state = AsyncValue.data(current.copyWith(playedWords: updatedWords));

    await _repo.submitWord(roomId: _roomId, word: normalized);
  }

  Future<void> submitVerb({required String verb}) async {
    final current = state.value;
    if (current == null) throw StateError('Oyun durumu mevcut değil');

    final userUid = ref.read(authControllerProvider).value?.uid;
    if (userUid == null) throw StateError('Kullanıcı oturumu açılmamış');

    if (current.room.currentTurnUid != userUid) {
      throw StateError('Sıra sizde değil!');
    }

    final normalizedVerb = verb.trim().toLowerCase().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
    if (normalizedVerb.isEmpty) {
      throw ArgumentError('Fiil boş olamaz');
    }

    // Optimistic update
    final optimisticWord = PlayedWord(
      word: normalizedVerb,
      type: WordType.verb,
      byUid: userUid,
      at: DateTime.now(),
    );
    final updatedWords = [...current.playedWords, optimisticWord];
    state = AsyncValue.data(current.copyWith(playedWords: updatedWords));

    await _repo.submitVerb(roomId: _roomId, verb: normalizedVerb);
  }

  /// Handles word submission based on current game mode and state.
  /// Returns the type of submission ('verb', 'adjective', 'word') for UI feedback.
  Future<String> handleWordSubmission(String word) async {
    final current = state.value;
    if (current == null) throw StateError('Game state not available');

    final userUid = ref.read(authControllerProvider).value?.uid;
    if (userUid == null) throw StateError('Kullanıcı oturumu açılmamış');

    // CRITICAL: Double check turn before allowing submission
    if (current.room.currentTurnUid != userUid) {
      throw StateError('Sıra sizde değil!');
    }

    final mode = current.room.gameMode;
    
    if (mode == GameMode.theme || mode == GameMode.core) {
      await submitWord(word: word);
      return 'word';
    } else {
      // Legacy mode
      final isVerb = current.room.currentWordType == 'verb' || 
                     current.room.currentWordType == null;
      
      if (isVerb) {
        await submitVerb(verb: word);
        return 'verb';
      } else {
        await submitAdjective(adjective: word);
        return 'adjective';
      }
    }
  }

  Future<void> submitAdjective({required String adjective}) async {
    final current = state.value;
    if (current == null) throw StateError('Oyun durumu mevcut değil');

    final userUid = ref.read(authControllerProvider).value?.uid;
    if (userUid == null) throw StateError('Kullanıcı oturumu açılmamış');

    if (current.room.currentTurnUid != userUid) {
      throw StateError('Sıra sizde değil!');
    }

    final normalizedAdjective = adjective.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalizedAdjective.isEmpty) {
      throw ArgumentError('Sıfat boş olamaz');
    }

    // Optimistic update
    final optimisticWord = PlayedWord(
      word: normalizedAdjective,
      type: WordType.adjective,
      byUid: userUid,
      at: DateTime.now(),
    );
    final updatedWords = [...current.playedWords, optimisticWord];
    state = AsyncValue.data(current.copyWith(playedWords: updatedWords));

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
