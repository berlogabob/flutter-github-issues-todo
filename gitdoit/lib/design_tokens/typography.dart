import 'package:flutter/material.dart';
import 'colors.dart';

/// Industrial Minimalism Typography System
///
/// Primary: Inter (Geometric Sans-Serif) - UI labels, headers, body
/// Secondary: JetBrains Mono (Monospace) - Data, IDs, timestamps, technical metadata
///
/// Inspired by: Teenage Engineering × Nothing Phone × Notion × Revolut
class AppTypography {
  const AppTypography._();

  // ===========================================================================
  // FONT FAMILIES
  // ===========================================================================

  /// Primary font family - Geometric Sans-Serif
  /// Use: Inter, or fallback to system sans-serif
  static const String fontFamilyPrimary = 'Inter';

  /// Secondary font family - Monospace
  /// Use: JetBrains Mono, or fallback to system monospace
  static const String fontFamilySecondary = 'JetBrains Mono';

  /// Fallback font family (system default)
  static const String fontFamilyFallback = '.SF Pro Display';

  // ===========================================================================
  // DISPLAY STYLES (Primary Font)
  // ===========================================================================

  /// Display Large - Page titles, hero sections
  /// 40px, Bold, -0.5px letter spacing
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Display Medium - Screen headers
  /// 32px, Bold, -0.3px letter spacing
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
  );

  // ===========================================================================
  // HEADLINE STYLES (Primary Font)
  // ===========================================================================

  /// Headline Large - Section headers
  /// 28px, Semi-Bold
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: -0.2,
  );

  /// Headline Medium - Card titles
  /// 24px, Semi-Bold
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0,
  );

  /// Headline Small - Subsection headers
  /// 20px, Semi-Bold
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  // ===========================================================================
  // BODY STYLES (Primary Font)
  // ===========================================================================

  /// Body Large - Long-form content
  /// 18px, Regular
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.56,
    letterSpacing: 0,
  );

  /// Body Medium - Primary body text
  /// 16px, Regular
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Body Small - Secondary content
  /// 14px, Regular
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0,
  );

  // ===========================================================================
  // LABEL STYLES (Primary Font)
  // ===========================================================================

  /// Label Large - Button labels (large buttons)
  /// 16px, Medium
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Label Medium - Button labels, input labels
  /// 14px, Medium, 0.2px letter spacing
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.2,
  );

  /// Label Small - Chip labels, small buttons
  /// 12px, Medium, 0.3px letter spacing
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.3,
  );

  // ===========================================================================
  // CAPTION STYLES (Primary Font)
  // ===========================================================================

  /// Caption Medium - Metadata, timestamps
  /// 12px, Regular
  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0,
  );

  /// Caption Small - Fine print, hints
  /// 11px, Regular
  static const TextStyle captionSmall = TextStyle(
    fontFamily: fontFamilyPrimary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.27,
    letterSpacing: 0,
  );

  // ===========================================================================
  // MONOSPACE STYLES (Secondary Font)
  // ===========================================================================

  /// Mono Data - IDs, issue numbers
  /// 14px, Regular
  static const TextStyle monoData = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Mono Timestamp - Dates, times
  /// 12px, Regular
  static const TextStyle monoTimestamp = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Mono Code - Inline code, technical text
  /// 13px, Regular
  static const TextStyle monoCode = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.54,
    letterSpacing: 0,
  );

  /// Mono Annotation - Technical annotations
  /// 11px, Regular, 0.5px letter spacing
  static const TextStyle monoAnnotation = TextStyle(
    fontFamily: fontFamilySecondary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ===========================================================================
  // TEXT THEME (For ThemeData)
  // ===========================================================================

  /// Create a TextTheme with Industrial Minimalism styles
  static TextTheme createTextTheme({Brightness? brightness}) {
    final isDark = brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final textTertiary = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return TextTheme(
      // Display
      displayLarge: displayLarge,
      displayMedium: displayMedium,

      // Headline
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,

      // Body
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,

      // Label
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Apply color to a text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply font weight to a text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply font size to a text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Create a monospace style for data display
  static TextStyle mono({double fontSize = 14, Color? color}) {
    return TextStyle(
      fontFamily: fontFamilySecondary,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0,
      color: color,
      fontFeatures: [FontFeature.tabularFigures()],
    );
  }
}
