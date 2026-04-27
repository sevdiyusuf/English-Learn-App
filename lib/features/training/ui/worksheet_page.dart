import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/subject_summaries_data.dart';
import '../logic/training_session_controller.dart';
import '../models/training_models.dart';
import '../models/training_state.dart';
import 'engine_renderer.dart';
import 'result_page.dart';
import 'widgets/subject_summary_dialog.dart';

class WorksheetPage extends ConsumerStatefulWidget {
  static const routeName = 'worksheet';
  final String path;

  const WorksheetPage({super.key, required this.path});

  @override
  ConsumerState<WorksheetPage> createState() => _WorksheetPageState();
}

class _WorksheetPageState extends ConsumerState<WorksheetPage> {
  dynamic _currentDraftAnswer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainingSessionProvider.notifier).loadWorksheet(widget.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(trainingSessionProvider);
    final controller = ref.read(trainingSessionProvider.notifier);

    ref.listen(trainingSessionProvider, (prev, next) {
      if (prev?.currentIndex != next.currentIndex) {
        setState(() => _currentDraftAnswer = null);
      }

      if (next.worksheet != null &&
          next.currentIndex >= next.worksheet!.items.length) {
        Future.microtask(() {
          if (mounted) {
            context.goNamed(
              ResultPage.routeName,
              queryParameters: {
                'correct': next.correctCount.toString(),
                'total': next.totalCount.toString(),
                'id': next.worksheet!.worksheetId,
              },
            );
          }
        });
      }
    });

    if (session.isLoading) {
      return const Scaffold(
        backgroundColor: Color(
          0xFF12141C,
        ), // Daha derin ve kaliteli bir lacivert-siyah
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (session.error != null || session.worksheet == null) {
      return _buildErrorState(session.error);
    }

    final item = session.currentItem!;
    final progress =
        (session.currentIndex + 1) / session.worksheet!.items.length;
    final displayAnswer =
        session.isLocked ? session.userAnswers[item.id] : _currentDraftAnswer;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29), // Daha ferah bir koyu ton
      appBar: _buildAppBar(context, session),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1D29), const Color(0xFF12141C)],
          ),
        ),
        child: Column(
          children: [
            _buildProgressBar(session, progress),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: EngineRenderer(
                        item: item,
                        userAnswer: displayAnswer,
                        onAnswerChanged: (val) {
                          if (!session.isLocked) {
                            setState(() => _currentDraftAnswer = val);
                          }
                        },
                        isLocked: session.isLocked,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, session, controller, item),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TrainingSessionState session,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        session.worksheet!.title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        if (session.worksheet != null &&
            subjectSummaries.containsKey(session.worksheet!.worksheetId))
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () => _showSummary(context, session),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'KONU ÖZETİ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar(TrainingSessionState session, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SORU ${session.currentIndex + 1}",
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                "${session.currentIndex + 1} / ${session.worksheet!.items.length}",
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    TrainingSessionState session,
    TrainingSessionController controller,
    WorksheetItem item,
  ) {
    if (session.isLocked) {
      final isCorrect = session.results[item.id] == true;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          // Renkler daha "muted" (kısılmış) ve kaliteli hale getirildi
          color:
              isCorrect
                  ? const Color(0xFF14251B) // Çok daha koyu ve oturaklı yeşil
                  : const Color(
                    0xFF2D1818,
                  ), // Çok daha koyu ve oturaklı kırmızı
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: (isCorrect ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'Harika!' : 'Tekrar Dene',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 12),
              Text(
                'Doğru Cevap: ${item.answer is List ? (item.answer as List).join(", ") : item.answer}',
                style: const TextStyle(color: Colors.white60, fontSize: 15),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => controller.nextQuestion(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCorrect ? AppColors.success : AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'DEVAM ET',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final canSubmit =
          _currentDraftAnswer != null &&
          (_currentDraftAnswer is String
              ? (_currentDraftAnswer as String).isNotEmpty
              : true) &&
          (_currentDraftAnswer is List
              ? (_currentDraftAnswer as List).isNotEmpty
              : true);

      return Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF12141C),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: ElevatedButton(
          onPressed:
              canSubmit
                  ? () => controller.submitAnswer(_currentDraftAnswer)
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF252836),
            disabledForegroundColor: Colors.white10,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'KONTROL ET',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildErrorState(dynamic error) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('Hata: $error', style: const TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSummary(BuildContext context, TrainingSessionState session) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder:
          (context) => SubjectSummaryDialog(
            summary: subjectSummaries[session.worksheet!.worksheetId]!,
          ),
    );
  }
}
