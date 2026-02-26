/// GitDoIt Logging Module
///
/// Centralized logging system with enhanced observability.
///
/// ## Usage:
/// ```dart
/// import 'package:gitdoit/utils/logging.dart';
///
/// Logger.d('Debug message', context: 'Auth');
/// Logger.i('Info message', context: 'Auth');
/// Logger.w('Warning message', context: 'Auth');
/// Logger.e('Error message', error: e, context: 'Auth');
/// Logger.trackJourney(JourneyEventType.screenView, 'Home', 'viewed');
/// final metric = Logger.startMetric('fetchIssues', 'GitHub');
/// Logger.completeMetric(metric, success: true);
/// ```
library logging;

export 'log_level.dart';
export 'log_entry.dart';
export 'journey_event.dart';
export 'performance_metric.dart';
export 'error_context.dart';
export 'logger_config.dart';
export 'logger_sanitizer.dart';
export 'logger_queries.dart';
export 'logger_exporter.dart';
export 'logger.dart';
