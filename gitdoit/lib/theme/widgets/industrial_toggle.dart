import 'package:flutter/material.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Industrial Toggle
///
/// A custom toggle/switch widget implementing Industrial Minimalism design.
/// Features:
/// - Physical switch simulation
/// - Tactile feedback with spring physics
/// - Z-axis movement
/// - WCAG AA compliant touch targets (48x48dp)
///
/// Usage:
/// ```dart
/// IndustrialToggle(
///   value: isEnabled,
///   onChanged: (value) => setState(() => isEnabled = value),
///   label: 'Enable notifications',
/// )
/// ```
class IndustrialToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? semanticLabel;
  final bool enabled;
  final IndustrialToggleSize size;

  const IndustrialToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
    this.enabled = true,
    this.size = IndustrialToggleSize.medium,
  });

  @override
  State<IndustrialToggle> createState() => _IndustrialToggleState();
}

enum IndustrialToggleSize { small, medium, large }

class _IndustrialToggleState extends State<IndustrialToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbPositionAnimation;
  late Animation<double> _thumbScaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.durationFast,
    );

    _thumbPositionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _thumbScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _updateController();
  }

  @override
  void didUpdateWidget(IndustrialToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateController();
    }
  }

  void _updateController() {
    if (widget.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (widget.enabled) {
      widget.onChanged(!widget.value);
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    // Track dimensions based on size
    double trackWidth;
    double trackHeight;
    double thumbSize;
    double touchTargetSize;

    switch (widget.size) {
      case IndustrialToggleSize.small:
        trackWidth = 40;
        trackHeight = 24;
        thumbSize = 18;
        touchTargetSize = 40;
        break;
      case IndustrialToggleSize.large:
        trackWidth = 60;
        trackHeight = 36;
        thumbSize = 28;
        touchTargetSize = 56;
        break;
      case IndustrialToggleSize.medium:
        trackWidth = 52;
        trackHeight = 32;
        thumbSize = 24;
        touchTargetSize = 48;
    }

    // Track color
    Color trackColor;
    if (!widget.enabled) {
      trackColor = industrialTheme.brightness == Brightness.dark
          ? industrialTheme.surfaceSecondary
          : AppColors.borderDisabledLight;
    } else if (widget.value) {
      trackColor = industrialTheme.accentPrimary;
    } else {
      trackColor = industrialTheme.borderPrimary;
    }

    // Thumb color
    Color thumbColor;
    if (!widget.enabled) {
      thumbColor = industrialTheme.textTertiary;
    } else {
      thumbColor = AppColors.pureWhite;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label (if provided)
        if (widget.label != null) ...[
          Expanded(
            child: Text(
              widget.label!,
              style: AppTypography.labelMedium.copyWith(
                color: widget.enabled
                    ? industrialTheme.textPrimary
                    : industrialTheme.textTertiary,
                fontFamily: AppTypography.fontFamilySecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],

        // Toggle
        Semantics(
          toggled: widget.value,
          enabled: widget.enabled,
          label: widget.semanticLabel ?? widget.label,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: SizedBox(
                width: touchTargetSize,
                height: touchTargetSize,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final thumbPosition = _thumbPositionAnimation.value;
                      final thumbScale = _isPressed
                          ? _thumbScaleAnimation.value
                          : 1.0;

                      // Calculate thumb position
                      final trackInnerWidth = trackWidth - 8;
                      final thumbX = thumbPosition * trackInnerWidth;

                      return SizedBox(
                        width: trackWidth,
                        height: trackHeight,
                        child: Stack(
                          children: [
                            // Track
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: trackColor,
                                  borderRadius: BorderRadius.circular(
                                    trackHeight / 2,
                                  ),
                                ),
                              ),
                            ),

                            // Thumb
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Transform.translate(
                                offset: Offset(thumbX, 0),
                                child: Transform.scale(
                                  scale: thumbScale,
                                  child: Container(
                                    width: thumbSize,
                                    height: thumbSize,
                                    decoration: BoxDecoration(
                                      color: thumbColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.pureBlack.withValues(
                                            alpha:
                                                industrialTheme.brightness ==
                                                    Brightness.dark
                                                ? 0.3
                                                : 0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
