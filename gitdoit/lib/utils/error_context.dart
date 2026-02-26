/// Error context for enriched error reporting
class ErrorContext {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final String context;
  final DateTime timestamp;
  final String? userId;
  final String? repository;
  final bool isOffline;
  final String appVersion;
  final Map<String, dynamic>? additionalContext;

  ErrorContext({
    required this.message,
    this.error,
    this.stackTrace,
    required this.context,
    required this.timestamp,
    this.userId,
    this.repository,
    this.isOffline = false,
    this.appVersion = '1.0.0+2',
    this.additionalContext,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'error_type': error?.runtimeType.toString() ?? 'Unknown',
      'error_message': _sanitizeError(error?.toString()),
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId ?? 'anonymous',
      'repository': repository ?? 'not_configured',
      'is_offline': isOffline,
      'app_version': appVersion,
      'has_stack_trace': stackTrace != null,
      'additional_context': _sanitizeAdditionalContext(additionalContext),
    };
  }

  /// Sanitize error message to remove sensitive data
  String _sanitizeError(String? errorStr) {
    if (errorStr == null) return 'Unknown error';
    // Remove potential tokens or sensitive patterns
    final sanitized = errorStr
        .replaceAll(RegExp(r'ghp_[a-zA-Z0-9]{36}'), '[TOKEN_REDACTED]')
        .replaceAll(
          RegExp(r'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}'),
          '[TOKEN_REDACTED]',
        )
        .replaceAll(
          RegExp(r'password[=:]\s*\S+', caseSensitive: false),
          'password=[REDACTED]',
        )
        .replaceAll(
          RegExp(r'token[=:]\s*\S+', caseSensitive: false),
          'token=[REDACTED]',
        );
    return sanitized;
  }

  /// Sanitize additional context
  Map<String, dynamic>? _sanitizeAdditionalContext(Map<String, dynamic>? ctx) {
    if (ctx == null) return null;
    final sensitiveKeys = [
      'token',
      'password',
      'secret',
      'key',
      'auth',
      'credential',
    ];
    final sanitized = <String, dynamic>{};
    ctx.forEach((key, value) {
      final isSensitive = sensitiveKeys.any(
        (s) => key.toLowerCase().contains(s),
      );
      if (isSensitive) {
        sanitized[key] = '[REDACTED]';
      } else if (value is String && value.length > 200) {
        sanitized[key] = '${value.substring(0, 200)}...';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  @override
  String toString() {
    return '[ERROR] $context: $message'
        '${error != null ? ' | ${error.runtimeType}' : ''}';
  }
}
