import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/game_saved_words_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../word_match/data/word_match_providers.dart';
import '../data/word_echo_service.dart';
import '../logic/word_echo_controller.dart';
import '../models/word_echo_config.dart';
import '../models/word_echo_state.dart';
import 'widgets/word_echo_summary_dialog.dart';

class WordEchoPage extends ConsumerStatefulWidget {
  const WordEchoPage({required this.speed, required this.setName, super.key});

  static const routeName = 'wordEcho';
  final WordEchoSpeed speed;
  final String setName;

  @override
  ConsumerState<WordEchoPage> createState() => _WordEchoPageState();
}

class _WordEchoPageState extends ConsumerState<WordEchoPage> {
  bool _gameStarted = false;
  bool _summaryShown = false;

  @override
  void initState() {
    super.initState();
  }

  void _startGameOnce() {
    if (_gameStarted) return;
    _gameStarted = true;

    ref
        .read(
          wordEchoControllerProvider(
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
      wordEchoControllerProvider(
        WordEchoControllerParams(speed: widget.speed, setName: widget.setName),
      ),
    );

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_gameStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startGameOnce());
    }

    if (state.phase == WordEchoPhase.finished && !_summaryShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _summaryShown = true;
        _showSummary(context, state);
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
          'Word Echo - ${widget.speed == WordEchoSpeed.normal ? "Normal" : "Hızlı"}',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // --- ÜST KISIM ---
              SizedBox(height: 60, child: _buildTopBar(state)),
              const SizedBox(height: 16),

              // --- ORTA KISIM (GRID) ---
              Expanded(
                flex: 6,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildSlotGrid(state),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- ALT KISIM (İPUCU) ---
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  // AnimatedSwitcher geçişlerin yumuşak olmasını sağlar
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildBottomContent(state),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Soru ${state.currentQuestionIndex + 1}/10',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(WordEchoState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoChip(
          icon: Icons.timer,
          text: '${state.timeRemaining}s',
          color:
              state.timeRemaining <= 10 ? AppColors.error : AppColors.primary,
        ),
        _buildInfoChip(
          icon: Icons.star,
          text: '${state.score}',
          color: AppColors.accent,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotGrid(WordEchoState state) {
    // Sadece 'waitingForAnswer' aşamasında tıklanabilir olsun.
    final bool canInteract = state.phase == WordEchoPhase.waitingForAnswer;

    return AbsorbPointer(
      absorbing: !canInteract,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          if (index >= state.slots.length) return const SizedBox.shrink();
          return _buildSlot(state.slots[index], index, state);
        },
      ),
    );
  }

  Widget _buildSlot(WordEchoSlot slot, int index, WordEchoState state) {
    final controller = ref.read(
      wordEchoControllerProvider(
        WordEchoControllerParams(speed: widget.speed, setName: widget.setName),
      ).notifier,
    );

    Color bgColor = AppColors.surfaceDark;
    Color borderColor = AppColors.surfaceLight;

    // --- RENK VE DURUM MANTIĞI ---
    if (slot.isCorrect) {
      bgColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (slot.isWrong) {
      bgColor = AppColors.error;
      borderColor = AppColors.error;
    } else if (slot.isActive) {
      bgColor = AppColors.primary.withValues(alpha: 0.3);
      borderColor = AppColors.primary;
    }

    // --- METİN GÖRÜNÜRLÜĞÜ ---
    // Sıra gösterilirken (isActive) YA DA sonuç belli olduğunda (Correct/Wrong) metni göster.
    final bool showText = slot.isActive || slot.isCorrect || slot.isWrong;
    final String displayText = showText ? (slot.englishWord ?? '') : '';

    // Get the word for this slot - slot.englishWord is always set when question loads
    final slotWord = slot.englishWord;
    final bool canSave = slotWord != null && slotWord.isNotEmpty;

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque, // Boş alana tıklamayı yakala
          onTap: () => controller.selectSlot(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow:
                  (slot.isActive || slot.isCorrect)
                      ? [
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    showText
                        ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            displayText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : Text(
                          '${index + 1}', // Metin gizliyken numara göster
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.1),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
              ),
            ),
          ),
        ),
        // Save button in top right corner - always visible
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap:
                canSave
                    ? () {
                      // canSave is true only when slotWord is non-null and non-empty
                      // ignore: unnecessary_non_null_assertion
                      _saveSlotWord(context, slotWord!);
                    }
                    : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    canSave
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/icons/bookmark.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  canSave
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.3),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSlotWord(BuildContext context, String english) async {
    try {
      // Find the Turkish translation for this English word
      // First try from current state (works for both Personal Echo and Global)
      String? turkish;

      // Check if word is in current slots (from Personal Echo or Global)
      final state = ref.read(
        wordEchoControllerProvider(
          WordEchoControllerParams(
            speed: widget.speed,
            setName: widget.setName,
          ),
        ),
      );

      // Try to find Turkish from current question's correct word
      if (state.currentCorrectEnglishWord?.toLowerCase() ==
          english.toLowerCase()) {
        turkish = state.currentTurkishHint;
      }

      // If not found, try from WordEchoService (Global words)
      if (turkish == null) {
        try {
          final word = WordEchoService.instance.getWordByEnglish(english);
          turkish = word?.turkish;
        } catch (_) {
          // Word not in JSON, will try Personal Echo
        }
      }

      // If still not found and Personal Echo is active, try from WordSet
      if (turkish == null) {
        final config = ref.read(wordEchoConfigProvider);
        if (config.isPersonalEchoActive && config.selectedWordSetId != null) {
          try {
            final repo = await ref.read(wordMatchRepoProvider.future);
            final pairs = await repo.fetchPairs(config.selectedWordSetId!);
            final pair = pairs.firstWhere(
              (p) => p.english.toLowerCase() == english.toLowerCase(),
              orElse: () => throw StateError('Word not found in set'),
            );
            turkish = pair.turkish;
          } catch (_) {
            // Word not in set either
          }
        }
      }

      if (turkish == null || turkish.isEmpty) {
        throw StateError('Turkish translation not found for: $english');
      }

      final repository = ref.read(gameSavedWordsRepositoryProvider);
      final saved = await repository.saveToWordsFromGames(
        english: english,
        turkish: turkish,
        sourceGame: 'word_echo',
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

  Widget _buildBottomContent(WordEchoState state) {
    // 1. Durum: Sıra Gösteriliyor
    if (state.phase == WordEchoPhase.showingSequence) {
      return Column(
        key: const ValueKey('showing_sequence'),
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.visibility, color: Colors.white54, size: 32),
          SizedBox(height: 8),
          Text(
            'Sırayı ve kelimeleri izle...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      );
    }
    // 2. Durum: Cevap Bekleniyor VEYA Sonuç Gösteriliyor (Feedback)
    // Feedback sırasında da ipucunu ekranda tutuyoruz ki titreme olmasın.
    if ((state.phase == WordEchoPhase.waitingForAnswer ||
        state.phase == WordEchoPhase.feedback)) {
      // Eğer currentTurkishHint null ise, yine de bir şey göster
      if (state.currentTurkishHint == null ||
          state.currentTurkishHint!.isEmpty) {
        return Container(
          key: const ValueKey('waiting_no_hint'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: const Text(
            'Yükleniyor...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        );
      }

      return Container(
        key: ValueKey('hint_${state.currentTurkishHint}'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.currentTurkishHint!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.phase == WordEchoPhase.feedback
                  ? (state.correctCount > 0 && state.slots.any((s) => s.isWrong)
                      ? 'Doğru cevap buydu'
                      : 'Sonuç')
                  : 'Hangi kutudaydı?',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Future<void> _showSummary(BuildContext context, WordEchoState state) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WordEchoSummaryDialog(state: state),
    );

    if (!mounted) return;

    if (result == 'retry') {
      _summaryShown = false;
      _gameStarted = false;
      ref.invalidate(
        wordEchoControllerProvider(
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
