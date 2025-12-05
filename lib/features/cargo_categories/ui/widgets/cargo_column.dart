import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/cargo_word.dart';
import '../../models/category.dart';
import 'cargo_package.dart';

class CargoColumnWidget extends StatelessWidget {
  const CargoColumnWidget({
    required this.category,
    required this.words,
    required this.showCategoryName,
    required this.onReceiveWord,
    required this.onWordMoved,
    this.onBookmarkTap,
    this.showTranslate = false,
    super.key,
  });

  final Category category;
  final List<CargoWord> words; // Max 4 words
  final bool showCategoryName; // If false, show "?"
  final Function(CargoWord) onReceiveWord; // Called when word dropped from belt
  final Function(CargoWord, int) onWordMoved; // Called when word moved from another column
  final Function(CargoWord)? onBookmarkTap; // Called when bookmark icon is tapped
  final bool showTranslate; // If true, show Turkish translations

  Color get _categoryColor {
    try {
      final colorString = category.color.replaceAll('#', '');
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _categoryColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Truck icon and category label at top
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/icons/local_shipping.svg',
                    width: 48,
                    height: 48,
                    colorFilter: ColorFilter.mode(
                      _categoryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showCategoryName ? category.name : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${words.length} / 4',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Words list
            Expanded(
              child: DragTarget<CargoWord>(
                onWillAcceptWithDetails: (details) {
                  // Accept all words (no limit)
                  return true;
                },
                onAcceptWithDetails: (details) {
                  final word = details.data;
                  // Check if word is already in this column
                  if (!words.any((w) => w.word == word.word)) {
                    onReceiveWord(word);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovering = candidateData.isNotEmpty;
                  final isRejected = rejectedData.isNotEmpty;

                  return Container(
                    decoration: BoxDecoration(
                      color: isHovering
                          ? _categoryColor.withValues(alpha: 0.2)
                          : isRejected
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: words.isEmpty
                        ? Center(
                          child: Text(
                            'Kelime sürükle',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: words.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final word = words[index];
                            return Draggable<CargoWord>(
                              data: word,
                              feedback: Material(
                                color: Colors.transparent,
                                child: CargoPackage(
                                  word: word,
                                  isSmall: false, // Larger when dragging
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: CargoPackage(
                                  word: word,
                                  isSmall: true,
                                ),
                              ),
                              child: CargoPackage(
                                word: word,
                                isSmall: true, // Small size in column
                                onBookmarkTap: onBookmarkTap != null
                                    ? () => onBookmarkTap!(word)
                                    : null,
                                showTranslate: showTranslate,
                              ),
                              onDragEnd: (details) {
                                // Word was dragged but not dropped on a valid target
                                // This is handled by the DragTarget in the column
                              },
                            );
                          },
                        ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

