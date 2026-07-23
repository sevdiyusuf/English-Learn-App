import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/training_repo.dart';
import '../models/training_models.dart';
import '../models/training_state.dart';
import 'training_controller.dart';

final trainingSessionProvider = StateNotifierProvider.autoDispose<
  TrainingSessionController,
  TrainingSessionState
>((ref) {
  return TrainingSessionController(ref.watch(trainingRepoProvider), ref);
});

class TrainingSessionController extends StateNotifier<TrainingSessionState> {
  final TrainingRepository _repo;
  final Ref _ref;

  TrainingSessionController(this._repo, this._ref)
    : super(TrainingSessionState());

  Future<void> loadWorksheet(String path) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final worksheet = await _repo.loadWorksheet(path);

      // Shuffle items for random order
      final shuffledItems = List<WorksheetItem>.from(worksheet.items)
        ..shuffle();

      // Also shuffle tokens for 'order' engine items so they don't appear in correct order initially
      final processedItems =
          shuffledItems.map((item) {
            if (item.engine == EngineType.order) {
              final shuffledBank = List<String>.from(item.bank)..shuffle();
              return WorksheetItem(
                id: item.id,
                engine: item.engine,
                prompt: item.prompt,
                answer: item.answer,
                hint: item.hint,
                translation: item.translation,
                bank: shuffledBank,
                options: item.options,
                steps: item.steps,
                raw: item.raw,
              );
            }
            return item;
          }).toList();

      final shuffledWorksheet = Worksheet(
        schemaVersion: worksheet.schemaVersion,
        level: worksheet.level,
        worksheetId: worksheet.worksheetId,
        title: worksheet.title,
        topicTags: worksheet.topicTags,
        subskills: worksheet.subskills,
        difficulty: worksheet.difficulty,
        items: processedItems,
      );

      state = TrainingSessionState(
        isLoading: false,
        worksheet: shuffledWorksheet,
        currentIndex: 0,
        userAnswers: {},
        results: {},
        isLocked: false,
        reviewQueue: const [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void submitAnswer(dynamic answer) {
    if (state.isLocked || state.currentItem == null) return;

    final item = state.currentItem!;
    final isCorrect = _validateAnswer(item, answer);

    final newAnswers = Map<String, dynamic>.from(state.userAnswers);
    newAnswers[item.id] = answer;

    final newResults = Map<String, bool>.from(state.results);
    newResults[item.id] = isCorrect;

    state = state.copyWith(
      userAnswers: newAnswers,
      results: newResults,
      isLocked: true,
    );
  }

  void nextQuestion() {
    if (state.worksheet == null) return;

    final baseLength = state.worksheet!.items.length;
    final reviewLength = state.reviewQueue.length;
    final totalSteps = baseLength + reviewLength;

    final isAtEndOfBaseRun =
        state.currentIndex == baseLength - 1 && reviewLength == 0;
    if (isAtEndOfBaseRun) {
      final wrongIds =
          state.results.entries
              .where((entry) => entry.value == false)
              .map((entry) => entry.key)
              .toSet();

      if (wrongIds.isEmpty) {
        _saveScoreIfNeeded();
        state = state.copyWith(
          currentIndex: state.currentIndex + 1,
          isLocked: false,
        );
      } else {
        final orderedWrongIds =
            state.worksheet!.items
                .where((item) => wrongIds.contains(item.id))
                .map((item) => item.id)
                .toList();

        state = state.copyWith(
          reviewQueue: orderedWrongIds,
          currentIndex: state.currentIndex + 1,
          isLocked: false,
        );
      }
      return;
    }

    final isLastStep = state.currentIndex >= totalSteps - 1;
    if (isLastStep) {
      _saveScoreIfNeeded();
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isLocked: false,
      );
    } else {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isLocked: false,
      );
    }
  }

  Future<void> _saveScoreIfNeeded() async {
    if (state.worksheet == null || state.totalCount == 0) return;

    // Calculate score
    final score = (state.correctCount / state.totalCount * 100).round();

    // Save to repo
    await _repo.saveScore(state.worksheet!.worksheetId, score);

    // Trigger update for Training Home
    _ref.read(trainingUpdateTriggerProvider.notifier).state++;
  }

  void restart() {
    if (state.worksheet != null) {
      state = TrainingSessionState(
        isLoading: false,
        worksheet: state.worksheet,
        currentIndex: 0,
        userAnswers: {},
        results: {},
        isLocked: false,
        reviewQueue: const [],
      );
    }
  }

  bool _validateAnswer(WorksheetItem item, dynamic answer) {
    if (answer == null) return false;

    switch (item.engine) {
      case EngineType.mcq:
      case EngineType.tap:
        return answer.toString() == item.answer.toString();

      case EngineType.fill:
        final normalizedUser = _normalize(answer.toString());
        if (item.answer is List) {
          final accepted =
              (item.answer as List)
                  .map((e) => _normalize(e.toString()))
                  .toList();
          return accepted.contains(normalizedUser);
        } else {
          return normalizedUser == _normalize(item.answer.toString());
        }

      case EngineType.order:
        // answer should be List<String>
        if (answer is List && item.answer is List) {
          final ansList = answer.map((e) => e.toString()).toList();
          final correctList =
              (item.answer as List).map((e) => e.toString()).toList();

          if (ansList.length != correctList.length) return false;
          for (int i = 0; i < ansList.length; i++) {
            if (ansList[i] != correctList[i]) return false;
          }
          return true;
        }
        return false;

      case EngineType.transform:
        // answer is List<String> corresponding to steps
        if (answer is List && item.steps.isNotEmpty) {
          final userSelections = answer;
          if (userSelections.length != item.steps.length) return false;

          for (int i = 0; i < item.steps.length; i++) {
            // Step answer vs user selection
            if (userSelections[i].toString() != item.steps[i].answer) {
              return false;
            }
          }
          return true;
        }
        // Fallback to string comparison if not step-based (or empty steps)
        return _normalize(answer.toString()) ==
            _normalize(item.answer.toString());

      default:
        return false;
    }
  }

  String _normalize(String input) {
    // lowercase, trim, collapse spaces
    // handle basic contractions if needed, but for now standard normalization
    var s = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    // Simple contraction mapping if needed: i'm -> i am.
    // But usually we accept both if provided in answer list.
    // If user asked to 'accept_contractions', we might need more logic.
    // For now, let's stick to basic normalization.
    return s;
  }
}
