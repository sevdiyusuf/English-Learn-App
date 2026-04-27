import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/word_match/logic/word_match_sets_controller.dart';
import '../../models/word_echo_config.dart';

class PersonalEchoSetSelector extends ConsumerWidget {
  const PersonalEchoSetSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(wordEchoConfigProvider);
    final setsAsync = ref.watch(wordMatchSetsControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Personal Echo - Set Seç',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Content
          Expanded(
            child: setsAsync.when(
              data: (state) {
                // Show user-created sets AND "Words from Games" built-in set
                final userSets =
                    state.sets
                        .where(
                          (overview) =>
                              !overview.set.isBuiltin ||
                              overview.set.name == 'Words from Games',
                        )
                        .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Global option
                    _SetOption(
                      title: 'Tümü (Global)',
                      description: 'Tüm kelimeleri kullan',
                      pairCount: null,
                      isSelected: config.selectedWordSetId == null,
                      onTap: () {
                        ref
                            .read(wordEchoConfigProvider.notifier)
                            .clearSelection();
                        Navigator.of(context).pop();
                      },
                    ),
                    // User sets
                    ...userSets.map(
                      (overview) => _SetOption(
                        title: overview.set.name,
                        description: '${overview.pairCount} kelime',
                        pairCount: overview.pairCount,
                        isSelected: config.selectedWordSetId == overview.set.id,
                        isEnabled: overview.pairCount >= 9,
                        onTap: () {
                          if (overview.pairCount < 9) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Yetersiz kelime sayısı. Set seçmek için en az 9 kelime olmalıdır.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          ref
                              .read(wordEchoConfigProvider.notifier)
                              .selectWordSet(overview.set.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    if (userSets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Henüz oluşturulmuş set yok.\nWord Match\'ten set oluşturabilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Setler yüklenemedi: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetOption extends StatelessWidget {
  const _SetOption({
    required this.title,
    required this.description,
    required this.pairCount,
    required this.isSelected,
    this.isEnabled = true,
    required this.onTap,
  });

  final String title;
  final String description;
  final int? pairCount;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isEnabled
            ? (isSelected ? AppColors.primary : Colors.white54)
            : Colors.white24;
    final textColor =
        isEnabled
            ? (isSelected ? Colors.white : Colors.white70)
            : Colors.white38;
    final descriptionColor =
        isEnabled
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected && isEnabled
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color:
                    isSelected && isEnabled
                        ? AppColors.primary
                        : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: effectiveColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight:
                                  isSelected && isEnabled
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (!isEnabled && pairCount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Min 9',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (pairCount != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(color: descriptionColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
