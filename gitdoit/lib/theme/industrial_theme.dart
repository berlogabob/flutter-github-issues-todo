import 'package:flutter/material.dart';
import '../design_tokens/tokens.dart';

/// Industrial Theme Extension
///
/// Custom theme extension providing Industrial Minimalism specific properties.
/// Access via: Theme.of(context).extension<IndustrialThemeData>()
///
/// Features:
/// - Z-level management
/// - Lighting and shadow utilities
/// - Spatial depth helpers
/// - Industrial-specific colors
class IndustrialThemeData extends ThemeExtension<IndustrialThemeData> {
  final Brightness brightness;

  // Surface Colors
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color surfaceHover;

  // Border Colors
  final Color borderPrimary;
  final Color borderFocus;
  final Color borderDisabled;

  // Text Colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textMono;

  // Accent Colors
  final Color accentPrimary;
  final Color accentHover;
  final Color accentPressed;
  final Color accentSubtle;

  // Status Colors
  final Color statusSuccess;
  final Color statusError;
  final Color statusWarning;

  // Z-Level Shadows
  final List<BoxShadow> z0Shadow;
  final List<BoxShadow> z1Shadow;
  final List<BoxShadow> z2Shadow;
  final List<BoxShadow> z3Shadow;

  // Spacing
  final double spacingXxs;
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double spacingXxl;

  // Radius
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;
  final double radiusFull;

  const IndustrialThemeData({
    required this.brightness,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.borderPrimary,
    required this.borderFocus,
    required this.borderDisabled,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMono,
    required this.accentPrimary,
    required this.accentHover,
    required this.accentPressed,
    required this.accentSubtle,
    required this.statusSuccess,
    required this.statusError,
    required this.statusWarning,
    required this.z0Shadow,
    required this.z1Shadow,
    required this.z2Shadow,
    required this.z3Shadow,
    required this.spacingXxs,
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.spacingXxl,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusFull,
  });

  // ===========================================================================
  // PRESET THEMES
  // ===========================================================================

  /// Light Theme Instance
  static final IndustrialThemeData light = IndustrialThemeData(
    brightness: Brightness.light,
    surfacePrimary: AppColors.lightGray,
    surfaceSecondary: AppColors.pureWhite,
    surfaceElevated: AppColors.pureWhite,
    surfaceHover: AppColors.pureWhite,
    borderPrimary: AppColors.borderLight,
    borderFocus: AppColors.signalOrange,
    borderDisabled: AppColors.borderDisabledLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textTertiary: AppColors.textTertiaryLight,
    textMono: AppColors.textPrimaryLight,
    accentPrimary: AppColors.signalOrange,
    accentHover: AppColors.signalOrangeHover,
    accentPressed: AppColors.signalOrangePressed,
    accentSubtle: AppColors.signalOrangeSubtle,
    statusSuccess: AppColors.statusGreenDark,
    statusError: AppColors.errorRed,
    statusWarning: AppColors.statusWarningDark,
    z0Shadow: AppElevation.z0Shadow,
    z1Shadow: AppElevation.z1ShadowLight,
    z2Shadow: AppElevation.z2ShadowLight,
    z3Shadow: AppElevation.z3ShadowLight,
    spacingXxs: AppSpacing.xxs,
    spacingXs: AppSpacing.xs,
    spacingSm: AppSpacing.sm,
    spacingMd: AppSpacing.md,
    spacingLg: AppSpacing.lg,
    spacingXl: AppSpacing.xl,
    spacingXxl: AppSpacing.xxl,
    radiusSmall: AppSpacing.radiusSmall,
    radiusMedium: AppSpacing.radiusMedium,
    radiusLarge: AppSpacing.radiusLarge,
    radiusFull: AppSpacing.radiusFull,
  );

  /// Dark Theme Instance
  static final IndustrialThemeData dark = IndustrialThemeData(
    brightness: Brightness.dark,
    surfacePrimary: AppColors.darkGray,
    surfaceSecondary: AppColors.surfaceDark,
    surfaceElevated: AppColors.surfaceDark,
    surfaceHover: AppColors.surfaceHoverDark,
    borderPrimary: AppColors.borderDark,
    borderFocus: AppColors.signalOrange,
    borderDisabled: AppColors.borderDisabledDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textTertiary: AppColors.textTertiaryDark,
    textMono: AppColors.textPrimaryDark,
    accentPrimary: AppColors.signalOrange,
    accentHover: AppColors.signalOrangeHover,
    accentPressed: AppColors.signalOrangePressed,
    accentSubtle: AppColors.signalOrangeSubtle,
    statusSuccess: AppColors.statusGreen,
    statusError: AppColors.errorRed,
    statusWarning: AppColors.statusWarning,
    z0Shadow: AppElevation.z0Shadow,
    z1Shadow: AppElevation.z1ShadowDark,
    z2Shadow: AppElevation.z2ShadowDark,
    z3Shadow: AppElevation.z3ShadowDark,
    spacingXxs: AppSpacing.xxs,
    spacingXs: AppSpacing.xs,
    spacingSm: AppSpacing.sm,
    spacingMd: AppSpacing.md,
    spacingLg: AppSpacing.lg,
    spacingXl: AppSpacing.xl,
    spacingXxl: AppSpacing.xxl,
    radiusSmall: AppSpacing.radiusSmall,
    radiusMedium: AppSpacing.radiusMedium,
    radiusLarge: AppSpacing.radiusLarge,
    radiusFull: AppSpacing.radiusFull,
  );

  // ===========================================================================
  // THEME EXTENSION IMPLEMENTATION
  // ===========================================================================

  @override
  IndustrialThemeData copyWith({
    Brightness? brightness,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? surfaceHover,
    Color? borderPrimary,
    Color? borderFocus,
    Color? borderDisabled,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textMono,
    Color? accentPrimary,
    Color? accentHover,
    Color? accentPressed,
    Color? accentSubtle,
    Color? statusSuccess,
    Color? statusError,
    Color? statusWarning,
    List<BoxShadow>? z0Shadow,
    List<BoxShadow>? z1Shadow,
    List<BoxShadow>? z2Shadow,
    List<BoxShadow>? z3Shadow,
    double? spacingXxs,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? spacingXxl,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusFull,
  }) {
    return IndustrialThemeData(
      brightness: brightness ?? this.brightness,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      borderPrimary: borderPrimary ?? this.borderPrimary,
      borderFocus: borderFocus ?? this.borderFocus,
      borderDisabled: borderDisabled ?? this.borderDisabled,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textMono: textMono ?? this.textMono,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentHover: accentHover ?? this.accentHover,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusError: statusError ?? this.statusError,
      statusWarning: statusWarning ?? this.statusWarning,
      z0Shadow: z0Shadow ?? this.z0Shadow,
      z1Shadow: z1Shadow ?? this.z1Shadow,
      z2Shadow: z2Shadow ?? this.z2Shadow,
      z3Shadow: z3Shadow ?? this.z3Shadow,
      spacingXxs: spacingXxs ?? this.spacingXxs,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      spacingXxl: spacingXxl ?? this.spacingXxl,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      radiusFull: radiusFull ?? this.radiusFull,
    );
  }

  @override
  IndustrialThemeData lerp(IndustrialThemeData other, double t) {
    if (identical(this, other)) return this;

    return IndustrialThemeData(
      brightness: brightness,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      borderPrimary: Color.lerp(borderPrimary, other.borderPrimary, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderDisabled: Color.lerp(borderDisabled, other.borderDisabled, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textMono: Color.lerp(textMono, other.textMono, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      z0Shadow: other.z0Shadow,
      z1Shadow: other.z1Shadow,
      z2Shadow: other.z2Shadow,
      z3Shadow: other.z3Shadow,
      spacingXxs: other.spacingXxs,
      spacingXs: other.spacingXs,
      spacingSm: other.spacingSm,
      spacingMd: other.spacingMd,
      spacingLg: other.spacingLg,
      spacingXl: other.spacingXl,
      spacingXxl: other.spacingXxl,
      radiusSmall: other.radiusSmall,
      radiusMedium: other.radiusMedium,
      radiusLarge: other.radiusLarge,
      radiusFull: other.radiusFull,
    );
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Get shadow for Z level
  List<BoxShadow> shadowForZLevel(double z) {
    if (z <= 0) return z0Shadow;
    if (z <= 2) return z1Shadow;
    if (z <= 4) return z2Shadow;
    return z3Shadow;
  }

  /// Get BoxDecoration with elevation
  BoxDecoration boxDecoration({
    Color? color,
    double zLevel = 0,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? surfacePrimary,
      boxShadow: shadowForZLevel(zLevel),
      borderRadius: borderRadius ?? BorderRadius.circular(radiusMedium),
      border: border,
    );
  }

  /// Get interactive BoxDecoration (Z=1 idle, Z=2 hover)
  BoxDecoration interactiveDecoration({
    Color? color,
    bool isHovered = false,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return boxDecoration(
      color: color ?? surfaceElevated,
      zLevel: isHovered ? 4 : 2,
      borderRadius: borderRadius,
      border: border ?? Border.all(color: borderPrimary, width: 1),
    );
  }
}

// ===========================================================================
// EXTENSION FOR EASY ACCESS
// ===========================================================================

/// Extension on BuildContext for easy IndustrialTheme access
extension IndustrialThemeExtension on BuildContext {
  /// Get IndustrialThemeData
  IndustrialThemeData get industrialTheme {
    return Theme.of(this).extension<IndustrialThemeData>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? IndustrialThemeData.dark
            : IndustrialThemeData.light);
  }

  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Check if light mode
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;
}
