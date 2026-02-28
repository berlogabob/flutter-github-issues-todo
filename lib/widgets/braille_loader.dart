import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Braille-based loading animation widget
///
/// Displays a smooth animation using Braille characters:
/// ⠀ (empty) → ⠁ → ⠃ → ⠇ → ⠧ → ⠷ → ⠿ (full)
///
/// The widget is square to prevent layout shifts during animation.
class BrailleLoader extends StatefulWidget {
  /// Size of the loader in pixels (width and height)
  final double size;

  /// Color of the Braille characters
  final Color? color;

  const BrailleLoader({super.key, this.size = 24.0, this.color});

  @override
  State<BrailleLoader> createState() => _BrailleLoaderState();
}

class _BrailleLoaderState extends State<BrailleLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Braille characters for loading animation (increasing dot count)
  static const List<String> _brailleFrames = [
    '⠀', // U+2800 - Empty (0 dots)
    '⠁', // U+2801 - 1 dot
    '⠃', // U+2803 - 2 dots
    '⠇', // U+2807 - 3 dots
    '⠧', // U+2827 - 4 dots
    '⠷', // U+2837 - 5 dots
    '⠿', // U+283F - 6 dots (full)
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: (_brailleFrames.length - 1).toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Auto-reverse animation for smooth looping
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Get current frame index (rounded for discrete frames)
        final frameIndex = _animation.value.round();

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Text(
              _brailleFrames[frameIndex],
              style: TextStyle(
                fontSize: widget.size * 0.9, // Slightly smaller to fit
                color: widget.color ?? AppColors.orange,
                fontWeight: FontWeight.bold,
                height: 1, // Ensure square aspect ratio
                fontFamily: 'monospace', // Monospace for consistent width
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
