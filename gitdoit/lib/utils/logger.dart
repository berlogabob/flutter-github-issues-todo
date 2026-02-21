import 'package:flutter/foundation.dart';

/// Log levels for different severity of messages
enum LogLevel { debug, info, warning, error }

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? context;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.context,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final timestampStr = timestamp.toIso8601String().substring(11, 23);
    final contextStr = context != null ? '[$context]' : '';
    return '$timestampStr ${level.name.toUpperCase().padLeft(7)} $contextStr: $message';
  }
}

/// GitDoIt Logger - Centralized logging system
///
/// Usage:
/// ```dart
/// Logger.d('Debug message', context: 'Auth');
/// Logger.i('Info message', context: 'Auth');
/// Logger.w('Warning message', context: 'Auth');
/// Logger.e('Error message', error: e, context: 'Auth');
/// ```
class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  static final List<LogEntry> _history = [];
  static const int _maxHistory = 100;

  /// Set minimum log level
  static void setLogLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Get log history
  static List<LogEntry> get history => List.unmodifiable(_history);

  /// Clear log history
  static void clear() {
    _history.clear();
  }

  /// Debug level log
  static void d(String message, {String? context}) {
    _log(LogLevel.debug, message, context: context);
  }

  /// Info level log
  static void i(String message, {String? context}) {
    _log(LogLevel.info, message, context: context);
  }

  /// Warning level log
  static void w(String message, {String? context}) {
    _log(LogLevel.warning, message, context: context);
  }

  /// Error level log
  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Internal log method
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) {
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
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
        debugPrint('$output\nError: $error\nStackTrace: $stackTrace');
      } else {
        debugPrint(output);
      }
    }

    // TODO: In production, send errors to crash reporting service
  }

  /// Export logs as string
  static String exportLogs() {
    return _history.map((e) => e.toString()).join('\n');
  }

  /// Get logs by context
  static List<LogEntry> getLogsByContext(String context) {
    return _history.where((e) => e.context == context).toList();
  }

  /// Get error logs only
  static List<LogEntry> getErrors() {
    return _history.where((e) => e.level == LogLevel.error).toList();
  }
}
