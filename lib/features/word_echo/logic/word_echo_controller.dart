import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/user_stats_repo.dart';
import '../../auth/logic/auth_controller.dart';
import '../../flash_opposites/data/opposites_service.dart';
import '../../word_match/data/word_match_providers.dart';
import '../data/word_echo_service.dart';
import '../models/word_echo_config.dart';
import '../models/word_echo_state.dart';
import '../models/word_echo_word.dart';

class WordEchoController extends StateNotifier<WordEchoState> {
  WordEchoController({
    required this.speed,
    required this.setName,
    required this.ref,
  }) : super(const WordEchoState()) {
    _initialize();
  }

  final WordEchoSpeed speed;
  final String setName;
  final Ref ref;
  Timer? _gameTimer;
  Timer? _responseTimer;
  final List<WordEchoWord> _availableWords = [];
  bool _isInitialized = false;
  final Random _random = Random();
  DateTime? _questionStartTime;

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await WordEchoService.instance.loadWords();
      await OppositesService.instance.loadData(); // Load wrong answers
      final allWords = WordEchoService.instance.getWords();
      _availableWords.addAll(allWords);
      _isInitialized = true;
      state = state.copyWith(
        isLoading: false,
        speed: speed,
        setName: setName,
        slots: List.generate(4, (index) => const WordEchoSlot()),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Hata olursa kullanıcıya bildirilebilir veya retry mekanizması eklenebilir
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) await _initialize();
  }

  Future<void> startGame() async {
    if (!_isInitialized) await ensureInitialized();
    // Eğer yeterli kelime yoksa başlatma
    if (_availableWords.length < 4) return;

    state = state.copyWith(
      timeRemaining: 60,
      score: 0,
      correctCount: 0,
      wrongCount: 0,
      currentQuestionIndex: 0,
      phase: WordEchoPhase.showingSequence,
    );

    _startGameTimer();
    _loadNextQuestion();
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining <= 0) {
        timer.cancel();
        _endGame();
        return;
      }
      state = state.copyWith(timeRemaining: state.timeRemaining - 1);
    });
  }

  Future<void> _loadNextQuestion() async {
    if (state.timeRemaining <= 0 || state.currentQuestionIndex >= 10) {
      _endGame();
      return;
    }

    // Check Personal Echo config
    final config = ref.read(wordEchoConfigProvider);
    WordEchoWord correctWord;
    List<String> wrongAnswerWords;

    if (config.isPersonalEchoActive && config.selectedWordSetId != null) {
      // Personal Echo: Get 1 correct word from selected WordSet, 3 wrong from opposites.json
      try {
        final repo = await ref.read(wordMatchRepoProvider.future);
        final pairs = await repo.fetchPairs(config.selectedWordSetId!);

        if (pairs.isEmpty) {
          // Not enough words in set - end game with error
          _endGame();
          return;
        }

        // Select 1 correct word from the set
        final correctPair = pairs[_random.nextInt(pairs.length)];
        correctWord = WordEchoWord(
          english: correctPair.english,
          turkish: correctPair.turkish,
        );

        // Get 3 wrong answers from opposites.json, excluding the correct word
        // Try new format first (with translate), fallback to old format
        final wrongAnswersWithTranslate = OppositesService.instance
            .getWrongAnswersWithTranslate(3, exclude: [correctWord.english]);
        if (wrongAnswersWithTranslate.isNotEmpty) {
          wrongAnswerWords =
              wrongAnswersWithTranslate.map((item) => item['word']!).toList();
        } else {
          wrongAnswerWords = OppositesService.instance.getWrongAnswers(
            3,
            exclude: [correctWord.english],
          );
        }
      } catch (e) {
        // Error loading from WordSet - end game
        _endGame();
        return;
      }
    } else {
      // Global: Get 1 correct word from JSON, 3 wrong from opposites.json
      final allWords = WordEchoService.instance.getRandomWords(1);
      correctWord = allWords[0];

      // Get 3 wrong answers from opposites.json, excluding the correct word
      // Try new format first (with translate), fallback to old format
      final wrongAnswersWithTranslate = OppositesService.instance
          .getWrongAnswersWithTranslate(3, exclude: [correctWord.english]);
      if (wrongAnswersWithTranslate.isNotEmpty) {
        wrongAnswerWords =
            wrongAnswersWithTranslate.map((item) => item['word']!).toList();
      } else {
        wrongAnswerWords = OppositesService.instance.getWrongAnswers(
          3,
          exclude: [correctWord.english],
        );
      }
    }

    // If we don't have enough wrong answers, fill with random words from JSON
    if (wrongAnswerWords.length < 3) {
      final needed = 3 - wrongAnswerWords.length;
      final excludeSet = {correctWord.english, ...wrongAnswerWords};
      final additionalWords =
          WordEchoService.instance
              .getWords()
              .where((w) => !excludeSet.contains(w.english))
              .toList()
            ..shuffle();

      for (int i = 0; i < needed && i < additionalWords.length; i++) {
        wrongAnswerWords.add(additionalWords[i].english);
      }
    }

    // Create WordEchoWord objects for wrong answers
    // First try to get translate from opposites.json (new format)
    final wrongWords = <WordEchoWord>[];
    final wrongAnswersWithTranslate = OppositesService.instance
        .getWrongAnswersWithTranslate(3, exclude: [correctWord.english]);

    if (wrongAnswersWithTranslate.isNotEmpty &&
        wrongAnswersWithTranslate.length >= 3) {
      // Use translate from opposites.json
      for (final wrongItem in wrongAnswersWithTranslate.take(3)) {
        wrongWords.add(
          WordEchoWord(
            english: wrongItem['word']!,
            turkish: wrongItem['translate']!,
          ),
        );
      }
    } else {
      // Fallback: try to find Turkish translation from WordEchoService
      final excludeSet = {correctWord.english, ...wrongAnswerWords};
      for (final wrongEnglish in wrongAnswerWords.take(3)) {
        // Try to find Turkish translation from WordEchoService
        final wordFromService = WordEchoService.instance.getWordByEnglish(
          wrongEnglish,
        );
        if (wordFromService != null) {
          wrongWords.add(wordFromService);
        } else {
          // If not found, get a random word from WordEchoService that's not the correct word
          final availableWords =
              WordEchoService.instance
                  .getWords()
                  .where((w) => !excludeSet.contains(w.english))
                  .toList();
          if (availableWords.isNotEmpty) {
            final randomWord =
                availableWords[_random.nextInt(availableWords.length)];
            wrongWords.add(randomWord);
            excludeSet.add(randomWord.english); // Avoid duplicates
          } else {
            // Last resort: create with empty Turkish
            wrongWords.add(WordEchoWord(english: wrongEnglish, turkish: ''));
          }
        }
      }
    }

    // Combine correct word with wrong words and shuffle
    final allWords = [correctWord, ...wrongWords]..shuffle();

    // Find the correct slot index after shuffling
    final correctSlotIndex = allWords.indexWhere(
      (w) => w.english == correctWord.english,
    );

    // Ensure we found the correct word
    assert(correctSlotIndex != -1, 'Correct word not found after shuffle');

    // 2. Slotları hazırla (İçlerine İngilizce kelimeleri koy)
    final slots = List.generate(4, (index) {
      return WordEchoSlot(englishWord: allWords[index].english);
    });

    // 3. Doğru kelimenin Türkçesini al
    final turkishHint = correctWord.turkish;

    // Debug: Türkçe ipucunun boş olmadığından emin ol
    assert(turkishHint.isNotEmpty, 'Turkish hint should not be empty');

    state = state.copyWith(
      slots: slots,
      phase: WordEchoPhase.showingSequence,
      currentSequence: [], // Kullanılmıyor ama temiz kalsın
      selectedSlots: [],
      // İpucunu state'e kaydediyoruz ama UI bunu phase 'waitingForAnswer' olana kadar göstermeyecek
      currentTurkishHint: turkishHint,
      currentCorrectSlotIndex: correctSlotIndex,
      currentCorrectEnglishWord: correctWord.english,
    );

    // 5. Animasyonu başlat
    await _showSequence();
  }

  Future<void> _showSequence() async {
    final wordDuration =
        speed == WordEchoSpeed.normal
            ? const Duration(milliseconds: 700)
            : const Duration(milliseconds: 400);
    final gapDuration =
        speed == WordEchoSpeed.normal
            ? const Duration(milliseconds: 200)
            : const Duration(milliseconds: 100);

    // 0'dan 3'e kadar slotları sırayla yakıp söndür
    for (int i = 0; i < 4; i++) {
      // Slotu AKTİF et (Görünür yap)
      var currentSlots = List<WordEchoSlot>.from(state.slots);
      currentSlots[i] = currentSlots[i].copyWith(isActive: true);
      state = state.copyWith(slots: currentSlots);

      await Future.delayed(wordDuration);

      // Slotu PASİF et (Gizle)
      currentSlots = List<WordEchoSlot>.from(state.slots);
      currentSlots[i] = currentSlots[i].copyWith(isActive: false);
      state = state.copyWith(slots: currentSlots);

      if (i < 3) {
        await Future.delayed(gapDuration);
      }
    }

    // Animasyon bitti!
    // Artık aşamayı değiştiriyoruz. Phase değişince:
    // 1. UI'daki AbsorbPointer kalkacak (tıklanabilir olacak).
    // 2. UI'daki alt kısım (ipucu) görünecek.
    // ÖNEMLİ: currentTurkishHint zaten _loadNextQuestion'da set edilmişti
    // copyWith'te ?? operatörü olduğu için null verilmezse mevcut değer korunur
    // Ama açıkça koruyoruz ki emin olalım
    final preservedHint = state.currentTurkishHint;
    state = state.copyWith(
      phase: WordEchoPhase.waitingForAnswer,
      currentTurkishHint: preservedHint, // Açıkça koru
    );

    _questionStartTime = DateTime.now();
    _startResponseTimer();
  }

  void _startResponseTimer() {
    _responseTimer?.cancel();
    final responseDuration =
        speed == WordEchoSpeed.normal
            ? const Duration(seconds: 8)
            : const Duration(seconds: 5);

    _responseTimer = Timer(responseDuration, () {
      if (state.phase == WordEchoPhase.waitingForAnswer) {
        _handleAnswer(null); // Süre doldu
      }
    });
  }

  void selectSlot(int slotIndex) {
    // Sadece cevap bekleme anında tıklanabilir
    if (state.phase != WordEchoPhase.waitingForAnswer) return;

    _responseTimer?.cancel();
    _handleAnswer(slotIndex);
  }

  void _handleAnswer(int? selectedSlotIndex) {
    if (selectedSlotIndex == null) {
      _applyFeedback(false, -1);
      return;
    }

    final correctSlotIndex = state.currentCorrectSlotIndex;

    // Basit ve kesin kontrol: İndexler eşit mi?
    final isCorrect = (selectedSlotIndex == correctSlotIndex);

    _applyFeedback(isCorrect, selectedSlotIndex);
  }

  void _applyFeedback(bool isCorrect, int selectedSlotIndex) {
    final updatedSlots = List<WordEchoSlot>.from(state.slots);
    final correctSlotIndex = state.currentCorrectSlotIndex;

    for (int i = 0; i < updatedSlots.length; i++) {
      // Önce temizle
      updatedSlots[i] = updatedSlots[i].copyWith(
        isActive: false,
        isCorrect: false,
        isWrong: false,
      );

      if (i == selectedSlotIndex) {
        // Tıklanan slot
        updatedSlots[i] = updatedSlots[i].copyWith(
          isCorrect: isCorrect, // Doğruysa Yeşil
          isWrong: !isCorrect, // Yanlışsa Kırmızı
        );
      } else if (i == correctSlotIndex && !isCorrect) {
        // Yanlış yapıldıysa doğru olanı da göster
        updatedSlots[i] = updatedSlots[i].copyWith(isCorrect: true);
      }
    }

    int newScore = state.score;
    if (isCorrect) {
      newScore += 10;
      if (_questionStartTime != null &&
          DateTime.now().difference(_questionStartTime!).inSeconds <= 2) {
        newScore += 3;
      }
    } else {
      newScore -= 5;
    }

    state = state.copyWith(
      correctCount: isCorrect ? state.correctCount + 1 : state.correctCount,
      wrongCount: isCorrect ? state.wrongCount : state.wrongCount + 1,
      score: newScore,
      phase: WordEchoPhase.feedback, // Feedback aşamasına geç
      slots: updatedSlots,
    );

    // Sonraki soruya geç
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (state.currentQuestionIndex >= 9 || state.timeRemaining <= 0) {
        _endGame();
      } else {
        _moveToNextQuestion();
      }
    });
  }

  Future<void> _moveToNextQuestion() async {
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
      phase: WordEchoPhase.showingSequence,
      slots: List.generate(4, (_) => const WordEchoSlot()),
      currentTurkishHint: null,
      currentCorrectSlotIndex: null,
      currentCorrectEnglishWord: null,
      selectedSlots: [],
      currentSequence: [],
    );
    await _loadNextQuestion();
  }

  void _endGame() {
    _gameTimer?.cancel();
    _responseTimer?.cancel();
    state = state.copyWith(phase: WordEchoPhase.finished);
    // Record stats (fire-and-forget)
    _recordSessionStats();
  }

  Future<void> _recordSessionStats() async {
    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;
      if (user == null) return;

      final statsRepo = ref.read(userStatsRepoProvider);
      // Calculate duration (60 seconds - remaining time)
      final duration = Duration(seconds: 60 - state.timeRemaining);

      // Calculate practiced words (total questions answered)
      final practicedWords = state.correctCount + state.wrongCount;

      await statsRepo.recordSession(
        user: user,
        modeId: 'word_echo_classic',
        practicedWords: practicedWords,
        correctAnswers: state.correctCount,
        wrongAnswers: state.wrongCount,
        duration: duration,
        score: state.score,
      );
    } catch (e) {
      // Don't break the game if stats recording fails
      debugPrint('Failed to record word echo stats: $e');
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _responseTimer?.cancel();
    super.dispose();
  }
}

final wordEchoControllerProvider = StateNotifierProvider.autoDispose
    .family<WordEchoController, WordEchoState, WordEchoControllerParams>((
      ref,
      params,
    ) {
      return WordEchoController(
        speed: params.speed,
        setName: params.setName,
        ref: ref,
      );
    });

class WordEchoControllerParams {
  const WordEchoControllerParams({required this.speed, required this.setName});

  final WordEchoSpeed speed;
  final String setName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordEchoControllerParams &&
          runtimeType == other.runtimeType &&
          speed == other.speed &&
          setName == other.setName;

  @override
  int get hashCode => speed.hashCode ^ setName.hashCode;
}
