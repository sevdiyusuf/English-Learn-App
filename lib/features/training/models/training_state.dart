import 'training_models.dart';

class TrainingSessionState {
  final bool isLoading;
  final String? error;
  final Worksheet? worksheet;
  final int currentIndex;
  final Map<String, dynamic> userAnswers; // itemId -> user's answer
  final Map<String, bool> results; // itemId -> isCorrect
  final bool isLocked; // if current question is submitted
  final List<String> reviewQueue;

  TrainingSessionState({
    this.isLoading = false,
    this.error,
    this.worksheet,
    this.currentIndex = 0,
    this.userAnswers = const {},
    this.results = const {},
    this.isLocked = false,
    this.reviewQueue = const [],
  });

  TrainingSessionState copyWith({
    bool? isLoading,
    String? error,
    Worksheet? worksheet,
    int? currentIndex,
    Map<String, dynamic>? userAnswers,
    Map<String, bool>? results,
    bool? isLocked,
    List<String>? reviewQueue,
  }) {
    return TrainingSessionState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // If not provided, it clears error unless I want to keep it. Usually clear on new state.
      worksheet: worksheet ?? this.worksheet,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      results: results ?? this.results,
      isLocked: isLocked ?? this.isLocked,
      reviewQueue: reviewQueue ?? this.reviewQueue,
    );
  }

  WorksheetItem? get currentItem {
    if (worksheet == null) {
      return null;
    }
    if (currentIndex < worksheet!.items.length) {
      return worksheet!.items[currentIndex];
    }
    final reviewOffset = currentIndex - worksheet!.items.length;
    if (reviewQueue.isEmpty || reviewOffset < 0) {
      return null;
    }
    if (reviewOffset >= reviewQueue.length) {
      return null;
    }
    final reviewId = reviewQueue[reviewOffset];
    final items =
        worksheet!.items.where((item) => item.id == reviewId).toList();
    if (items.isEmpty) {
      return null;
    }
    return items.first;
  }

  bool get isFinished {
    if (worksheet == null) {
      return false;
    }
    final baseLength = worksheet!.items.length;
    final reviewLength = reviewQueue.length;
    final totalSteps = baseLength + reviewLength;
    return currentIndex >= totalSteps;
  }

  int get correctCount => results.values.where((v) => v).length;
  int get totalCount => worksheet?.items.length ?? 0;
}
