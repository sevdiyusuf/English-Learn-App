import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Helper class for grid color tags
/// Each card index (0-8) has a fixed color
class GridColorHelper {
  static const List<Color> _colors = [
    Color(0xFF10B981), // Green (success)
    Color(0xFF6366F1), // Blue (primary/indigo)
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Orange (warning)
    Color(0xFF8B5CF6), // Purple (accent)
    Color(0xFFEAB308), // Yellow
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red (error)
    Color(0xFF94A3B8), // Gray (textTertiary)
  ];

  /// Get color for a card index (0-8)
  static Color colorForIndex(int index) {
    if (index < 0 || index >= _colors.length) {
      return AppColors.surfaceLight;
    }
    return _colors[index];
  }

  /// Get all available colors
  static List<Color> get allColors => List.unmodifiable(_colors);
}
