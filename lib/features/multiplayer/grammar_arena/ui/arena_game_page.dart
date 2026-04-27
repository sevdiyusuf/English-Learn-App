import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/logic/auth_controller.dart';
import '../../../training/models/training_models.dart';
import '../../../training/ui/engine_renderer.dart';
import '../logic/arena_session_controller.dart';
import '../models/arena_models.dart';

class ArenaGamePage extends ConsumerStatefulWidget {
  final String roomId;
  const ArenaGamePage({super.key, required this.roomId});

  @override
  ConsumerState<ArenaGamePage> createState() => _ArenaGamePageState();
}

class _ArenaGamePageState extends ConsumerState<ArenaGamePage> {
  Timer? _timer;
  int _remainingMs = 0;

  @override
  void initState() {
    super.initState();
    _startLocalTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLocalTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      final sessionState = ref.read(
        arenaSessionControllerProvider(widget.roomId),
      );
      final room = sessionState.value?.room;

      if (room?.round != null) {
        final round = room!.round!;
        final endTime = round.roundStartAt.add(
          Duration(milliseconds: round.timeLimitMs),
        );
        final remaining = endTime.difference(DateTime.now()).inMilliseconds;

        setState(() {
          _remainingMs = remaining > 0 ? remaining : 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(
      arenaSessionControllerProvider(widget.roomId),
    );
    final currentUser = ref.watch(authControllerProvider).value;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: sessionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            data: (state) {
              if (state.room == null) {
                return const Center(child: Text('Oda bulunamadı'));
              }

              // Check if game finished
              if (state.room!.status == ArenaStatus.finished) {
                // Navigate to result page - handled by router usually, but here we can redirect
                // Or we can just return the Result Page widget if we want to stay on same route path
                // But better to use GoRouter listener.
                // For now, let's show a button or auto-redirect?
                // Let's assume the router will handle it or we push replacement.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go(
                    '/multiplayer/grammar-arena/result/${widget.roomId}',
                  );
                });
                return const Center(child: CircularProgressIndicator());
              }

              final room = state.room!;
              final worksheet = state.worksheet;

              if (worksheet == null || room.round == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final currentRoundIndex = room.round!.index;
              final currentItemId =
                  room.resolvedWorksheet!.questionIds[currentRoundIndex];
              WorksheetItem? currentItem;
              for (final i in worksheet.items) {
                if (i.id == currentItemId) {
                  currentItem = i;
                  break;
                }
              }

              if (currentItem == null) {
                return const Center(
                  child: Text(
                    'Sonraki tur bekleniyor...',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final isHost = currentUser?.uid == room.hostId;
              final myScore = isHost ? room.hostScore : room.guestScore;
              final opponentScore = isHost ? room.guestScore : room.hostScore;
              final opponentName =
                  isHost
                      ? (room.guest?.name ?? 'Misafir')
                      : (room.host?.name ?? 'Kurucu');

              // Determine lock state
              // Locked if user has answered correctly OR max attempts reached OR time out
              // We check local answers
              final myAnswer = state.answers[currentItem.id];
              final isLocked = myAnswer != null && myAnswer.isCorrect;
              // Note: If user answered wrong, they might have another attempt depending on logic.
              // But here we rely on controller. Usually engine locks if correct.
              // If wrong, we might want to allow retry if logic permits.
              // Controller logic: "At1 yanlış:-10, At2 yanlış:-20". implies 2 attempts?
              // Let's check session controller submit logic.

              // Also locked if time is up
              final timeUp = _remainingMs <= 0;
              final locked =
                  isLocked ||
                  timeUp ||
                  (myAnswer != null &&
                      myAnswer.attempt >= 2); // Assuming 2 attempts max

              return Column(
                children: [
                  // Header
                  _buildHeader(
                    currentRoundIndex,
                    room.config.questionCount,
                    myScore,
                    opponentScore,
                    opponentName,
                  ),

                  // Progress / Timer
                  LinearProgressIndicator(
                    value: _remainingMs / room.round!.timeLimitMs,
                    backgroundColor: Colors.white10,
                    color:
                        _remainingMs < 5000
                            ? AppColors.error
                            : AppColors.primary,
                  ),

                  // Game Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Question Prompt / Content
                          // Engine Renderer handles the prompt usually inside specific engines?
                          // Let's check EngineRenderer. It takes 'item'.
                          // Engines usually display prompt.
                          // But standard 'prompt' text might need to be shown outside if engine doesn't?
                          // Looking at 'engine_mcq.dart', it takes item and likely shows prompt?
                          // Wait, let me check 'engine_mcq.dart' source I read earlier.
                          // It wasn't fully read. But usually EngineRenderer just delegates.
                          // Standard 'WorksheetPage' shows prompt outside?
                          // Let's check 'worksheet_page.dart' snippet.
                          // It shows prompt inside a container before EngineRenderer?
                          // "Text(item.prompt...)"
                          _buildQuestionCard(
                            currentItem,
                            state,
                            room.round!.index,
                            locked,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    int round,
    int total,
    int myScore,
    int oppScore,
    String oppName,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOU',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$myScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'ROUND $round / $total',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(_remainingMs / 1000).ceil()}s',
                style: TextStyle(
                  color: _remainingMs < 5000 ? AppColors.error : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                oppName.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$oppScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    WorksheetItem item,
    ArenaSessionState state,
    int roundIndex,
    bool locked,
  ) {
    // Get existing answer value
    // Logic: EngineRenderer expects 'userAnswer' which might be String or List or Map.
    // 'answers' in state maps itemId -> ArenaAnswer.
    // ArenaAnswer doesn't store the *value* of the answer, just correctness/metadata?
    // Wait, let's check ArenaAnswer model.
    // ArenaAnswer: attempt, isCorrect, pointsAwarded, clientSentAt.
    // It DOES NOT store the actual value (e.g. "Paris").
    // This means we need to store the *current draft answer* locally in the widget state?
    // OR the controller should store it?
    // The controller state has 'answers' which are the *results*.
    // But for the UI to show what I selected (e.g. highlighting the selected MCQ option), I need the value.
    // Since 'ArenaAnswer' is for scoring, maybe I need a local state for 'currentValue'.
    // BUT, if I navigate away and back, I lose it?
    // The user requirement says "Optimistic UI".
    // Maybe we should store the value in the controller too?
    // The 'ArenaSessionController' has 'submitAnswer(dynamic answerValue, int attempt)'.
    // It validates it.
    // But where do we store the *value* so the UI stays consistent?
    // The user specs didn't include 'value' in ArenaAnswer (Firestore).
    // So we assume once submitted, we don't need to show the value?
    // NO, we need to show the locked state with the user's selection.
    // So we should probably persist the user's selection locally or in the controller.
    // Let's check 'ArenaSessionState'. It has `answers` map.
    // Maybe I should add `values` map to `ArenaSessionState` (local only, not synced to DB if not needed).
    // But 'ArenaAnswer' is what is synced.
    // If I want to show what the user selected, I should probably keep it in the Page State or Controller.
    // Since the Page rebuilds on stream updates, keeping it in Page State is risky if key changes.
    // But here, the Page stays for the whole game.
    // I will use a Map<String, dynamic> _localAnswers in the State.

    return Card(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.prompt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            EngineRenderer(
              item: item,
              userAnswer: _localValues[item.id],
              onAnswerChanged: (val) {
                if (locked) return;
                setState(() {
                  _localValues[item.id] = val;
                });

                // Some engines (MCQ, Tap) submit immediately?
                // User specs: "MCQ: Seçim anında submit."
                // "Fill: Input+Submit."
                // "Tap: Chip seçimi anında submit."
                // "Order: Drag-drop/swap + Submit."

                _handleAutoSubmit(item, val, state);
              },
              isLocked: locked,
            ),

            if (!locked && _requiresManualSubmit(item.engine))
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed:
                      () => _submitAnswer(item, _localValues[item.id], state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SUBMIT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  final Map<String, dynamic> _localValues = {};

  bool _requiresManualSubmit(EngineType type) {
    return type == EngineType.fill ||
        type == EngineType.order ||
        type == EngineType.transform ||
        type == EngineType.error_spotting ||
        type == EngineType.matching;
  }

  void _handleAutoSubmit(
    WorksheetItem item,
    dynamic value,
    ArenaSessionState state,
  ) {
    if (item.engine == EngineType.mcq || item.engine == EngineType.tap) {
      _submitAnswer(item, value, state);
    }
  }

  Future<void> _submitAnswer(
    WorksheetItem item,
    dynamic value,
    ArenaSessionState state,
  ) async {
    if (value == null) {
      return;
    }

    final controller = ref.read(
      arenaSessionControllerProvider(widget.roomId).notifier,
    );
    final currentAnswer = state.answers[item.id];
    final attempt = (currentAnswer?.attempt ?? 0) + 1;

    final isCorrect = await controller.submitAnswer(value, attempt);

    if (isCorrect) {
      // Feedback? The EngineRenderer handles locked state if correct (via locked prop).
    } else {
      // Feedback for wrong answer
      if (attempt < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wrong answer! Try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(milliseconds: 1000),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wrong answer! Locked.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
