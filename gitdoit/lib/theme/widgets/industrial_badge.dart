import 'package:flutter/material.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Industrial Badge Variant
enum IndustrialBadgeVariant {
  /// Default: Gray background, for general labels
  defaultVariant,

  /// Accent: Signal Orange border/text, for active/important items
  accent,

  /// Success: Green indicator, for open/completed status
  success,

  /// Error: Red indicator, for closed/error status
  error,

  /// Warning: Warning orange indicator, for in-progress status
  warning,

  /// Info: Blue-ish indicator, for informational status
  info,
}

/// Industrial Badge Size
enum IndustrialBadgeSize {
  /// Small: Compact badge
  small,

  /// Medium: Standard size (default)
  medium,

  /// Large: Prominent badge
  large,
}

/// Industrial Badge
///
/// A custom badge/chip widget implementing Industrial Minimalism design.
/// Features:
/// - Dot-matrix style prefix option
/// - Status indicators with icon/text support
/// - Monospace data display option
/// - WCAG AA compliant colors
///
/// Usage:
/// ```dart
/// IndustrialBadge(
///   label: 'Open',
///   variant: IndustrialBadgeVariant.success,
///   showDot: true,
/// )
/// ```
class IndustrialBadge extends StatelessWidget {
  final String label;
  final IndustrialBadgeVariant variant;
  final IndustrialBadgeSize size;
  final bool showDot;
  final bool useMonospace;
  final VoidCallback? onTap;
  final Widget? icon;
  final String? semanticLabel;

  const IndustrialBadge({
    super.key,
    required this.label,
    this.variant = IndustrialBadgeVariant.defaultVariant,
    this.size = IndustrialBadgeSize.medium,
    this.showDot = false,
    this.useMonospace = false,
    this.onTap,
    this.icon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final isInteractive = onTap != null;

    // Size configuration
    double horizontalPadding;
    double verticalPadding;
    double fontSize;
    double minHeight;
    double dotSize;

    switch (size) {
      case IndustrialBadgeSize.small:
        horizontalPadding = AppSpacing.xs;
        verticalPadding = 2;
        fontSize = 11;
        minHeight = 20;
        dotSize = 4;
        break;
      case IndustrialBadgeSize.large:
        horizontalPadding = AppSpacing.sm;
        verticalPadding = 6;
        fontSize = 14;
        minHeight = 28;
        dotSize = 8;
        break;
      case IndustrialBadgeSize.medium:
      default:
        horizontalPadding = AppSpacing.badgePaddingHorizontal;
        verticalPadding = AppSpacing.badgePaddingVertical;
        fontSize = 12;
        minHeight = 24;
        dotSize = 6;
    }

    // Color configuration based on variant
    Color backgroundColor;
    Color textColor;
    Color? borderColor;
    Color? dotColor;

    switch (variant) {
      case IndustrialBadgeVariant.accent:
        backgroundColor = industrialTheme.accentSubtle;
        textColor = industrialTheme.accentPrimary;
        borderColor = industrialTheme.accentPrimary;
        dotColor = industrialTheme.accentPrimary;
        break;
      case IndustrialBadgeVariant.success:
        backgroundColor = AppColors.statusGreen.withOpacity(0.1);
        textColor = industrialTheme.brightness == Brightness.dark
            ? AppColors.statusGreen
            : AppColors.statusGreenDark;
        borderColor = textColor;
        dotColor = textColor;
        break;
      case IndustrialBadgeVariant.error:
        backgroundColor = AppColors.errorRed.withOpacity(0.1);
        textColor = industrialTheme.brightness == Brightness.dark
            ? AppColors.errorRed
            : AppColors.errorRedDark;
        borderColor = textColor;
        dotColor = textColor;
        break;
      case IndustrialBadgeVariant.warning:
        backgroundColor = AppColors.statusWarning.withOpacity(0.1);
        textColor = industrialTheme.brightness == Brightness.dark
            ? AppColors.statusWarning
            : AppColors.statusWarningDark;
        borderColor = textColor;
        dotColor = textColor;
        break;
      case IndustrialBadgeVariant.info:
        backgroundColor = AppColors.signalOrange.withOpacity(0.05);
        textColor = industrialTheme.textSecondary;
        borderColor = industrialTheme.borderPrimary;
        dotColor = industrialTheme.textSecondary;
        break;
      case IndustrialBadgeVariant.defaultVariant:
      default:
        backgroundColor = industrialTheme.surfacePrimary;
        textColor = industrialTheme.textPrimary;
        borderColor = null;
        dotColor = industrialTheme.textSecondary;
    }

    final textStyle =
        (useMonospace ? AppTypography.monoData : AppTypography.labelSmall)
            .copyWith(
              fontSize: fontSize,
              color: textColor,
              fontWeight: FontWeight.w500,
            );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dot indicator
        if (showDot && dotColor != null) ...[
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],

        // Icon (if provided)
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(color: textColor, size: fontSize + 2),
            child: icon!,
          ),
          const SizedBox(width: AppSpacing.xxs),
        ],

        // Label
        Text(label, style: textStyle),
      ],
    );

    return Semantics(
      label: semanticLabel ?? label,
      button: isInteractive,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: isInteractive
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: AppAnimations.durationFast,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                size == IndustrialBadgeSize.small
                    ? AppSpacing.radiusSmall
                    : AppSpacing.radiusFull,
              ),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1)
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Industrial Status Badge
///
/// Pre-configured badge for status display (Open/Closed)
/// Combines dot indicator with status text
class IndustrialStatusBadge extends StatelessWidget {
  final bool isOpen;
  final String? customOpenLabel;
  final String? customClosedLabel;
  final IndustrialBadgeSize size;

  const IndustrialStatusBadge({
    super.key,
    required this.isOpen,
    this.customOpenLabel,
    this.customClosedLabel,
    this.size = IndustrialBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return IndustrialBadge(
      label: isOpen
          ? (customOpenLabel ?? 'Open')
          : (customClosedLabel ?? 'Closed'),
      variant: isOpen
          ? IndustrialBadgeVariant.success
          : IndustrialBadgeVariant.error,
      size: size,
      showDot: true,
      useMonospace: true,
    );
  }
}

/// Industrial Label Badge
///
/// Pre-configured badge for GitHub-style labels
class IndustrialLabelBadge extends StatelessWidget {
  final String label;
  final String colorHex;
  final String? description;
  final IndustrialBadgeSize size;

  const IndustrialLabelBadge({
    super.key,
    required this.label,
    required this.colorHex,
    this.description,
    this.size = IndustrialBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorHex);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == IndustrialBadgeSize.small
            ? AppSpacing.xs
            : AppSpacing.badgePaddingHorizontal,
        vertical: size == IndustrialBadgeSize.small
            ? 2
            : AppSpacing.badgePaddingVertical,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          fontSize: size == IndustrialBadgeSize.small ? 11 : 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final hexColor = hex.replaceFirst('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.grey;
  }
}
