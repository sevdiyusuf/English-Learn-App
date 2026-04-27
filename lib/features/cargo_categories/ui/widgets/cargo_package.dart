import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/cargo_word.dart';

class CargoPackage extends StatelessWidget {
  final CargoWord word;
  final bool isSmall; // true for column, false for belt
  final VoidCallback? onBookmarkTap; // Callback for bookmark tap (only used when isSmall is true)
  final bool showTranslate; // If true, show Turkish translation instead of English word

  const CargoPackage({
    super.key,
    required this.word,
    this.isSmall = false,
    this.onBookmarkTap,
    this.showTranslate = false,
  });

  @override
  Widget build(BuildContext context) {
    final double height = isSmall ? 42 : 64; // Biraz büyütüldü
    final double fontSize = isSmall ? 12 : 17; // Biraz büyütüldü
    final double packageIconSize = isSmall ? 20 : 28; // package.svg için daha büyük
    final double borderRadius = isSmall ? 6 : 12;

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD7B483), // Light cardboard
            Color(0xFFA67C52), // Dark cardboard
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: isSmall ? 2 : 4,
            offset: Offset(0, isSmall ? 1 : 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF8D6E63),
          width: isSmall ? 0.5 : 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tape effect
          Center(
            child: Container(
              height: double.infinity,
              width: isSmall ? 8 : 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 8 : 16,
                vertical: isSmall ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(isSmall ? 4 : 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sol tarafa package.svg ikonu
                  SvgPicture.asset(
                    'assets/icons/package.svg',
                    width: packageIconSize,
                    height: packageIconSize,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.7),
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: isSmall ? 6 : 10),
                  Flexible(
                    child: Text(
                      showTranslate ? word.translate : word.word,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: isSmall ? 0 : 0.5,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bookmark icon - sadece kategoriye yerleşmiş halinde (isSmall: true)
          // Paketin sağ üstünde, beyaz alanın dışında
          if (isSmall && onBookmarkTap != null)
            Positioned(
              top: -6,
              right: -6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBookmarkTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/bookmark.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.9),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Staples (Decoration) - only for large boxes
          if (!isSmall) ...[
            Positioned(top: 4, left: 4, child: _buildStaple()),
            Positioned(top: 4, right: 4, child: _buildStaple()),
            Positioned(bottom: 4, left: 4, child: _buildStaple()),
            Positioned(bottom: 4, right: 4, child: _buildStaple()),
          ],
        ],
      ),
    );
  }

  Widget _buildStaple() {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFF5D4037),
        shape: BoxShape.circle,
      ),
    );
  }
}

