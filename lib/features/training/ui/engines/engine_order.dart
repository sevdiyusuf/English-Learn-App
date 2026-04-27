import 'package:flutter/material.dart';
import '../../models/training_models.dart';
import '../../../../core/theme/app_colors.dart';

class EngineOrder extends StatelessWidget {
  final WorksheetItem item;
  final List<String>? currentOrder;
  final ValueChanged<List<String>> onChanged;
  final bool isLocked;

  const EngineOrder({
    super.key,
    required this.item,
    required this.currentOrder,
    required this.onChanged,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final selected = currentOrder ?? [];
    // The bank should contain all items, but some might be selected already.
    // If duplicates are allowed, we need a different strategy.
    // Assuming 'order' engine usually means reordering a set of unique tokens
    // OR picking from a bank to form a sentence.
    // If the bank has unique tokens that move between bank and sentence line:
    final available = List<String>.from(item.bank);
    for (var s in selected) {
      available.remove(s);
      // Note: this removes first occurrence. If duplicates exist in bank, it handles one by one.
    }

    // Correct answer for display when locked
    final correctAnswer =
        item.answer is List
            ? (item.answer as List).join(' ')
            : item.answer.toString();

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
                item.prompt.isEmpty ? 'Order the words:' : item.prompt,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              if (isLocked) ...[
                const SizedBox(height: 8),
                Text(
                  'Answer: $correctAnswer',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.translation != null && item.translation!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Çeviri:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.translation!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sentence Line (Drop Zone)
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selected.map((word) {
                  return GestureDetector(
                    onTap:
                        isLocked
                            ? null
                            : () {
                              final newList = List<String>.from(selected)
                                ..remove(word);
                              onChanged(newList);
                            },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        word,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Token Bank
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children:
              available.map((word) {
                return GestureDetector(
                  onTap:
                      isLocked
                          ? null
                          : () {
                            final newList = List<String>.from(selected)
                              ..add(word);
                            onChanged(newList);
                          },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      word,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
