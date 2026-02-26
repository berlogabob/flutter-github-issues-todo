import 'log_level.dart';

/// Configuration for the GitDoIt Logger
class LoggerConfig {
  /// Minimum log level (default: debug in debug mode, warning in release)
  final LogLevel minLevel;

  /// Maximum number of log entries to keep in history
  final int maxHistory;

  /// Maximum number of journey events to keep
  final int maxJourneyHistory;

  /// Maximum number of error contexts to keep
  final int maxErrorHistory;

  /// App version for error reporting
  final String appVersion;

  const LoggerConfig({
    this.minLevel = LogLevel.debug,
    this.maxHistory = 200,
    this.maxJourneyHistory = 50,
    this.maxErrorHistory = 30,
    this.appVersion = '1.0.0+2',
  });

  /// Default config for debug mode
  factory LoggerConfig.debug() {
    return const LoggerConfig(minLevel: LogLevel.debug);
  }

  /// Default config for release mode
  factory LoggerConfig.release() {
    return const LoggerConfig(minLevel: LogLevel.warning);
  }
}
