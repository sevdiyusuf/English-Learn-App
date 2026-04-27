enum WordEchoGridPhase {
  showAll, // Phase 1: All cards revealed
  englishQuery, // Phase 2: English word → card position
  turkishQuery, // Phase 3: Turkish meaning → card position
  finished,
}

class EchoGridWord {
  const EchoGridWord({required this.english, required this.turkish});

  final String english;
  final String turkish;
}

class EchoGridCard {
  const EchoGridCard({
    required this.index,
    required this.word,
    this.isRevealed = false,
    this.isSelected = false,
    this.isCorrect = false,
    this.isWrong = false,
  });

  final int index; // 0..8
  final EchoGridWord word;
  final bool isRevealed; // Front face visible?
  final bool isSelected; // Currently selected?
  final bool isCorrect; // Correct answer?
  final bool isWrong; // Wrong answer?

  EchoGridCard copyWith({
    int? index,
    EchoGridWord? word,
    bool? isRevealed,
    bool? isSelected,
    bool? isCorrect,
    bool? isWrong,
  }) {
    return EchoGridCard(
      index: index ?? this.index,
      word: word ?? this.word,
      isRevealed: isRevealed ?? this.isRevealed,
      isSelected: isSelected ?? this.isSelected,
      isCorrect: isCorrect ?? this.isCorrect,
      isWrong: isWrong ?? this.isWrong,
    );
  }
}

class WordEchoGridState {
  const WordEchoGridState({
    this.isLoading = false,
    this.phase = WordEchoGridPhase.showAll,
    this.cards = const [],
    this.currentTargetIndex,
    this.currentTargetWord,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.currentQuestionIndex = 0,
    this.englishPhaseQuestions = const [],
    this.turkishPhaseQuestions = const [],
    this.setName,
    this.countdown,
    this.remainingViews = 3,
    this.errorMessage,
  });

  final bool isLoading;
  final WordEchoGridPhase phase;
  final List<EchoGridCard> cards; // 9 cards (3x3 grid)
  final int? currentTargetIndex; // Target card index for phase 2-3
  final EchoGridWord? currentTargetWord; // Target word for phase 2-3
  final int score;
  final int correctCount;
  final int wrongCount;
  final int currentQuestionIndex; // Current question in phase
  final List<EchoGridWord> englishPhaseQuestions; // Words to ask in phase 2
  final List<EchoGridWord> turkishPhaseQuestions; // Words to ask in phase 3
  final String? setName;
  final int? countdown; // Countdown timer (4, 3, 2, 1, null)
  final int remainingViews; // Remaining card view chances (3, 2, 1, 0)
  final String? errorMessage; // Error message if initialization fails

  WordEchoGridState copyWith({
    bool? isLoading,
    WordEchoGridPhase? phase,
    List<EchoGridCard>? cards,
    int? currentTargetIndex,
    EchoGridWord? currentTargetWord,
    int? score,
    int? correctCount,
    int? wrongCount,
    int? currentQuestionIndex,
    List<EchoGridWord>? englishPhaseQuestions,
    List<EchoGridWord>? turkishPhaseQuestions,
    String? setName,
    int? countdown,
    Object? countdownNull = _undefined,
    int? remainingViews,
    String? errorMessage,
    Object? errorMessageNull = _undefined,
  }) {
    return WordEchoGridState(
      isLoading: isLoading ?? this.isLoading,
      phase: phase ?? this.phase,
      cards: cards ?? this.cards,
      currentTargetIndex: currentTargetIndex ?? this.currentTargetIndex,
      currentTargetWord: currentTargetWord ?? this.currentTargetWord,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      englishPhaseQuestions:
          englishPhaseQuestions ?? this.englishPhaseQuestions,
      turkishPhaseQuestions:
          turkishPhaseQuestions ?? this.turkishPhaseQuestions,
      setName: setName ?? this.setName,
      countdown:
          countdownNull == _undefined ? (countdown ?? this.countdown) : null,
      remainingViews: remainingViews ?? this.remainingViews,
      errorMessage:
          errorMessageNull == _undefined
              ? (errorMessage ?? this.errorMessage)
              : null,
    );
  }
}

// Sentinel object for null values in copyWith
const _undefined = Object();
