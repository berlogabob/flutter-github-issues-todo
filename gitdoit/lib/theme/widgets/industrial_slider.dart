import 'package:flutter/material.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Industrial Slider
///
/// A custom slider/fader widget implementing Industrial Minimalism design.
/// Inspired by Teenage Engineering fader-style controls.
///
/// Features:
/// - Fader-style control
/// - Precise value display with monospace font
/// - Spring physics animation
/// - Technical annotations
/// - WCAG AA compliant touch targets
///
/// Usage:
/// ```dart
/// IndustrialSlider(
///   value: priority,
///   min: 0,
///   max: 100,
///   onChanged: (value) => setState(() => priority = value),
///   label: 'Priority',
///   showValue: true,
/// )
/// ```
class IndustrialSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final String? label;
  final String? semanticLabel;
  final bool enabled;
  final bool showValue;
  final int divisions;
  final IndustrialSliderOrientation orientation;

  const IndustrialSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.label,
    this.semanticLabel,
    this.enabled = true,
    this.showValue = true,
    this.divisions = 100,
    this.orientation = IndustrialSliderOrientation.horizontal,
  });

  @override
  State<IndustrialSlider> createState() => _IndustrialSliderState();
}

enum IndustrialSliderOrientation { horizontal, vertical }

class _IndustrialSliderState extends State<IndustrialSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbScaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.durationFast,
    );

    _thumbScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _normalizedValue {
    final range = widget.max - widget.min;
    return ((widget.value - widget.min) / range).clamp(0.0, 1.0);
  }

  void _onStart() {
    setState(() => _isDragging = true);
    _controller.forward();
    widget.onChangeStart?.call(widget.value);
  }

  void _onEnd() {
    setState(() => _isDragging = false);
    _controller.reverse();
    widget.onChangeEnd?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final normalizedValue = _normalizedValue;

    // Track colors
    final trackBackgroundColor = industrialTheme.borderPrimary;
    final trackActiveColor = industrialTheme.accentPrimary;

    // Thumb colors
    final thumbColor = AppColors.pureWhite;
    final thumbRingColor = _isDragging
        ? industrialTheme.accentPrimary
        : industrialTheme.accentPrimary.withValues(alpha: 0.5);

    // Dimensions
    const trackHeight = 4.0;
    const thumbSize = 20.0;
    const touchTargetSize = 48.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label and value row
        if (widget.label != null || widget.showValue) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: AppTypography.monoAnnotation.copyWith(
                      color: industrialTheme.textSecondary,
                    ),
                  ),
                if (widget.showValue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: industrialTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                      border: Border.all(
                        color: industrialTheme.borderPrimary,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.value.toStringAsFixed(0),
                      style: AppTypography.monoData.copyWith(
                        color: industrialTheme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],

        // Slider area
        SizedBox(
          height: touchTargetSize,
          child: Stack(
            children: [
              // Track background
              Positioned(
                left: 0,
                right: 0,
                top: touchTargetSize / 2 - trackHeight / 2,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: trackBackgroundColor,
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),
              ),

              // Active track
              Positioned(
                left: 0,
                top: touchTargetSize / 2 - trackHeight / 2,
                width: MediaQuery.of(context).size.width * normalizedValue,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: trackActiveColor,
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),
              ),

              // Thumb (custom gesture detection for precise control)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragStart: (_) => _onStart(),
                  onHorizontalDragEnd: (_) => _onEnd(),
                  onHorizontalDragUpdate: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final size = renderBox.size;
                    final dx = details.localPosition.dx;
                    final newValue =
                        (dx / size.width) * (widget.max - widget.min) +
                        widget.min;
                    widget.onChanged(newValue.clamp(widget.min, widget.max));
                  },
                  child: MouseRegion(
                    cursor: widget.enabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final thumbScale = _thumbScaleAnimation.value;
                        final thumbX =
                            normalizedValue *
                            (MediaQuery.of(context).size.width - thumbSize);

                        return Positioned(
                          left: thumbX.clamp(0.0, double.infinity),
                          top: touchTargetSize / 2 - thumbSize / 2,
                          child: Transform.scale(
                            scale: _isDragging ? thumbScale : 1.0,
                            child: Container(
                              width: thumbSize,
                              height: thumbSize,
                              decoration: BoxDecoration(
                                color: thumbColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: thumbRingColor,
                                  width: _isDragging ? 3 : 2,
                                ),
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
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tick marks and labels
        if (widget.divisions <= 10) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                widget.divisions + 1,
                (index) => Text(
                  (widget.min +
                          (widget.max - widget.min) * index / widget.divisions)
                      .toStringAsFixed(0),
                  style: AppTypography.monoAnnotation.copyWith(
                    color: industrialTheme.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
