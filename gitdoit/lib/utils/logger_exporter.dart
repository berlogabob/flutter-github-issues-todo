import 'journey_event.dart';
import 'error_context.dart';

/// Export utilities for Logger
class LoggerExporter {
  static const appVersion = '1.0.0+2';

  /// Export logs as string (for debugging/crash reports)
  static String exportLogs({
    required List<ErrorContext> errorHistory,
    required List<JourneyEvent> journeyHistory,
    required List<String> logStrings,
    String? userId,
    String? repository,
    bool isOffline = false,
    bool includeJourney = true,
    bool includeErrors = true,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('GITDOIT LOG EXPORT');
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('App Version: $appVersion');
    buffer.writeln('User ID: ${userId ?? "anonymous"}');
    buffer.writeln('Repository: ${repository ?? "not_configured"}');
    buffer.writeln('Offline: $isOffline');
    buffer.writeln('=' * 60);
    buffer.writeln();

    if (includeErrors && errorHistory.isNotEmpty) {
      buffer.writeln('--- ERRORS (${errorHistory.length}) ---');
      for (final error in errorHistory) {
        buffer.writeln(error.toJson());
      }
      buffer.writeln();
    }

    if (includeJourney && journeyHistory.isNotEmpty) {
      buffer.writeln('--- JOURNEY EVENTS (${journeyHistory.length}) ---');
      for (final event in journeyHistory) {
        buffer.writeln(event.toString());
      }
      buffer.writeln();
    }

    buffer.writeln('--- LOGS (${logStrings.length}) ---');
    for (final entry in logStrings) {
      buffer.writeln(entry);
    }

    return buffer.toString();
  }

  /// Export logs as JSON (for crash reporting services)
  static Map<String, dynamic> exportJson({
    required List<ErrorContext> errorHistory,
    required List<JourneyEvent> journeyHistory,
    required List<String> logStrings,
    required List<String> metricStrings,
    String? userId,
    String? repository,
    bool isOffline = false,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'app_version': appVersion,
      'user_id': userId ?? 'anonymous',
      'repository': repository ?? 'not_configured',
      'is_offline': isOffline,
      'errors': errorHistory.map((e) => e.toJson()).toList(),
      'journey_events': journeyHistory.map((e) => e.toString()).toList(),
      'logs': logStrings,
      'metrics': metricStrings,
    };
  }
}
