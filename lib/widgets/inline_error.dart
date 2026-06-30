import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class InlineError extends StatelessWidget {
  const InlineError({
    super.key,
    required this.message,
    this.details,
    this.onDismiss,
    this.fullScreen = false,
  });

  final String message;
  final String? details;
  final VoidCallback? onDismiss;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final content = Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: fullScreen ? null : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: fullScreen ? 40 : 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: fullScreen ? 16 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      details!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss error',
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );

    if (!fullScreen) return content;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: content),
    );
  }
}
