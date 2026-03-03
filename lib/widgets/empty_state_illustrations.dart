import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Empty state illustrations using CustomPainter.
///
/// Provides 5 lightweight illustrations for different empty states:
/// - No repos: Folder with question mark
/// - No issues: Checklist with X
/// - No comments: Speech bubble with question mark
/// - No projects: Board with question mark
/// - Search empty: Magnifying glass with question mark
///
/// Each illustration uses simple geometric shapes and subtle opacity animation.

/// Widget displaying an empty state illustration with optional animation.
class EmptyStateIllustration extends StatefulWidget {
  /// Type of empty state to display.
  final EmptyStateType type;

  /// Whether to animate the illustration with opacity pulse.
  final bool animate;

  /// Size of the illustration in pixels.
  final double size;

  /// Creates an empty state illustration widget.
  ///
  /// [type] specifies which illustration to display (required).
  /// [animate] enables subtle opacity pulse animation (default: true).
  /// [size] controls the illustration dimensions (default: 120).
  const EmptyStateIllustration({
    super.key,
    required this.type,
    this.animate = true,
    this.size = 120,
  });

  @override
  State<EmptyStateIllustration> createState() => _EmptyStateIllustrationState();
}

class _EmptyStateIllustrationState extends State<EmptyStateIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
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
        return Opacity(
          opacity: _animation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _getPainter(widget.type),
          ),
        );
      },
    );
  }

  CustomPainter _getPainter(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.noRepos:
        return NoReposPainter();
      case EmptyStateType.noIssues:
        return NoIssuesPainter();
      case EmptyStateType.noComments:
        return NoCommentsPainter();
      case EmptyStateType.noProjects:
        return NoProjectsPainter();
      case EmptyStateType.searchEmpty:
        return SearchEmptyPainter();
    }
  }
}

/// Types of empty state illustrations available.
enum EmptyStateType {
  /// No repositories available.
  noRepos,

  /// No issues available.
  noIssues,

  /// No comments available.
  noComments,

  /// No projects available.
  noProjects,

  /// No search results.
  searchEmpty,
}

/// Painter for "No Repos" - Folder with question mark.
class NoReposPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangeSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.orangeSecondary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final questionPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Folder body
    final folderRect = Rect.fromLTWH(size.width * 0.15, size.height * 0.35,
        size.width * 0.7, size.height * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(folderRect, const Radius.circular(4)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(folderRect, const Radius.circular(4)),
      paint,
    );

    // Folder tab
    final tabRect = Rect.fromLTWH(
        size.width * 0.15, size.height * 0.35, size.width * 0.3, size.height * 0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tabRect, const Radius.circular(2)),
      paint,
    );

    // Question mark
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.55;

    // Question mark curve
    final questionPath = Path();
    questionPath.moveTo(centerX - 3, centerY - 8);
    questionPath.quadraticBezierTo(
        centerX - 6, centerY - 12, centerX - 3, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 3, centerY - 18, centerX + 6, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 8, centerY - 12, centerX + 6, centerY - 8);
    canvas.drawPath(questionPath, questionPaint);

    // Question mark dot
    final dotPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY + 5), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for "No Issues" - Checklist with X.
class NoIssuesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangeSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.orangeSecondary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final xPaint = Paint()
      ..color = Colors.red.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Clipboard body
    final clipboardRect = Rect.fromLTWH(size.width * 0.2, size.height * 0.25,
        size.width * 0.6, size.height * 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(clipboardRect, const Radius.circular(4)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(clipboardRect, const Radius.circular(4)),
      paint,
    );

    // Clipboard clip
    final clipRect = Rect.fromLTWH(
        size.width * 0.4, size.height * 0.2, size.width * 0.2, size.height * 0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(clipRect, const Radius.circular(2)),
      paint,
    );

    // Checklist lines
    final linePaint = Paint()
      ..color = AppColors.secondaryText.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.4),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.55, size.height * 0.6),
      linePaint,
    );

    // X mark
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;
    final xSize = size.width * 0.15;

    canvas.drawLine(
      Offset(centerX - xSize, centerY - xSize),
      Offset(centerX + xSize, centerY + xSize),
      xPaint,
    );
    canvas.drawLine(
      Offset(centerX + xSize, centerY - xSize),
      Offset(centerX - xSize, centerY + xSize),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for "No Comments" - Speech bubble with question mark.
class NoCommentsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangeSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.orangeSecondary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final questionPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Speech bubble body
    final bubblePath = Path();
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.45;
    final bubbleWidth = size.width * 0.6;
    final bubbleHeight = size.height * 0.4;

    bubblePath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: bubbleWidth,
          height: bubbleHeight,
        ),
        const Radius.circular(12),
      ),
    );

    // Speech bubble tail
    bubblePath.lineTo(centerX - 8, centerY + bubbleHeight / 2);
    bubblePath.lineTo(centerX + 4, centerY + bubbleHeight / 2 - 8);

    canvas.drawPath(bubblePath, fillPaint);
    canvas.drawPath(bubblePath, paint);

    // Question mark
    final questionPath = Path();
    questionPath.moveTo(centerX - 5, centerY - 8);
    questionPath.quadraticBezierTo(
        centerX - 8, centerY - 12, centerX - 5, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 2, centerY - 18, centerX + 5, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 7, centerY - 12, centerX + 5, centerY - 8);
    canvas.drawPath(questionPath, questionPaint);

    // Question mark dot
    final dotPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY + 5), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for "No Projects" - Board with question mark.
class NoProjectsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangeSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.orangeSecondary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final questionPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Board frame
    final boardRect = Rect.fromLTWH(size.width * 0.15, size.height * 0.25,
        size.width * 0.7, size.height * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(4)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(4)),
      paint,
    );

    // Board columns
    final columnPaint = Paint()
      ..color = AppColors.secondaryText.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.32,
          size.width * 0.18, size.height * 0.35),
      columnPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.41, size.height * 0.32,
          size.width * 0.18, size.height * 0.35),
      columnPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.32,
          size.width * 0.18, size.height * 0.35),
      columnPaint,
    );

    // Question mark in center
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;

    final questionPath = Path();
    questionPath.moveTo(centerX - 6, centerY - 10);
    questionPath.quadraticBezierTo(
        centerX - 10, centerY - 15, centerX - 6, centerY - 19);
    questionPath.quadraticBezierTo(
        centerX + 3, centerY - 23, centerX + 7, centerY - 19);
    questionPath.quadraticBezierTo(
        centerX + 10, centerY - 15, centerX + 7, centerY - 10);
    canvas.drawPath(questionPath, questionPaint);

    // Question mark dot
    final dotPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY + 8), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for "Search Empty" - Magnifying glass with question mark.
class SearchEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangeSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final questionPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final centerX = size.width * 0.45;
    final centerY = size.height * 0.45;
    final lensRadius = size.width * 0.2;

    // Magnifying glass lens
    final lensPaint = Paint()
      ..color = AppColors.orangeSecondary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), lensRadius, lensPaint);
    canvas.drawCircle(Offset(centerX, centerY), lensRadius, paint);

    // Magnifying glass handle
    final handlePath = Path();
    handlePath.moveTo(
      centerX + lensRadius * 0.7,
      centerY + lensRadius * 0.7,
    );
    handlePath.lineTo(
      centerX + lensRadius * 1.4,
      centerY + lensRadius * 1.4,
    );
    canvas.drawPath(handlePath, paint);

    // Question mark inside lens
    final questionPath = Path();
    questionPath.moveTo(centerX - 5, centerY - 8);
    questionPath.quadraticBezierTo(
        centerX - 8, centerY - 12, centerX - 5, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 2, centerY - 18, centerX + 5, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 7, centerY - 12, centerX + 5, centerY - 8);
    canvas.drawPath(questionPath, questionPaint);

    // Question mark dot
    final dotPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY + 5), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full empty state widget with illustration and message.
class EmptyStateWidget extends StatelessWidget {
  /// Type of empty state.
  final EmptyStateType type;

  /// Title text to display.
  final String title;

  /// Subtitle text to display (optional).
  final String? subtitle;

  /// Action button to display (optional).
  final Widget? action;

  /// Creates a complete empty state widget.
  ///
  /// [type] specifies which illustration to use (required).
  /// [title] is the main heading text (required).
  /// [subtitle] is optional descriptive text below the title.
  /// [action] is an optional button or widget for user action.
  const EmptyStateWidget({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyStateIllustration(type: type, size: 100),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
