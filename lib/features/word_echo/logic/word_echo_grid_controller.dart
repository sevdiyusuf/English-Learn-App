import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/user_stats_repo.dart';
import '../../auth/logic/auth_controller.dart';
import '../../word_match/data/word_match_providers.dart';
import '../../word_match/models/word_pair.dart';
import '../data/word_echo_service.dart';
import '../logic/word_echo_controller.dart';
import '../models/word_echo_config.dart';
import '../models/word_echo_grid_state.dart';
import '../models/word_echo_state.dart';
import '../models/word_echo_word.dart';

class WordEchoGridController extends StateNotifier<WordEchoGridState> {
  WordEchoGridController({
    required this.speed,
    required this.setName,
    required this.ref,
  }) : super(const WordEchoGridState()) {
    _initialize();
  }

  final WordEchoSpeed speed;
  final String setName;
  final Ref ref;
  final List<WordEchoWord> _availableWords = [];
  bool _isInitialized = false;
  Timer? _showAllTimer;
  Timer? _countdownTimer;

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await WordEchoService.instance.loadWords();
      final allWords = WordEchoService.instance.getWords();
      _availableWords.addAll(allWords);
      _isInitialized = true;
      state = state.copyWith(isLoading: false, setName: setName);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) await _initialize();
  }

  Future<void> startGame() async {
    if (!_isInitialized) await ensureInitialized();
    await initRound();
  }

  /// Merkezi Timer Yönetimi
  /// Sayacı başlatır ve bittiğinde [onFinished] callback'ini çalıştırır.
  void _startCountdown(int seconds, VoidCallback onFinished) {
    _countdownTimer?.cancel();

    // Başlangıç değerini set et
    state = state.copyWith(countdown: seconds);

    // İlk değeri hemen göster, sonra her saniye azalt
    int remaining = seconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      remaining--;

      if (remaining <= 0) {
        // Countdown bitti, timer'ı iptal et
        timer.cancel();
        // Hemen null yap - direkt yeni state oluştur
        state = WordEchoGridState(
          isLoading: state.isLoading,
          phase: state.phase,
          cards: state.cards,
          currentTargetIndex: state.currentTargetIndex,
          currentTargetWord: state.currentTargetWord,
          score: state.score,
          correctCount: state.correctCount,
          wrongCount: state.wrongCount,
          currentQuestionIndex: state.currentQuestionIndex,
          englishPhaseQuestions: state.englishPhaseQuestions,
          turkishPhaseQuestions: state.turkishPhaseQuestions,
          setName: state.setName,
          countdown: null,
          remainingViews: state.remainingViews,
        );
        // Callback'i çağır
        if (mounted) {
          onFinished();
        }
        return;
      }

      if (remaining == 1) {
        // Son saniye (1), göster ve hemen kaybol
        debugPrint('DEBUG: remaining == 1, setting countdown to 1');
        state = state.copyWith(countdown: 1);
        debugPrint(
          'DEBUG: countdown set to 1, state.countdown = ${state.countdown}',
        );
        // Timer'ı iptal et
        timer.cancel();
        debugPrint('DEBUG: timer cancelled');
        // Hemen null yap (çok kısa bir gecikme ile)
        Future.microtask(() {
          debugPrint(
            'DEBUG: Future.microtask executing, mounted=$mounted, state.countdown=${state.countdown}',
          );
          if (mounted) {
            // Direkt yeni state oluştur (copyWith null değerleri handle etmiyor)
            state = WordEchoGridState(
              isLoading: state.isLoading,
              phase: state.phase,
              cards: state.cards,
              currentTargetIndex: state.currentTargetIndex,
              currentTargetWord: state.currentTargetWord,
              score: state.score,
              correctCount: state.correctCount,
              wrongCount: state.wrongCount,
              currentQuestionIndex: state.currentQuestionIndex,
              englishPhaseQuestions: state.englishPhaseQuestions,
              turkishPhaseQuestions: state.turkishPhaseQuestions,
              setName: state.setName,
              countdown: null, // Direkt null
              remainingViews: state.remainingViews,
            );
            debugPrint(
              'DEBUG: countdown set to null, state.countdown = ${state.countdown}',
            );
            onFinished();
            debugPrint('DEBUG: onFinished() called');
          }
        });
        return;
      }

      // Saymaya devam et
      state = state.copyWith(countdown: remaining);
    });
  }

  Future<void> initRound() async {
    // Get 9 words (from Personal Echo or Global)
    final config = ref.read(wordEchoConfigProvider);
    List<EchoGridWord> selectedWords;

    if (config.isPersonalEchoActive && config.selectedWordSetId != null) {
      try {
        final repo = await ref.read(wordMatchRepoProvider.future);
        final pairs = await repo.fetchPairs(config.selectedWordSetId!);

        if (pairs.length < 9) {
          // Not enough words in set - cannot proceed
          state = state.copyWith(
            phase: WordEchoGridPhase.finished,
            errorMessage: 'Set\'te yeterli kelime yok (en az 9 kelime gerekli)',
          );
          return;
        }

        final random = Random();
        final selectedPairs = <WordPair>[];
        final usedIndices = <int>{};

        while (selectedPairs.length < 9) {
          final index = random.nextInt(pairs.length);
          if (!usedIndices.contains(index)) {
            usedIndices.add(index);
            selectedPairs.add(pairs[index]);
          }
        }

        selectedWords =
            selectedPairs
                .map(
                  (pair) => EchoGridWord(
                    english: pair.english,
                    turkish: pair.turkish,
                  ),
                )
                .toList();
      } catch (e) {
        // Error loading from WordSet - cannot proceed
        state = state.copyWith(
          phase: WordEchoGridPhase.finished,
          errorMessage: 'Set yüklenirken hata oluştu: $e',
        );
        return;
      }
    } else {
      // Global: Use JSON words
      final globalWords = WordEchoService.instance.getRandomWords(9);
      selectedWords =
          globalWords
              .map((w) => EchoGridWord(english: w.english, turkish: w.turkish))
              .toList();
    }

    // Create 9 cards
    final cards = List.generate(9, (index) {
      return EchoGridCard(
        index: index,
        word: selectedWords[index],
        isRevealed: true, // Phase 1: all revealed
      );
    });

    // Shuffle questions for English phase only
    // English phase: ask all 9 words in English
    final shuffledWords = List<EchoGridWord>.from(selectedWords)..shuffle();
    final englishQuestions = shuffledWords.toList(); // All 9 words
    final turkishQuestions =
        <EchoGridWord>[]; // Not used, but kept for state compatibility

    // Start countdown (7 seconds) - Initial countdown
    final countdownSeconds = 7;

    state = state.copyWith(
      phase: WordEchoGridPhase.showAll,
      cards: cards,
      currentTargetIndex: null,
      currentTargetWord: null,
      score: 0,
      correctCount: 0,
      wrongCount: 0,
      currentQuestionIndex: 0,
      englishPhaseQuestions: englishQuestions,
      turkishPhaseQuestions: turkishQuestions,
      countdown: countdownSeconds,
      remainingViews: 2, // İlk görüntüleme 1 hakkı gider, 2 kalır
    );

    // Yeni Timer yapısı ile başlat
    _startCountdown(countdownSeconds, () {
      startEnglishPhase();
    });
  }

  void viewCards() {
    // Kullanıcı kartları tekrar görmek istiyor
    if (state.remainingViews <= 0) return;
    if (state.phase != WordEchoGridPhase.englishQuery) return;
    if (state.countdown != null) return; // Already showing cards

    // Reveal all cards (but keep correct cards revealed)
    final revealedCards =
        state.cards.map((card) {
          if (card.isCorrect) {
            // Keep correct cards revealed
            return card;
          } else {
            // Reveal other cards
            return card.copyWith(
              isRevealed: true,
              isWrong: false, // Reset wrong state
            );
          }
        }).toList();

    // Start countdown (4 seconds for normal, 3 for fast) - View cards button
    final countdownSeconds = speed == WordEchoSpeed.normal ? 4 : 3;

    // Önce kartları göster
    state = state.copyWith(
      cards: revealedCards,
      remainingViews: state.remainingViews - 1,
    );

    // Sonra countdown'ı başlat (countdown state'i _startCountdown içinde set edilecek)
    _startCountdown(countdownSeconds, () {
      _hideCardsKeepingCorrect();
    });
  }

  void _hideCardsKeepingCorrect() {
    final hiddenCards =
        state.cards.map((card) {
          if (card.isCorrect) {
            return card;
          } else {
            return card.copyWith(isRevealed: false);
          }
        }).toList();

    state = WordEchoGridState(
      isLoading: state.isLoading,
      phase: state.phase,
      cards: hiddenCards,
      currentTargetIndex: state.currentTargetIndex,
      currentTargetWord: state.currentTargetWord,
      score: state.score,
      correctCount: state.correctCount,
      wrongCount: state.wrongCount,
      currentQuestionIndex: state.currentQuestionIndex,
      englishPhaseQuestions: state.englishPhaseQuestions,
      turkishPhaseQuestions: state.turkishPhaseQuestions,
      setName: state.setName,
      countdown: null,
      remainingViews: state.remainingViews,
    );
  }

  void startEnglishPhase() {
    _showAllTimer?.cancel();
    _countdownTimer?.cancel();

    // Hide all cards
    final hiddenCards =
        state.cards
            .map(
              (card) => card.copyWith(
                isRevealed: false,
                isSelected: false,
                isCorrect: false,
                isWrong: false,
              ),
            )
            .toList();

    // Countdown'ı da null yap
    if (state.countdown != null) {
      state = WordEchoGridState(
        isLoading: state.isLoading,
        phase: state.phase,
        cards: state.cards,
        currentTargetIndex: state.currentTargetIndex,
        currentTargetWord: state.currentTargetWord,
        score: state.score,
        correctCount: state.correctCount,
        wrongCount: state.wrongCount,
        currentQuestionIndex: state.currentQuestionIndex,
        englishPhaseQuestions: state.englishPhaseQuestions,
        turkishPhaseQuestions: state.turkishPhaseQuestions,
        setName: state.setName,
        countdown: null,
        remainingViews: state.remainingViews,
      );
    }

    // Start with first question
    if (state.englishPhaseQuestions.isEmpty) {
      // No questions, finish round
      finishRound();
      return;
    }

    final firstWord = state.englishPhaseQuestions[0];
    final targetIndex = state.cards.indexWhere(
      (c) => c.word.english == firstWord.english,
    );

    state = state.copyWith(
      phase: WordEchoGridPhase.englishQuery,
      cards: hiddenCards,
      currentTargetIndex: targetIndex >= 0 ? targetIndex : null,
      currentTargetWord: firstWord,
      currentQuestionIndex: 0,
    );
  }

  void onCardTapped(int cardIndex) {
    if (state.phase != WordEchoGridPhase.englishQuery) {
      return;
    }

    // Eğer sayaç çalışıyorsa (kartları gör modundaysa) tıklamaya izin verme
    if (state.countdown != null) return;

    if (state.currentTargetIndex == null) return;

    final isCorrect = cardIndex == state.currentTargetIndex;
    final updatedCards = List<EchoGridCard>.from(state.cards);

    if (isCorrect) {
      // Correct: reveal the card (or keep it revealed if already correct)
      final wasAlreadyCorrect = updatedCards[cardIndex].isCorrect;
      updatedCards[cardIndex] = updatedCards[cardIndex].copyWith(
        isRevealed: true,
        isCorrect: true,
        isSelected: true,
      );

      // Update score only if it wasn't already correct
      final newScore = wasAlreadyCorrect ? state.score : state.score + 10;
      final newCorrectCount =
          wasAlreadyCorrect ? state.correctCount : state.correctCount + 1;

      state = state.copyWith(
        cards: updatedCards,
        score: newScore,
        correctCount: newCorrectCount,
      );

      // Move to next question after short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _moveToNextQuestion();
      });
    } else {
      // Wrong: show feedback - only show wrong card as red, don't reveal correct card
      updatedCards[cardIndex] = updatedCards[cardIndex].copyWith(
        isWrong: true,
        isRevealed: true, // Reveal to show it's wrong
        isSelected: true,
      );

      final newScore = state.score - 5;
      final newWrongCount = state.wrongCount + 1;

      state = state.copyWith(
        cards: updatedCards,
        score: newScore,
        wrongCount: newWrongCount,
      );

      // Hide wrong selection after feedback, but don't move to next question
      // User must answer correctly before moving to next question
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        // Hide wrong selection
        final resetCards =
            state.cards.map((card) {
              if (card.index == cardIndex) {
                // Reset wrong card
                return card.copyWith(
                  isRevealed: false,
                  isWrong: false,
                  isSelected: false,
                );
              } else if (card.isCorrect) {
                // Keep correct cards revealed
                return card;
              } else {
                // Keep other cards hidden
                return card.copyWith(isRevealed: false, isSelected: false);
              }
            }).toList();

        state = state.copyWith(cards: resetCards);
        // Don't call _moveToNextQuestion() - wait for correct answer
      });
    }
  }

  void _moveToNextQuestion() {
    // Hide cards but keep correct cards revealed
    final hiddenCards =
        state.cards.map((card) {
          if (card.isCorrect) {
            // Keep correct cards revealed
            return card.copyWith(
              isRevealed: true,
              isSelected: false,
              isWrong: false,
            );
          } else {
            // Hide other cards
            return card.copyWith(
              isRevealed: false,
              isSelected: false,
              isWrong: false,
            );
          }
        }).toList();

    if (state.phase == WordEchoGridPhase.englishQuery) {
      final nextIndex = state.currentQuestionIndex + 1;
      if (nextIndex >= state.englishPhaseQuestions.length) {
        // All questions in englishPhaseQuestions are done
        // Check if all words are matched
        final allMatched = state.cards.every((card) => card.isCorrect);
        if (allMatched) {
          finishRound();
        } else {
          // Not all words matched, find remaining unmatched words and continue
          final unmatchedWords =
              state.cards
                  .where((card) => !card.isCorrect)
                  .map((card) => card.word.english)
                  .toList();

          if (unmatchedWords.isEmpty) {
            // All words matched (shouldn't happen, but safety check)
            finishRound();
          } else {
            // Find first unmatched word from all available words
            final allEnglishWords = state.cards.map((c) => c.word).toList();
            final nextUnmatchedWord = allEnglishWords.firstWhere(
              (word) => unmatchedWords.contains(word.english),
              orElse: () => allEnglishWords[0],
            );
            final targetIndex = state.cards.indexWhere(
              (c) =>
                  c.word.english == nextUnmatchedWord.english && !c.isCorrect,
            );

            // Add this word to englishPhaseQuestions if not already there
            final updatedEnglishQuestions = List<EchoGridWord>.from(
              state.englishPhaseQuestions,
            );
            if (!updatedEnglishQuestions.any(
              (w) => w.english == nextUnmatchedWord.english,
            )) {
              updatedEnglishQuestions.add(nextUnmatchedWord);
            }

            state = state.copyWith(
              cards: hiddenCards,
              currentTargetIndex: targetIndex >= 0 ? targetIndex : null,
              currentTargetWord: nextUnmatchedWord,
              currentQuestionIndex: updatedEnglishQuestions.length - 1,
              englishPhaseQuestions: updatedEnglishQuestions,
            );
          }
        }
      } else {
        final nextWord = state.englishPhaseQuestions[nextIndex];
        final targetCard = state.cards.firstWhere(
          (c) => c.word.english == nextWord.english,
          orElse: () => state.cards[0],
        );

        // If this word is already matched, skip to next unmatched word
        if (targetCard.isCorrect) {
          // Find next unmatched word
          final unmatchedWords =
              state.cards
                  .where((card) => !card.isCorrect)
                  .map((card) => card.word.english)
                  .toList();

          if (unmatchedWords.isEmpty) {
            // All words matched
            finishRound();
          } else {
            // Find first unmatched word in remaining questions
            final nextUnmatchedWord = state.englishPhaseQuestions
                .skip(nextIndex)
                .firstWhere(
                  (word) => unmatchedWords.contains(word.english),
                  orElse: () => state.englishPhaseQuestions[nextIndex],
                );
            final targetIndex = state.cards.indexWhere(
              (c) =>
                  c.word.english == nextUnmatchedWord.english && !c.isCorrect,
            );
            final questionIndex = state.englishPhaseQuestions.indexOf(
              nextUnmatchedWord,
            );

            state = state.copyWith(
              cards: hiddenCards,
              currentTargetIndex: targetIndex >= 0 ? targetIndex : null,
              currentTargetWord: nextUnmatchedWord,
              currentQuestionIndex:
                  questionIndex >= 0 ? questionIndex : nextIndex,
            );
          }
        } else {
          // Next word is not matched, proceed normally
          final targetIndex = state.cards.indexWhere(
            (c) => c.word.english == nextWord.english && !c.isCorrect,
          );

          state = state.copyWith(
            cards: hiddenCards,
            currentTargetIndex: targetIndex >= 0 ? targetIndex : null,
            currentTargetWord: nextWord,
            currentQuestionIndex: nextIndex,
          );
        }
      }
      // Turkish phase removed - only English phase exists
    }
  }

  void finishRound() {
    _showAllTimer?.cancel();
    state = state.copyWith(phase: WordEchoGridPhase.finished);
    // Record stats (fire-and-forget)
    _recordSessionStats();
  }

  Future<void> _recordSessionStats() async {
    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;
      if (user == null) return;

      final statsRepo = ref.read(userStatsRepoProvider);
      // Calculate duration (approximate - grid mode doesn't have strict timer)
      final duration = const Duration(minutes: 2); // Approximate duration

      // Calculate practiced words (total questions answered)
      final practicedWords = state.correctCount + state.wrongCount;

      await statsRepo.recordSession(
        user: user,
        modeId: 'word_echo_grid',
        practicedWords: practicedWords,
        correctAnswers: state.correctCount,
        wrongAnswers: state.wrongCount,
        duration: duration,
        score: state.score,
      );
    } catch (e) {
      // Don't break the game if stats recording fails
      debugPrint('Failed to record word echo grid stats: $e');
    }
  }

  @override
  void dispose() {
    _showAllTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final wordEchoGridControllerProvider = StateNotifierProvider.autoDispose.family<
  WordEchoGridController,
  WordEchoGridState,
  WordEchoControllerParams
>((ref, params) {
  return WordEchoGridController(
    speed: params.speed,
    setName: params.setName,
    ref: ref,
  );
});
