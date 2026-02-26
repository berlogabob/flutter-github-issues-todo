/// Sanitization utilities for Logger
class LoggerSanitizer {
  static const _sensitiveKeys = [
    'token',
    'password',
    'secret',
    'key',
    'auth',
    'credential',
    'bearer',
  ];

  /// Sanitize message to remove sensitive data
  static String sanitizeMessage(String message) {
    return message
        .replaceAll(RegExp(r'ghp_[a-zA-Z0-9]{36}'), '[TOKEN_REDACTED]')
        .replaceAll(RegExp(r'github_pat_[a-zA-Z0-9_]+'), '[TOKEN_REDACTED]')
        .replaceAll(
          RegExp(r'password[=:]\s*\S+', caseSensitive: false),
          'password=[REDACTED]',
        )
        .replaceAll(
          RegExp(r'token[=:]\s*\S+', caseSensitive: false),
          'token=[REDACTED]',
        );
  }

  /// Sanitize metadata to remove sensitive data
  static Map<String, dynamic>? sanitizeMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) return null;

    final sanitized = <String, dynamic>{};

    metadata.forEach((key, value) {
      final isSensitive = _sensitiveKeys.any(
        (s) => key.toLowerCase().contains(s),
      );
      if (isSensitive) {
        sanitized[key] = '[REDACTED]';
      } else if (value is String && value.length > 200) {
        sanitized[key] = '${value.substring(0, 200)}...';
      } else if (value is Map) {
        sanitized[key] = sanitizeMetadata(value as Map<String, dynamic>);
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }
}
