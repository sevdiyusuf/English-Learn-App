import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Not: Bu importların senin projende doğru yerleri gösterdiğinden emin ol
import '../data/word_match_providers.dart';
import '../logic/word_match_session_controller.dart';
import 'widgets/match_card.dart';

// --- Providers & Logic ---

final _learnedStatusesProvider = FutureProvider.family<Map<int, bool>, int>((
  ref,
  setId,
) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  return repo.getLearnedStatuses(setId);
});

Future<void> _toggleLearned(WidgetRef ref, int pairId, bool learned) async {
  try {
    final repo = await ref.read(wordMatchRepoProvider.future);
    await repo.toggleLearned(pairId, learned);
    ref.invalidate(_learnedStatusesProvider);
  } catch (e) {
    debugPrint('Error toggling learned: $e');
  }
}

// --- Page Widget ---

class PracticeMatchPage extends ConsumerStatefulWidget {
  const PracticeMatchPage({
    super.key,
    required this.setId,
    required this.usePassiveOnly,
  });

  static const routeName = 'practiceMatch';
  final int setId;
  final bool usePassiveOnly;

  @override
  ConsumerState<PracticeMatchPage> createState() => _PracticeMatchPageState();
}

class _PracticeMatchPageState extends ConsumerState<PracticeMatchPage> {
  bool _summaryShown = false;

  void _handleSessionState(AsyncValue<WordMatchSessionState> value) {
    final state = value.valueOrNull;
    if (state?.isComplete == true && !_summaryShown) {
      _summaryShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSummary(state!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = WordMatchSessionArgs(
      setId: widget.setId,
      usePassiveOnly: widget.usePassiveOnly,
    );
    final session = ref.watch(wordMatchSessionControllerProvider(args));
    final controller = ref.read(
      wordMatchSessionControllerProvider(args).notifier,
    );

    ref.listen<AsyncValue<WordMatchSessionState>>(
      wordMatchSessionControllerProvider(args),
      (previous, next) => _handleSessionState(next),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          session.valueOrNull?.set.name.toUpperCase() ?? 'EŞLEŞTİRME',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => context.go('/word-match/sets'),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _showHowToPlay(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: session.when(
            data:
                (state) => _MatchBoard(
                  state: state,
                  onSelectLeft: controller.selectLeft,
                  onSelectRight: controller.selectRight,
                ),
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            error:
                (error, _) => _ErrorState(
                  error: error.toString(),
                  onRetry:
                      () => ref.invalidate(
                        wordMatchSessionControllerProvider(args),
                      ),
                ),
          ),
        ),
      ),
    );
  }

  // --- Summary Dialog (Modernize Edilmiş) ---
  Future<void> _showSummary(WordMatchSessionState state) async {
    final accuracy =
        state.attempts == 0
            ? 0
            : ((state.correctAttempts / state.attempts) * 100).round();

    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black87,
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.amber,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Set Tamamlandı!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryRow(
                    label: 'Doğruluk',
                    value: '%$accuracy',
                    color: Colors.greenAccent,
                  ),
                  _SummaryRow(
                    label: 'Hamle',
                    value: '${state.attempts}',
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    accuracy >= 80
                        ? 'Harika bir iş çıkardın! 🔥'
                        : 'Güzel deneme, gelişmeye devam et! 💪',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'list'),
                  child: const Text(
                    'LİSTE',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'TEKRAR DENE',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'retry') {
      _summaryShown = false;
      final args = WordMatchSessionArgs(
        setId: widget.setId,
        usePassiveOnly: widget.usePassiveOnly,
      );
      ref.invalidate(wordMatchSessionControllerProvider(args));
    } else if (result == 'list') {
      if (mounted) context.go('/word-match/sets');
    }
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Nasıl Oynanır?',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Sol taraftaki Türkçe kelimelerle sağ taraftaki İngilizce karşılıklarını eşleştir.\n\nHer doğru eşleşme puan kazandırır ve kartları temizler!',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ANLADIM'),
                ),
              ],
            ),
          ),
    );
  }
}

// --- Board & Layout ---

class _MatchBoard extends ConsumerWidget {
  const _MatchBoard({
    required this.state,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  final WordMatchSessionState state;
  final void Function(int id) onSelectLeft;
  final void Function(int id) onSelectRight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solvedCount =
        state.currentRoundPairs.length +
        state.remainingPairs.length -
        (state.currentRoundPairs.length -
            state.solvedPairIds.length +
            state.remainingPairs.length);
    final totalPairs =
        state.currentRoundPairs.length + state.remainingPairs.length;
    final progress = totalPairs == 0 ? 0.0 : solvedCount / totalPairs;

    return Column(
      children: [
        _ModernStatsHeader(
          state: state,
          progress: progress,
          solvedCount: solvedCount,
          totalPairs: totalPairs,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildColumn(context, ref, true)),
              const SizedBox(width: 16),
              Expanded(child: _buildColumn(context, ref, false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(BuildContext context, WidgetRef ref, bool isLeft) {
    final ids = isLeft ? state.leftOrder : state.rightOrder;
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: ids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final id = ids[index];
        final pair = state.pairById(id);
        final isSolved = state.solvedPairIds.contains(id);
        final isSelected =
            (isLeft ? state.selectedLeftId : state.selectedRightId) == id;

        final learnedStatusesAsync = ref.watch(
          _learnedStatusesProvider(state.set.id),
        );
        final isLearned = learnedStatusesAsync.valueOrNull?[id] ?? false;

        return MatchCard(
          text: isLeft ? pair.turkish : pair.english,
          isSelected: isSelected,
          isSolved: isSolved,
          visualState: _visualStateFor(id, isLeft, isSolved),
          isLearned: isLearned,
          onTap: () => isLeft ? onSelectLeft(id) : onSelectRight(id),
          onLearnedToggle: () => _toggleLearned(ref, id, !isLearned),
        );
      },
    );
  }

  MatchCardVisualState _visualStateFor(int id, bool isLeft, bool isSolved) {
    if (isSolved) return MatchCardVisualState.correct;
    final matchId = isLeft ? state.attemptLeftId : state.attemptRightId;
    if (matchId == id) {
      if (state.attemptState == MatchAttemptState.correct) {
        return MatchCardVisualState.correct;
      }
      if (state.attemptState == MatchAttemptState.wrong) {
        return MatchCardVisualState.wrong;
      }
    }
    return MatchCardVisualState.normal;
  }
}

// --- UI Components ---

class _ModernStatsHeader extends StatelessWidget {
  const _ModernStatsHeader({
    required this.state,
    required this.progress,
    required this.solvedCount,
    required this.totalPairs,
  });
  final WordMatchSessionState state;
  final double progress;
  final int solvedCount;
  final int totalPairs;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'DOĞRU',
                    value: '${state.correctAttempts}',
                    icon: Icons.check_circle,
                    color: Colors.greenAccent,
                  ),
                  _StatItem(
                    label: 'HATALI',
                    value: '${state.wrongAttempts}',
                    icon: Icons.error,
                    color: Colors.redAccent,
                  ),
                  _StatItem(
                    label: 'KALAN',
                    value: '${totalPairs - solvedCount}',
                    icon: Icons.hourglass_bottom,
                    color: Colors.amberAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 10,
                    width: (MediaQuery.of(context).size.width - 72) * progress,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.cyanAccent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}
