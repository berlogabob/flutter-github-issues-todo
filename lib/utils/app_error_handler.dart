import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Centralized error handling utility
class AppErrorHandler {
  /// Handle error with logging and optional user feedback
  static void handle(
    Object error, {
    StackTrace? stackTrace,
    BuildContext? context,
    String? userMessage,
    bool showSnackBar = true,
  }) {
    // Always log error
    debugPrint('❌ Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack: $stackTrace');
    }

    // Show user feedback if context provided
    if (context != null && showSnackBar && context.mounted) {
      _showSnackBar(context, userMessage ?? _getDefaultMessage(error));
    }
  }

  /// Show error SnackBar
  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Get user-friendly error message
  static String _getDefaultMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socket') || errorStr.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Authentication failed. Please login again.';
    }
    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'Access denied. Check token permissions.';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Resource not found.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Handle async operation with error handling
  static Future<T?> runAsync<T>({
    required Future<T> Function() operation,
    BuildContext? context,
    String? errorMessage,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      handle(e, stackTrace: stack, context: context, userMessage: errorMessage);
      return defaultValue;
    }
  }
}
