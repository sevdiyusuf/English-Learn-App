import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum MatchCardVisualState { normal, correct, wrong }

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.text,
    required this.onTap,
    required this.isSelected,
    required this.isSolved,
    required this.visualState,
    this.isLearned = false,
    this.onLearnedToggle,
  });

  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSolved;
  final MatchCardVisualState visualState;
  final bool isLearned;
  final VoidCallback? onLearnedToggle;

  @override
  Widget build(BuildContext context) {
    final isCorrect = visualState == MatchCardVisualState.correct;
    final isWrong = visualState == MatchCardVisualState.wrong;

    Color cardColor;
    Color borderColor;
    List<BoxShadow> shadows = [];

    // Durumlara göre renk ve efekt yönetimi
    if (isSolved || isCorrect) {
      cardColor = AppColors.success.withValues(alpha: 0.2);
      borderColor = AppColors.success;
      shadows = [
        BoxShadow(
          color: AppColors.success.withValues(alpha: 0.3),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else if (isWrong) {
      cardColor = Colors.redAccent.withValues(alpha: 0.2);
      borderColor = Colors.redAccent;
      shadows = [
        BoxShadow(
          color: Colors.redAccent.withValues(alpha: 0.3),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else if (isSelected) {
      cardColor = Colors.cyanAccent.withValues(alpha: 0.15);
      borderColor = Colors.cyanAccent;
      shadows = [
        BoxShadow(
          color: Colors.cyanAccent.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
    } else {
      cardColor = Colors.white30.withValues(alpha: 0.12);
      borderColor = Colors.white.withValues(alpha: 0.45);
    }

    return AnimatedScale(
      scale: isSelected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: isSolved ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isSelected || isCorrect || isWrong ? 2 : 1,
            ),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSolved ? Colors.white38 : Colors.white,
                        decoration:
                            isSolved ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  // Sağ üstteki yıldız butonu
                  if (onLearnedToggle != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: onLearnedToggle,
                        icon: Icon(
                          isLearned ? Icons.star : Icons.star_border,
                          color:
                              isLearned ? Colors.amberAccent : Colors.white24,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
