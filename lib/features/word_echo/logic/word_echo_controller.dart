import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/word_echo_service.dart';
import '../models/word_echo_state.dart';
import '../models/word_echo_word.dart';

class WordEchoController extends StateNotifier<WordEchoState> {
  WordEchoController({required this.speed, required this.setName})
    : super(const WordEchoState()) {
    _initialize();
  }

  final WordEchoSpeed speed;
  final String setName;
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

    // 1. Rastgele 4 kelime seç
    final selectedWords = WordEchoService.instance.getRandomWords(4);
    final shuffledWords = selectedWords.toList()..shuffle();

    // 2. Slotları hazırla (İçlerine İngilizce kelimeleri koy)
    final slots = List.generate(4, (index) {
      return WordEchoSlot(englishWord: shuffledWords[index].english);
    });

    // 3. Doğru slotu rastgele seç (0, 1, 2 veya 3)
    final correctSlotIndex = _random.nextInt(4);

    // 4. KRİTİK DÜZELTME: Hedef kelimenin Türkçesini ŞİMDİ alıyoruz.
    // Sonraya bırakmıyoruz. shuffledWords listesi elimizdeyken alıyoruz.
    final correctWordObj = shuffledWords[correctSlotIndex];
    final turkishHint = correctWordObj.turkish;

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
      currentCorrectEnglishWord: correctWordObj.english,
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
      return WordEchoController(speed: params.speed, setName: params.setName);
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
