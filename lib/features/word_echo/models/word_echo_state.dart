enum WordEchoSpeed { normal, fast }

enum WordEchoPhase { showingSequence, waitingForAnswer, feedback, finished }

class WordEchoSlot {
  const WordEchoSlot({
    this.englishWord,
    this.isActive = false,
    this.isCorrect = false,
    this.isWrong = false,
  });

  final String? englishWord;
  final bool isActive;
  final bool isCorrect;
  final bool isWrong;

  WordEchoSlot copyWith({
    String? englishWord,
    bool? isActive,
    bool? isCorrect,
    bool? isWrong,
  }) {
    return WordEchoSlot(
      englishWord: englishWord ?? this.englishWord,
      isActive: isActive ?? this.isActive,
      isCorrect: isCorrect ?? this.isCorrect,
      isWrong: isWrong ?? this.isWrong,
    );
  }
}

class WordEchoState {
  const WordEchoState({
    this.isLoading = false,
    this.timeRemaining = 60,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.speed = WordEchoSpeed.normal,
    this.slots = const [],
    this.phase = WordEchoPhase.showingSequence,
    this.currentTurkishHint,
    this.currentCorrectSlotIndex,
    this.currentCorrectEnglishWord,
    this.currentQuestionIndex = 0,
    this.setName,
    this.selectedSlots = const [],
    this.currentSequence = const [],
  });

  final bool isLoading;
  final int timeRemaining; // seconds
  final int score;
  final int correctCount;
  final int wrongCount;
  final WordEchoSpeed speed;
  final List<WordEchoSlot> slots; // Always 4 slots
  final WordEchoPhase phase;
  final String? currentTurkishHint;
  final int? currentCorrectSlotIndex;
  final String?
  currentCorrectEnglishWord; // Store the correct English word for verification
  final int currentQuestionIndex; // 0-9 (10 questions)
  final String? setName;
  final List<int>
  selectedSlots; // Which slots are selected for current question
  final List<String> currentSequence; // Current sequence of English words

  WordEchoState copyWith({
    bool? isLoading,
    int? timeRemaining,
    int? score,
    int? correctCount,
    int? wrongCount,
    WordEchoSpeed? speed,
    List<WordEchoSlot>? slots,
    WordEchoPhase? phase,
    String? currentTurkishHint,
    int? currentCorrectSlotIndex,
    String? currentCorrectEnglishWord,
    int? currentQuestionIndex,
    String? setName,
    List<int>? selectedSlots,
    List<String>? currentSequence,
  }) {
    return WordEchoState(
      isLoading: isLoading ?? this.isLoading,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      speed: speed ?? this.speed,
      slots: slots ?? this.slots,
      phase: phase ?? this.phase,
      currentTurkishHint: currentTurkishHint ?? this.currentTurkishHint,
      currentCorrectSlotIndex:
          currentCorrectSlotIndex ?? this.currentCorrectSlotIndex,
      currentCorrectEnglishWord:
          currentCorrectEnglishWord ?? this.currentCorrectEnglishWord,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      setName: setName ?? this.setName,
      selectedSlots: selectedSlots ?? this.selectedSlots,
      currentSequence: currentSequence ?? this.currentSequence,
    );
  }
}
