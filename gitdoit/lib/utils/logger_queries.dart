import 'log_entry.dart';
import 'log_level.dart';
import 'journey_event.dart';
import 'error_context.dart';

/// Query utilities for Logger
class LoggerQueries {
  /// Get logs by context
  static List<LogEntry> getLogsByContext(
    List<LogEntry> history,
    String context,
  ) {
    return history.where((e) => e.context == context).toList();
  }

  /// Get error logs only
  static List<LogEntry> getErrors(List<LogEntry> history) {
    return history.where((e) => e.level == LogLevel.error).toList();
  }

  /// Get journey events by type
  static List<JourneyEvent> getJourneyEventsByType(
    List<JourneyEvent> journeyHistory,
    JourneyEventType type,
  ) {
    return journeyHistory.where((e) => e.type == type).toList();
  }

  /// Get recent errors (last N errors)
  static List<ErrorContext> getRecentErrors(
    List<ErrorContext> errorHistory, {
    int limit = 10,
  }) {
    return errorHistory.take(limit).toList();
  }

  /// Get top errors by frequency
  static Map<String, int> getTopErrors(
    List<ErrorContext> errorHistory, {
    int limit = 5,
  }) {
    final errorCounts = <String, int>{};
    for (final error in errorHistory) {
      final key = '${error.context}: ${error.error?.runtimeType ?? "Unknown"}';
      errorCounts[key] = (errorCounts[key] ?? 0) + 1;
    }

    final sorted = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }
}
