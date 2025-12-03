import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final background = switch (visualState) {
      MatchCardVisualState.correct => colorScheme.primaryContainer,
      MatchCardVisualState.wrong => colorScheme.errorContainer,
      MatchCardVisualState.normal => colorScheme.surfaceContainerHighest,
    };
    final borderColor =
        isSelected
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color:
            isSolved
                ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                : background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSolved ? colorScheme.primary : borderColor,
          width: isSelected ? 2.2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: isSolved ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 18.0,
                ),
                child: Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          isSolved
                              ? colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              )
                              : colorScheme.onSurface,
                      decoration: isSolved ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ),
            // ⭐ toggle icon - only show on solved cards
            if (isSolved && onLearnedToggle != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: Tooltip(
                    message: isLearned ? 'Öğrendiğim kelime' : 'Öğrenmediğim kelime',
                    child: InkWell(
                      onTap: onLearnedToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: isLearned
                            ? SvgPicture.asset(
                                'assets/icons/star.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Colors.amber,
                                  BlendMode.srcIn,
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/icons/star_empty.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
