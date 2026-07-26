import 'package:flutter/material.dart';

/// Centers readable page content on wide windows while retaining compact
/// edge spacing and the caller's scroll/state ownership.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.maxWidth = 960,
    this.compactPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.expandedPadding = const EdgeInsets.symmetric(horizontal: 24),
    this.alignment = Alignment.topCenter,
    super.key,
  });

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 840;

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry compactPadding;
  final EdgeInsetsGeometry expandedPadding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding =
            constraints.maxWidth >= mediumBreakpoint
                ? expandedPadding
                : compactPadding;
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}
