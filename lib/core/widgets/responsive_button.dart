import 'package:flutter/material.dart';

import '../responsive/responsive_utils.dart';

/// Responsive button with adaptive sizing
class ResponsiveButton extends StatelessWidget {
  const ResponsiveButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.style,
    this.tooltip,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final buttonHeight = ResponsiveUtils.buttonHeight(context);
    final minWidth = isMobile ? 120.0 : 100.0;

    Widget button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: buttonHeight,
      ),
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon!,
              label: child,
              style: style,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: child,
            ),
    );

    if (tooltip != null && !isMobile) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Responsive filled button
class ResponsiveFilledButton extends StatelessWidget {
  const ResponsiveFilledButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.tooltip,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final buttonHeight = ResponsiveUtils.buttonHeight(context);
    final minWidth = isMobile ? 120.0 : 100.0;

    Widget button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: buttonHeight,
      ),
      child: icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: icon!,
              label: child,
            )
          : FilledButton(
              onPressed: onPressed,
              child: child,
            ),
    );

    if (tooltip != null && !isMobile) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Responsive text button
class ResponsiveTextButton extends StatelessWidget {
  const ResponsiveTextButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.tooltip,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final minHeight = isMobile ? 48.0 : 40.0;

    Widget button = SizedBox(
      height: minHeight,
      child: icon != null
          ? TextButton.icon(
              onPressed: onPressed,
              icon: icon!,
              label: child,
            )
          : TextButton(
              onPressed: onPressed,
              child: child,
            ),
    );

    if (tooltip != null && !isMobile) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

/// Responsive icon button
class ResponsiveIconButton extends StatelessWidget {
  const ResponsiveIconButton({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.size,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final iconSize = size ?? ResponsiveUtils.iconSize(context);
    final buttonSize = isMobile ? 48.0 : 40.0;

    Widget button = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
      ),
    );

    if (tooltip != null && !isMobile) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

