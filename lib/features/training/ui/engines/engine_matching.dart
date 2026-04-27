import 'package:flutter/material.dart';
import '../../models/training_models.dart';
import '../../../../core/theme/app_colors.dart';

class EngineMatching extends StatefulWidget {
  final WorksheetItem item;
  final Map<String, String>? currentMatches;
  final ValueChanged<Map<String, String>> onChanged;
  final bool isLocked;

  const EngineMatching({
    super.key,
    required this.item,
    required this.currentMatches,
    required this.onChanged,
    required this.isLocked,
  });

  @override
  State<EngineMatching> createState() => _EngineMatchingState();
}

class _EngineMatchingState extends State<EngineMatching> {
  String? _selectedLeft;

  // We need to store keys and values separately to display them
  late List<String> _leftItems;
  late List<String> _rightItems;

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    // Assuming item.options contains keys, and item.answer is a Map<String, String>
    // Or item.raw might have structure.
    // Let's assume item.options is the list of all items (keys and values mixed) or just keys?
    // Based on standard implementation, we usually separate them.
    // If item.answer is Map<String, String>, keys are left, values are right.

    if (widget.item.answer is Map) {
      final map = widget.item.answer as Map;
      _leftItems = map.keys.map((e) => e.toString()).toList();
      _rightItems = map.values.map((e) => e.toString()).toList();
      // Shuffle right items for difficulty
      _rightItems.shuffle();
    } else {
      // Fallback or specific parsing logic if answer is not a map directly
      _leftItems = [];
      _rightItems = [];
    }
  }

  void _handleLeftTap(String item) {
    if (widget.isLocked) return;
    setState(() {
      if (_selectedLeft == item) {
        _selectedLeft = null;
      } else {
        _selectedLeft = item;
      }
    });
  }

  void _handleRightTap(String item) {
    if (widget.isLocked || _selectedLeft == null) return;

    final newMatches = Map<String, String>.from(widget.currentMatches ?? {});

    // If this right item is already matched, remove that match
    final existingKey = newMatches.keys.firstWhere(
      (k) => newMatches[k] == item,
      orElse: () => '',
    );
    if (existingKey.isNotEmpty) {
      newMatches.remove(existingKey);
    }

    // Set new match
    newMatches[_selectedLeft!] = item;

    widget.onChanged(newMatches);
    setState(() {
      _selectedLeft = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.item.hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.item.hint!,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        Row(
          children: [
            // Left Column
            Expanded(
              child: Column(
                spacing: 12,
                children:
                    _leftItems.map((item) => _buildLeftItem(item)).toList(),
              ),
            ),

            const SizedBox(width: 24),

            // Right Column
            Expanded(
              child: Column(
                spacing: 12,
                children:
                    _rightItems.map((item) => _buildRightItem(item)).toList(),
              ),
            ),
          ],
        ),
        if (widget.isLocked &&
            widget.item.translation != null &&
            widget.item.translation!.isNotEmpty) ...[
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
            widget.item.translation!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLeftItem(String text) {
    final isSelected = _selectedLeft == text;
    final isMatched = widget.currentMatches?.containsKey(text) ?? false;
    final matchedValue = widget.currentMatches?[text];

    // Correctness check
    bool? isCorrect;
    if (widget.isLocked && isMatched) {
      final correctValue = (widget.item.answer as Map)[text];
      isCorrect = matchedValue == correctValue;
    }

    Color borderColor = Colors.transparent;
    Color bgColor = AppColors.surfaceLight;

    if (widget.isLocked) {
      if (isMatched) {
        borderColor = isCorrect! ? AppColors.success : AppColors.error;
        bgColor =
            isCorrect
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1);
      }
    } else {
      if (isSelected) {
        borderColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.2);
      } else if (isMatched) {
        borderColor = AppColors.accent;
        bgColor = AppColors.accent.withValues(alpha: 0.1);
      }
    }

    return GestureDetector(
      onTap: () => _handleLeftTap(text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRightItem(String text) {
    // Check if this item is matched with any left item
    final matchedKey = widget.currentMatches?.keys.firstWhere(
      (k) => widget.currentMatches![k] == text,
      orElse: () => '',
    );
    final isMatched = matchedKey != null && matchedKey.isNotEmpty;

    // Correctness check
    bool? isCorrect;
    if (widget.isLocked && isMatched) {
      final correctValue = (widget.item.answer as Map)[matchedKey];
      isCorrect = text == correctValue;
    }

    Color borderColor = Colors.transparent;
    Color bgColor = AppColors.surfaceLight;

    if (widget.isLocked) {
      if (isMatched) {
        borderColor = isCorrect! ? AppColors.success : AppColors.error;
        bgColor =
            isCorrect
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1);
      }
    } else {
      if (isMatched) {
        borderColor = AppColors.accent;
        bgColor = AppColors.accent.withValues(alpha: 0.1);
      }
    }

    return GestureDetector(
      onTap: () => _handleRightTap(text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
