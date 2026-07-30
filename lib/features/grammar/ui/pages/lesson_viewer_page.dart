import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yunoo/core/telemetry/telemetry_events.dart';
import 'package:yunoo/core/telemetry/telemetry_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../training/ui/engine_renderer.dart';
import '../../logic/grammar_providers.dart';
import '../../models/grammar_models.dart';

class LessonViewerPage extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonViewerPage({super.key, required this.lessonId});

  @override
  ConsumerState<LessonViewerPage> createState() => _LessonViewerPageState();
}

class _LessonViewerPageState extends ConsumerState<LessonViewerPage> {
  final PageController _pageController = PageController();
  dynamic _checkpointAnswer;
  bool _isCheckpointSolved = false;
  bool _isCheckpointCorrect = false;
  bool _hasLoggedStart = false;

  @override
  void initState() {
    super.initState();
    // Reset index when entering a lesson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentCardIndexProvider(widget.lessonId).notifier).state = 0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int totalCards, LessonDoc doc) {
    final currentIndex = ref.read(currentCardIndexProvider(widget.lessonId));
    if (currentIndex < totalCards - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(currentCardIndexProvider(widget.lessonId).notifier).state++;
      setState(() {
        _checkpointAnswer = null;
        _isCheckpointSolved = false;
        _isCheckpointCorrect = false;
      });
    } else {
      // Last card finished
      TelemetryService.instance.logAnalyticsEvent(
        TelemetryEvents.lessonCompleted,
        parameters: {
          TelemetryParams.contentType: 'grammar_lesson',
          TelemetryParams.contentLevel: doc.level,
        },
      );

      if (doc.storyMode.enabled) {
        context.push('/grammar/learn/${widget.lessonId}/story');
      } else if (doc.trainWorksheetId != null) {
        context.push(
          '/training/worksheet?path=${doc.level}/${doc.trainWorksheetId}.json',
        );
      } else {
        context.pop();
      }
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return AppColors.success;
      case 'A2':
        return AppColors.warning;
      case 'B1':
        return Colors.blue;
      case 'B2':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDocProvider(widget.lessonId));

    return lessonAsync.when(
      data: (doc) {
        if (!_hasLoggedStart) {
          _hasLoggedStart = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            TelemetryService.instance.logAnalyticsEvent(
              TelemetryEvents.lessonStarted,
              parameters: {
                TelemetryParams.contentType: 'grammar_lesson',
                TelemetryParams.contentLevel: doc.level,
              },
            );
          });
        }
        final cards = doc.microLesson.cards;
        final currentIndex = ref.watch(
          currentCardIndexProvider(widget.lessonId),
        );

        return Scaffold(
          backgroundColor: const Color(
            0xFF0F172A,
          ), // GrammarHome background color
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(doc.level),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    doc.level,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(doc.title, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text('${currentIndex + 1} / ${cards.length}'),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: (currentIndex + 1) / cards.length,
                backgroundColor: Colors.white10,
                color: AppColors.primary,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(cards[index]);
                  },
                ),
              ),
              _buildNavigation(currentIndex, cards.length, doc),
            ],
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Hata: $e'))),
    );
  }

  Widget _buildCard(LessonCard card) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.title != null) ...[
            Text(
              card.title!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (card.type == LessonCardType.checkpoint && card.checkpoint != null)
            _buildCheckpoint(card)
          else
            _buildContentCard(card),
        ],
      ),
    );
  }

  Widget _buildContentCard(LessonCard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (card.bullets.isNotEmpty)
          ...card.bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 18, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(b, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        if (card.formula.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children:
                  card.formula
                      .map(
                        (f) => Text(
                          f,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
        if (card.examples.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Examples:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...card.examples.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckpoint(LessonCard card) {
    final item = card.checkpoint!;
    return Column(
      children: [
        EngineRenderer(
          item: item,
          userAnswer: _checkpointAnswer,
          onAnswerChanged: (val) {
            if (!_isCheckpointSolved) {
              setState(() => _checkpointAnswer = val);
            }
          },
          isLocked: _isCheckpointSolved,
        ),
        if (_isCheckpointSolved) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  _isCheckpointCorrect
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCheckpointCorrect ? Colors.green : Colors.red,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCheckpointCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isCheckpointCorrect ? Colors.green : Colors.red,
                  ),
                ),
                if (item.raw['explain'] != null) ...[
                  const SizedBox(height: 8),
                  Text(item.raw['explain']),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigation(int currentIndex, int totalCards, LessonDoc doc) {
    final isCheckpoint =
        doc.microLesson.cards[currentIndex].type == LessonCardType.checkpoint;
    final canGoNext = !isCheckpoint || _isCheckpointSolved;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  ref
                      .read(currentCardIndexProvider(widget.lessonId).notifier)
                      .state--;
                },
                child: const Text('Back'),
              ),
            ),
          if (currentIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  canGoNext
                      ? () => _nextPage(totalCards, doc)
                      : (isCheckpoint && _checkpointAnswer != null
                          ? () {
                            final item =
                                doc.microLesson.cards[currentIndex].checkpoint!;
                            bool correct = false;
                            if (item.answer is String) {
                              correct =
                                  _checkpointAnswer
                                      .toString()
                                      .trim()
                                      .toLowerCase() ==
                                  item.answer.toString().trim().toLowerCase();
                            } else if (item.answer is List) {
                              // Simple list check
                              correct =
                                  _checkpointAnswer.toString().trim() ==
                                  item.answer.toString().trim();
                            }
                            setState(() {
                              _isCheckpointSolved = true;
                              _isCheckpointCorrect = correct;
                            });
                          }
                          : null),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canGoNext ? AppColors.primary : AppColors.surfaceLight,
                foregroundColor: Colors.white,
              ),
              child: Text(
                canGoNext
                    ? (currentIndex == totalCards - 1
                        ? (doc.storyMode.enabled ? 'Go to Story' : 'Finish')
                        : 'Next')
                    : 'Check Answer',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
