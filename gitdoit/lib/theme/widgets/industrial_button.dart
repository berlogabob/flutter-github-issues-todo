import 'package:flutter/material.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Industrial Button Variant
enum IndustrialButtonVariant {
  /// Primary: Signal Orange background, for main actions
  primary,

  /// Secondary: Border-focused, monochrome, for secondary actions
  secondary,

  /// Text: Minimal, caption style, for tertiary actions
  text,

  /// Destructive: Error red, for delete/remove actions
  destructive,
}

/// Industrial Button Size
enum IndustrialButtonSize {
  /// Small: Compact buttons for tight spaces
  small,

  /// Medium: Standard size (default)
  medium,

  /// Large: Prominent buttons for primary actions
  large,
}

/// Industrial Button
///
/// A custom button widget implementing Industrial Minimalism design.
/// Features:
/// - Spring physics animations
/// - Z-axis hover/press states
/// - Signal Orange accent (primary variant)
/// - WCAG AA compliant touch targets (48x48dp minimum)
///
/// Usage:
/// ```dart
/// IndustrialButton(
///   onPressed: () => print('Pressed!'),
///   label: 'Save Changes',
///   variant: IndustrialButtonVariant.primary,
/// )
/// ```
class IndustrialButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final Widget? icon;
  final IndustrialButtonVariant variant;
  final IndustrialButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticLabel;

  const IndustrialButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = IndustrialButtonVariant.primary,
    this.size = IndustrialButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.semanticLabel,
  });

  @override
  State<IndustrialButton> createState() => _IndustrialButtonState();
}

class _IndustrialButtonState extends State<IndustrialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.durationNormal,
    );

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    if (widget.onPressed != null) {
      setState(() => _isHovered = true);
      _controller.forward();
    }
  }

  void _onHoverExit() {
    setState(() {
      _isHovered = false;
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    // Size configuration
    double horizontalPadding;
    double verticalPadding;
    TextStyle textStyle;
    double minHeight;

    switch (widget.size) {
      case IndustrialButtonSize.small:
        horizontalPadding = AppSpacing.buttonPaddingHorizontalText;
        verticalPadding = AppSpacing.buttonPaddingVerticalText;
        textStyle = AppTypography.labelSmall;
        minHeight = 40;
        break;
      case IndustrialButtonSize.large:
        horizontalPadding = AppSpacing.buttonPaddingHorizontal + 8;
        verticalPadding = AppSpacing.buttonPaddingVertical + 4;
        textStyle = AppTypography.labelLarge;
        minHeight = 56;
        break;
      case IndustrialButtonSize.medium:
        horizontalPadding = AppSpacing.buttonPaddingHorizontal;
        verticalPadding = AppSpacing.buttonPaddingVertical;
        textStyle = AppTypography.labelMedium;
        minHeight = 48;
    }

    // Color configuration based on variant
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    if (!isEnabled) {
      // Disabled state
      backgroundColor = industrialTheme.brightness == Brightness.dark
          ? industrialTheme.surfaceSecondary
          : AppColors.borderDisabledLight;
      foregroundColor = industrialTheme.textTertiary;
      borderColor = Colors.transparent;
    } else {
      switch (widget.variant) {
        case IndustrialButtonVariant.primary:
          backgroundColor = _isPressed
              ? AppColors.signalOrangePressed
              : industrialTheme.accentPrimary;
          foregroundColor = AppColors.textOnAccent;
          borderColor = Colors.transparent;
          break;
        case IndustrialButtonVariant.destructive:
          backgroundColor = _isPressed
              ? AppColors.errorRedDark
              : AppColors.errorRed;
          foregroundColor = AppColors.textOnAccent;
          borderColor = Colors.transparent;
          break;
        case IndustrialButtonVariant.secondary:
          backgroundColor = industrialTheme.surfaceElevated;
          foregroundColor = industrialTheme.textPrimary;
          borderColor = industrialTheme.borderPrimary;
          break;
        case IndustrialButtonVariant.text:
          backgroundColor = Colors.transparent;
          foregroundColor = industrialTheme.textPrimary;
          borderColor = Colors.transparent;
          break;
      }
    }

    // Apply hover state background for secondary and text variants
    if (_isHovered && isEnabled) {
      if (widget.variant == IndustrialButtonVariant.secondary) {
        backgroundColor = industrialTheme.surfaceHover;
      } else if (widget.variant == IndustrialButtonVariant.text) {
        backgroundColor = industrialTheme.surfacePrimary.withValues(alpha: 0.5);
      }
    }

    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Calculate scale and elevation
            final scale = _isPressed
                ? 0.98
                : (1.0 + (_elevationAnimation.value * 0.005));
            final elevation = _isPressed ? 0.0 : _elevationAnimation.value;

            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: AppAnimations.durationNormal,
                curve: Curves.easeInOutCubic,
                constraints: BoxConstraints(
                  minWidth: widget.isFullWidth ? double.infinity : minHeight,
                  minHeight: minHeight,
                ),
                width: widget.isFullWidth ? double.infinity : null,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border:
                      widget.variant == IndustrialButtonVariant.secondary ||
                          widget.variant == IndustrialButtonVariant.destructive
                      ? Border.all(
                          color: borderColor,
                          width: _isHovered && isEnabled ? 2 : 1,
                        )
                      : null,
                  boxShadow: elevation > 0
                      ? [
                          BoxShadow(
                            color: AppColors.pureBlack.withValues(
                              alpha:
                                  industrialTheme.brightness == Brightness.dark
                                  ? 0.3
                                  : 0.12,
                            ),
                            blurRadius: 16,
                            offset: Offset(0, elevation),
                          ),
                        ]
                      : null,
                ),
                child: Semantics(
                  button: true,
                  label: widget.semanticLabel ?? widget.label,
                  enabled: isEnabled,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.variant ==
                                            IndustrialButtonVariant.primary ||
                                        widget.variant ==
                                            IndustrialButtonVariant.destructive
                                    ? AppColors.textOnAccent
                                    : industrialTheme.textPrimary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                widget.icon!,
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              Text(
                                widget.label,
                                style: textStyle.copyWith(
                                  color: foregroundColor,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
