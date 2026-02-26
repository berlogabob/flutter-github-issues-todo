import 'package:flutter/foundation.dart';
import 'log_level.dart';
import 'log_entry.dart';
import 'journey_event.dart';
import 'performance_metric.dart';
import 'error_context.dart';
import 'logger_sanitizer.dart';
import 'logger_queries.dart';
import 'logger_exporter.dart';

/// GitDoIt Logger - Centralized logging with observability
/// Usage: Logger.d('msg'); Logger.i('msg'); Logger.w('msg'); Logger.e('msg');
/// Logger.trackJourney(type, screen, action); Logger.startMetric/op/completeMetric
class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;
  static final _history = <LogEntry>[];
  static final _journeyHistory = <JourneyEvent>[];
  static final _metrics = <String, OperationMetrics>{};
  static final _errorHistory = <ErrorContext>[];
  static String? _userId;
  static String? _repo;
  static bool _isOffline = false;

  static void setLogLevel(LogLevel level) {
    _minLevel = level;
    i('Log level: ${level.name}', context: 'Logger');
  }

  static List<LogEntry> get history => List.unmodifiable(_history);
  static List<JourneyEvent> get journeyHistory => List.unmodifiable(_journeyHistory);
  static List<ErrorContext> get errorHistory => List.unmodifiable(_errorHistory);
  static List<OperationMetricSummary> get metricsSummary =>
      _metrics.values.map((m) => m.summary).toList();
  static void clear() => _history.clear();
  static void clearJourney() => _journeyHistory.clear();
  static void clearErrors() => _errorHistory.clear();
  static void setCurrentUser(String? id) => _userId = id;
  static void setCurrentRepository(String? owner, String? repo) =>
      _repo = (owner != null && repo != null) ? '$owner/$repo' : null;
  static void setOfflineState(bool offline) {
    if (_isOffline != offline) {
      _isOffline = offline;
      i('Connectivity: ${offline ? "OFFLINE" : "ONLINE"}', context: 'Network');
    }
  }

  static void d(String msg, {String? context, Map<String, dynamic>? metadata}) =>
      _log(LogLevel.debug, msg, context: context, metadata: metadata);
  static void i(String msg, {String? context, Map<String, dynamic>? metadata}) =>
      _log(LogLevel.info, msg, context: context, metadata: metadata);
  static void w(String msg, {Object? error, StackTrace? stackTrace,
      String? context, Map<String, dynamic>? metadata}) =>
      _log(LogLevel.warning, msg, error: error, stackTrace: stackTrace,
          context: context, metadata: metadata);
  static void e(String msg, {Object? error, StackTrace? stackTrace,
      String? context, Map<String, dynamic>? metadata}) {
    _errorHistory.add(ErrorContext(message: msg, error: error,
        stackTrace: stackTrace, context: context ?? 'Unknown',
        timestamp: DateTime.now(), userId: _userId, repository: _repo,
        isOffline: _isOffline, additionalContext: metadata));
    if (_errorHistory.length > 30) _errorHistory.removeAt(0);
    _log(LogLevel.error, msg, error: error, stackTrace: stackTrace,
        context: context, metadata: metadata);
  }

  static void trackJourney(JourneyEventType type, String screen, String action,
      {Map<String, dynamic>? metadata}) {
    final event = JourneyEvent(timestamp: DateTime.now(), type: type,
        screen: screen, action: action, metadata: metadata);
    _journeyHistory.add(event);
    if (_journeyHistory.length > 50) _journeyHistory.removeAt(0);
    d('Journey: ${type.name} | $screen | $action',
        context: 'Journey', metadata: metadata);
  }

  static PerformanceMetric startMetric(String op, String ctx) =>
      PerformanceMetric(operation: op, context: ctx, startTime: DateTime.now());

  static void completeMetric(PerformanceMetric m,
      {bool success = true, int? errorCode, String? errorMessage}) {
    m.complete(success: success, errorCode: errorCode, errorMessage: errorMessage);
    final key = '${m.operation}:${m.context}';
    _metrics.putIfAbsent(key, () => OperationMetrics(m.operation, m.context));
    _metrics[key]!.record(m);
    if (m.duration.inMilliseconds > 1000)
      w('Slow: ${m.operation} (${m.duration.inMilliseconds}ms)',
          context: m.context,
          metadata: {'duration_ms': m.duration.inMilliseconds});
    if (!success) e('Failed: ${m.operation}', context: m.context, metadata: {
      'duration_ms': m.duration.inMilliseconds,
      'error_code': errorCode, 'error_message': errorMessage});
  }

  static void _log(LogLevel level, String msg, {Object? error,
      StackTrace? stackTrace, String? context, Map<String, dynamic>? metadata}) {
    if (level.index < _minLevel.index) return;
    final entry = LogEntry(timestamp: DateTime.now(), level: level,
        message: LoggerSanitizer.sanitizeMessage(msg), context: context,
        error: error, stackTrace: stackTrace,
        metadata: LoggerSanitizer.sanitizeMetadata(metadata));
    _history.add(entry);
    if (_history.length > 200) _history.removeAt(0);
    if (kDebugMode) {
      final out = entry.toString();
      if (level == LogLevel.error) {
        final st = stackTrace?.toString();
        final safe = st != null
            ? (st.length > 500 ? '${st.substring(0, 497)}...' : st)
            : 'null';
        debugPrint('$out\nError: $error\nStackTrace: $safe');
      } else {
        debugPrint(out);
      }
    }
  }

  static String exportLogs(
          {bool includeJourney = true, bool includeErrors = true}) =>
      LoggerExporter.exportLogs(
          errorHistory: _errorHistory,
          journeyHistory: _journeyHistory,
          logStrings: _history.map((e) => e.toString()).toList(),
          userId: _userId,
          repository: _repo,
          isOffline: _isOffline,
          includeJourney: includeJourney,
          includeErrors: includeErrors);

  static Map<String, dynamic> exportJson() => LoggerExporter.exportJson(
      errorHistory: _errorHistory,
      journeyHistory: _journeyHistory,
      logStrings: _history.map((e) => e.toString()).toList(),
      metricStrings: _metrics.values.map((m) => m.summary.toString()).toList(),
      userId: _userId,
      repository: _repo,
      isOffline: _isOffline);

  static List<LogEntry> getLogsByContext(String ctx) =>
      LoggerQueries.getLogsByContext(_history, ctx);
  static List<LogEntry> getErrors() => LoggerQueries.getErrors(_history);
  static List<JourneyEvent> getJourneyEventsByType(JourneyEventType type) =>
      LoggerQueries.getJourneyEventsByType(_journeyHistory, type);
  static List<ErrorContext> getRecentErrors({int limit = 10}) =>
      LoggerQueries.getRecentErrors(_errorHistory, limit: limit);
  static Map<String, int> getTopErrors({int limit = 5}) =>
      LoggerQueries.getTopErrors(_errorHistory, limit: limit);
}
