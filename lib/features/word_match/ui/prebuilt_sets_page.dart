import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../data/word_match_providers.dart';
import '../models/word_set.dart';
import '../logic/word_match_sets_controller.dart';

// ignore: unused_element
final _learnedStatusesProvider = FutureProvider.family<Map<int, bool>, int>((
  ref,
  setId,
) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  return repo.getLearnedStatuses(setId);
});

final _pairCountProvider = FutureProvider.family<int, int>((ref, setId) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  return repo.countPairs(setId);
});

class PreBuiltSetsPage extends ConsumerWidget {
  const PreBuiltSetsPage({super.key});

  static const routeName = 'prebuiltSets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsState = ref.watch(preBuiltSetsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hazır Setler',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: setsState.when(
            data: (sets) => _PreBuiltSetsList(sets: sets),
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            error:
                (error, stack) => Center(
                  child: Text(
                    'Hata: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _PreBuiltSetsList extends ConsumerWidget {
  const _PreBuiltSetsList({required this.sets});

  final List<WordSet> sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ['A1', 'A2', 'B1', 'B2'];
    final allSetsState = ref.watch(wordMatchSetsControllerProvider);
    final allSets = allSetsState.valueOrNull?.sets ?? [];
    final wordsFromGamesOverview = allSets.where((s) => s.set.name == 'Words from Games').firstOrNull;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: levels.length + 2,
      itemBuilder: (context, index) {
        if (index == levels.length) {
          if (wordsFromGamesOverview == null) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: 16),
              _WordsFromGamesCard(overview: wordsFromGamesOverview),
              const SizedBox(height: 16),
            ],
          );
        }

        if (index == levels.length + 1) {
          return const Column(
            children: [
              SizedBox(height: 16),
              _IrregularVerbsHeroCard(),
              SizedBox(height: 32),
            ],
          );
        }

        final level = levels[index];
        final levelSets = sets.where((s) => s.name.startsWith(level)).toList();

        // Sort by difficulty (Kolay, Orta, Zor)
        levelSets.sort((a, b) {
          final order = {'Kolay': 0, 'Orta': 1, 'Zor': 2};
          final aDiff = a.name.split(' ').last;
          final bDiff = b.name.split(' ').last;
          return (order[aDiff] ?? 0).compareTo(order[bDiff] ?? 0);
        });

        if (levelSets.isEmpty) return const SizedBox.shrink();

        return _LevelGroup(level: level, sets: levelSets);
      },
    );
  }
}

class _LevelGroup extends ConsumerStatefulWidget {
  const _LevelGroup({required this.level, required this.sets});

  final String level;
  final List<WordSet> sets;

  @override
  ConsumerState<_LevelGroup> createState() => _LevelGroupState();
}

class _LevelGroupState extends ConsumerState<_LevelGroup> {
  bool _isExpanded = false;

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return const Color(0xFF4FD1C5); // Turkuaz/Yeşilimsi
      case 'A2':
        return const Color(0xFF63B3ED); // Mavi
      case 'B1':
        return const Color(0xFFF6AD55); // Turuncu
      case 'B2':
        return const Color(0xFFF687B3); // Pembe
      default:
        return Colors.amber;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'A1':
        return Icons.child_care;
      case 'A2':
        return Icons.directions_walk;
      case 'B1':
        return Icons.directions_run;
      case 'B2':
        return Icons.rocket_launch;
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(widget.level);
    final levelIcon = _getLevelIcon(widget.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _isExpanded
                      ? levelColor.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(levelIcon, color: levelColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.level} Seviyesi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.sets.length} Kelime Seti',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: levelColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: levelColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.sets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _PreBuiltSetCard(set: widget.sets[index]);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!_isExpanded) const SizedBox(height: 4),
      ],
    );
  }
}

class _PreBuiltSetCard extends ConsumerWidget {
  const _PreBuiltSetCard({required this.set});

  final WordSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = set.name.split(' ').last;
    final stripeColor = _getDifficultyColor(difficulty);

    // Watch learned statuses to calculate active count
    final learnedStatusesAsync = ref.watch(_learnedStatusesProvider(set.id));
    final learnedStatuses = learnedStatusesAsync.valueOrNull;

    // Watch total pair count
    final pairCountAsync = ref.watch(_pairCountProvider(set.id));
    final pairCount = pairCountAsync.valueOrNull;

    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF1E293B,
        ).withValues(alpha: 0.98), // Daha az şeffaf
        borderRadius: BorderRadius.circular(16), // Daha yumuşak köşeler
        border: Border.all(
          color: stripeColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _startPracticeDirect(context, set.id),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 7, // Daha kalın şerit
                decoration: BoxDecoration(color: stripeColor),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, // Daha geniş padding
                    vertical: 14, // Daha yüksek padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                              8,
                            ), // Daha büyük ikon kutusu
                            decoration: BoxDecoration(
                              color: stripeColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getDifficultyIcon(difficulty),
                              color: stripeColor,
                              size: 20, // Daha büyük ikon
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  set.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17, // Daha büyük başlık
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '$difficulty seviye kelime seti',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: stripeColor.withValues(alpha: 0.5),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SmallChip(
                            label: 'Kelimeler: ${pairCount ?? '...'}',
                            icon: Icons.format_list_bulleted,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          _SmallChip(
                            label:
                                'Yıldızlı: ${learnedStatuses != null ? learnedStatuses.values.where((v) => v).length : '...'}',
                            icon: Icons.star_border,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          _SmallChip(
                            label: 'Detay',
                            icon: Icons.info_outline,
                            color: Colors.white.withValues(alpha: 0.8),
                            onTap: () => _showSetDetail(context, set.id),
                          ),
                          const Spacer(),
                          Material(
                            color: stripeColor,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap:
                                  () => _startPracticeDirect(context, set.id),
                              borderRadius: BorderRadius.circular(14),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'BAŞLA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startPracticeDirect(BuildContext context, int setId) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.play_arrow,
                  color: Colors.greenAccent,
                ),
                title: const Text(
                  'Kelime Eşleştirme',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/word-match/practice/$setId');
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.blueAccent),
                title: const Text(
                  'Test Modu',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/word-match/test/$setId');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showSetDetail(BuildContext context, int setId) {
    context.push('/word-match/detail/$setId');
  }

  IconData _getDifficultyIcon(String diff) {
    switch (diff) {
      case 'Kolay':
        return Icons.sentiment_satisfied_alt;
      case 'Orta':
        return Icons.sentiment_neutral;
      case 'Zor':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.star;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff) {
      case 'Kolay':
        return const Color(0xFF26A69A); // Turkuaz
      case 'Orta':
        return const Color(0xFFFF9800); // Turuncu
      case 'Zor':
        return const Color(0xFFEF5350); // Kırmızımsı
      default:
        return Colors.amber;
    }
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordsFromGamesCard extends ConsumerWidget {
  const _WordsFromGamesCard({required this.overview});

  final WordSetOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final set = overview.set;
    final stripeColor = const Color(0xFFFF9800); // Turuncu

    final learnedStatusesAsync = ref.watch(_learnedStatusesProvider(set.id));
    final learnedStatuses = learnedStatusesAsync.valueOrNull;
    final pairCountAsync = ref.watch(_pairCountProvider(set.id));
    final pairCount = pairCountAsync.valueOrNull;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stripeColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _startPracticeDirect(context, set.id);
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 7,
                decoration: BoxDecoration(color: stripeColor),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10, // Kucuk yapildi 4/5 orantili (14 -> 10)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: stripeColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sports_esports,
                              color: stripeColor,
                              size: 16, // Kucultuldu (20 -> 16)
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Word from Games',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14, // Kucultuldu (17 -> 14)
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Oyunlardan öğrenilen kelimeler',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 9, // Kucultuldu (11 -> 9)
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: stripeColor.withValues(alpha: 0.5),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _SmallChip(
                            label: 'Kelimeler: ${pairCount ?? '...'}',
                            icon: Icons.format_list_bulleted,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 6),
                          _SmallChip(
                            label: 'Yıldızlı: ${learnedStatuses != null ? learnedStatuses.values.where((v) => v).length : '...'}',
                            icon: Icons.star_border,
                            color: Colors.greenAccent,
                          ),
                          const Spacer(),
                          Material(
                            color: stripeColor,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _startPracticeDirect(context, set.id),
                              borderRadius: BorderRadius.circular(10),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'BAŞLA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startPracticeDirect(BuildContext context, int setId) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.play_arrow,
                  color: Colors.greenAccent,
                ),
                title: const Text(
                  'Kelime Eşleştirme',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/word-match/practice/$setId');
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.blueAccent),
                title: const Text(
                  'Test Modu',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/word-match/test/$setId');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _IrregularVerbsHeroCard extends StatelessWidget {
  const _IrregularVerbsHeroCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/irregular-verbs'),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF232526), Color(0xFF414345)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ÖZEL MOD',
                            style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Irregular Verbs',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Düzensiz fiilleri kolayca öğrenin',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
