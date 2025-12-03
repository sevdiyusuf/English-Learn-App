import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG icon widget with Material Icon fallback for web compatibility
class SvgIcon extends StatelessWidget {
  const SvgIcon({
    required this.svgAsset,
    required this.fallbackIcon,
    this.color,
    this.size,
    super.key,
  });

  final String svgAsset;
  final IconData fallbackIcon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.0;
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.white;

    // Try to load SVG, fallback to Material Icon if not found
    return Builder(
      builder: (context) {
        try {
          return SvgPicture.asset(
            svgAsset,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            width: iconSize,
            height: iconSize,
            placeholderBuilder: (context) => Icon(
              fallbackIcon,
              color: iconColor,
              size: iconSize,
            ),
          );
        } catch (e) {
          // If SVG fails, use Material Icon as fallback
          return Icon(
            fallbackIcon,
            color: iconColor,
            size: iconSize,
          );
        }
      },
    );
  }
}

