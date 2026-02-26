import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Error Boundary Widget - Catches and displays errors in child widgets
/// 
/// Usage:
/// ```dart
/// ErrorBoundary(
///   errorMessage: 'Failed to load data',
///   onRetry: () => _reloadData(),
///   child: YourWidget(),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.showRetryButton = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorDetails;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorUI();
    }

    return _ErrorBoundaryScope(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    debugPrint('ErrorBoundary caught error: $error');
    debugPrint('Stack trace: $stackTrace');

    if (mounted) {
      setState(() {
        _hasError = true;
        _errorDetails = error.toString();
      });
    }
  }

  Widget _buildErrorUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.red.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(
            widget.errorMessage ?? 'Something went wrong',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_errorDetails != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorDetails!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (widget.showRetryButton && widget.onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorDetails = null;
                });
                widget.onRetry!();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Scope for error boundary - allows child widgets to report errors
class _ErrorBoundaryScope extends InheritedWidget {
  final Function(Object error, StackTrace stackTrace) onError;

  const _ErrorBoundaryScope({
    required this.onError,
    required super.child,
  });

  static _ErrorBoundaryScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ErrorBoundaryScope>();
  }

  @override
  bool updateShouldNotify(_ErrorBoundaryScope oldWidget) => false;
}

/// Extension to report errors from within widgets
extension ErrorBoundaryExtension on BuildContext {
  void reportError(Object error, [StackTrace? stackTrace]) {
    final scope = _ErrorBoundaryScope.of(this);
    if (scope != null) {
      scope.onError(error, stackTrace ?? StackTrace.current);
    }
  }
}

/// Widget for displaying inline errors
class InlineError extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onDismiss;
  final bool fullScreen;

  const InlineError({
    super.key,
    required this.message,
    this.details,
    this.onDismiss,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: _buildErrorContent(context),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
      ),
      child: _buildErrorContent(context, compact: true),
    );
  }

  Widget _buildErrorContent(BuildContext context, {bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.red,
              size: compact ? 20 : 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: compact ? 13 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (details != null && !compact) ...[
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
            if (onDismiss != null) ...[
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: onDismiss,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
