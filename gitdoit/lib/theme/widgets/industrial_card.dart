import 'package:flutter/material.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Industrial Card Type
enum IndustrialCardType {
  /// Data Card: Standard card for displaying information
  data,

  /// Interactive Card: Card with hover/press states for navigation
  interactive,

  /// Selected Card: Card in selected state with accent indicator
  selected,
}

/// Industrial Card
///
/// A custom card widget implementing Industrial Minimalism design.
/// Features:
/// - Z-axis spatial depth
/// - Spring physics hover/press animations
/// - Modular block construction
/// - Optional grid lines exposure
///
/// Usage:
/// ```dart
/// IndustrialCard(
///   type: IndustrialCardType.interactive,
///   onTap: () => print('Card tapped!'),
///   child: Column(
///     children: [
///       Text('Card Title'),
///       Text('Card Content'),
///     ],
///   ),
/// )
/// ```
class IndustrialCard extends StatefulWidget {
  final Widget child;
  final IndustrialCardType type;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showGridLines;
  final String? semanticLabel;
  final Color? backgroundColor;

  const IndustrialCard({
    super.key,
    required this.child,
    this.type = IndustrialCardType.data,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.showGridLines = false,
    this.semanticLabel,
    this.backgroundColor,
  });

  @override
  State<IndustrialCard> createState() => _IndustrialCardState();
}

class _IndustrialCardState extends State<IndustrialCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _translationAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.durationSlow,
    );

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _translationAnimation = Tween<double>(
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
    if (widget.onTap != null) {
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
    if (widget.onTap != null) {
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
    final isInteractive =
        widget.onTap != null || widget.type == IndustrialCardType.interactive;

    // Background color
    Color bgColor = widget.backgroundColor ?? industrialTheme.surfaceElevated;

    // Border color
    Color borderColor = industrialTheme.borderPrimary;
    if (widget.type == IndustrialCardType.selected && _isHovered) {
      borderColor = industrialTheme.accentPrimary;
    }

    // Calculate elevation and translation
    final elevation = _isPressed
        ? 0.0
        : (_isHovered && isInteractive ? _elevationAnimation.value : 2.0);
    final translation = _isPressed
        ? 0.0
        : (_isHovered && isInteractive ? _translationAnimation.value : 0.0);

    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isInteractive ? _onTapDown : null,
        onTapUp: isInteractive ? _onTapUp : null,
        onTapCancel: isInteractive ? _onTapCancel : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -translation),
              child: AnimatedContainer(
                duration: AppAnimations.durationSlow,
                curve: Curves.easeInOutCubic,
                margin: widget.margin ?? EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: borderColor,
                    width: widget.type == IndustrialCardType.selected ? 2 : 1,
                  ),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  child: Semantics(
                    label: widget.semanticLabel,
                    button: isInteractive,
                    child: Stack(
                      children: [
                        // Grid lines overlay (optional)
                        if (widget.showGridLines && _isHovered)
                          CustomPaint(
                            size: Size.infinite,
                            painter: _GridLinesPainter(
                              color: industrialTheme.accentPrimary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),

                        // Selected indicator (left border accent)
                        if (widget.type == IndustrialCardType.selected)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 3,
                              color: industrialTheme.accentPrimary,
                            ),
                          ),

                        // Content
                        Padding(
                          padding:
                              widget.padding ??
                              const EdgeInsets.all(AppSpacing.cardPadding),
                          child: widget.child,
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

/// Grid Lines Painter for technical aesthetic
class _GridLinesPainter extends CustomPainter {
  final Color color;

  _GridLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Vertical lines
    const gridSpacing = 8.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridLinesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
