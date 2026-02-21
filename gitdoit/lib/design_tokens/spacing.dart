import 'package:flutter/material.dart';

/// Industrial Minimalism Spacing System
///
/// Base unit: 8px - All spacing values are multiples of 8px
/// for visual consistency and rhythm.
///
/// Inspired by: Teenage Engineering × Nothing Phone × Notion × Revolut
class AppSpacing {
  const AppSpacing._();

  // ===========================================================================
  // BASE UNIT
  // ===========================================================================

  /// Base spacing unit: 8px
  /// All other spacing values are derived from this unit
  static const double unit = 8.0;

  // ===========================================================================
  // SPACING SCALE (Margins & Padding)
  // ===========================================================================

  /// Extra Small: 4px (0.5x unit)
  /// Use: Tight spacing, icon gaps
  static const double xxs = 4.0;

  /// Extra Small: 8px (1x unit)
  /// Use: Minimum internal padding, tight spacing
  static const double xs = 8.0;

  /// Small: 12px (1.5x unit)
  /// Use: Compact spacing for chips, badges
  static const double sm = 12.0;

  /// Medium: 16px (2x unit)
  /// Use: Standard padding, margins
  static const double md = 16.0;

  /// Large: 24px (3x unit)
  /// Use: Section spacing, card padding
  static const double lg = 24.0;

  /// Extra Large: 32px (4x unit)
  /// Use: Large section gaps
  static const double xl = 32.0;

  /// Extra Extra Large: 48px (6x unit)
  /// Use: Screen margins, major divisions
  static const double xxl = 48.0;

  /// Extra Extra Extra Large: 64px (8x unit)
  /// Use: Hero sections, screen headers
  static const double xxxl = 64.0;

  // ===========================================================================
  // COMPONENT SPACING
  // ===========================================================================

  // Button Padding
  /// Primary button horizontal padding
  static const double buttonPaddingHorizontal = 24.0;

  /// Primary button vertical padding
  static const double buttonPaddingVertical = 14.0;

  /// Secondary button horizontal padding
  static const double buttonPaddingHorizontalSecondary = 20.0;

  /// Secondary button vertical padding
  static const double buttonPaddingVerticalSecondary = 12.0;

  /// Text button horizontal padding
  static const double buttonPaddingHorizontalText = 12.0;

  /// Text button vertical padding
  static const double buttonPaddingVerticalText = 8.0;

  // Card Padding
  /// Standard card padding (all sides)
  static const double cardPadding = 16.0;

  /// Large card padding
  static const double cardPaddingLarge = 24.0;

  // Input Padding
  /// Input field vertical padding
  static const double inputPaddingVertical = 14.0;

  /// Input field horizontal padding
  static const double inputPaddingHorizontal = 16.0;

  // Badge/Chip Padding
  /// Badge vertical padding
  static const double badgePaddingVertical = 4.0;

  /// Badge horizontal padding
  static const double badgePaddingHorizontal = 8.0;

  // Screen Margins
  /// Screen horizontal margin
  static const double screenMarginHorizontal = 16.0;

  /// Screen vertical margin
  static const double screenMarginVertical = 16.0;

  // ===========================================================================
  // BORDER RADIUS
  // ===========================================================================

  /// Small radius: 4px
  /// Use: Small badges, tight corners
  static const double radiusSmall = 4.0;

  /// Medium radius: 8px
  /// Use: Buttons, cards, inputs (default)
  static const double radiusMedium = 8.0;

  /// Large radius: 16px
  /// Use: Large cards, modals
  static const double radiusLarge = 16.0;

  /// Extra large radius: 24px
  /// Use: Extra large containers
  static const double radiusExtraLarge = 24.0;

  /// Full radius: 999px
  /// Use: Pills, circular buttons, toggles, avatars
  static const double radiusFull = 999.0;

  // ===========================================================================
  // TOUCH TARGETS
  // ===========================================================================

  /// Minimum touch target size: 48x48 dp
  /// WCAG AA compliant minimum
  static const double touchTargetMin = 48.0;

  /// Recommended touch target size: 56x56 dp
  /// For primary actions
  static const double touchTargetRecommended = 56.0;

  /// Icon size for buttons
  static const double iconSize = 24.0;

  /// Small icon size
  static const double iconSizeSmall = 20.0;

  /// Large icon size
  static const double iconSizeLarge = 32.0;

  // ===========================================================================
  // DIVIDER & STROKE
  // ===========================================================================

  /// Standard divider thickness
  static const double dividerThickness = 1.0;

  /// Thick divider thickness
  static const double dividerThicknessLarge = 2.0;

  /// Subtle divider thickness
  static const double dividerThicknessSmall = 0.5;

  // ===========================================================================
  // LAYOUT GRID
  // ===========================================================================

  // Phone (<600px)
  /// Phone columns
  static const int gridColumnsPhone = 4;

  /// Phone margin
  static const double gridMarginPhone = 16.0;

  /// Phone gutter
  static const double gridGutterPhone = 16.0;

  // Tablet (600-900px)
  /// Tablet columns
  static const int gridColumnsTablet = 8;

  /// Tablet margin
  static const double gridMarginTablet = 24.0;

  /// Tablet gutter
  static const double gridGutterTablet = 24.0;

  // Desktop (>900px)
  /// Desktop columns
  static const int gridColumnsDesktop = 12;

  /// Desktop margin
  static const double gridMarginDesktop = 32.0;

  /// Desktop gutter
  static const double gridGutterDesktop = 24.0;

  /// Desktop max width
  static const double desktopMaxWidth = 1200.0;

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Get EdgeInsets with uniform padding
  static EdgeInsets all(double value) => EdgeInsets.all(value);

  /// Get EdgeInsets with symmetric padding
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Get EdgeInsets with only padding
  static EdgeInsets only({
    double top = 0,
    double right = 0,
    double bottom = 0,
    double left = 0,
  }) {
    return EdgeInsets.only(top: top, right: right, bottom: bottom, left: left);
  }

  /// Get standard screen padding
  static EdgeInsets screenPadding() {
    return EdgeInsets.symmetric(
      horizontal: screenMarginHorizontal,
      vertical: screenMarginVertical,
    );
  }

  /// Get standard card border radius
  static BorderRadius cardBorderRadius() {
    return BorderRadius.circular(radiusMedium);
  }

  /// Get full (pill) border radius
  static BorderRadius pillBorderRadius() {
    return BorderRadius.circular(radiusFull);
  }

  /// Calculate gap based on count
  /// Returns appropriate gap for list of items
  static double gap({int count = 1, double base = xs}) {
    return base * count;
  }

  /// Get responsive horizontal margin based on screen width
  static double responsiveHorizontalMargin(double screenWidth) {
    if (screenWidth > 900) return gridMarginDesktop;
    if (screenWidth > 600) return gridMarginTablet;
    return gridMarginPhone;
  }
}
