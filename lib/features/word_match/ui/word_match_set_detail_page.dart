import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/repositories/game_saved_words_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/models/app_user.dart';
import '../../moderation/ugc_policy_gate.dart';
import '../data/word_match_providers.dart';
import '../data/word_match_share_repo.dart';
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
      body: GradientBackground(
        child: SafeArea(
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
                      pairs.where((p) => learnedStatuses[p.id] ?? false).length;

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$activeCount / ${pairs.length} kelime aktif',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () => _shareSet(context, ref, set),
                                  tooltip: 'Paylaş',
                                ),
                              ],
                            ),
                            if (!set.isBuiltin) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<SetVisibility>(
                                  segments: const [
                                    ButtonSegment(
                                      value: SetVisibility.private,
                                      label: Text('Gizli'),
                                      icon: Icon(Icons.lock_outline, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: SetVisibility.friendsOnly,
                                      label: Text('Arkadaşlar'),
                                      icon: Icon(
                                        Icons.people_outline,
                                        size: 16,
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: SetVisibility.public,
                                      label: Text('Herkes'),
                                      icon: Icon(Icons.public, size: 16),
                                    ),
                                  ],
                                  selected: {set.visibility},
                                  onSelectionChanged: (newSelection) {
                                    _updateVisibility(
                                      ref,
                                      set.id,
                                      newSelection.first,
                                    );
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    textStyle: WidgetStateProperty.all(
                                      const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
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
                                          () => _removeDuplicates(context, ref),
                                      icon: const Icon(Icons.cleaning_services),
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
                              label: 'Kaydedilen Kelimeler',
                              isSelected: _filter == SetDetailFilter.active,
                              onTap:
                                  () => setState(
                                    () => _filter = SetDetailFilter.active,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Yalnızca pasif',
                              isSelected: _filter == SetDetailFilter.learned,
                              onTap:
                                  () => setState(
                                    () => _filter = SetDetailFilter.learned,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Row(
                          children: const [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Aktif = zorlandığım kelimeler',
                              style: TextStyle(fontSize: 11),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.star_border,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Pasif = bekleyen kelimeler',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Word list + "kelimeleri eşleştir" butonu
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildWordList(pairs, learnedStatuses),
                            ),
                            if (_filter == SetDetailFilter.active)
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.push(
                                      '/word-match/practice/${widget.setId}?mode=active',
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Kelimeleri eşleştir'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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
      ),
    );
  }

  Widget _buildWordList(List<WordPair> pairs, Map<int, bool> learnedStatuses) {
    // Remove duplicates based on english+turkish combination
    final seen = <String>{};
    final uniquePairs = <WordPair>[];
    for (final pair in pairs) {
      final key =
          '${pair.english.toLowerCase().trim()}_${pair.turkish.toLowerCase().trim()}';
      if (!seen.contains(key) &&
          pair.english.trim().isNotEmpty &&
          pair.turkish.trim().isNotEmpty) {
        seen.add(key);
        uniquePairs.add(pair);
      }
    }

    final filteredPairs =
        uniquePairs.where((pair) {
          final isLearned = learnedStatuses[pair.id] ?? false;
          switch (_filter) {
            case SetDetailFilter.all:
              return true;
            case SetDetailFilter.active:
              return isLearned;
            case SetDetailFilter.learned:
              return !isLearned;
          }
        }).toList();

    if (filteredPairs.isEmpty) {
      return Center(
        child: Text(
          _filter == SetDetailFilter.active
              ? 'Henüz aktif (yıldızlı) kelime yok'
              : _filter == SetDetailFilter.learned
              ? 'Henüz pasif kelime yok'
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
            title: const Text('Tüm aktif (yıldızlı) kelimeleri sıfırla?'),
            content: const Text(
              'Tüm kelimelerin aktif (yıldızlı) işareti kaldırılacak. Bu işlem geri alınamaz.',
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
        ref.invalidate(wordMatchLearnedStatusesProvider(widget.setId));
        ref.invalidate(wordMatchPairsProvider(widget.setId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tüm aktif (yıldızlı) işaretler sıfırlandı'),
            ),
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
      // Invalidate both learned statuses and pairs to ensure UI updates
      // Use public providers for consistency
      ref.invalidate(wordMatchLearnedStatusesProvider(widget.setId));
      ref.invalidate(wordMatchPairsProvider(widget.setId));
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durum güncellenemedi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
        ref.invalidate(wordMatchPairsProvider(widget.setId));
        ref.invalidate(wordMatchLearnedStatusesProvider(widget.setId));

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

  Future<void> _updateVisibility(
    WidgetRef ref,
    int setId,
    SetVisibility visibility,
  ) async {
    try {
      final repo = await ref.read(wordMatchRepoProvider.future);
      await repo.updateSetVisibility(setId, visibility);
      ref.invalidate(wordMatchSetProvider(setId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görünürlük güncellendi: ${visibility.name}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görünürlük güncellenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareSet(
    BuildContext context,
    WidgetRef ref,
    WordSet set,
  ) async {
    try {
      // Ensure we have a user (anonymous or logged in)
      final notifier = ref.read(authControllerProvider.notifier);
      final AppUser user =
          (ref.read(authControllerProvider).value) ??
          await notifier.ensureAnonymousGuestSignedIn();
      if (!context.mounted) return;
      if (!await ensureCurrentUgcAcceptance(context, ref)) return;
      if (!context.mounted) return;

      // Show a simple loading dialog
      if (context.mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return const Center(child: CircularProgressIndicator());
          },
        );
      }

      final shareRepo = await ref.read(wordMatchShareRepositoryProvider.future);
      final shareId = await shareRepo.createShareForLocalSet(
        owner: user,
        localSetId: set.id,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop(); // close dialog

      final base = Uri.base;
      // Route: /s/{shareId} handled by GoRouter
      final link = '${base.origin}/#/s/$shareId';

      if (kIsWeb) {
        // Web: linki kopyala
        await Clipboard.setData(ClipboardData(text: link));
        if (context.mounted) {
          ref
              .read(notificationServiceProvider)
              .showSuccess(
                title: 'Bağlantı Kopyalandı',
                message: 'Paylaşım bağlantısı panoya kopyalandı.',
              );
        }
      } else {
        // Mobile / desktop: sistem paylaşım ekranı
        await SharePlus.instance.share(
          ShareParams(text: link, subject: 'Kelime setimi dene: ${set.name}'),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      // Ensure any loading dialog is closed if still open
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst || route is! PopupRoute);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Paylaşım oluşturulamadı: $e')));
    }
  }

  Future<void> _autoCleanDuplicates(WidgetRef ref) async {
    try {
      final repository = ref.read(gameSavedWordsRepositoryProvider);
      final removedCount =
          await repository.removeDuplicatesFromWordsFromGames();

      if (removedCount > 0) {
        // Refresh the pairs list
        ref.invalidate(wordMatchPairsProvider(widget.setId));
        ref.invalidate(wordMatchLearnedStatusesProvider(widget.setId));
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

// Public providers so they can be invalidated from other pages
final wordMatchSetProvider = FutureProvider.family<WordSet, int>((
  ref,
  setId,
) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  final set = await repo.getSet(setId);
  if (set == null) {
    throw StateError('Set bulunamadı');
  }
  return set;
});

final wordMatchPairsProvider = FutureProvider.family<List<WordPair>, int>((
  ref,
  setId,
) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  return repo.fetchPairs(setId);
});

final wordMatchLearnedStatusesProvider =
    FutureProvider.family<Map<int, bool>, int>((ref, setId) async {
      final repo = await ref.watch(wordMatchRepoProvider.future);
      return repo.getLearnedStatuses(setId);
    });

// Keep private aliases for backward compatibility within this file
final _setProvider = wordMatchSetProvider;
final _pairsProvider = wordMatchPairsProvider;
final _learnedStatusesProvider = wordMatchLearnedStatusesProvider;
