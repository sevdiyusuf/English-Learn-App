import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/category.dart';
import '../../models/cargo_word.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryDock extends StatelessWidget {
  const CategoryDock({
    required this.category,
    required this.onTap,
    required this.onReceiveWord, // YENİ: Kelime alma fonksiyonu
    required this.isHighlighted,
    required this.isWrong,
    super.key,
  });

  final Category category;
  final VoidCallback onTap;
  final Function(CargoWord) onReceiveWord; // Callback tanımı
  final bool isHighlighted;
  final bool isWrong;

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
      child: DragTarget<CargoWord>(
        // Her türlü kelimeyi kabul et
        onWillAcceptWithDetails: (details) => true,

        // Kelime bırakıldığında
        onAcceptWithDetails: (details) {
          final data = details.data;
          debugPrint("CategoryDock: Kelime bırakıldı -> ${data.word}");
          // Controller'a iletmek üzere yukarı gönder
          onReceiveWord(data);
        },

        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap, // Sadece tıklama (test için vs.)
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isHighlighted
                          ? AppColors.success.withValues(alpha: 0.2)
                          : isWrong
                          ? AppColors.error.withValues(alpha: 0.2)
                          : isHovering
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isHighlighted
                            ? AppColors.success
                            : isWrong
                            ? AppColors.error
                            : isHovering
                            ? Colors.white
                            : _categoryColor,
                    width: isHighlighted || isWrong || isHovering ? 3 : 2,
                  ),
                  boxShadow: [
                    if (isHighlighted || isHovering)
                      BoxShadow(
                        color: (isHighlighted
                                ? AppColors.success
                                : Colors.white)
                            .withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/local_shipping.svg',
                      width: 48,
                      height: 48,
                      colorFilter: ColorFilter.mode(
                        isHovering ? Colors.white : _categoryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            isHovering ? FontWeight.w900 : FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
