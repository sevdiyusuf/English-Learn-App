import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The colors available for selection
const accentColorsList = [
  Color(0xFF2997FF), // Blue
  Color(0xFF9B59FF), // Purple
  Color(0xFF00D1FF), // Cyan
  Color(0xFFFF4B5C), // Red
];

class AccentColorNotifier extends StateNotifier<int> {
  AccentColorNotifier() : super(0);

  void setAccentIndex(int index) {
    state = index;
  }

  Color get currentColor {
    if (state >= 0 && state < accentColorsList.length) {
      return accentColorsList[state];
    }
    return accentColorsList[0];
  }
}

final accentColorProvider = StateNotifierProvider<AccentColorNotifier, int>((ref) {
  return AccentColorNotifier();
});
