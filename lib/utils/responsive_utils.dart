import 'package:flutter/material.dart';

/// Breakpoints for responsive design
/// Based on Material Design breakpoints
class AppBreakpoints {
  /// Mobile: phones in portrait
  static const double mobile = 0;

  /// Tablet: phones in landscape / small tablets
  static const double tablet = 600;

  /// Desktop: large tablets / desktops
  static const double desktop = 1024;

  /// Wide desktop: large monitors
  static const double wide = 1440;
}

/// Responsive utility class
class AppResponsive {
  /// Check if screen width is mobile (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppBreakpoints.tablet;
  }

  /// Check if screen width is tablet (600-1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.tablet && width < AppBreakpoints.desktop;
  }

  /// Check if screen width is desktop (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpoints.desktop;
  }

  /// Check if screen is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get screen width
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.desktop) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (width >= AppBreakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.desktop) {
      return 48;
    } else if (width >= AppBreakpoints.tablet) {
      return 24;
    } else {
      return 16;
    }
  }

  /// Get max content width for readability on large screens
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.wide) {
      return 1200;
    } else if (width >= AppBreakpoints.desktop) {
      return 900;
    } else if (width >= AppBreakpoints.tablet) {
      return 600;
    } else {
      return width - 32; // Full width with padding
    }
  }

  /// Get responsive font size
  static double fontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.desktop && desktop != null) {
      return desktop;
    } else if (width >= AppBreakpoints.tablet && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Get responsive grid columns count
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.wide) {
      return 4;
    } else if (width >= AppBreakpoints.desktop) {
      return 3;
    } else if (width >= AppBreakpoints.tablet) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Build widget based on screen size
  static Widget buildForScreen({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.desktop && desktop != null) {
      return desktop;
    } else if (width >= AppBreakpoints.tablet && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

/// Responsive layout widget that adapts content based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktop && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= AppBreakpoints.tablet &&
            tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Widget that constrains content width for better readability on large screens
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ConstrainedContent({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppResponsive.maxContentWidth(context);
    final horizontalPadding = AppResponsive.horizontalPadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive spacing utility
class AppSpacing {
  /// Get spacing based on screen size
  static double spacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.desktop && desktop != null) {
      return desktop;
    } else if (width >= AppBreakpoints.tablet && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Standard spacing values (mobile base)
  static double xs(BuildContext context) => 4;
  static double sm(BuildContext context) => 8;
  static double md(BuildContext context) => 16;
  static double lg(BuildContext context) => 24;
  static double xl(BuildContext context) => 32;
  static double xxl(BuildContext context) => 48;
}
