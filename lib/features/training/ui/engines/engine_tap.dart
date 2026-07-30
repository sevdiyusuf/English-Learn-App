import 'package:flutter/material.dart';
import '../../models/training_models.dart';
import '../../../../core/theme/app_colors.dart';

class EngineTap extends StatelessWidget {
  final WorksheetItem item;
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool isLocked;

  const EngineTap({
    super.key,
    required this.item,
    required this.selected,
    required this.onChanged,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMedium,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            item.prompt.replaceAll('____', '_______'),
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children:
              item.bank.map((word) {
                final isSelected = selected == word;
                final isCorrect = word == item.answer;

                Color bgColor = AppColors.surfaceLight;
                Color textColor = Colors.white;
                BorderSide borderSide = BorderSide.none;

                if (isLocked) {
                  if (isSelected) {
                    if (isCorrect) {
                      bgColor = AppColors.success;
                    } else {
                      bgColor = AppColors.error;
                    }
                  } else if (isCorrect) {
                    // Show correct one gently
                    bgColor = AppColors.success.withValues(alpha: 0.3);
                  } else {
                    bgColor = AppColors.surfaceLight.withValues(alpha: 0.3);
                    textColor = Colors.white38;
                  }
                } else {
                  if (isSelected) {
                    bgColor = AppColors.primary;
                    borderSide = const BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    );
                  } else {
                    bgColor = AppColors.surfaceLight;
                  }
                }

                return GestureDetector(
                  onTap: isLocked ? null : () => onChanged(word),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.fromBorderSide(borderSide),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        if (isLocked &&
            item.translation != null &&
            item.translation!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Çeviri:',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            item.translation!,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ],
    );
  }
}
