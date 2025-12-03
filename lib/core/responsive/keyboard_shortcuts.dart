import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'responsive_utils.dart';

/// Keyboard shortcuts for desktop
class KeyboardShortcuts {
  /// Handle keyboard shortcuts
  static Widget wrap({
    required Widget child,
    required Map<LogicalKeySet, VoidCallback> shortcuts,
  }) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final keySet = LogicalKeySet(event.logicalKey);
          final callback = shortcuts[keySet];
          if (callback != null) {
            callback();
          }
        }
      },
      child: child,
    );
  }

  /// Create enter key set
  static LogicalKeySet enter(LogicalKeyboardKey key) {
    return LogicalKeySet(key);
  }

  /// Create escape key set
  static LogicalKeySet escape(LogicalKeyboardKey key) {
    return LogicalKeySet(key);
  }

  /// Create space key set
  static LogicalKeySet space(LogicalKeyboardKey key) {
    return LogicalKeySet(key);
  }
}

/// Keyboard shortcut handler for game
class GameKeyboardShortcuts extends StatelessWidget {
  const GameKeyboardShortcuts({
    required this.child,
    this.onSubmit,
    this.onCancel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    // Only enable keyboard shortcuts on desktop
    if (!ResponsiveUtils.isDesktop(context)) {
      return child;
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter && onSubmit != null) {
            onSubmit!();
          } else if (event.logicalKey == LogicalKeyboardKey.escape && onCancel != null) {
            onCancel!();
          }
        }
      },
      child: child,
    );
  }
}

