import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/user_stats_repo.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/opposites_service.dart';
import '../models/flash_opposites_state.dart';
import '../models/opposite_word.dart';
import 'adaptive_difficulty_helper.dart';

class FlashOppositesController extends StateNotifier<FlashOppositesState> {
  FlashOppositesController(this.level, this.ref)
    : super(const FlashOppositesState()) {
    _initialize();
  }

  final String level;
  final Ref ref;
  final Random _random = Random();
  // ignore: prefer_final_fields
  List<OppositeWord> _usedWords = [];
  final Map<String, Timer> _fallingWordTimers = {};
  Timer? _gameTimer; // Timer for visual display only (doesn't end game)

  // Adaptive difficulty pools
  Map<DifficultyLevel, List<OppositeWord>> _wordsByDifficulty = {};

  Future<void> _initialize() async {
    await OppositesService.instance.loadData();

    // Initialize words by difficulty for adaptive system
    _wordsByDifficulty = {
      DifficultyLevel.easy:
          OppositesService.instance.getWordsByLevel('easy').toList()
            ..shuffle(_random),
      DifficultyLevel.medium:
          OppositesService.instance.getWordsByLevel('medium').toList()
            ..shuffle(_random),
      DifficultyLevel.upper:
          OppositesService.instance.getWordsByLevel('upper').toList()
            ..shuffle(_random),
      DifficultyLevel.expert:
          OppositesService.instance.getWordsByLevel('expert').toList()
            ..shuffle(_random),
    };
  }

  void startGame() {
    if (_wordsByDifficulty.isEmpty) {
      return;
    }

    // Initialize adaptive stage and max stage based on selected level
    final initialStage = AdaptiveDifficultyHelper.getInitialStage(level);
    final maxStage = AdaptiveDifficultyHelper.getMaxStage(level);
    final startTime = DateTime.now();

    state = state.copyWith(
      isGameActive: true,
      hasPassUsed: false,
      score: 0,
      correctCount: 0,
      wrongCount: 0,
      passCount: 0,
      livesLeft: 3,
      streak: 0,
      stage: initialStage,
      maxStage: maxStage,
      lastDifficulty: null,
      showLevelUpBanner: false,
      gameStartTime: startTime,
      elapsedDuration: Duration.zero,
    );

    // Start timer for visual display (updates every second)
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isGameActive || state.isGameFinished) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(
        state.gameStartTime ?? DateTime.now(),
      );
      state = state.copyWith(elapsedDuration: elapsed);
    });

    _loadNextQuestion();
  }

  void _loadNextQuestion() {
    final currentStage = state.stage;
    if (currentStage == null) return;

    // Pick next difficulty based on adaptive stage
    final nextDifficulty = AdaptiveDifficultyHelper.pickNextDifficulty(
      currentStage,
      state.lastDifficulty,
    );

    // Get word from appropriate difficulty pool
    final difficultyWords = _wordsByDifficulty[nextDifficulty] ?? [];
    if (difficultyWords.isEmpty) {
      // Reshuffle if pool is empty
      _wordsByDifficulty[nextDifficulty] =
          OppositesService.instance
              .getWordsByLevel(
                AdaptiveDifficultyHelper.difficultyLevelToString(
                  nextDifficulty,
                ),
              )
              .toList()
            ..shuffle(_random);
    }

    final availablePool = _wordsByDifficulty[nextDifficulty]!;
    if (availablePool.isEmpty) {
      return; // No words available
    }

    final word = availablePool.removeAt(0);

    // Get wrong answers
    final wrongAnswers = OppositesService.instance.getWrongAnswers(
      4,
      exclude: [word.opposite, word.word],
    );

    // Create options: correct answer + 4 wrong answers
    final allOptions = [word.opposite, ...wrongAnswers]..shuffle(_random);

    state = state.copyWith(
      currentWord: word,
      options: allOptions,
      selectedOption: null,
      currentQuestionStartTime: DateTime.now(),
      hasPassUsed: false, // Reset pass for new question
      wordColors: {},
      fallingWordsPositions: {},
      lastDifficulty: nextDifficulty,
      showLevelUpBanner: false, // Reset banner flag
    );

    _startFallingAnimation(allOptions);
  }

  void _startFallingAnimation(List<String> options) {
    // Cancel previous timers
    for (final timer in _fallingWordTimers.values) {
      timer.cancel();
    }
    _fallingWordTimers.clear();

    // Create random order for falling (0.1s intervals)
    final order = List.generate(5, (i) => i)..shuffle(_random);

    // Initialize positions at top (-100)
    final positions = <String, double>{};
    for (final option in options) {
      positions[option] = -100.0;
    }

    state = state.copyWith(fallingWordsPositions: positions);

    // Start falling animation for each word
    for (int i = 0; i < order.length; i++) {
      final delay = Duration(milliseconds: 100 * i);
      Timer(delay, () {
        final option = options[order[i]];
        _animateWordFalling(option);
      });
    }
  }

  void _animateWordFalling(String word) {
    const targetPosition = 0.0; // Center position
    const duration = Duration(milliseconds: 400); // Increased speed (was 600)
    const steps = 40;
    final stepDuration = duration ~/ steps;
    final stepSize = 100.0 / steps; // From -100 to 0

    int currentStep = 0;
    final timer = Timer.periodic(stepDuration, (timer) {
      if (!state.isGameActive) {
        timer.cancel();
        return;
      }

      currentStep++;
      final newPosition = -100.0 + (stepSize * currentStep);
      final positions = Map<String, double>.from(state.fallingWordsPositions);
      positions[word] = newPosition.clamp(-100.0, targetPosition);

      state = state.copyWith(fallingWordsPositions: positions);

      if (newPosition >= targetPosition || currentStep >= steps) {
        positions[word] = targetPosition;
        state = state.copyWith(fallingWordsPositions: positions);
        timer.cancel();
        _fallingWordTimers.remove(word);
      }
    });

    _fallingWordTimers[word] = timer;
  }

  void selectAnswer(String selectedWord) {
    if (state.selectedOption != null || !state.isGameActive) {
      return; // Already answered or game not active
    }

    final currentWord = state.currentWord;
    if (currentWord == null) return;

    final isCorrect = selectedWord == currentWord.opposite;
    final colors = Map<String, Color>.from(state.wordColors);

    if (isCorrect) {
      colors[selectedWord] = Colors.green;
      _handleCorrectAnswer();
    } else {
      colors[selectedWord] = Colors.red;
      colors[currentWord.opposite] = Colors.green;
      _handleWrongAnswer();
    }

    state = state.copyWith(selectedOption: selectedWord, wordColors: colors);

    // Load next question after delay
    Timer(const Duration(milliseconds: 1500), () {
      if (state.isGameActive && !state.isGameFinished) {
        _loadNextQuestion();
      }
    });
  }

  void hideLevelUpBanner() {
    state = state.copyWith(showLevelUpBanner: false);
  }

  void _handleCorrectAnswer() {
    final currentDifficulty = state.lastDifficulty;
    if (currentDifficulty == null) return;

    // Get score based on difficulty
    final baseScore = AdaptiveDifficultyHelper.getScoreForDifficulty(
      currentDifficulty,
    );
    final newScore = state.score + baseScore;
    final newCorrectCount = state.correctCount + 1;
    final newStreak = state.streak + 1;

    // Check for stage upgrade (5 correct in a row)
    final currentStage = state.stage;
    final maxStage = state.maxStage;
    bool shouldUpgrade = false;
    AdaptiveStage? nextStage;

    if (newStreak >= 5 && currentStage != null && maxStage != null) {
      // Check if we can still progress (not at max stage)
      if (currentStage.index < maxStage.index) {
        nextStage = AdaptiveDifficultyHelper.getNextStage(currentStage);
        shouldUpgrade = true;
      }
    }

    state = state.copyWith(
      score: newScore,
      correctCount: newCorrectCount,
      streak: shouldUpgrade ? 0 : newStreak, // Reset streak on upgrade
      stage: nextStage ?? currentStage,
      showLevelUpBanner: shouldUpgrade,
    );
  }

  void _handleWrongAnswer() {
    final newLivesLeft = state.livesLeft - 1;
    final newWrongCount = state.wrongCount + 1;

    state = state.copyWith(
      wrongCount: newWrongCount,
      livesLeft: newLivesLeft,
      streak: 0, // Reset streak on wrong answer
    );

    // End game if no lives left
    if (newLivesLeft <= 0) {
      Timer(const Duration(milliseconds: 1500), () {
        _endGame();
      });
    }
  }

  void passQuestion() {
    if (state.hasPassUsed ||
        !state.isGameActive ||
        state.selectedOption != null) {
      return; // Already used pass or already answered
    }

    state = state.copyWith(passCount: state.passCount + 1, hasPassUsed: true);

    // Load next question after short delay
    Timer(const Duration(milliseconds: 500), () {
      if (state.isGameActive && !state.isGameFinished) {
        _loadNextQuestion();
      }
    });
  }

  void _endGame() {
    for (final timer in _fallingWordTimers.values) {
      timer.cancel();
    }
    _fallingWordTimers.clear();
    _gameTimer?.cancel();
    _gameTimer = null;

    // Calculate final elapsed time
    final finalElapsed =
        state.gameStartTime != null
            ? DateTime.now().difference(state.gameStartTime!)
            : state.elapsedDuration;

    state = state.copyWith(
      isGameActive: false,
      isGameFinished: true,
      elapsedDuration: finalElapsed,
    );

    // Record stats (fire-and-forget)
    _recordSessionStats();
  }

  Future<void> _recordSessionStats() async {
    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;
      if (user == null) return;

      final statsRepo = ref.read(userStatsRepoProvider);
      final duration = state.elapsedDuration;

      // Calculate practiced words (total questions answered)
      final practicedWords = state.correctCount + state.wrongCount;

      await statsRepo.recordSession(
        user: user,
        modeId: 'flash_opposites',
        practicedWords: practicedWords,
        correctAnswers: state.correctCount,
        wrongAnswers: state.wrongCount,
        duration: duration,
        score: state.score,
      );
    } catch (e) {
      // Don't break the game if stats recording fails
      debugPrint('Failed to record flash opposites stats: $e');
    }
  }

  void reset() {
    for (final timer in _fallingWordTimers.values) {
      timer.cancel();
    }
    _fallingWordTimers.clear();
    _gameTimer?.cancel();
    _gameTimer = null;

    _usedWords.clear();

    // Reset difficulty pools
    for (final difficulty in DifficultyLevel.values) {
      _wordsByDifficulty[difficulty] =
          OppositesService.instance
              .getWordsByLevel(
                AdaptiveDifficultyHelper.difficultyLevelToString(difficulty),
              )
              .toList()
            ..shuffle(_random);
    }

    state = const FlashOppositesState();
  }

  @override
  void dispose() {
    for (final timer in _fallingWordTimers.values) {
      timer.cancel();
    }
    _fallingWordTimers.clear();
    _gameTimer?.cancel();
    _gameTimer = null;
    super.dispose();
  }
}

final flashOppositesControllerProvider = StateNotifierProvider.autoDispose
    .family<FlashOppositesController, FlashOppositesState, String>((
      ref,
      level,
    ) {
      return FlashOppositesController(level, ref);
    });
