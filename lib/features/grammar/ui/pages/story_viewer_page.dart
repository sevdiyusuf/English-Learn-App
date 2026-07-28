import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/content/educational_content_id_resolver.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/educational_content/content_report_dialog.dart';
import '../../logic/grammar_providers.dart';
import '../../models/grammar_models.dart';
import '../../../training/models/training_models.dart';
import '../../../training/ui/engine_renderer.dart';

class StoryViewerPage extends ConsumerStatefulWidget {
  final String lessonId;

  const StoryViewerPage({super.key, required this.lessonId});

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage> {
  List<dynamic> _answers = [];
  List<bool> _solved = [];
  List<bool> _correct = [];
  bool _showRecap = false;
  final ScrollController _scrollController = ScrollController();

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return const Color(0xFF4ADE80);
      case 'A2':
        return const Color(0xFFFACC15);
      case 'B1':
        return const Color(0xFF60A5FA);
      case 'B2':
        return const Color(0xFFC084FC);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDocProvider(widget.lessonId));

    return lessonAsync.when(
      data: (doc) {
        if (_showRecap) return _buildRecap(doc);

        final items = doc.storyMode.items;

        if (_answers.length != items.length) {
          _answers = List<dynamic>.filled(items.length, null, growable: false);
          _solved = List<bool>.filled(items.length, false, growable: false);
          _correct = List<bool>.filled(items.length, false, growable: false);
        }

        final solvedCount = _solved.where((v) => v).length;
        final progress = items.isEmpty ? 0.0 : solvedCount / items.length;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Deep Slate
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar with Progress
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildLevelBadge(doc.level),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                doc.storyMode.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    alignment: Alignment.center,
                    child: Text(
                      '$solvedCount / ${items.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _ReportButton(lessonId: widget.lessonId),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getLevelColor(doc.level),
                    ),
                    minHeight: 4,
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildIntroCard(doc.storyMode),
                    const SizedBox(height: 32),
                    ...List.generate(items.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildStoryItem(items[index], index),
                      );
                    }),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton:
              _solved.every((v) => v)
                  ? FloatingActionButton.extended(
                    onPressed: () => setState(() => _showRecap = true),
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Complete Story & See Recap'),
                  )
                  : null,
        );
      },
      loading:
          () => const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          ),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getLevelColor(level).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getLevelColor(level).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: _getLevelColor(level),
        ),
      ),
    );
  }

  Widget _buildIntroCard(StoryMode story) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.auto_stories,
                size: 100,
                color: Colors.orange.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'HİKAYE ÖZETİ',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...story.introBullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(WorksheetItem item, int index) {
    final isSolved = _solved[index];
    final isCorrect = _correct[index];
    final isActive =
        index == 0 || _solved[index - 1]; // Önceki çözüldüyse bu aktif

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1.0 : 0.4,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isSolved
                    ? (isCorrect
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.red.withValues(alpha: 0.5))
                    : (isActive ? Colors.white12 : Colors.transparent),
            width: 1.5,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header of Item
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isSolved
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Colors.blueAccent.withValues(alpha: 0.2),
                    child:
                        isSolved
                            ? Icon(
                              isCorrect ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 16,
                            )
                            : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Fill in the blanks',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content Renderer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EngineRenderer(
                item: item,
                userAnswer: _answers[index],
                onAnswerChanged: (val) {
                  if (!isSolved && isActive) {
                    setState(() => _answers[index] = val);
                  }
                },
                isLocked: isSolved,
              ),
            ),

            const SizedBox(height: 20),

            // Action Button
            if (isActive)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            isSolved || _answers[index] == null
                                ? null
                                : () {
                                  final correct = _validateAnswer(item, index);
                                  setState(() {
                                    _solved[index] = true;
                                    _correct[index] = correct;
                                  });
                                  // Otomatik aşağı kaydırma
                                  if (index < _solved.length - 1) {
                                    Future.delayed(
                                      const Duration(milliseconds: 300),
                                      () {
                                        _scrollController.animateTo(
                                          _scrollController.offset + 150,
                                          duration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                    );
                                  }
                                },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              isSolved
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isSolved ? 'Completed' : 'Confirm Answer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Explanation Section
            if (isSolved && item.raw['explain'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      isCorrect
                          ? Colors.green.withValues(alpha: 0.05)
                          : Colors.red.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: isCorrect ? Colors.green : Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Great Job!' : 'Explanation',
                          style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.raw['explain'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _validateAnswer(WorksheetItem item, int index) {
    final userAnswer = _answers[index];
    if (userAnswer == null) return false;

    if (item.answer is String) {
      return userAnswer.toString().trim().toLowerCase() ==
          item.answer.toString().trim().toLowerCase();
    } else if (item.answer is List) {
      final answerList = List<String>.from(item.answer);
      final userAnswerStr = userAnswer.toString().trim().toLowerCase();
      return answerList.any((a) => a.trim().toLowerCase() == userAnswerStr);
    }
    return false;
  }

  Widget _buildRecap(LessonDoc doc) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              AppColors.primary.withValues(alpha: 0.2),
              const Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.stars_rounded,
                size: 100,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Hikaye Tamamlandı!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'İşte öğrendiklerinin özeti:',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
              const SizedBox(height: 40),
              Expanded(
                flex: 4,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: doc.storyMode.recapBullets.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              doc.storyMode.recapBullets[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (doc.trainWorksheetId != null) {
                          context.pushReplacement(
                            '/training/worksheet?path=${doc.level}/${doc.trainWorksheetId}.json',
                          );
                        } else {
                          context.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ŞİMDİ PRATİK YAP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Derslere Dön',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
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

class _ReportButton extends ConsumerWidget {
  const _ReportButton({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registryAsync = ref.watch(educationalContentRegistryProvider);
    final lessonAsync = ref.watch(lessonDocProvider(lessonId));
    
    return lessonAsync.when(
      data: (doc) {
        return registryAsync.when(
          data: (registry) {
            final items = doc.storyMode.items;
            if (items.isEmpty) {
              return const SizedBox.shrink();
            }
            
            // Use the first story item for reporting
            final item = items[0];
            
            // Try multiple possible keys for the registry lookup
            String? contentId;
            
            // Try with prompt as anchor (for story items)
            if (item.prompt.isNotEmpty) {
              final promptKey = EducationalItemKey(
                'assets/lessons/$doc.level/$lessonId.json',
                'prompt:${item.prompt}',
              );
              contentId = registry[promptKey];
            }
            
            // Fallback to ID-based key
            if (contentId == null) {
              final idKey = EducationalItemKey(
                'assets/lessons/$doc.level/$lessonId.json',
                'id:${item.id}',
              );
              contentId = registry[idKey];
            }
            
            if (contentId == null) {
              return const SizedBox.shrink();
            }
            
            return IconButton(
              key: const ValueKey('report_story_item_0'),
              icon: const Icon(Icons.flag_outlined, color: Colors.white54),
              tooltip: 'Report an issue with this content',
              onPressed: () async {
                await showContentReportSheet(
                  context,
                  contentId: contentId!,
                  contentVersion: 1,
                  contentType: 'story_item',
                );
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
