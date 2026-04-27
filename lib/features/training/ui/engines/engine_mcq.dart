
import 'package:flutter/material.dart';
import '../../models/training_models.dart';
import '../../../../core/theme/app_colors.dart';

class EngineMcq extends StatelessWidget {
  final WorksheetItem item;
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool isLocked;

  const EngineMcq({
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
            style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
        ...item.options.map((option) {
          final isSelected = selected == option;
          final isCorrect = option == item.answer;
          
          Color borderColor = AppColors.surfaceLight;
          Color bgColor = AppColors.surfaceMedium;
          IconData? icon;

          if (isLocked) {
             if (isSelected) {
               if (isCorrect) {
                 borderColor = AppColors.success;
                 bgColor = AppColors.success.withValues(alpha: 0.2);
                 icon = Icons.check_circle;
               } else {
                 borderColor = AppColors.error;
                 bgColor = AppColors.error.withValues(alpha: 0.2);
                 icon = Icons.cancel;
               }
             } else if (isCorrect) {
               // Show correct answer if user missed it
               borderColor = AppColors.success;
               bgColor = AppColors.success.withValues(alpha: 0.1);
               icon = Icons.check_circle_outline;
             }
          } else {
            if (isSelected) {
              borderColor = AppColors.primary;
              bgColor = AppColors.primary.withValues(alpha: 0.2);
              icon = Icons.radio_button_checked;
            } else {
              icon = Icons.radio_button_unchecked;
            }
          }

          return GestureDetector(
            onTap: isLocked ? null : () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: isLocked ? borderColor : (isSelected ? AppColors.primary : Colors.grey)),
                ],
              ),
            ),
          );
        }),
        if (isLocked &&
            item.translation != null &&
            item.translation!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Çeviri:',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.translation!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );
  }
}
