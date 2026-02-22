import 'package:flutter/material.dart';
import 'colors.dart';

/// Industrial Minimalism Elevation System
///
/// Z-Axis Spatial Depth through translation, lighting, and shadows.
///
/// Z=0: Base layer (flat, no shadows)
/// Z=1: Interactive components (buttons, cards)
/// Z=2: Attraction points (key actions, hover states)
/// Z=3: Critical/Modal (dialogs, overlays)
///
/// Inspired by: Teenage Engineering × Nothing Phone × Notion × Revolut
class AppElevation {
  const AppElevation._();

  // ===========================================================================
  // Z-AXIS LEVELS (Translation Values)
  // ===========================================================================

  /// Z=0: Base layer
  /// No elevation, flat surfaces
  /// Use: Backgrounds, static surfaces
  static const double z0 = 0.0;

  /// Z=1: Interactive layer
  /// Slight elevation for interactive elements
  /// Use: Cards, buttons (idle state)
  static const double z1 = 2.0;

  /// Z=2: Attraction layer
  /// Medium elevation for important elements
  /// Use: Hover states, key actions, modals
  static const double z2 = 4.0;

  /// Z=3: Critical layer
  /// High elevation for critical elements
  /// Use: Active press, drag, dialogs, FAB
  static const double z3 = 8.0;

  /// Z=4: Overlay layer
  /// Maximum elevation for overlays
  /// Use: Full-screen modals, popovers
  static const double z4 = 16.0;

  // ===========================================================================
  // SHADOW CONFIGURATIONS (Light Theme)
  // ===========================================================================

  /// Z=0 Shadow - No shadow
  static const List<BoxShadow> z0Shadow = [];

  /// Z=1 Shadow - Soft ambient shadow
  /// Use: Cards, buttons at rest
  static List<BoxShadow> get z1ShadowLight => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.08),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  /// Z=2 Shadow - Defined shadow with subtle glow
  /// Use: Hover states, important actions
  static List<BoxShadow> get z2ShadowLight => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.12),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
    // Subtle colored glow (Signal Orange at low opacity)
    BoxShadow(
      color: AppColors.signalOrange.withValues(alpha: 0.08),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 0),
    ),
  ];

  /// Z=3 Shadow - Strong shadow with halo
  /// Use: Active press, dialogs
  static List<BoxShadow> get z3ShadowLight => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.16),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    // Colored halo
    BoxShadow(
      color: AppColors.signalOrange.withValues(alpha: 0.1),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 0),
    ),
  ];

  /// Z=4 Shadow - Maximum shadow
  /// Use: Full-screen overlays
  static List<BoxShadow> get z4ShadowLight => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.2),
      blurRadius: 32,
      spreadRadius: 0,
      offset: const Offset(0, 16),
    ),
  ];

  // ===========================================================================
  // SHADOW CONFIGURATIONS (Dark Theme)
  // ===========================================================================

  /// Z=1 Shadow - Dark theme
  /// Higher opacity for visibility on dark backgrounds
  static List<BoxShadow> get z1ShadowDark => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.2),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  /// Z=2 Shadow - Dark theme
  static List<BoxShadow> get z2ShadowDark => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.3),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
    // Subtle colored glow
    BoxShadow(
      color: AppColors.signalOrange.withValues(alpha: 0.12),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 0),
    ),
  ];

  /// Z=3 Shadow - Dark theme
  static List<BoxShadow> get z3ShadowDark => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.4),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    // Colored halo
    BoxShadow(
      color: AppColors.signalOrange.withValues(alpha: 0.15),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 0),
    ),
  ];

  /// Z=4 Shadow - Dark theme
  static List<BoxShadow> get z4ShadowDark => [
    BoxShadow(
      color: AppColors.pureBlack.withValues(alpha: 0.5),
      blurRadius: 32,
      spreadRadius: 0,
      offset: const Offset(0, 16),
    ),
  ];

  // ===========================================================================
  // SHADOW HELPERS
  // ===========================================================================

  /// Get shadow for Z level (light theme)
  static List<BoxShadow> shadowForZLevelLight(double z) {
    if (z <= z0) return z0Shadow;
    if (z <= z1) return z1ShadowLight;
    if (z <= z2) return z2ShadowLight;
    if (z <= z3) return z3ShadowLight;
    return z4ShadowLight;
  }

  /// Get shadow for Z level (dark theme)
  static List<BoxShadow> shadowForZLevelDark(double z) {
    if (z <= z0) return z0Shadow;
    if (z <= z1) return z1ShadowDark;
    if (z <= z2) return z2ShadowDark;
    if (z <= z3) return z3ShadowDark;
    return z4ShadowDark;
  }

  /// Get shadow for Z level based on brightness
  static List<BoxShadow> shadowForZLevel(double z, Brightness brightness) {
    return brightness == Brightness.dark
        ? shadowForZLevelDark(z)
        : shadowForZLevelLight(z);
  }

  // ===========================================================================
  // LIGHTING MODEL
  // ===========================================================================

  /// Primary light source angle: 135° (top-left)
  /// Used for calculating highlight and shadow direction
  static const double lightSourceAngle = 135.0 * (3.14159 / 180);

  /// Get highlight gradient for elevated surfaces
  /// Simulates light reflection on Z=2+ elements
  static LinearGradient highlightGradient({
    double opacity = 0.1,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        AppColors.pureWhite.withValues(alpha: opacity),
        AppColors.pureWhite.withValues(alpha: 0),
      ],
    );
  }

  /// Get edge lighting effect
  /// 1px inner highlight on elevated surfaces
  static BoxDecoration edgeLighting({
    required Color borderColor,
    double width = 1.0,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      border: Border(
        top: BorderSide(
          color: AppColors.pureWhite.withValues(alpha: 0.1),
          width: width,
        ),
        left: BorderSide(
          color: AppColors.pureWhite.withValues(alpha: 0.1),
          width: width,
        ),
      ),
      borderRadius: borderRadius,
    );
  }

  // ===========================================================================
  // DECORATION HELPERS
  // ===========================================================================

  /// Create BoxDecoration with elevation
  static BoxDecoration boxDecoration({
    required Color color,
    required double zLevel,
    Brightness brightness = Brightness.light,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    final shadows = shadowForZLevel(zLevel, brightness);

    return BoxDecoration(
      color: color,
      boxShadow: shadows,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      border: border,
    );
  }

  /// Create BoxDecoration for interactive component
  /// Z=1 idle, Z=2 hover
  static BoxDecoration interactiveDecoration({
    required Color color,
    bool isHovered = false,
    bool isPressed = false,
    Brightness brightness = Brightness.light,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    double zLevel = z1;
    if (isPressed) zLevel = z1; // Press stays at Z=1 but translates down
    if (isHovered) zLevel = z2;

    return boxDecoration(
      color: color,
      zLevel: zLevel,
      brightness: brightness,
      borderRadius: borderRadius,
      border: border,
    );
  }

  // ===========================================================================
  // TRANSFORM HELPERS
  // ===========================================================================

  /// Get translation for Z level
  /// Use with Transform.translate for Z-axis effect
  static Offset translationForZLevel(double z) {
    return Offset(0, -z);
  }

  /// Get scale for pressed state
  /// Slight scale down to simulate physical depression
  static const double pressScale = 0.98;

  /// Get scale for hover state
  /// Slight scale up to simulate lift
  static const double hoverScale = 1.02;

  // ===========================================================================
  // ANIMATION SPECIFICATIONS
  // ===========================================================================

  /// Duration for elevation transitions
  static const Duration elevationDuration = Duration(milliseconds: 200);

  /// Curve for elevation transitions
  static const Curve elevationCurve = Curves.easeInOutCubic;

  /// Spring curve for tactile elevation changes
  static const Curve elevationSpring = Curves.easeInOutCubicEmphasized;
}
