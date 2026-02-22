import 'package:flutter/foundation.dart';

/// Log levels for different severity of messages
enum LogLevel { debug, info, warning, error }

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

/// Performance metric for tracking operation latency
class PerformanceMetric {
  final String operation;
  final String context;
  final DateTime startTime;
  DateTime? endTime;
  bool isSuccess;
  int? errorCode;
  String? errorMessage;

  PerformanceMetric({
    required this.operation,
    required this.context,
    required this.startTime,
    this.isSuccess = true,
    this.errorCode,
    this.errorMessage,
  });

  void complete({bool success = true, int? errorCode, String? errorMessage}) {
    endTime = DateTime.now();
    isSuccess = success;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
  }

  Duration get duration =>
      endTime != null ? endTime!.difference(startTime) : Duration.zero;

  @override
  String toString() {
    final status = isSuccess ? '✅' : '❌';
    return '$status $operation ($context): ${duration.inMilliseconds}ms'
        '${!isSuccess ? ' [${errorCode ?? 0}] $errorMessage' : ''}';
  }
}

/// Aggregated metrics for a specific operation
class OperationMetrics {
  final String operation;
  final String context;
  int _totalCalls = 0;
  int _successCount = 0;
  int _failureCount = 0;
  Duration _totalDuration = Duration.zero;

  OperationMetrics(this.operation, this.context);

  OperationMetricSummary get summary {
    final avgMs = _totalCalls > 0
        ? (_totalDuration.inMilliseconds / _totalCalls).round()
        : 0;
    final successRate = _totalCalls > 0
        ? ((_successCount / _totalCalls) * 100).round()
        : 0;
    return OperationMetricSummary(
      operation: operation,
      context: context,
      totalCalls: _totalCalls,
      successCount: _successCount,
      failureCount: _failureCount,
      averageLatencyMs: avgMs,
      successRatePercent: successRate,
    );
  }

  void record(PerformanceMetric metric) {
    _totalCalls++;
    if (metric.isSuccess) {
      _successCount++;
    } else {
      _failureCount++;
    }
    _totalDuration += metric.duration;
  }
}

/// Summary of operation metrics
class OperationMetricSummary {
  final String operation;
  final String context;
  final int totalCalls;
  final int successCount;
  final int failureCount;
  final int averageLatencyMs;
  final int successRatePercent;

  OperationMetricSummary({
    required this.operation,
    required this.context,
    required this.totalCalls,
    required this.successCount,
    required this.failureCount,
    required this.averageLatencyMs,
    required this.successRatePercent,
  });

  String get statusEmoji {
    if (successRatePercent >= 95) return '✅';
    if (successRatePercent >= 80) return '⚠️';
    return '❌';
  }

  @override
  String toString() {
    return '$statusEmoji $operation ($context): '
        '$totalCalls calls, $averageLatencyMs ms avg, $successRatePercent% success';
  }
}

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

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? context;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.context,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  @override
  String toString() {
    final timestampStr = timestamp.toIso8601String().substring(11, 23);
    final contextStr = context != null ? '[$context]' : '';
    final metadataStr = metadata != null ? ' | $metadata' : '';
    return '$timestampStr ${level.name.toUpperCase().padLeft(7)} $contextStr: $message$metadataStr';
  }
}

/// GitDoIt Logger - Centralized logging system with enhanced observability
///
/// ## Features:
/// - Structured logging with levels (debug, info, warning, error)
/// - User journey event tracking
/// - Performance metrics collection
/// - Error context enrichment
/// - Privacy-safe (auto-redacts sensitive data)
/// - Log history with configurable retention
/// - Export functionality for debugging
///
/// ## Usage:
/// ```dart
/// // Basic logging
/// Logger.d('Debug message', context: 'Auth');
/// Logger.i('Info message', context: 'Auth');
/// Logger.w('Warning message', context: 'Auth');
/// Logger.e('Error message', error: e, context: 'Auth');
///
/// // Journey tracking
/// Logger.trackJourney(JourneyEventType.screenView, 'Home', 'viewed_issues');
///
/// // Performance metrics
/// final metric = Logger.startMetric('fetchIssues', 'GitHub');
/// // ... perform operation ...
/// Logger.completeMetric(metric, success: true);
///
/// // Error with context
/// Logger.e('Failed to fetch', error: e, context: 'GitHub', metadata: {'repo': 'owner/repo'});
/// ```
class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;
  static final List<LogEntry> _history = [];
  static const int _maxHistory = 200;

  // Journey events storage
  static final List<JourneyEvent> _journeyHistory = [];
  static const int _maxJourneyHistory = 50;

  // Performance metrics storage
  static final Map<String, OperationMetrics> _metrics = {};

  // Error context storage
  static final List<ErrorContext> _errorHistory = [];
  static const int _maxErrorHistory = 30;

  // App state for error context
  static String? _currentUserId;
  static String? _currentRepository;
  static bool _isOffline = false;

  /// Set minimum log level
  static void setLogLevel(LogLevel level) {
    _minLevel = level;
    i('Log level set to ${level.name}', context: 'Logger');
  }

  /// Get log history
  static List<LogEntry> get history => List.unmodifiable(_history);

  /// Get journey event history
  static List<JourneyEvent> get journeyHistory =>
      List.unmodifiable(_journeyHistory);

  /// Get error history
  static List<ErrorContext> get errorHistory =>
      List.unmodifiable(_errorHistory);

  /// Get performance metrics summary
  static List<OperationMetricSummary> get metricsSummary {
    return _metrics.values.map((m) => m.summary).toList();
  }

  /// Clear log history
  static void clear() {
    _history.clear();
  }

  /// Clear journey history
  static void clearJourney() {
    _journeyHistory.clear();
  }

  /// Clear error history
  static void clearErrors() {
    _errorHistory.clear();
  }

  /// Set current user ID for error context
  static void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  /// Set current repository for error context
  static void setCurrentRepository(String? owner, String? repo) {
    _currentRepository = (owner != null && repo != null)
        ? '$owner/$repo'
        : null;
  }

  /// Set offline state
  static void setOfflineState(bool isOffline) {
    if (_isOffline != isOffline) {
      _isOffline = isOffline;
      i(
        'Connectivity changed: ${isOffline ? "OFFLINE" : "ONLINE"}',
        context: 'Network',
      );
    }
  }

  /// Debug level log
  static void d(
    String message, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.debug, message, context: context, metadata: metadata);
  }

  /// Info level log
  static void i(
    String message, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    _log(LogLevel.info, message, context: context, metadata: metadata);
  }

  /// Warning level log
  static void w(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.warning,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      metadata: metadata,
    );
  }

  /// Error level log with enriched context
  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final errorCtx = ErrorContext(
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context ?? 'Unknown',
      timestamp: DateTime.now(),
      userId: _currentUserId,
      repository: _currentRepository,
      isOffline: _isOffline,
      additionalContext: metadata,
    );

    // Add to error history
    _errorHistory.add(errorCtx);
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }

    // Log the error
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
      metadata: metadata,
    );
  }

  /// Track a user journey event
  static void trackJourney(
    JourneyEventType type,
    String screen,
    String action, {
    Map<String, dynamic>? metadata,
  }) {
    final event = JourneyEvent(
      timestamp: DateTime.now(),
      type: type,
      screen: screen,
      action: action,
      metadata: metadata,
    );

    _journeyHistory.add(event);
    if (_journeyHistory.length > _maxJourneyHistory) {
      _journeyHistory.removeAt(0);
    }

    // Also log the event
    d(
      'Journey: ${type.name} | $screen | $action',
      context: 'Journey',
      metadata: metadata,
    );
  }

  /// Start a performance metric
  static PerformanceMetric startMetric(String operation, String context) {
    return PerformanceMetric(
      operation: operation,
      context: context,
      startTime: DateTime.now(),
    );
  }

  /// Complete a performance metric
  static void completeMetric(
    PerformanceMetric metric, {
    bool success = true,
    int? errorCode,
    String? errorMessage,
  }) {
    metric.complete(
      success: success,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );

    // Aggregate metrics
    final key = '${metric.operation}:${metric.context}';
    _metrics.putIfAbsent(
      key,
      () => OperationMetrics(metric.operation, metric.context),
    );
    _metrics[key]!.record(metric);

    // Log slow operations
    if (metric.duration.inMilliseconds > 1000) {
      w(
        'Slow operation: ${metric.operation} took ${metric.duration.inMilliseconds}ms',
        context: metric.context,
        metadata: {'duration_ms': metric.duration.inMilliseconds},
      );
    }

    // Log failed operations
    if (!success) {
      e(
        'Operation failed: ${metric.operation}',
        context: metric.context,
        metadata: {
          'duration_ms': metric.duration.inMilliseconds,
          'error_code': errorCode,
          'error_message': errorMessage,
        },
      );
    }
  }

  /// Internal log method
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    if (level.index < _minLevel.index) return;

    // Sanitize message and metadata
    final sanitizedMessage = _sanitizeMessage(message);
    final sanitizedMetadata = _sanitizeMetadata(metadata);

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: sanitizedMessage,
      context: context,
      error: error,
      stackTrace: stackTrace,
      metadata: sanitizedMetadata,
    );

    // Add to history
    _history.add(entry);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    // Output to console
    if (kDebugMode) {
      final output = entry.toString();
      if (level == LogLevel.error) {
        final stackTraceStr = stackTrace?.toString();
        final safeStackTrace = stackTraceStr != null
            ? (stackTraceStr.length > 500
                ? stackTraceStr.substring(0, 497) + '...'
                : stackTraceStr)
            : 'null';
        debugPrint(
          '$output\nError: $error\nStackTrace: $safeStackTrace',
        );
      } else {
        debugPrint(output);
      }
    }
  }

  /// Sanitize message to remove sensitive data
  static String _sanitizeMessage(String message) {
    // Remove potential tokens or sensitive patterns
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
  static Map<String, dynamic>? _sanitizeMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) return null;

    final sensitiveKeys = [
      'token',
      'password',
      'secret',
      'key',
      'auth',
      'credential',
      'bearer',
    ];
    final sanitized = <String, dynamic>{};

    metadata.forEach((key, value) {
      final isSensitive = sensitiveKeys.any(
        (s) => key.toLowerCase().contains(s),
      );
      if (isSensitive) {
        sanitized[key] = '[REDACTED]';
      } else if (value is String && value.length > 200) {
        // Truncate long strings
        sanitized[key] = '${value.substring(0, 200)}...';
      } else if (value is Map) {
        // Recursively sanitize nested maps
        sanitized[key] = _sanitizeMetadata(value as Map<String, dynamic>);
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  /// Export logs as string (for debugging/crash reports)
  static String exportLogs({
    bool includeJourney = true,
    bool includeErrors = true,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('GITDOIT LOG EXPORT');
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('App Version: 1.0.0+2');
    buffer.writeln('User ID: ${_currentUserId ?? "anonymous"}');
    buffer.writeln('Repository: ${_currentRepository ?? "not_configured"}');
    buffer.writeln('Offline: $_isOffline');
    buffer.writeln('=' * 60);
    buffer.writeln();

    if (includeErrors && _errorHistory.isNotEmpty) {
      buffer.writeln('--- ERRORS (${_errorHistory.length}) ---');
      for (final error in _errorHistory) {
        buffer.writeln(error.toJson());
      }
      buffer.writeln();
    }

    if (includeJourney && _journeyHistory.isNotEmpty) {
      buffer.writeln('--- JOURNEY EVENTS (${_journeyHistory.length}) ---');
      for (final event in _journeyHistory) {
        buffer.writeln(event.toString());
      }
      buffer.writeln();
    }

    buffer.writeln('--- LOGS (${_history.length}) ---');
    for (final entry in _history) {
      buffer.writeln(entry.toString());
    }

    return buffer.toString();
  }

  /// Export logs as JSON (for crash reporting services)
  static Map<String, dynamic> exportJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': '1.0.0+2',
      'user_id': _currentUserId ?? 'anonymous',
      'repository': _currentRepository ?? 'not_configured',
      'is_offline': _isOffline,
      'errors': _errorHistory.map((e) => e.toJson()).toList(),
      'journey_events': _journeyHistory.map((e) => e.toString()).toList(),
      'logs': _history.map((e) => e.toString()).toList(),
      'metrics': _metrics.values.map((m) => m.summary.toString()).toList(),
    };
  }

  /// Get logs by context
  static List<LogEntry> getLogsByContext(String context) {
    return _history.where((e) => e.context == context).toList();
  }

  /// Get error logs only
  static List<LogEntry> getErrors() {
    return _history.where((e) => e.level == LogLevel.error).toList();
  }

  /// Get journey events by type
  static List<JourneyEvent> getJourneyEventsByType(JourneyEventType type) {
    return _journeyHistory.where((e) => e.type == type).toList();
  }

  /// Get recent errors (last N errors)
  static List<ErrorContext> getRecentErrors({int limit = 10}) {
    return _errorHistory.take(limit).toList();
  }

  /// Get top errors by frequency
  static Map<String, int> getTopErrors({int limit = 5}) {
    final errorCounts = <String, int>{};
    for (final error in _errorHistory) {
      final key = '${error.context}: ${error.error?.runtimeType ?? "Unknown"}';
      errorCounts[key] = (errorCounts[key] ?? 0) + 1;
    }

    // Sort by count descending
    final sorted = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }
}
