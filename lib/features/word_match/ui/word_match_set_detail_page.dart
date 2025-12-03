import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/repositories/game_saved_words_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/word_match_providers.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';

enum SetDetailFilter { all, active, learned }

class WordMatchSetDetailPage extends ConsumerStatefulWidget {
  const WordMatchSetDetailPage({super.key, required this.setId});

  static const routeName = 'wordMatchSetDetail';

  final int setId;

  @override
  ConsumerState<WordMatchSetDetailPage> createState() =>
      _WordMatchSetDetailPageState();
}

class _WordMatchSetDetailPageState
    extends ConsumerState<WordMatchSetDetailPage> {
  SetDetailFilter _filter = SetDetailFilter.all;

  @override
  Widget build(BuildContext context) {
    final setAsync = ref.watch(_setProvider(widget.setId));
    final pairsAsync = ref.watch(_pairsProvider(widget.setId));
    final learnedStatusesAsync = ref.watch(
      _learnedStatusesProvider(widget.setId),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child:
              setAsync.valueOrNull != null
                  ? Text(setAsync.value!.name)
                  : const Text('Set Detayı'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
            child: setAsync.when(
              data: (set) {
                final isWordsFromGames = set.name == 'Words from Games';

                // "Words from Games" seti için duplicate temizleme (sadece bir kez)
                if (isWordsFromGames) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _autoCleanDuplicates(ref);
                  });
                }

                return pairsAsync.when(
                  data: (pairs) {
                    final learnedStatuses =
                        learnedStatusesAsync.valueOrNull ?? {};
                    final activeCount =
                        pairs
                            .where((p) => !(learnedStatuses[p.id] ?? false))
                            .length;

                    return Column(
                      children: [
                        // Header with stats and reset button
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark.withValues(alpha: 0.9),
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$activeCount / ${pairs.length} kelime aktif',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () => _showResetConfirmation(
                                            context,
                                            ref,
                                          ),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Sıfırla'),
                                    ),
                                  ),
                                  if (isWordsFromGames) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                            () =>
                                                _removeDuplicates(context, ref),
                                        icon: const Icon(
                                          Icons.cleaning_services,
                                        ),
                                        label: const Text('Tekrarları Temizle'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Filter chips
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'Hepsi',
                                isSelected: _filter == SetDetailFilter.all,
                                onTap:
                                    () => setState(
                                      () => _filter = SetDetailFilter.all,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Yalnızca aktif',
                                isSelected: _filter == SetDetailFilter.active,
                                onTap:
                                    () => setState(
                                      () => _filter = SetDetailFilter.active,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Yalnızca öğrenilen',
                                isSelected: _filter == SetDetailFilter.learned,
                                onTap:
                                    () => setState(
                                      () => _filter = SetDetailFilter.learned,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Word list
                        Expanded(child: _buildWordList(pairs, learnedStatuses)),
                      ],
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stack) =>
                          Center(child: Text('Kelimeler yüklenemedi: $error')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) =>
                      Center(child: Text('Set yüklenemedi: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(List<WordPair> pairs, Map<int, bool> learnedStatuses) {
    final filteredPairs =
        pairs.where((pair) {
          final isLearned = learnedStatuses[pair.id] ?? false;
          switch (_filter) {
            case SetDetailFilter.all:
              return true;
            case SetDetailFilter.active:
              return !isLearned;
            case SetDetailFilter.learned:
              return isLearned;
          }
        }).toList();

    if (filteredPairs.isEmpty) {
      return Center(
        child: Text(
          _filter == SetDetailFilter.learned
              ? 'Henüz öğrenilen kelime yok'
              : _filter == SetDetailFilter.active
              ? 'Tüm kelimeler öğrenilmiş'
              : 'Kelime bulunamadı',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPairs.length,
      itemBuilder: (context, index) {
        final pair = filteredPairs[index];
        final isLearned = learnedStatuses[pair.id] ?? false;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              pair.english,
              style: TextStyle(
                decoration: isLearned ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(pair.turkish),
            trailing: IconButton(
              icon:
                  isLearned
                      ? SvgPicture.asset(
                        'assets/icons/star.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.amber,
                          BlendMode.srcIn,
                        ),
                      )
                      : SvgPicture.asset(
                        'assets/icons/star_empty.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).iconTheme.color ?? Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
              onPressed: () => _toggleLearned(ref, pair.id, !isLearned),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showResetConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tüm öğrenilenleri sıfırla?'),
            content: const Text(
              'Tüm kelimelerin öğrenildi işareti kaldırılacak. Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sıfırla'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final repo = await ref.read(wordMatchRepoProvider.future);
        await repo.resetAllLearned(widget.setId);
        ref.invalidate(_learnedStatusesProvider(widget.setId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tüm öğrenilenler sıfırlandı')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _toggleLearned(WidgetRef ref, int pairId, bool learned) async {
    try {
      final repo = await ref.read(wordMatchRepoProvider.future);
      await repo.toggleLearned(pairId, learned);
      ref.invalidate(_learnedStatusesProvider(widget.setId));
    } catch (e) {
      // Error is silently handled - learned status will refresh on next build
      debugPrint('Error toggling learned: $e');
    }
  }

  Future<void> _removeDuplicates(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(gameSavedWordsRepositoryProvider);
      final removedCount =
          await repository.removeDuplicatesFromWordsFromGames();

      if (context.mounted) {
        // Refresh the pairs list
        ref.invalidate(_pairsProvider(widget.setId));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              removedCount > 0
                  ? '$removedCount tekrar eden kelime temizlendi'
                  : 'Tekrar eden kelime bulunamadı',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tekrarları temizlerken hata oluştu: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _autoCleanDuplicates(WidgetRef ref) async {
    try {
      final repository = ref.read(gameSavedWordsRepositoryProvider);
      final removedCount =
          await repository.removeDuplicatesFromWordsFromGames();

      if (removedCount > 0) {
        // Refresh the pairs list
        ref.invalidate(_pairsProvider(widget.setId));
        debugPrint(
          'Auto-cleaned $removedCount duplicates from Words from Games',
        );
      }
    } catch (e) {
      debugPrint('Error auto-cleaning duplicates: $e');
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

final _setProvider = FutureProvider.family<WordSet, int>((ref, setId) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  final set = await repo.getSet(setId);
  if (set == null) {
    throw StateError('Set bulunamadı');
  }
  return set;
});

final _pairsProvider = FutureProvider.family<List<WordPair>, int>((
  ref,
  setId,
) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  return repo.fetchPairs(setId);
});

final _learnedStatusesProvider = FutureProvider.family<Map<int, bool>, int>((
  ref,
  setId,
) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  return repo.getLearnedStatuses(setId);
});
