import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/repositories/game_saved_words_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/word_echo_controller.dart';
import '../logic/word_echo_grid_controller.dart';
import '../models/word_echo_grid_state.dart';
import '../models/word_echo_state.dart';
import '../utils/grid_color_helper.dart';
import 'widgets/word_echo_summary_dialog.dart';

class WordEchoGridPage extends ConsumerStatefulWidget {
  const WordEchoGridPage({
    required this.speed,
    required this.setName,
    super.key,
  });

  static const routeName = 'wordEchoGrid';
  final WordEchoSpeed speed;
  final String setName;

  @override
  ConsumerState<WordEchoGridPage> createState() => _WordEchoGridPageState();
}

class _WordEchoGridPageState extends ConsumerState<WordEchoGridPage> {
  bool _gameStarted = false;
  bool _summaryShown = false;

  void _startGameOnce() {
    if (_gameStarted) return;
    _gameStarted = true;

    ref
        .read(
          wordEchoGridControllerProvider(
            WordEchoControllerParams(
              speed: widget.speed,
              setName: widget.setName,
            ),
          ).notifier,
        )
        .startGame();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      wordEchoGridControllerProvider(
        WordEchoControllerParams(speed: widget.speed, setName: widget.setName),
      ),
    );

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if initialization failed
    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
          toolbarHeight: 48,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Hata'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 64),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Geri Dön'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_gameStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGameOnce());
    }

    if (state.phase == WordEchoGridPhase.finished && !_summaryShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _summaryShown = true;
        if (state.errorMessage == null) {
          _showSummary(context, state);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Word Echo Grid - ${widget.speed == WordEchoSpeed.normal ? "Normal" : "Hızlı"}',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Top bar
              SizedBox(height: 60, child: _buildTopBar(state)),
              const SizedBox(height: 12),

              // View cards button (only in Phase 2 & 3)
              if (state.phase == WordEchoGridPhase.englishQuery ||
                  state.phase == WordEchoGridPhase.turkishQuery)
                _buildViewCardsButton(state),
              const SizedBox(height: 8),

              // Phase info
              _buildPhaseInfo(state),
              const SizedBox(height: 8),

              // Countdown (Phase 1 or when viewing cards)
              if (state.countdown != null)
                SizedBox(height: 60, child: _buildCountdown(state.countdown!))
              else
                const SizedBox(height: 60),

              // Grid - Fixed size to ensure all cards are visible
              Expanded(child: _buildGrid(state)),

              const SizedBox(height: 12),

              // Question area (Phase 2 & 3) - Fixed height
              if (state.phase == WordEchoGridPhase.englishQuery ||
                  state.phase == WordEchoGridPhase.turkishQuery)
                SizedBox(height: 90, child: _buildQuestionArea(state))
              else
                const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(WordEchoGridState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoChip(
          icon: Icons.star,
          text: '${state.score}',
          color: AppColors.accent,
        ),
        _buildInfoChip(
          icon: Icons.check_circle,
          text: '${state.correctCount}',
          color: AppColors.success,
        ),
        _buildInfoChip(
          icon: Icons.cancel,
          text: '${state.wrongCount}',
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildViewCardsButton(WordEchoGridState state) {
    final canView = state.remainingViews > 0 && state.countdown == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                canView
                    ? () {
                      ref
                          .read(
                            wordEchoGridControllerProvider(
                              WordEchoControllerParams(
                                speed: widget.speed,
                                setName: widget.setName,
                              ),
                            ).notifier,
                          )
                          .viewCards();
                    }
                    : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: canView ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility,
                    size: 20,
                    color: canView ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kartları Gör',
                    style: TextStyle(
                      color: canView ? Colors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kalan Hak: ${state.remainingViews}',
          style: TextStyle(
            color:
                state.remainingViews > 0 ? AppColors.primary : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseInfo(WordEchoGridState state) {
    if (state.phase == WordEchoGridPhase.englishQuery ||
        state.phase == WordEchoGridPhase.turkishQuery ||
        state.phase == WordEchoGridPhase.showAll) {
      return const SizedBox.shrink();
    }

    String text;
    Color color;

    switch (state.phase) {
      case WordEchoGridPhase.finished:
        text = 'Round tamamlandı!';
        color = AppColors.success;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGrid(WordEchoGridState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final spacing = 8.0;
        final crossAxisCount = 3;

        final cardWidth =
            (availableWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final cardHeight =
            (availableHeight - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: cardWidth / cardHeight,
          ),
          itemBuilder: (context, index) {
            if (index >= state.cards.length) return const SizedBox.shrink();
            return _buildCard(state.cards[index], state);
          },
        );
      },
    );
  }

  Widget _buildCard(EchoGridCard card, WordEchoGridState state) {
    final color = GridColorHelper.colorForIndex(card.index);
    final canTap =
        state.phase == WordEchoGridPhase.englishQuery ||
        state.phase == WordEchoGridPhase.turkishQuery;

    // Kartın açık olup olmadığı (animasyon için)
    final isRevealed = card.isRevealed || card.isWrong || card.isCorrect;

    // Arka Yüz (Kapalı Hali)
    final backWidget = _buildCardFace(
      child: Center(
        child: Icon(
          Icons.help_outline,
          color: Colors.white.withValues(alpha: 0.3),
          size: 28,
        ),
      ),
      bgColor: AppColors.surfaceDark,
      borderColor: AppColors.surfaceLight,
    );

    // Ön Yüz (Açık Hali)
    Color frontBgColor = AppColors.primary.withValues(alpha: 0.1);
    Color frontBorderColor = AppColors.primary;
    List<BoxShadow> shadows = [];

    if (card.isWrong) {
      frontBgColor = AppColors.error.withValues(alpha: 0.3);
      frontBorderColor = AppColors.error;
      shadows = [
        BoxShadow(
          color: AppColors.error.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    } else if (card.isCorrect) {
      frontBgColor = AppColors.success.withValues(alpha: 0.2);
      frontBorderColor = AppColors.success;
      shadows = [
        BoxShadow(
          color: AppColors.success.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    } else {
      // Normal revealed
      shadows = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    }

    final frontWidget = _buildCardFace(
      bgColor: frontBgColor,
      borderColor: frontBorderColor,
      shadows: shadows,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color tag
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // English word
            Flexible(
              child: Text(
                card.word.english,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // Turkish meaning
            Flexible(
              child: Text(
                card.word.turkish,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap:
              canTap &&
                      !isRevealed // Sadece kapalıyken ve sıra bendeyken tıkla
                  ? () {
                    ref
                        .read(
                          wordEchoGridControllerProvider(
                            WordEchoControllerParams(
                              speed: widget.speed,
                              setName: widget.setName,
                            ),
                          ).notifier,
                        )
                        .onCardTapped(card.index);
                  }
                  : null,
          child: _FlipCard(
            isRevealed: isRevealed,
            front: frontWidget,
            back: backWidget,
          ),
        ),
        // Bookmark icon - only when card is revealed, positioned outside the card
        if (isRevealed)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    () => _saveWord(
                      context,
                      card.word.english,
                      card.word.turkish,
                    ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/bookmark.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.9),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Ortak kart yüzü tasarımı - Boyut sabitlemek için SizedBox.expand kullanır
  Widget _buildCardFace({
    required Widget child,
    required Color bgColor,
    required Color borderColor,
    List<BoxShadow> shadows = const [],
  }) {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: shadows,
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
      ),
    );
  }

  Widget _buildQuestionArea(WordEchoGridState state) {
    if (state.currentTargetWord == null || state.currentTargetIndex == null) {
      return const Center(
        child: Text('Yükleniyor...', style: TextStyle(color: Colors.white70)),
      );
    }

    final color = GridColorHelper.colorForIndex(state.currentTargetIndex!);
    final isEnglishPhase = state.phase == WordEchoGridPhase.englishQuery;
    final questionText =
        isEnglishPhase
            ? state.currentTargetWord!.english
            : state.currentTargetWord!.turkish;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      questionText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40), // Space for bookmark icon
            ],
          ),
          // Bookmark icon on the right
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    () => _saveWord(
                      context,
                      state.currentTargetWord!.english,
                      state.currentTargetWord!.turkish,
                    ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/bookmark.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.9),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(int countdown) {
    return Center(
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: Center(
          child: Text(
            '$countdown',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
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
        sourceGame: 'word_echo_grid',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? '"$english" kelimesi "Words from Games" setine kaydedildi.'
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

  Future<void> _showSummary(
    BuildContext context,
    WordEchoGridState state,
  ) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    final summaryState = WordEchoState(
      timeRemaining: 0,
      score: state.score,
      correctCount: state.correctCount,
      wrongCount: state.wrongCount,
      speed:
          state.setName == 'Word Echo Grid'
              ? WordEchoSpeed.normal
              : widget.speed,
      phase: WordEchoPhase.finished,
      setName: state.setName,
    );

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WordEchoSummaryDialog(state: summaryState),
    );

    if (!mounted) return;

    if (result == 'retry') {
      _summaryShown = false;
      _gameStarted = false;
      ref.invalidate(
        wordEchoGridControllerProvider(
          WordEchoControllerParams(
            speed: widget.speed,
            setName: widget.setName,
          ),
        ),
      );
    } else if (result == 'back') {
      if (!mounted) return;
      router.go('/mini-games');
    } else {
      if (!mounted) return;
      navigator.pop();
    }
  }
}

// --------------------------------------------------------------------------
// FLIP CARD WIDGET
// Gerçek 3D Dönüş Animasyonu sağlar ve boyutları sabit tutar.
// --------------------------------------------------------------------------

class _FlipCard extends StatefulWidget {
  final bool isRevealed;
  final Widget front;
  final Widget back;

  const _FlipCard({
    required this.isRevealed,
    required this.front,
    required this.back,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Eğer başlangıçta açıksa 1.0 (Front), kapalıysa 0.0 (Back)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isRevealed ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed != oldWidget.isRevealed) {
      if (widget.isRevealed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 0.0 -> Back (Kapalı), 1.0 -> Front (Açık)
        // Dönüş açısı: 0 ile 180 derece (0 ile pi)
        // 1.0 (Açık) iken açı 0 olsun (Düz duruyor)
        // 0.0 (Kapalı) iken açı 180 olsun (Ters dönmüş gibi)
        // Ancak biz içeriği değiştireceğimiz için şöyle yapıyoruz:
        // angle: 0 (Front) -> pi (Back)
        final angle = (1.0 - _controller.value) * pi;

        final transform =
            Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspektif
              ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child:
              _controller.value >= 0.5
                  ? widget
                      .front // 90 dereceden küçükse ön yüz
                  : Transform(
                    alignment: Alignment.center,
                    transform:
                        Matrix4.identity()
                          ..rotateY(pi), // Arka yüzü düzeltmek için ayna etkisi
                    child: widget.back,
                  ),
        );
      },
    );
  }
}
