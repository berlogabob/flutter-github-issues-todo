/// Types of user journey events for tracking navigation and actions
enum JourneyEventType {
  screenView, // User navigated to a screen
  userAction, // User performed an action (tap, submit, etc.)
  configChange, // User changed app configuration
  authEvent, // Authentication-related event
  syncEvent, // Online/offline sync event
  systemAction, // System-triggered action (auto-refresh, validation, etc.)
}

/// User journey event model
class JourneyEvent {
  final DateTime timestamp;
  final JourneyEventType type;
  final String screen;
  final String action;
  final Map<String, dynamic>? metadata;

  JourneyEvent({
    required this.timestamp,
    required this.type,
    required this.screen,
    required this.action,
    this.metadata,
  });

  @override
  String toString() {
    return '[${timestamp.toIso8601String().substring(11, 23)}] '
        '${type.name.toUpperCase()} | $screen | $action'
        '${metadata != null ? ' | ${_sanitizeMetadata(metadata!)}' : ''}';
  }

  /// Sanitize metadata to ensure no sensitive data is included
  String _sanitizeMetadata(Map<String, dynamic> metadata) {
    final sensitiveKeys = ['token', 'password', 'secret', 'key', 'auth'];
    final sanitized = <String, dynamic>{};
    metadata.forEach((key, value) {
      final isSensitive = sensitiveKeys.any(
        (s) => key.toLowerCase().contains(s),
      );
      if (isSensitive) {
        sanitized[key] = '[REDACTED]';
      } else if (value is String && value.length > 100) {
        // Truncate long strings
        sanitized[key] = '${value.substring(0, 100)}...';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized.toString();
  }
}
