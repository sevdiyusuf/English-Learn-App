import 'dart:ui'; // Blur efekti için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/game_saved_words_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/adaptive_difficulty_helper.dart';
import '../logic/flash_synonym_controller.dart'; // Dikkat: Synonym Controller
import '../models/flash_synonym_state.dart'; // Dikkat: Synonym State
import 'widgets/score_dialog.dart';

class FlashSynonymPage extends ConsumerStatefulWidget {
  const FlashSynonymPage({required this.level, super.key});

  static const routeName = 'flashSynonym';

  final String level;

  @override
  ConsumerState<FlashSynonymPage> createState() => _FlashSynonymPageState();
}

class _FlashSynonymPageState extends ConsumerState<FlashSynonymPage> {
  bool _scoreDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        ref
            .read(flashSynonymControllerProvider(widget.level).notifier)
            .startGame();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(flashSynonymControllerProvider(widget.level));

    if (gameState.isGameFinished && !_scoreDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scoreDialogShown = true;
        _showScoreDialog(context, gameState);
      });
    }

    if (gameState.showLevelUpBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ref
                .read(flashSynonymControllerProvider(widget.level).notifier)
                .hideLevelUpBanner();
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Arka plan resmi görünsün
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
            tooltip: 'Geri dön',
          ),
        ),
        centerTitle: true,
        title: _GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Flash Synonym - ${_getLevelName(widget.level)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background3.png',
              fit: BoxFit.cover,
            ),
          ),
          // 1. KATMAN: Arka plan karartma (Vignette)
          // Lacivert arka planın çok parlak kısımlarını bastırır
          const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),

          // 2. KATMAN: Oyun İçeriği
          gameState.isGameFinished
              ? _buildGameFinishedView()
              : gameState.isGameActive
              ? _buildGameView(gameState)
              : _buildLoadingView(),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildGameView(FlashSynonymState gameState) {
    final currentWord = gameState.currentWord;
    if (currentWord == null) {
      return _buildLoadingView();
    }

    return SafeArea(
      child: Column(
        children: [
          // Top bar: HUD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: _buildTopBar(gameState),
          ),

          // Falling words area
          Expanded(child: _buildFallingWordsArea(gameState)),

          // Bottom: Question word and Pass button
          _buildBottomSection(gameState),
        ],
      ),
    );
  }

  Widget _buildTopBar(FlashSynonymState gameState) {
    return _GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      borderRadius: 24,
      child: Row(
        children: [
          // Timer (left)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(gameState.elapsedDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Spacer to push lives to center
          Expanded(
            child: Center(
              // Lives (center)
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  _buildLivesIndicator(gameState.livesLeft),
                ],
              ),
            ),
          ),

          // Score (right)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${gameState.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLivesIndicator(int livesLeft) {
    return Row(
      children: List.generate(3, (index) {
        final isAlive = index < livesLeft;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isAlive ? 1.0 : 0.8,
            child: SvgPicture.asset(
              'assets/icons/heart.svg',
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(
                isAlive ? const Color(0xFFFF5252) : Colors.white24,
                BlendMode.srcIn,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLevelUpBanner(AdaptiveStage? stage) {
    if (stage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.8),
            Colors.deepOrange.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.orangeAccent,
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.keyboard_double_arrow_up,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Seviye zorlaştırıldı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black45,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallingWordsArea(FlashSynonymState gameState) {
    final options = gameState.options;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final centerY = screenHeight / 2;

        const topRowCount = 3;
        const bottomRowCount = 2;
        const buttonWidth = 100.0;
        const horizontalSpacing = 50.0;
        const verticalSpacing = 80.0;

        // Üst satırdaki 3 kartı ekranın ortasında, eşit aralıklı hizala
        final topRowWidth =
            (buttonWidth * topRowCount) +
            (horizontalSpacing * (topRowCount - 1));
        final topRowStartX = (screenWidth - topRowWidth) / 2;
        final bottomRowWidth =
            (buttonWidth * bottomRowCount) +
            (horizontalSpacing * (bottomRowCount - 1));
        final bottomRowStartX = (screenWidth - bottomRowWidth) / 2;
        final topRowY = centerY - verticalSpacing / 2;
        final bottomRowY = centerY + verticalSpacing / 2;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (gameState.showLevelUpBanner)
              Positioned(top: 10, child: _buildLevelUpBanner(gameState.stage)),
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final fallOffset =
                  gameState.fallingWordsPositions[option] ?? -100.0;
              final isTopRow = index < topRowCount;
              final rowIndex = isTopRow ? index : index - topRowCount;

              final baseX =
                  isTopRow
                      ? topRowStartX +
                          (buttonWidth + horizontalSpacing) * rowIndex
                      : bottomRowStartX +
                          (buttonWidth + horizontalSpacing) * rowIndex;

              final baseY = isTopRow ? topRowY : bottomRowY;
              final actualY = fallOffset < 0 ? baseY + fallOffset - 50 : baseY;

              final color = gameState.wordColors[option];
              final isSelected = gameState.selectedOption == option;

              // Üst satırdaki en sağdaki kart (rowIndex == 2) ekrandan taşmaması
              // ve hafif içerde durması için sağdan 2px içeride hizalanıyor.
              if (isTopRow && rowIndex == 2) {
                return Positioned(
                  top: actualY,
                  right: 2.0,
                  child: _buildWordButton(
                    option,
                    color,
                    isSelected,
                    gameState.selectedOption == null,
                    () {
                      if (gameState.selectedOption == null) {
                        ref
                            .read(
                              flashSynonymControllerProvider(
                                widget.level,
                              ).notifier,
                            )
                            .selectAnswer(option);
                      }
                    },
                  ),
                );
              }

              // Diğer kartlar soldan hesaplanan baseX ile hizalanıyor.
              return Positioned(
                top: actualY,
                left: baseX,
                child: _buildWordButton(
                  option,
                  color,
                  isSelected,
                  gameState.selectedOption == null,
                  () {
                    if (gameState.selectedOption == null) {
                      ref
                          .read(
                            flashSynonymControllerProvider(
                              widget.level,
                            ).notifier,
                          )
                          .selectAnswer(option);
                    }
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // --- KRİTİK BÖLÜM: Yüksek Kontrastlı Buton Tasarımı ---
  Widget _buildWordButton(
    String word,
    Color? color,
    bool isSelected,
    bool isEnabled,
    VoidCallback onTap,
  ) {
    final bool hasCustomColor = color != null;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          // Parlaklık için %15 varsayılan beyaz, renkli ise tam renk
          color: color ?? Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          // Gradient: Sol üstten parlak beyaz ışık vuruyor gibi
          gradient:
              hasCustomColor
                  ? null
                  : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(
                        alpha: 0.4,
                      ), // Yüksek Kontrast (Parlak)
                      Colors.white.withValues(alpha: 0.1), // Şeffaf
                    ],
                  ),
          // Kalın kenarlık, kartı arka plandan ayırır
          border: Border.all(
            color:
                hasCustomColor
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
            width: hasCustomColor ? 2.5 : 1.5,
          ),
          // Gölgeler
          boxShadow: [
            if (isSelected || hasCustomColor)
              BoxShadow(
                color: (color ?? Colors.white).withValues(alpha: 0.8),
                blurRadius: 20,
                spreadRadius: 2,
              )
            else
              // Arka plan koyu olduğu için siyah gölge ile derinlik ver
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            // Ekstra glow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            word,
            style: TextStyle(
              color: const Color.fromARGB(255, 255, 255, 255),
              fontSize: 17,
              fontWeight: FontWeight.w800, // Kalın font
              letterSpacing: 0.5,
              // Metin Gölgeleri: Yazının her türlü zeminde okunmasını sağlar
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(1, 1),
                ),
                const Shadow(
                  blurRadius: 8,
                  color: Colors.black,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(FlashSynonymState gameState) {
    final currentWord = gameState.currentWord;
    if (currentWord == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6), // Koyu panel arka planı
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Target Word Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          currentWord.word,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 123, 239, 148),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: AppColors.primary,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentWord.translate,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Save Button
                  IconButton(
                    onPressed:
                        () => _saveWord(
                          context,
                          currentWord.word,
                          currentWord.translate,
                        ),
                    icon: SvgPicture.asset(
                      'assets/icons/bookmark.svg',
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Pass Button (Modern Pill Shape)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed:
                      !gameState.hasPassUsed && gameState.selectedOption == null
                          ? () {
                            ref
                                .read(
                                  flashSynonymControllerProvider(
                                    widget.level,
                                  ).notifier,
                                )
                                .passQuestion();
                          }
                          : null,
                  icon: const Icon(Icons.fast_forward_rounded),
                  label: Text(
                    gameState.hasPassUsed ? 'PAS KULLANILDI' : 'PAS GEÇ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        gameState.hasPassUsed
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            gameState.hasPassUsed
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveWord(
    BuildContext context,
    String english,
    String turkish,
  ) async {
    try {
      final repository = ref.read(gameSavedWordsRepositoryProvider);
      final saved = await repository.saveToWordsFromGames(
        english: english,
        turkish: turkish,
        sourceGame: 'flash_synonym',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? '"$english" kelimesi kaydedildi.'
                  : 'Bu kelime zaten kayıtlı.',
            ),
            backgroundColor: saved ? AppColors.success : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildGameFinishedView() {
    return Center(
      child: _GlassContainer(
        padding: const EdgeInsets.all(32),
        child: const Text(
          'Oyun Bitti!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showScoreDialog(BuildContext context, FlashSynonymState gameState) {
    // Calculate final score with time bonus
    // Faster completion = higher bonus
    // Formula: baseScore * (1 + timeBonusMultiplier)
    // Time bonus decreases as time increases
    final baseScore = gameState.score;
    final elapsedSeconds = gameState.elapsedDuration.inSeconds;

    // Time bonus: maximum 2x for very fast games, decreases with time
    // For games under 60 seconds: 2.0x
    // For games 60-120 seconds: 1.5x
    // For games 120-180 seconds: 1.2x
    // For games over 180 seconds: 1.0x (no bonus)
    double timeBonusMultiplier = 1.0;
    if (elapsedSeconds < 60) {
      timeBonusMultiplier = 2.0;
    } else if (elapsedSeconds < 120) {
      timeBonusMultiplier = 1.5;
    } else if (elapsedSeconds < 180) {
      timeBonusMultiplier = 1.2;
    }

    final finalScore = (baseScore * timeBonusMultiplier).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ScoreDialog(
            score: finalScore,
            baseScore: baseScore,
            correctCount: gameState.correctCount,
            wrongCount: gameState.wrongCount,
            passCount: gameState.passCount,
            elapsedTime: gameState.elapsedDuration,
            onPlayAgain: () {
              Navigator.of(context).pop();
              _scoreDialogShown = false;
              ref
                  .read(flashSynonymControllerProvider(widget.level).notifier)
                  .reset();
              ref
                  .read(flashSynonymControllerProvider(widget.level).notifier)
                  .startGame();
            },
            onBack: () {
              Navigator.of(context).pop();
              context.pop();
            },
          ),
    );
  }

  String _getLevelName(String level) {
    switch (level) {
      case 'easy':
        return 'Kolay';
      case 'medium':
        return 'Orta';
      case 'upper':
        return 'İleri';
      case 'expert':
        return 'Uzman';
      default:
        return level;
    }
  }
}

// Yardımcı Widget
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
