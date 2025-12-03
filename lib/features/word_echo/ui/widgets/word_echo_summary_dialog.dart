import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/word_echo_state.dart';

class WordEchoSummaryDialog extends StatelessWidget {
  const WordEchoSummaryDialog({required this.state, super.key});

  final WordEchoState state;

  @override
  Widget build(BuildContext context) {
    final accuracy = state.correctCount + state.wrongCount > 0
        ? ((state.correctCount / (state.correctCount + state.wrongCount)) * 100)
            .round()
        : 0;

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text(
        'Oyun Tamamlandı!',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Toplam Skor', '${state.score}', AppColors.accent),
            const SizedBox(height: 16),
            _buildStatRow('Doğru', '${state.correctCount}', AppColors.success),
            const SizedBox(height: 8),
            _buildStatRow('Yanlış', '${state.wrongCount}', AppColors.error),
            const SizedBox(height: 16),
            _buildStatRow('Doğruluk Oranı', '%$accuracy', AppColors.primary),
            const SizedBox(height: 16),
            _buildStatRow(
              'Mod',
              state.speed == WordEchoSpeed.normal ? 'Normal' : 'Hızlı',
              AppColors.primaryLight,
            ),
            const SizedBox(height: 8),
            _buildStatRow('Kullanılan Set', state.setName ?? '-', Colors.white70),
            const SizedBox(height: 24),
            // Message based on performance
            _buildPerformanceMessage(context, accuracy),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'back'),
          child: const Text('Mini Games\'e Dön'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'retry'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Yeniden Oyna'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMessage(BuildContext context, int accuracy) {
    String message;
    if (accuracy >= 80) {
      message = 'Harika performans! 🎉';
    } else if (accuracy >= 60) {
      message = 'İyi iş çıkardın, biraz daha pratik yap!';
    } else if (accuracy >= 40) {
      message = 'Fena değil, daha fazla tekrar accuracy oranını yükseltecek.';
    } else {
      message = 'Zor bir set seçmiş olabilirsin, tekrar denemek gelişmene yardım eder.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        ),
      ),
    );
  }
}
