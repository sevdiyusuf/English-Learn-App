import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/word_match_providers.dart';
import '../logic/word_match_session_controller.dart';
import 'widgets/match_card.dart';

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
    // Invalidate to refresh learned statuses
    ref.invalidate(_learnedStatusesProvider);
  } catch (e) {
    debugPrint('Error toggling learned: $e');
  }
}

class PracticeMatchPage extends ConsumerStatefulWidget {
  const PracticeMatchPage({super.key, required this.setId});

  static const routeName = 'practiceMatch';

  final int setId;

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
        if (mounted) {
          _showSummary(state!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(wordMatchSessionControllerProvider(widget.setId));
    final controller = ref.read(
      wordMatchSessionControllerProvider(widget.setId).notifier,
    );

    // Listen to session state changes within build method
    ref.listen<AsyncValue<WordMatchSessionState>>(
      wordMatchSessionControllerProvider(widget.setId),
      (previous, next) => _handleSessionState(next),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          session.valueOrNull?.set.name ?? 'Eşleştirme',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.go('/word-match/sets'),
          tooltip: 'Set listesine dön',
        ),
        actions: [
          IconButton(
            tooltip: 'Nasıl oynanır?',
            icon: SvgPicture.asset(
              'assets/icons/info.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => _showHowToPlay(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background2.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: session.when(
                data:
                    (state) => _MatchBoard(
                      state: state,
                      onSelectLeft: controller.selectLeft,
                      onSelectRight: controller.selectRight,
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 8),
                          Text('Oturum açılamadı: $error'),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed:
                                () => ref.invalidate(
                                  wordMatchSessionControllerProvider(
                                    widget.setId,
                                  ),
                                ),
                            child: const Text('Tekrar dene'),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSummary(WordMatchSessionState state) async {
    if (!mounted) {
      return;
    }
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final accuracy =
            state.attempts == 0
                ? 0
                : ((state.correctAttempts / state.attempts) * 100).round();
        final message = () {
          if (state.correctAttempts == 0) {
            return 'Henüz doğru eşleşme yapmadın, bir tur daha dene 🙂';
          }
          if (accuracy >= 90) return 'Harika! Neredeyse kusursuz çalıştın 👏';
          if (accuracy >= 70) {
            return 'Gayet iyi, birkaç tekrar ile mükemmel olursun.';
          }
          if (accuracy >= 50) {
            return 'Fena değil, daha fazla tekrar accuracy oranını yükseltecek.';
          }
          return 'Zor bir set seçmiş olabilirsin, tekrar denemek gelişmene yardım eder.';
        }();

        return AlertDialog(
          title: const Text('Set tamamlandı!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam deneme: ${state.attempts}'),
              Text('Doğru eşleşme: ${state.correctAttempts}'),
              Text('Yanlış deneme: ${state.wrongAttempts}'),
              const SizedBox(height: 8),
              Text('Doğruluk oranı: %$accuracy'),
              const SizedBox(height: 8),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'list'),
              child: const Text('Set listesi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'retry'),
              child: const Text('Yeniden oyna'),
            ),
          ],
        );
      },
    );

    switch (result) {
      case 'retry':
        _summaryShown = false;
        ref.invalidate(wordMatchSessionControllerProvider(widget.setId));
        break;
      case 'list':
        if (mounted) {
          context.go('/word-match/sets');
        }
        break;
      default:
        _summaryShown = false;
    }
  }

  void _showHowToPlay(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Word Match nasıl oynanır?'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Solda Türkçe, sağda İngilizce kelime kartları bulunur.\n'
                  '• Önce soldan, sonra sağdan bir kart seçerek eşleştirme yapmaya çalış.\n'
                  '• Doğru eşleşmeler yeşil olarak işaretlenir ve listeden kalkar.\n'
                  '• Yanlış denemeler kırmızı olarak gösterilir ve istatistiklere yansır.',
                ),
                SizedBox(height: 12),
                Text(
                  'Amaç: En az hatayla tüm kelimeleri eşleştirmek. İstersen bitince yeniden oynayabilirsin.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }
}

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
    final remainingInRound =
        state.currentRoundPairs.length - state.solvedPairIds.length;
    final totalRemaining = remainingInRound + state.remainingPairs.length;
    final totalPairs =
        state.currentRoundPairs.length + state.remainingPairs.length;
    final solvedCount = totalPairs - totalRemaining;
    final progress =
        totalPairs == 0 ? 0.0 : solvedCount.clamp(0, totalPairs) / totalPairs;

    return Column(
      children: [
        _StatsHeader(
          state: state,
          totalRemaining: totalRemaining,
          progress: progress,
          solvedCount: solvedCount,
          totalPairs: totalPairs,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildColumn(context, ref, true)),
              const SizedBox(width: 12),
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
      itemCount: ids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final id = ids[index];
        final pair = state.pairById(id);
        final isSolved = state.solvedPairIds.contains(id);
        final isSelected =
            (isLeft ? state.selectedLeftId : state.selectedRightId) == id;
        final visualState = _visualStateFor(id, isLeft, isSolved);
        final text = isLeft ? pair.turkish : pair.english;

        // Get learned status from repository
        final learnedStatusesAsync = ref.watch(
          _learnedStatusesProvider(state.set.id),
        );
        final isLearned = learnedStatusesAsync.valueOrNull?[id] ?? false;

        return MatchCard(
          text: text,
          isSelected: isSelected,
          isSolved: isSolved,
          visualState: visualState,
          isLearned: isLearned,
          onTap: () => isLeft ? onSelectLeft(id) : onSelectRight(id),
          onLearnedToggle:
              isSolved ? () => _toggleLearned(ref, id, !isLearned) : null,
        );
      },
    );
  }

  MatchCardVisualState _visualStateFor(int id, bool isLeft, bool isSolved) {
    if (isSolved) {
      return MatchCardVisualState.correct;
    }
    if (state.attemptState == MatchAttemptState.correct) {
      final matchId = isLeft ? state.attemptLeftId : state.attemptRightId;
      if (matchId == id) {
        return MatchCardVisualState.correct;
      }
    } else if (state.attemptState == MatchAttemptState.wrong) {
      final matchId = isLeft ? state.attemptLeftId : state.attemptRightId;
      if (matchId == id) {
        return MatchCardVisualState.wrong;
      }
    }
    return MatchCardVisualState.normal;
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.state,
    required this.totalRemaining,
    required this.progress,
    required this.solvedCount,
    required this.totalPairs,
  });

  final WordMatchSessionState state;
  final int totalRemaining;
  final double progress;
  final int solvedCount;
  final int totalPairs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Doğru',
                value: state.correctAttempts.toString(),
                color: theme.colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                label: 'Yanlış',
                value: state.wrongAttempts.toString(),
                color: theme.colorScheme.errorContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                label: 'Kalan',
                value: totalRemaining.toString(),
                color: AppColors.surfaceDark.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (totalPairs > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İlerleme: $solvedCount / $totalPairs',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
