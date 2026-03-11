import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Error Boundary Widget - Catches and displays errors in child widgets
///
/// Features:
/// - Retry button to rebuild child widget
/// - Go Back button to navigate to previous screen
/// - Expandable error details section
/// - Styled with AppColors
/// - Error logging preserved
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
  /// The child widget to protect with error handling.
  final Widget child;

  /// Custom error message to display.
  final String? errorMessage;

  /// Callback function to retry the failed operation.
  final VoidCallback? onRetry;

  /// Whether to show the retry button.
  final bool showRetryButton;

  /// Whether to show the go back button.
  final bool showGoBackButton;

  /// Whether to allow expanding error details.
  final bool allowExpandDetails;

  /// Creates an error boundary widget.
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.showRetryButton = true,
    this.showGoBackButton = true,
    this.allowExpandDetails = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  /// Error state flag.
  bool _hasError = false;

  /// Detailed error message.
  String? _errorDetails;

  /// Stack trace for debugging.
  StackTrace? _stackTrace;

  /// Expanded state for error details.
  bool _isDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorUI();
    }

    return _ErrorBoundaryScope(onError: _handleError, child: widget.child);
  }

  void _handleError(Object error, StackTrace stackTrace) {
    debugPrint('ErrorBoundary caught error: $error');
    debugPrint('Stack trace: $stackTrace');

    if (mounted) {
      setState(() {
        _hasError = true;
        _errorDetails = error.toString();
        _stackTrace = stackTrace;
      });
    }
  }

  Widget _buildErrorUI() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error Icon
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),

          // Error Message
          Text(
            widget.errorMessage ?? 'Something went wrong',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          // Brief Error Summary
          if (_errorDetails != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorDetails!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Action Buttons
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              // Retry Button
              if (widget.showRetryButton && widget.onRetry != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorDetails = null;
                      _stackTrace = null;
                      _isDetailsExpanded = false;
                    });
                    widget.onRetry!();
                  },
                ),

              // Go Back Button
              if (widget.showGoBackButton)
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
            ],
          ),

          // Expandable Error Details Section
          if (widget.allowExpandDetails && _errorDetails != null) ...[
            const SizedBox(height: 24),
            _buildExpandableErrorDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableErrorDetails() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isDetailsExpanded = !_isDetailsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _isDetailsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.error.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Error Details',
                    style: TextStyle(
                      color: AppColors.error.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _isDetailsExpanded ? 'Hide' : 'Show',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isDetailsExpanded) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error Message
                  Text(
                    'Error:',
                    style: TextStyle(
                      color: AppColors.error.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _errorDetails!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),

                  // Stack Trace
                  if (_stackTrace != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Stack Trace:',
                      style: TextStyle(
                        color: AppColors.error.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _stackTrace.toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Copy Error Button
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Error Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        final errorText = 'Error: $_errorDetails\n\nStackTrace: $_stackTrace';
                        // Copy to clipboard would be implemented here
                        debugPrint('Error copied: $errorText');
                      },
                    ),
                  ),
                ],
              ),
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

  const _ErrorBoundaryScope({required this.onError, required super.child});

  static _ErrorBoundaryScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ErrorBoundaryScope>();
  }

  @override
  bool updateShouldNotify(_ErrorBoundaryScope oldWidget) => false;
}

/// Extension to report errors from within widgets.
///
/// Provides convenient error reporting from any widget context.
/// Errors are propagated to the nearest ErrorBoundary ancestor.
extension ErrorBoundaryExtension on BuildContext {
  /// Reports an error to the nearest ErrorBoundary.
  ///
  /// [error] is the error object or message.
  /// [stackTrace] is optional and defaults to current stack trace.
  void reportError(Object error, [StackTrace? stackTrace]) {
    final scope = _ErrorBoundaryScope.of(this);
    if (scope != null) {
      scope.onError(error, stackTrace ?? StackTrace.current);
    }
  }
}

/// Widget for displaying inline errors within a UI.
///
/// Shows error message with optional details and dismiss button.
/// Can be displayed as full-screen or inline.
class InlineError extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Optional error details for debugging.
  final String? details;

  /// Callback when user dismisses the error.
  final VoidCallback? onDismiss;

  /// Whether to display as full-screen error.
  final bool fullScreen;

  /// Creates an inline error widget.
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
        body: Center(child: _buildErrorContent(context)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
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
              color: AppColors.error,
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
                      color: AppColors.error,
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
