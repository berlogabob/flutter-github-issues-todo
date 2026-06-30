import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/github_api_service.dart';

/// Auth Error Handler - Centralized authentication error handling
///
/// Features:
/// - Detects 401/403 errors from API calls
/// - Triggers automatic logout on auth failures
/// - Shows user-friendly error messages
/// - Navigates to onboarding screen
/// - Prevents multiple logout prompts
///
/// Usage:
/// ```dart
/// // In GitHubApiService
/// if (response.statusCode == 401 || response.statusCode == 403) {
///   AuthErrorHandler.handle(context, 'Session expired');
///   return;
/// }
/// ```
class AuthErrorHandler {
  static bool _isLoggingOut = false;
  static DateTime? _lastAuthError;
  static const _debounceDuration = Duration(minutes: 5);

  /// Handle authentication error (401/403)
  ///
  /// [context] - BuildContext for navigation and dialogs
  /// [message] - User-friendly error message
  /// [forceLogout] - If true, immediately logout without confirmation
  static Future<void> handle(
    BuildContext context,
    String message, {
    bool forceLogout = false,
  }) async {
    // Prevent duplicate logout prompts
    if (_isLoggingOut) {
      debugPrint('AuthErrorHandler: Logout already in progress');
      return;
    }

    // Debounce: Don't show multiple auth errors within 5 minutes
    final now = DateTime.now();
    if (_lastAuthError != null &&
        now.difference(_lastAuthError!) < _debounceDuration) {
      debugPrint('AuthErrorHandler: Debouncing auth error (too recent)');
      return;
    }

    _lastAuthError = now;
    debugPrint('AuthErrorHandler: Handling auth error - $message');

    // Clear cached API token immediately
    GitHubApiService().clearCachedToken();

    if (forceLogout) {
      // Immediate logout without confirmation
      await _performLogout(context);
    } else {
      // Show confirmation dialog
      await _showAuthErrorDialog(context, message);
    }
  }

  /// Show auth error dialog with logout option
  static Future<void> _showAuthErrorDialog(
    BuildContext context,
    String message,
  ) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(
          Icons.error_outline,
          color: Color(0xFFFF3B30),
          size: 48,
        ),
        title: const Text(
          'Authentication Error',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Perform logout and navigate to onboarding
  static Future<void> _performLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      debugPrint('AuthErrorHandler: Performing logout...');

      // Clear secure storage
      await SecureStorageService.clearAll();

      // Clear cached token
      GitHubApiService().clearCachedToken();

      // Navigate to onboarding (replace all routes)
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }

      debugPrint('AuthErrorHandler: Logout completed');
    } catch (e, stackTrace) {
      debugPrint('AuthErrorHandler: Logout failed - $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoggingOut = false;
    }
  }

  /// Check if error is an authentication error (401/403)
  static bool isAuthError(dynamic error) {
    if (error == null) return false;

    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('forbidden') ||
        errorStr.contains('invalid token') ||
        errorStr.contains('bad credentials');
  }

  /// Get user-friendly message for auth error
  static String getAuthErrorMessage(dynamic error) {
    if (error == null) {
      return 'Authentication failed. Please login again.';
    }

    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('401') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('invalid token') ||
        errorStr.contains('bad credentials')) {
      return 'Your session has expired. Please login again to continue.';
    }

    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'Access denied. Your token may have expired or lacks required permissions.';
    }

    return 'Authentication error. Please login again.';
  }

  /// Reset state (for testing)
  static void reset() {
    _isLoggingOut = false;
    _lastAuthError = null;
  }
}
