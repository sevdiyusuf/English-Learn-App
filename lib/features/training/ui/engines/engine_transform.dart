import 'package:flutter/material.dart';
import '../../models/training_models.dart';
import '../../../../core/theme/app_colors.dart';

class EngineTransform extends StatelessWidget {
  final WorksheetItem item;
  final List<String>? currentAnswer;
  final ValueChanged<List<String>> onChanged;
  final bool isLocked;

  const EngineTransform({
    super.key,
    required this.item,
    required this.currentAnswer,
    required this.onChanged,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have a list of correct length
    final selections =
        currentAnswer ?? List<String>.filled(item.steps.length, '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMedium,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.prompt,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(height: 12),
                const Text(
                  'Final Answer:',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.answer is String
                      ? item.answer
                      : item.raw['final_answer'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.translation != null &&
                    item.translation!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Çeviri:',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.translation!,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Steps
        ...List.generate(item.steps.length, (index) {
          final step = item.steps[index];
          final stepSelection =
              index < selections.length ? selections[index] : '';
          final isStepCorrect = isLocked && stepSelection == step.answer;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${index + 1}. ${step.label}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isStepCorrect ? Icons.check_circle : Icons.cancel,
                        color:
                            isStepCorrect ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      step.options.map((option) {
                        final isSelected = stepSelection == option;
                        final isCorrect = option == step.answer;

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
                            bgColor = AppColors.success.withValues(alpha: 0.3);
                          } else {
                            bgColor = AppColors.surfaceLight.withValues(
                              alpha: 0.3,
                            );
                            textColor = Colors.white38;
                          }
                        } else {
                          if (isSelected) {
                            bgColor = AppColors.primary;
                            borderSide = const BorderSide(
                              color: AppColors.primaryLight,
                              width: 2,
                            );
                          }
                        }

                        return GestureDetector(
                          onTap:
                              isLocked
                                  ? null
                                  : () {
                                    final newSelections = List<String>.from(
                                      selections,
                                    );
                                    // Ensure size
                                    while (newSelections.length <= index) {
                                      newSelections.add('');
                                    }
                                    newSelections[index] = option;
                                    onChanged(newSelections);
                                  },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.fromBorderSide(borderSide),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
