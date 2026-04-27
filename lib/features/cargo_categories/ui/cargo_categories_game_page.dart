import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/game_saved_words_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/cargo_categories_controller.dart';
import '../models/cargo_categories_state.dart';
import '../models/cargo_word.dart';
import 'widgets/cargo_column.dart' show CargoColumnWidget;
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
  // Modal yerine durum değişkeni ile kontrol edilen görünürlük
  bool _isScorePanelVisible = false;
  bool _gameFinishedHandled = false;
  bool _showTranslate = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cargoCategoriesControllerProvider);

    // Oyun bittiğinde paneli tetikle
    if (state.isFinished &&
        !_gameFinishedHandled &&
        !state.isRegrouping &&
        state.chosenCategories.isNotEmpty) {
      _gameFinishedHandled = true;
      // Animasyonun pürüzsüz başlaması için ufak gecikme
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _isScorePanelVisible = true;
            });
          }
        });
      });
    }

    // Oyun başlamadıysa setup'a yönlendir
    if (!state.isRunning &&
        !state.isFinished &&
        state.chosenCategories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (context.mounted) {
            final currentState = ref.read(cargoCategoriesControllerProvider);
            if (!currentState.isRunning &&
                !currentState.isFinished &&
                currentState.chosenCategories.isEmpty) {
              context.go('/cargo-categories/setup');
            }
          }
        });
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Kategori kontrolü
    if (state.chosenCategories.length != 3) {
      return const Scaffold(body: Center(child: Text('Kategori bulunamadı')));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.isRunning) {
          ref.read(cargoCategoriesControllerProvider.notifier).reset();
          if (context.mounted) {
            context.go('/cargo-categories/setup');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          // Stack kullanarak Skor Panelini sayfanın bir parçası yapıyoruz (Modal değil)
          child: Stack(
            children: [
              // 1. Arka Plan
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

              // 2. Oyun Alanı (En altta kalacak, etkileşime açık)
              Column(
                children: [
                  _buildTopBar(context, state),
                  _buildGameArea(context, state),
                  _buildConveyorArea(context, state),
                ],
              ),

              // 3. Skor Paneli Overlay'i
              // AnimatedSlide ile aşağıdan yukarı kayarak gelir
              // IgnorePointer kullanmıyoruz, böylece sadece panelin kendisine tıklanır, arkası boş kalır.
              if (state.isFinished) // Sadece oyun bittiğinde render et
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedSlide(
                    offset:
                        _isScorePanelVisible
                            ? Offset.zero
                            : const Offset(0, 1.2),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuart,
                    child: _buildScorePanel(context, state),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, CargoCategoriesState state) {
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
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (state.isRunning) {
                    ref
                        .read(cargoCategoriesControllerProvider.notifier)
                        .reset();
                  }
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/cargo-categories/setup');
                  }
                },
                tooltip: 'Geri',
              ),
              const SizedBox(width: 8),
              Text(
                '${state.totalWordsPlaced} / 12',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              SvgPicture.asset(
                'assets/icons/speed.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.8),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(state.elapsedTime),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          FilledButton(
            onPressed:
                state.canCheck && !state.isFinished
                    ? () {
                      ref
                          .read(cargoCategoriesControllerProvider.notifier)
                          .checkSolution();
                    }
                    : null,
            style: FilledButton.styleFrom(
              backgroundColor:
                  state.canCheck && !state.isFinished
                      ? AppColors.success
                      : Colors.grey,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/local_shipping.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Doğrula'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(BuildContext context, CargoCategoriesState state) {
    return Expanded(
      child: AnimatedOpacity(
        opacity: state.isRegrouping ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          // Skor tablosu geldiğinde oyun alanını biraz yukarı kaydırabiliriz (isteğe bağlı)
          // veya olduğu gibi bırakabiliriz. Şimdilik olduğu gibi bırakıyoruz.
          child: Row(
            children: List.generate(3, (index) {
              final category = state.chosenCategories[index];
              final column =
                  state.columns.length > index
                      ? state.columns[index]
                      : const CargoColumn(words: []);

              return CargoColumnWidget(
                category: category,
                words: column.words,
                showCategoryName: state.showSolution,
                showTranslate: _showTranslate,
                onBookmarkTap: (word) => _saveWordToGames(context, word),
                onReceiveWord: (word) {
                  if (state.isRegrouping) return;
                  int? fromColumnIndex;
                  for (int i = 0; i < state.columns.length; i++) {
                    if (state.columns[i].words.any(
                      (w) => w.word == word.word,
                    )) {
                      fromColumnIndex = i;
                      break;
                    }
                  }

                  if (fromColumnIndex != null && fromColumnIndex != index) {
                    ref
                        .read(cargoCategoriesControllerProvider.notifier)
                        .moveWordBetweenColumns(word, fromColumnIndex, index);
                  } else {
                    ref
                        .read(cargoCategoriesControllerProvider.notifier)
                        .dropWordToColumn(word, index);
                  }
                },
                onWordMoved: (word, fromIndex) {
                  // This is handled by onReceiveWord
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildConveyorArea(BuildContext context, CargoCategoriesState state) {
    // Skor paneli açıkken bantın üstüne binmemesi için biraz boşluk bırakabiliriz
    // veya panel bantın üstünü örtebilir (daha şık durur).
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ConveyorArea(
        currentWord: state.currentWord,
        travelDuration:
            state.selectedDifficulty?.travelDuration ??
            const Duration(seconds: 2),
        onTimeout: (timedOutWord) {
          ref
              .read(cargoCategoriesControllerProvider.notifier)
              .handleTimeout(timedOutWord);
        },
        onDragStart: (word) {
          ref
              .read(cargoCategoriesControllerProvider.notifier)
              .onDragStart(word);
        },
        onDragEnd: (word) {
          ref.read(cargoCategoriesControllerProvider.notifier).onDragEnd(word);
        },
      ),
    );
  }

  // Özel Skor Paneli Widget'ı (Dialog Değil)
  Widget _buildScorePanel(BuildContext context, CargoCategoriesState state) {
    // Skor değerlerini al
    final score = state.finalScore ?? 0;
    final correctCount = state.finalCorrectCount ?? 0;
    final wrongCount = state.finalWrongCount ?? 0;

    return ScoreDialog(
      score: score,
      correctCount: correctCount,
      wrongCount: wrongCount,
      missedCount: 0,
      elapsedTime: state.elapsedTime,
      difficulty: state.selectedDifficulty,
      selectedCategories: state.chosenCategories.map((c) => c.id).toList(),
      onPlayAgain: () {
        setState(() {
          _isScorePanelVisible = false;
          _gameFinishedHandled = false;
        });
        ref.read(cargoCategoriesControllerProvider.notifier).reset();
        if (context.mounted) {
          context.go('/cargo-categories/setup');
        }
      },
      onBack: () {
        setState(() {
          _isScorePanelVisible = false;
          _gameFinishedHandled = false;
        });
        ref.read(cargoCategoriesControllerProvider.notifier).reset();
        if (context.mounted) {
          context.go('/cargo-categories/setup');
        }
      },
      onToggleTranslate: () {
        setState(() {
          _showTranslate = !_showTranslate;
        });
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveWordToGames(BuildContext context, CargoWord word) async {
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
            backgroundColor: saved ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kelime kaydedilirken hata oluştu: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
