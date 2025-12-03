import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cargo_service.dart';
import '../models/cargo_categories_state.dart';
import '../models/cargo_word.dart'; // CargoWord import'unu eklemeyi unutmayın

class CargoCategoriesController extends StateNotifier<CargoCategoriesState> {
  CargoCategoriesController() : super(const CargoCategoriesState()) {
    _initialize();
  }

  Timer? _gameTimer;
  final Random _random = Random();

  Future<void> _initialize() async {
    await CargoService.instance.loadData();
  }

  void selectDifficulty(Difficulty difficulty) {
    state = state.copyWith(selectedDifficulty: difficulty);
  }

  void toggleCategory(String categoryId) {
    final currentCategories = List<String>.from(state.selectedCategories);

    if (currentCategories.contains(categoryId)) {
      currentCategories.remove(categoryId);
    } else {
      if (currentCategories.length < 3) {
        currentCategories.add(categoryId);
      }
    }
    state = state.copyWith(selectedCategories: currentCategories);
  }

  void startGame() {
    if (!state.canStartGame) return;

    final words = CargoService.instance.getWordsByCategories(
      state.selectedCategories,
    )..shuffle(_random);

    state = state.copyWith(
      remainingWords: words,
      score: 0,
      correctCount: 0,
      wrongCount: 0,
      missedCount: 0,
      remainingTime: const Duration(minutes: 1),
      isRunning: true,
      isFinished: false,
    );

    _startGameTimer();
    _loadNextWord();
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newTime = state.remainingTime - const Duration(seconds: 1);
      if (newTime <= Duration.zero) {
        _endGame();
        return;
      }
      state = state.copyWith(remainingTime: newTime);
    });
  }

  void _loadNextWord() {
    if (state.remainingWords.isEmpty) {
      _endGame();
      return;
    }

    final word = state.remainingWords.removeAt(0);

    state = state.copyWith(
      currentWord: word,
      remainingWords: List.from(state.remainingWords),
      currentWordStartTime: DateTime.now(),
    );

    debugPrint('CONTROLLER: Yeni kelime yüklendi -> ${word.word}');
  }

  // --- GÜNCELLENEN FONKSİYON ---
  void handleAnswer(String selectedCategoryId, {CargoWord? droppedWord}) {
    // 1. Oyun çalışıyor mu?
    if (!state.isRunning) {
      debugPrint('CONTROLLER: Oyun çalışmıyor, işlem iptal.');
      return;
    }

    // 2. İşlem yapılacak kelimeyi belirle
    // Eğer sürüklenen bir kelime varsa onu kullan, yoksa state'tekini kullan.
    final CargoWord? targetWord = droppedWord ?? state.currentWord;

    // 3. Kelime yoksa hata ver
    if (targetWord == null) {
      debugPrint('CONTROLLER HATA: targetWord NULL. Eşleştirme yapılamıyor.');
      return;
    }

    debugPrint(
      'CONTROLLER: Kontrol -> Kelime: ${targetWord.word} vs Kategori: $selectedCategoryId',
    );

    final isCorrect = targetWord.category == selectedCategoryId;

    int newScore = state.score;
    int newCorrectCount = state.correctCount;
    int newWrongCount = state.wrongCount;

    if (isCorrect) {
      // Bonus Hesaplama (Sadece currentWord ile zaman tutuyorsak geçerli)
      int bonus = 0;
      // Eğer drop edilen kelime ile o anki aktif kelime aynıysa zaman bonusu ver
      if (state.currentWord?.word == targetWord.word &&
          state.currentWordStartTime != null) {
        final responseTime = DateTime.now().difference(
          state.currentWordStartTime!,
        );
        if (responseTime <= const Duration(seconds: 1)) {
          bonus = 2;
        }
      }

      newScore = state.score + 10 + bonus;
      newCorrectCount++;
      debugPrint('CONTROLLER: DOĞRU! +${10 + bonus} puan.');
    } else {
      newScore = (state.score - 5).clamp(0, double.infinity).toInt();
      newWrongCount++;
      debugPrint('CONTROLLER: YANLIŞ! -5 puan.');
    }

    state = state.copyWith(
      score: newScore,
      correctCount: newCorrectCount,
      wrongCount: newWrongCount,
      highlightedCategoryId: isCorrect ? selectedCategoryId : null,
      wrongCategoryId: !isCorrect ? selectedCategoryId : null,
    );

    // 800ms bekleyip yeni kelime yükle
    Future.delayed(const Duration(milliseconds: 800), () {
      if (state.isRunning && !state.isFinished) {
        state = state.copyWith(
          highlightedCategoryId: null,
          wrongCategoryId: null,
        );
        _loadNextWord();
      }
    });
  }

  void handleTimeout() {
    if (!state.isRunning) return;

    // Kelime null olsa bile ceza kesip devam et
    final newScore = (state.score - 3).clamp(0, double.infinity).toInt();

    state = state.copyWith(score: newScore, missedCount: state.missedCount + 1);

    debugPrint('CONTROLLER: Timeout - Ceza kesildi, yeni kelime yükleniyor.');
    _loadNextWord();
  }

  void handleWordSaved() {
    if (!state.isRunning) return;

    debugPrint('CONTROLLER: Kelime kaydedildi, yeni kelime yükleniyor.');
    // Kelime kaydedildi, yeni kelime yükle (ceza yok)
    _loadNextWord();
  }

  void _endGame() {
    _gameTimer?.cancel();
    _gameTimer = null;
    state = state.copyWith(
      isRunning: false,
      isFinished: true,
      remainingTime: Duration.zero,
    );
  }

  void reset() {
    _gameTimer?.cancel();
    _gameTimer = null;
    state = state.copyWith(
      currentWord: null,
      remainingWords: const [],
      score: 0,
      correctCount: 0,
      wrongCount: 0,
      missedCount: 0,
      remainingTime: const Duration(minutes: 1),
      isRunning: false,
      isFinished: false,
      currentWordStartTime: null,
      highlightedCategoryId: null,
      wrongCategoryId: null,
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

final cargoCategoriesControllerProvider =
    StateNotifierProvider<CargoCategoriesController, CargoCategoriesState>(
      (ref) => CargoCategoriesController(),
    );
