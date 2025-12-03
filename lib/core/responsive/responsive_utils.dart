import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Breakpoint definitions for responsive design
class Breakpoints {
  // Mobile first approach
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 900;
  static const double wide = 1200;
  static const double ultraWide = 1600;

  /// Check if current width is mobile
  static bool isMobile(double width) => width < tablet;

  /// Check if current width is tablet
  static bool isTablet(double width) => width >= tablet && width < desktop;

  /// Check if current width is desktop
  static bool isDesktop(double width) => width >= desktop && width < wide;

  /// Check if current width is wide desktop
  static bool isWide(double width) => width >= wide;

  /// Check if current width is ultra wide
  static bool isUltraWide(double width) => width >= ultraWide;
}

/// Screen size category
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  wide,
  ultraWide,
}

/// Responsive utilities
class ResponsiveUtils {
  /// Get screen size category from width
  static ScreenSize getScreenSize(double width) {
    if (width < Breakpoints.tablet) return ScreenSize.mobile;
    if (width < Breakpoints.desktop) return ScreenSize.tablet;
    if (width < Breakpoints.wide) return ScreenSize.desktop;
    if (width < Breakpoints.ultraWide) return ScreenSize.wide;
    return ScreenSize.ultraWide;
  }

  /// Get responsive value based on screen size
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
    T? ultraWide,
  }) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = getScreenSize(width);

    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.wide:
        return wide ?? desktop ?? tablet ?? mobile;
      case ScreenSize.ultraWide:
        return ultraWide ?? wide ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsive<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(20),
      desktop: const EdgeInsets.all(24),
      wide: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return responsive<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 24),
      desktop: const EdgeInsets.symmetric(horizontal: 32),
      wide: const EdgeInsets.symmetric(horizontal: 48),
    );
  }

  /// Get responsive spacing
  static double responsiveSpacing(BuildContext context) {
    return responsive<double>(
      context: context,
      mobile: 8,
      tablet: 12,
      desktop: 16,
      wide: 20,
    );
  }

  /// Get responsive font size
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? wide,
  }) {
    return responsive<double>(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? tablet ?? mobile * 1.2,
      wide: wide ?? desktop ?? tablet ?? mobile * 1.3,
    );
  }

  /// Get responsive max width for content
  static double responsiveMaxWidth(BuildContext context) {
    return responsive<double>(
      context: context,
      mobile: double.infinity,
      tablet: 700,
      desktop: 1200,
      wide: 1400,
    );
  }

  /// Check if is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.tablet;
  }

  /// Check if is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.tablet && width < Breakpoints.desktop;
  }

  /// Check if is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  /// Check if is wide
  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.wide;
  }

  /// Get touch target size (minimum 48x48 for mobile)
  static double touchTargetSize(BuildContext context) {
    return isMobile(context) ? 48 : 40;
  }

  /// Get button height
  static double buttonHeight(BuildContext context) {
    return responsive<double>(
      context: context,
      mobile: 48,
      tablet: 44,
      desktop: 40,
    );
  }

  /// Get icon size
  static double iconSize(BuildContext context) {
    return responsive<double>(
      context: context,
      mobile: 24,
      tablet: 22,
      desktop: 20,
    );
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });

  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenSize = ResponsiveUtils.getScreenSize(width);
    return builder(context, screenSize);
  }
}

/// Responsive value widget
class ResponsiveValue<T> extends StatelessWidget {
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
    this.ultraWide,
    required this.builder,
    super.key,
  });

  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? wide;
  final T? ultraWide;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveUtils.responsive<T>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      wide: wide,
      ultraWide: ultraWide,
    );
    return builder(context, value);
  }
}

/// Adaptive container with max width constraint
class AdaptiveContainer extends StatelessWidget {
  const AdaptiveContainer({
    required this.child,
    this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveUtils.responsiveMaxWidth(context);
    final containerPadding = padding ?? ResponsiveUtils.responsivePadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: containerPadding,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }
}

