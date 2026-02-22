import 'package:flutter/material.dart';
import '../design_tokens/tokens.dart';
import 'industrial_theme.dart';

/// Industrial Minimalism App Theme
///
/// Custom ThemeData configuration using Industrial Minimalism design tokens.
/// Material Design is used only as a base layer, themed beyond recognition.
///
/// Features:
/// - Monochrome palette with Signal Orange accent
/// - Inter + JetBrains Mono typography
/// - Z-axis spatial depth
/// - Spring physics animations
class IndustrialAppTheme {
  const IndustrialAppTheme._();

  // ===========================================================================
  // LIGHT THEME
  // ===========================================================================

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme - Minimal Material usage
      colorScheme:
          const ColorScheme.light(
            primary: AppColors.signalOrange,
            onPrimary: AppColors.textOnAccent,
            secondary: AppColors.textSecondaryLight,
            tertiary: AppColors.textTertiaryLight,
            error: AppColors.errorRed,
            onError: AppColors.pureWhite,
            surface: AppColors.pureWhite,
            onSurface: AppColors.textPrimaryLight,
            outline: AppColors.borderLight,
          ).copyWith(
            primaryContainer: AppColors.signalOrangeSubtle,
            onPrimaryContainer: AppColors.signalOrangePressed,
            onSecondary: AppColors.pureWhite,
            secondaryContainer: AppColors.lightGray,
            onSecondaryContainer: AppColors.textSecondaryLight,
            onTertiary: AppColors.pureWhite,
            tertiaryContainer: AppColors.lightGray,
            onTertiaryContainer: AppColors.textTertiaryLight,
            errorContainer: Color(0x1AFF3333),
            onErrorContainer: AppColors.errorRedDark,
            surfaceContainerHighest: AppColors.lightGray,
            onSurfaceVariant: AppColors.textSecondaryLight,
            shadow: AppColors.pureBlack,
          ),

      // Typography
      textTheme: AppTypography.createTextTheme(brightness: Brightness.light),

      // Component Themes - Heavily customized
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
          size: 24,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        shadowColor: AppColors.pureBlack.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signalOrange,
          foregroundColor: AppColors.textOnAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: AppSpacing.buttonPaddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          textStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.textOnAccent,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.pureWhite,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontalSecondary,
            vertical: AppSpacing.buttonPaddingVerticalSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
          textStyle: AppTypography.labelMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontalText,
            vertical: AppSpacing.buttonPaddingVerticalText,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          textStyle: AppTypography.labelSmall,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingHorizontal,
          vertical: AppSpacing.inputPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.signalOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.borderDisabledLight,
            width: 1,
          ),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        errorStyle: AppTypography.captionSmall.copyWith(
          color: AppColors.errorRed,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        prefixIconColor: AppColors.textSecondaryLight,
        suffixIconColor: AppColors.textSecondaryLight,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.signalOrange,
        foregroundColor: AppColors.textOnAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightGray,
        deleteIconColor: AppColors.textSecondaryLight,
        disabledColor: AppColors.borderDisabledLight,
        elevation: 0,
        labelStyle: AppTypography.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.badgePaddingHorizontal,
          vertical: AppSpacing.badgePaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkGray,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),

      // Extension for Industrial Theme
      extensions: [IndustrialThemeData.light],
    );
  }

  // ===========================================================================
  // DARK THEME
  // ===========================================================================

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme - Minimal Material usage
      colorScheme:
          const ColorScheme.dark(
            primary: AppColors.signalOrange,
            onPrimary: AppColors.textOnAccent,
            secondary: AppColors.textSecondaryDark,
            tertiary: AppColors.textTertiaryDark,
            error: AppColors.errorRed,
            onError: AppColors.pureWhite,
            surface: AppColors.pureBlack,
            onSurface: AppColors.textPrimaryDark,
            outline: AppColors.borderDark,
          ).copyWith(
            primaryContainer: AppColors.signalOrangeSubtle,
            onPrimaryContainer: AppColors.signalOrangeHover,
            onSecondary: AppColors.pureBlack,
            secondaryContainer: AppColors.darkGray,
            onSecondaryContainer: AppColors.textSecondaryDark,
            onTertiary: AppColors.pureBlack,
            tertiaryContainer: AppColors.surfaceDark,
            onTertiaryContainer: AppColors.textTertiaryDark,
            errorContainer: Color(0x1AFF3333),
            onErrorContainer: AppColors.errorRed,
            surfaceContainerHighest: AppColors.darkGray,
            onSurfaceVariant: AppColors.textSecondaryDark,
            shadow: AppColors.pureBlack,
          ),

      // Typography
      textTheme: AppTypography.createTextTheme(brightness: Brightness.dark),

      // Component Themes - Heavily customized
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pureBlack,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 24,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: AppColors.pureBlack.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signalOrange,
          foregroundColor: AppColors.textOnAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: AppSpacing.buttonPaddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          textStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.textOnAccent,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontalSecondary,
            vertical: AppSpacing.buttonPaddingVerticalSecondary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
          textStyle: AppTypography.labelMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontalText,
            vertical: AppSpacing.buttonPaddingVerticalText,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          textStyle: AppTypography.labelSmall,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inputPaddingHorizontal,
          vertical: AppSpacing.inputPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.signalOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.borderDisabledDark,
            width: 1,
          ),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        errorStyle: AppTypography.captionSmall.copyWith(
          color: AppColors.errorRed,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiaryDark,
        ),
        prefixIconColor: AppColors.textSecondaryDark,
        suffixIconColor: AppColors.textSecondaryDark,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.signalOrange,
        foregroundColor: AppColors.textOnAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkGray,
        deleteIconColor: AppColors.textSecondaryDark,
        disabledColor: AppColors.borderDisabledDark,
        elevation: 0,
        labelStyle: AppTypography.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.badgePaddingHorizontal,
          vertical: AppSpacing.badgePaddingVertical,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightGray,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),

      // Extension for Industrial Theme
      extensions: [IndustrialThemeData.dark],
    );
  }
}
