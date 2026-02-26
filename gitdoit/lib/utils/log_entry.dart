import 'log_level.dart';

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
