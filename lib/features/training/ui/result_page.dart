import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/training_session_controller.dart';

class ResultPage extends ConsumerWidget {
  static const routeName = 'training_result';

  final int correct;
  final int total;
  final String worksheetId;

  const ResultPage({
    super.key,
    required this.correct,
    required this.total,
    required this.worksheetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = total > 0 ? (correct / total * 100).round() : 0;

    // Determine color based on percentage
    Color scoreColor;
    String message;
    if (percentage >= 80) {
      scoreColor = AppColors.success;
      message = 'Excellent!';
    } else if (percentage >= 60) {
      scoreColor = AppColors.warning;
      message = 'Good Job!';
    } else {
      scoreColor = AppColors.error;
      message = 'Keep Practicing!';
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go('/training'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Score Circle
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 8),
                  color: scoreColor.withValues(alpha: 0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$correct / $total',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Restart logic
                    // We need to reset the controller state
                    ref.read(trainingSessionProvider.notifier).restart();
                    // Go back to worksheet
                    context.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Worksheet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/training'),
                  icon: const Icon(Icons.school),
                  label: const Text('Back to Training Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
