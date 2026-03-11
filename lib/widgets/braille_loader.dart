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
  late Animation<int> _frameAnimation;

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create discrete frame animation (no interpolation)
    _frameAnimation = StepTween(
      begin: 0,
      end: _brailleFrames.length,
    ).animate(_controller);

    // Loop continuously
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _frameAnimation,
        builder: (context, child) {
          final frameIndex = _frameAnimation.value % _brailleFrames.length;

          return Text(
            _brailleFrames[frameIndex],
            style: TextStyle(
              fontSize: widget.size * 0.9,
              color: widget.color ?? AppColors.primary,
              fontWeight: FontWeight.bold,
              height: 1,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }
}
