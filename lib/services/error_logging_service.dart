import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Error Logging Service - Singleton for local error logging
///
/// Features:
/// - Saves errors to file: ${appDirectory}/errors.log
/// - Format: [timestamp] [level] message\nstackTrace
/// - Human-readable, timestamped entries
/// - Thread-safe file operations
/// - Configurable max log size
///
/// Usage:
/// ```dart
/// // Log an error
/// ErrorLoggingService.instance.logError(
///   'Database error',
///   error: Exception('Connection failed'),
///   stackTrace: StackTrace.current,
///   level: ErrorLevel.error,
/// );
///
/// // Get all errors
/// final errors = await ErrorLoggingService.instance.getErrors();
///
/// // Clear errors
/// await ErrorLoggingService.instance.clearErrors();
///
/// // Export errors
/// final path = await ErrorLoggingService.instance.exportErrors();
/// ```
enum ErrorLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class ErrorLoggingService {
  ErrorLoggingService._();

  static final ErrorLoggingService _instance = ErrorLoggingService._();
  static ErrorLoggingService get instance => _instance;

  File? _logFile;
  bool _isInitialized = false;
  static const int _maxLogSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int _maxLogLines = 1000;

  /// Initialize the error logging service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logFile = File('${appDir.path}/errors.log');

      // Create file if it doesn't exist
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }

      // Rotate log if too large
      await _rotateLogIfNeeded();

      _isInitialized = true;
      debugPrint('ErrorLoggingService: Initialized with log file at ${_logFile!.path}');
    } catch (e, stackTrace) {
      debugPrint('ErrorLoggingService: Initialization failed: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  /// Rotate log file if it exceeds max size
  Future<void> _rotateLogIfNeeded() async {
    if (_logFile == null || !await _logFile!.exists()) return;

    try {
      final stats = await _logFile!.stat();
      if (stats.size > _maxLogSizeBytes) {
        // Keep only last _maxLogLines
        final lines = await _logFile!.readAsLines();
        final startIdx = lines.length > _maxLogLines
            ? lines.length - _maxLogLines
            : 0;
        final recentLines = lines.sublist(startIdx);
        await _logFile!.writeAsString(recentLines.join('\n') + '\n');
        debugPrint('ErrorLoggingService: Log rotated, kept ${recentLines.length} lines');
      }
    } catch (e) {
      debugPrint('ErrorLoggingService: Log rotation failed: $e');
    }
  }

  /// Log an error with level, message, and optional error/stackTrace
  Future<void> logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    ErrorLevel level = ErrorLevel.error,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (_logFile == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final levelStr = _formatLevel(level);
      
      // Format: [timestamp] [level] message
      var logEntry = '[$timestamp] [$levelStr] $message';

      // Add error if present
      if (error != null) {
        logEntry += '\nError: $error';
      }

      // Add stack trace if present
      if (stackTrace != null) {
        logEntry += '\nStackTrace:\n$stackTrace';
      }

      // Add context if present
      if (context != null) {
        logEntry += '\nContext: $context';
      }

      // Add separator
      logEntry += '\n${'-' * 80}\n';

      // Append to file
      await _logFile!.writeAsString(logEntry, mode: FileMode.append);

      // Also log to console in debug mode
      if (kDebugMode) {
        debugPrint('ErrorLoggingService: $logEntry');
      }

      // Rotate if needed after write
      await _rotateLogIfNeeded();
    } catch (e, stackTrace) {
      debugPrint('ErrorLoggingService: Failed to log error: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  /// Log a debug message
  Future<void> logDebug(String message, {Object? error, StackTrace? stackTrace}) {
    return logError(message, error: error, stackTrace: stackTrace, level: ErrorLevel.debug);
  }

  /// Log an info message
  Future<void> logInfo(String message, {Object? error, StackTrace? stackTrace}) {
    return logError(message, error: error, stackTrace: stackTrace, level: ErrorLevel.info);
  }

  /// Log a warning
  Future<void> logWarning(String message, {Object? error, StackTrace? stackTrace}) {
    return logError(message, error: error, stackTrace: stackTrace, level: ErrorLevel.warning);
  }

  /// Log a critical error
  Future<void> logCritical(String message, {Object? error, StackTrace? stackTrace}) {
    return logError(message, error: error, stackTrace: stackTrace, level: ErrorLevel.critical);
  }

  /// Get all errors from the log file
  Future<List<LogEntry>> getErrors() async {
    if (!_isInitialized || _logFile == null) {
      await init();
    }

    if (_logFile == null || !await _logFile!.exists()) {
      return [];
    }

    try {
      final content = await _logFile!.readAsString();
      if (content.isEmpty) return [];

      final entries = <LogEntry>[];
      final blocks = content.split('-' * 80);

      for (final block in blocks) {
        if (block.trim().isEmpty) continue;

        final entry = _parseLogEntry(block.trim());
        if (entry != null) {
          entries.add(entry);
        }
      }

      // Return most recent first
      return entries.reversed.toList();
    } catch (e, stackTrace) {
      debugPrint('ErrorLoggingService: Failed to read errors: $e');
      debugPrint('Stack: $stackTrace');
      return [];
    }
  }

  /// Parse a log entry from text
  LogEntry? _parseLogEntry(String text) {
    try {
      final lines = text.split('\n');
      if (lines.isEmpty) return null;

      // Parse header line: [timestamp] [level] message
      final headerMatch = RegExp(r'\[([^\]]+)\] \[([^\]]+)\] (.+)').firstMatch(lines.first);
      if (headerMatch == null) return null;

      final timestamp = DateTime.tryParse(headerMatch.group(1)!) ?? DateTime.now();
      final level = _parseLevel(headerMatch.group(2)!) ?? ErrorLevel.error;
      final message = headerMatch.group(3)!;

      // Collect error and stack trace from remaining lines
      final errorLines = <String>[];
      final stackTraceLines = <String>[];
      var isStackTrace = false;

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.startsWith('Error:')) {
          errorLines.add(line.substring(6).trim());
        } else if (line.startsWith('StackTrace:')) {
          isStackTrace = true;
        } else if (line.startsWith('Context:')) {
          isStackTrace = false;
        } else if (isStackTrace) {
          stackTraceLines.add(line);
        } else {
          errorLines.add(line);
        }
      }

      return LogEntry(
        timestamp: timestamp,
        level: level,
        message: message,
        error: errorLines.join('\n'),
        stackTrace: stackTraceLines.join('\n'),
      );
    } catch (e) {
      debugPrint('ErrorLoggingService: Failed to parse log entry: $e');
      return null;
    }
  }

  ErrorLevel? _parseLevel(String levelStr) {
    switch (levelStr.toLowerCase()) {
      case 'debug':
        return ErrorLevel.debug;
      case 'info':
        return ErrorLevel.info;
      case 'warning':
        return ErrorLevel.warning;
      case 'error':
        return ErrorLevel.error;
      case 'critical':
        return ErrorLevel.critical;
      default:
        return null;
    }
  }

  String _formatLevel(ErrorLevel level) {
    switch (level) {
      case ErrorLevel.debug:
        return 'DEBUG';
      case ErrorLevel.info:
        return 'INFO';
      case ErrorLevel.warning:
        return 'WARNING';
      case ErrorLevel.error:
        return 'ERROR';
      case ErrorLevel.critical:
        return 'CRITICAL';
    }
  }

  /// Clear all errors from the log file
  Future<void> clearErrors() async {
    if (!_isInitialized || _logFile == null) {
      await init();
    }

    if (_logFile != null) {
      try {
        await _logFile!.writeAsString('');
        debugPrint('ErrorLoggingService: All errors cleared');
      } catch (e, stackTrace) {
        debugPrint('ErrorLoggingService: Failed to clear errors: $e');
        debugPrint('Stack: $stackTrace');
      }
    }
  }

  /// Export errors to a shareable file
  /// Returns the path to the exported file
  Future<String?> exportErrors() async {
    if (!_isInitialized || _logFile == null) {
      await init();
    }

    if (_logFile == null || !await _logFile!.exists()) {
      return null;
    }

    try {
      // Create export file with timestamp
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportFile = File('${appDir.path}/errors_export_$timestamp.log');

      // Copy current log to export file
      await _logFile!.copy(exportFile.path);

      debugPrint('ErrorLoggingService: Errors exported to ${exportFile.path}');
      return exportFile.path;
    } catch (e, stackTrace) {
      debugPrint('ErrorLoggingService: Failed to export errors: $e');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }

  /// Get the path to the log file
  String? get logFilePath => _logFile?.path;

  /// Get the number of errors in the log
  Future<int> getErrorCount() async {
    final errors = await getErrors();
    return errors.length;
  }

  /// Check if there are any errors
  Future<bool> hasErrors() async {
    final count = await getErrorCount();
    return count > 0;
  }
}

/// Represents a single log entry
class LogEntry {
  final DateTime timestamp;
  final ErrorLevel level;
  final String message;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  /// Format the entry for display
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Get a brief summary
  String get summary {
    return '[$formattedTimestamp] [${_levelEmoji()}] $message';
  }

  String _levelEmoji() {
    switch (level) {
      case ErrorLevel.debug:
        return '🐛';
      case ErrorLevel.info:
        return 'ℹ️';
      case ErrorLevel.warning:
        return '⚠️';
      case ErrorLevel.error:
        return '❌';
      case ErrorLevel.critical:
        return '🔥';
    }
  }

  @override
  String toString() {
    return 'LogEntry(timestamp: $timestamp, level: $level, message: $message)';
  }
}
