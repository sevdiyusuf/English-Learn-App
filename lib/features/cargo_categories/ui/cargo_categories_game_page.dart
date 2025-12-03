import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/game_saved_words_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../data/cargo_service.dart';
import '../logic/cargo_categories_controller.dart';
import '../models/cargo_categories_state.dart';
import '../models/cargo_word.dart';
import 'widgets/category_dock.dart';
import 'widgets/conveyor_area.dart';
import 'widgets/score_dialog.dart';

class CargoCategoriesGamePage extends ConsumerStatefulWidget {
  const CargoCategoriesGamePage({super.key});

  static const routeName = 'cargoCategoriesGame';

  @override
  ConsumerState<CargoCategoriesGamePage> createState() =>
      _CargoCategoriesGamePageState();
}

class _CargoCategoriesGamePageState
    extends ConsumerState<CargoCategoriesGamePage> {
  bool _scoreDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cargoCategoriesControllerProvider);

    // Show score dialog when game finishes
    if (state.isFinished && !_scoreDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scoreDialogShown = true;
        _showScoreDialog(context, state);
      });
    }

    // Oyun başlamamışsa ve bitmemişse setup'a yönlendir
    // Ancak currentWord varsa oyun başlamış demektir, bekle
    if (!state.isRunning && !state.isFinished && state.currentWord == null) {
      // Redirect to setup if game not started
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/cargo-categories/setup');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Handle back button - stop game and go back to setup
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.isRunning) {
          // Stop the game when back button is pressed
          ref.read(cargoCategoriesControllerProvider.notifier).reset();
          if (context.mounted) {
            context.go('/cargo-categories/setup');
          }
        }
      },
      child: _buildGameContent(context, state),
    );
  }

  Widget _buildGameContent(BuildContext context, CargoCategoriesState state) {
    final selectedCategories =
        state.selectedCategories
            .map((id) => CargoService.instance.getCategoryById(id))
            .where((cat) => cat != null)
            .cast()
            .toList();

    if (selectedCategories.length != 3) {
      return const Scaffold(body: Center(child: Text('Kategori bulunamadı')));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundDark,
                      AppColors.backgroundMedium,
                    ],
                  ),
                ),
              ),
            ),

            // Top bar: Timer and Score - En üstte, her zaman görünür
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopStatusBar(
                remainingTime: state.remainingTime,
                score: state.score,
              ),
            ),

            // Save bar above categories
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: _SaveBar(
                onReceiveWord: (word) {
                  // Kelimeyi kaydet (async ama await etmeden devam et)
                  _saveWord(context, word);
                  // Kelime kaydedildikten sonra yeni kelime yükle
                  if (state.isRunning && !state.isFinished) {
                    ref
                        .read(cargoCategoriesControllerProvider.notifier)
                        .handleWordSaved();
                  }
                },
              ),
            ),

            // Category docks in the center - Save bar'ın altında
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 140),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      selectedCategories.map((category) {
                        return CategoryDock(
                          category: category,

                          // State'ten gelen renk/durum bilgileri
                          isHighlighted:
                              state.highlightedCategoryId == category.id,
                          isWrong: state.wrongCategoryId == category.id,

                          // 1. Tıklama (Tap) Durumu
                          onTap: () {
                            ref
                                .read(
                                  cargoCategoriesControllerProvider.notifier,
                                )
                                .handleAnswer(category.id);
                          },

                          // 2. Sürükle-Bırak (Drag) Durumu - KRİTİK KISIM
                          onReceiveWord: (droppedWord) {
                            debugPrint(
                              "PAGE: Kelime Drop Edildi: ${droppedWord.word}",
                            );
                            ref
                                .read(
                                  cargoCategoriesControllerProvider.notifier,
                                )
                                .handleAnswer(
                                  category.id,
                                  droppedWord: droppedWord,
                                );
                          },
                        );
                      }).toList(),
                ),
              ),
            ),

            // Conveyor belt at the bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: ConveyorArea(
                currentWord: state.currentWord,
                travelDuration:
                    state.selectedDifficulty?.travelDuration ??
                    const Duration(seconds: 2),
                onTimeout: () {
                  ref
                      .read(cargoCategoriesControllerProvider.notifier)
                      .handleTimeout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreDialog(BuildContext context, CargoCategoriesState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ScoreDialog(
            score: state.score,
            correctCount: state.correctCount,
            wrongCount: state.wrongCount,
            missedCount: state.missedCount,
            difficulty: state.selectedDifficulty,
            selectedCategories: state.selectedCategories,
            onPlayAgain: () {
              Navigator.of(context).pop();
              _scoreDialogShown = false;
              ref.read(cargoCategoriesControllerProvider.notifier).reset();
              context.go('/cargo-categories/setup');
            },
            onBack: () {
              Navigator.of(context).pop();
              ref.read(cargoCategoriesControllerProvider.notifier).reset();
              context.go('/cargo-categories/setup');
            },
          ),
    );
  }

  Future<void> _saveWord(BuildContext context, CargoWord word) async {
    try {
      final repository = ref.read(gameSavedWordsRepositoryProvider);
      final saved = await repository.saveToWordsFromGames(
        english: word.word,
        turkish: word.translate,
        sourceGame: 'cargo_categories',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? '"${word.word}" kelimesi "Words from Games" setine kaydedildi.'
                  : 'Bu kelime zaten kayıtlı.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilemedi, lütfen tekrar deneyin: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onReceiveWord});

  final Function(CargoWord) onReceiveWord;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CargoWord>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onReceiveWord(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          height: 50,
          decoration: BoxDecoration(
            color:
                isHovering
                    ? AppColors.primary.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isHovering
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/bookmark.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.9),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Bilmediğin kelimeleri buraya sürükle',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  const _TopStatusBar({required this.remainingTime, required this.score});

  final Duration remainingTime;
  final int score;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _formatDuration(remainingTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
