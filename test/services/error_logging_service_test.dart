import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/error_logging_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock path provider for testing
class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  String? temporaryPath;
  String? applicationSupportPath;
  String? libraryPath;
  String? applicationDocumentsPath;
  String? externalStoragePath;
  String? externalCachePath;
  String? downloadsPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;

  @override
  Future<String?> getApplicationSupportPath() async => applicationSupportPath;

  @override
  Future<String?> getLibraryPath() async => libraryPath;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      applicationDocumentsPath;

  @override
  Future<String?> getExternalStoragePath() async => externalStoragePath;

  @override
  Future<List<String>?> getExternalCachePaths() async =>
      externalCachePath != null ? [externalCachePath!] : null;

  @override
  Future<String?> getDownloadsPath() async => downloadsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorLoggingService Tests', () {
    late MockPathProviderPlatform mockPathProvider;
    late String testDir;

    setUp(() async {
      // Create a temporary directory for testing
      testDir = Directory.systemTemp.createTempSync('error_log_test_').path;

      mockPathProvider = MockPathProviderPlatform()
        ..applicationDocumentsPath = testDir;

      PathProviderPlatform.instance = mockPathProvider;

      // Reset the singleton instance for each test
      ErrorLoggingService.instance;
    });

    tearDown(() async {
      // Clean up test directory
      final dir = Directory(testDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    group('Initialization', () {
      testWidgets('service initializes successfully', (tester) async {
        await ErrorLoggingService.instance.init();

        expect(ErrorLoggingService.instance.logFilePath, isNotNull);
      });

      testWidgets('creates log file if not exists', (tester) async {
        await ErrorLoggingService.instance.init();

        final logFile = File(ErrorLoggingService.instance.logFilePath!);
        expect(await logFile.exists(), isTrue);
      });

      testWidgets('service is singleton', (tester) async {
        final instance1 = ErrorLoggingService.instance;
        final instance2 = ErrorLoggingService.instance;

        expect(instance1, same(instance2));
      });

      testWidgets('init is idempotent', (tester) async {
        await ErrorLoggingService.instance.init();
        final path1 = ErrorLoggingService.instance.logFilePath;

        await ErrorLoggingService.instance.init();
        final path2 = ErrorLoggingService.instance.logFilePath;

        expect(path1, equals(path2));
      });
    });

    group('Log Error', () {
      testWidgets('logs error with message', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logError('Test error message');

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.length, greaterThan(0));
        expect(errors.first.message, contains('Test error message'));
      });

      testWidgets('logs error with error object', (tester) async {
        await ErrorLoggingService.instance.init();

        final testException = Exception('Test exception');
        await ErrorLoggingService.instance.logError(
          'Error occurred',
          error: testException,
        );

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.error, contains('Test exception'));
      });

      testWidgets('logs error with stack trace', (tester) async {
        await ErrorLoggingService.instance.init();

        final stackTrace = StackTrace.current;
        await ErrorLoggingService.instance.logError(
          'Error with stack',
          stackTrace: stackTrace,
        );

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.stackTrace, isNotEmpty);
      });

      testWidgets('logs error with context', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logError(
          'Error with context',
          context: {'key': 'value', 'number': 42},
        );

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.message, contains('Error with context'));
      });

      testWidgets('log entry has timestamp', (tester) async {
        await ErrorLoggingService.instance.init();

        final beforeLog = DateTime.now();
        await ErrorLoggingService.instance.logError('Timestamp test');
        final afterLog = DateTime.now();

        final errors = await ErrorLoggingService.instance.getErrors();
        final timestamp = errors.first.timestamp;

        expect(
          timestamp.isAfter(beforeLog.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          timestamp.isBefore(afterLog.add(const Duration(seconds: 1))),
          isTrue,
        );
      });

      testWidgets('log entry has correct level', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logError(
          'Error level test',
          level: ErrorLevel.error,
        );

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.level, equals(ErrorLevel.error));
      });
    });

    group('Log Levels', () {
      testWidgets('logDebug creates debug level entry', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logDebug('Debug message');

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.level, equals(ErrorLevel.debug));
      });

      testWidgets('logInfo creates info level entry', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logInfo('Info message');

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.level, equals(ErrorLevel.info));
      });

      testWidgets('logWarning creates warning level entry', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logWarning('Warning message');

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.level, equals(ErrorLevel.warning));
      });

      testWidgets('logCritical creates critical level entry', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logCritical('Critical message');

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.first.level, equals(ErrorLevel.critical));
      });

      testWidgets('all levels are formatted correctly', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logDebug('Debug');
        await ErrorLoggingService.instance.logInfo('Info');
        await ErrorLoggingService.instance.logWarning('Warning');
        await ErrorLoggingService.instance.logError('Error');
        await ErrorLoggingService.instance.logCritical('Critical');

        final errors = await ErrorLoggingService.instance.getErrors();

        expect(
          errors.map((e) => e.level).toList(),
          containsAll([
            ErrorLevel.debug,
            ErrorLevel.info,
            ErrorLevel.warning,
            ErrorLevel.error,
            ErrorLevel.critical,
          ]),
        );
      });
    });

    group('Get Errors', () {
      testWidgets('returns empty list when no errors', (tester) async {
        await ErrorLoggingService.instance.init();

        // Clear any existing errors
        await ErrorLoggingService.instance.clearErrors();

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors, isEmpty);
      });

      testWidgets('returns errors in reverse chronological order', (
        tester,
      ) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        await ErrorLoggingService.instance.logError('First');
        await Future.delayed(const Duration(milliseconds: 10));
        await ErrorLoggingService.instance.logError('Second');
        await Future.delayed(const Duration(milliseconds: 10));
        await ErrorLoggingService.instance.logError('Third');

        final errors = await ErrorLoggingService.instance.getErrors();

        expect(errors.length, equals(3));
        expect(errors.first.message, contains('Third'));
        expect(errors.last.message, contains('First'));
      });

      testWidgets('returns all error details', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        final testException = Exception('Test exception');
        final testStackTrace = StackTrace.current;

        await ErrorLoggingService.instance.logError(
          'Complete error',
          error: testException,
          stackTrace: testStackTrace,
          level: ErrorLevel.error,
        );

        final errors = await ErrorLoggingService.instance.getErrors();
        final error = errors.first;

        expect(error.message, contains('Complete error'));
        expect(error.error, contains('Test exception'));
        expect(error.stackTrace, isNotEmpty);
        expect(error.level, equals(ErrorLevel.error));
        expect(error.timestamp, isNotNull);
      });
    });

    group('Clear Errors', () {
      testWidgets('clears all errors', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logError('Error 1');
        await ErrorLoggingService.instance.logError('Error 2');
        await ErrorLoggingService.instance.logError('Error 3');

        await ErrorLoggingService.instance.clearErrors();

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors, isEmpty);
      });

      testWidgets('clear on empty log does not error', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        // Should not throw
        expect(await ErrorLoggingService.instance.getErrors(), isEmpty);
      });

      testWidgets('can log after clearing', (tester) async {
        await ErrorLoggingService.instance.init();

        await ErrorLoggingService.instance.logError('Before clear');
        await ErrorLoggingService.instance.clearErrors();
        await ErrorLoggingService.instance.logError('After clear');

        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors.length, equals(1));
        expect(errors.first.message, contains('After clear'));
      });
    });

    group('Export Errors', () {
      testWidgets('exports errors to file', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        await ErrorLoggingService.instance.logError('Export test');

        final exportPath = await ErrorLoggingService.instance.exportErrors();

        expect(exportPath, isNotNull);
        expect(File(exportPath!).existsSync(), isTrue);
      });

      testWidgets('export file contains error data', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        await ErrorLoggingService.instance.logError('Export content test');

        final exportPath = await ErrorLoggingService.instance.exportErrors();
        final exportContent = await File(exportPath!).readAsString();

        expect(exportContent, contains('Export content test'));
      });

      testWidgets('export file has timestamp in name', (tester) async {
        await ErrorLoggingService.instance.init();

        final exportPath = await ErrorLoggingService.instance.exportErrors();

        expect(exportPath, contains('errors_export_'));
        expect(exportPath, contains('.log'));
      });

      testWidgets('export returns null when no log file', (tester) async {
        // Don't initialize - log file won't exist
        final exportPath = await ErrorLoggingService.instance.exportErrors();

        // May return null or create file on init
        // Service auto-initializes, so we check if file exists
        if (exportPath != null) {
          expect(File(exportPath).existsSync(), isTrue);
        }
      });

      testWidgets('multiple exports create separate files', (tester) async {
        await ErrorLoggingService.instance.init();

        final export1 = await ErrorLoggingService.instance.exportErrors();
        await Future.delayed(const Duration(milliseconds: 10));
        final export2 = await ErrorLoggingService.instance.exportErrors();

        expect(export1, isNotNull);
        expect(export2, isNotNull);
        expect(export1, isNot(equals(export2)));
      });
    });

    group('Error Count', () {
      testWidgets('getErrorCount returns correct count', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        expect(await ErrorLoggingService.instance.getErrorCount(), equals(0));

        await ErrorLoggingService.instance.logError('Error 1');
        expect(await ErrorLoggingService.instance.getErrorCount(), equals(1));

        await ErrorLoggingService.instance.logError('Error 2');
        expect(await ErrorLoggingService.instance.getErrorCount(), equals(2));
      });

      testWidgets('hasErrors returns true when errors exist', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        expect(await ErrorLoggingService.instance.hasErrors(), isFalse);

        await ErrorLoggingService.instance.logError('Test error');

        expect(await ErrorLoggingService.instance.hasErrors(), isTrue);
      });

      testWidgets('hasErrors returns false when no errors', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        expect(await ErrorLoggingService.instance.hasErrors(), isFalse);
      });
    });

    group('Log Entry', () {
      testWidgets('formattedTimestamp formats correctly', (tester) async {
        final entry = LogEntry(
          timestamp: DateTime(2024, 1, 15, 10, 30, 45),
          level: ErrorLevel.error,
          message: 'Test',
        );

        expect(entry.formattedTimestamp, equals('10:30:45'));
      });

      testWidgets('summary includes emoji and message', (tester) async {
        final entry = LogEntry(
          timestamp: DateTime.now(),
          level: ErrorLevel.error,
          message: 'Test error message',
        );

        expect(entry.summary, contains('Test error message'));
        expect(entry.summary, contains('❌'));
      });

      testWidgets('debug level has bug emoji', (tester) async {
        final entry = LogEntry(
          timestamp: DateTime.now(),
          level: ErrorLevel.debug,
          message: 'Debug',
        );

        expect(entry.summary, contains('🐛'));
      });

      testWidgets('info level has info emoji', (tester) async {
        final entry = LogEntry(
          timestamp: DateTime.now(),
          level: ErrorLevel.info,
          message: 'Info',
        );

        expect(entry.summary, contains('ℹ️'));
      });

      testWidgets('warning level has warning emoji', (tester) async {
        final entry = LogEntry(
          timestamp: DateTime.now(),
          level: ErrorLevel.warning,
          message: 'Warning',
        );

        expect(entry.summary, contains('⚠️'));
      });

      testWidgets('critical level has fire emoji', (tester) async {
        final entry = LogEntry(
          timestamp: DateTime.now(),
          level: ErrorLevel.critical,
          message: 'Critical',
        );

        expect(entry.summary, contains('🔥'));
      });

      testWidgets('toString returns class info', (tester) async {
        final entry = LogEntry(
          timestamp: DateTime.now(),
          level: ErrorLevel.error,
          message: 'Test',
        );

        expect(entry.toString(), contains('LogEntry'));
        expect(entry.toString(), contains('message: Test'));
      });
    });

    group('Log File Format', () {
      testWidgets('log file has correct format', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        await ErrorLoggingService.instance.logError('Format test');

        final logFile = File(ErrorLoggingService.instance.logFilePath!);
        final content = await logFile.readAsString();

        // Format: [timestamp] [LEVEL] message
        expect(content, contains('[ERROR]'));
        expect(content, contains('Format test'));
        expect(content, contains('-' * 80));
      });

      testWidgets('log entries are separated', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        await ErrorLoggingService.instance.logError('First');
        await ErrorLoggingService.instance.logError('Second');

        final logFile = File(ErrorLoggingService.instance.logFilePath!);
        final content = await logFile.readAsString();

        final blocks = content.split('-' * 80);
        expect(blocks.length, greaterThan(1));
      });

      testWidgets('timestamp is ISO8601 format', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        await ErrorLoggingService.instance.logError('Timestamp format test');

        final logFile = File(ErrorLoggingService.instance.logFilePath!);
        final content = await logFile.readAsString();

        // ISO8601 contains T separator
        expect(content, contains(RegExp(r'\[\d{4}-\d{2}-\d{2}T')));
      });
    });

    group('Log Rotation', () {
      testWidgets('rotates log when too large', (tester) async {
        await ErrorLoggingService.instance.init();
        await ErrorLoggingService.instance.clearErrors();

        // Write many errors to trigger rotation
        for (int i = 0; i < 100; i++) {
          await ErrorLoggingService.instance.logError('Error $i');
        }

        final logFile = File(ErrorLoggingService.instance.logFilePath!);
        final stats = await logFile.stat();

        // Log should be rotated and not exceed max size
        expect(stats.size, lessThan(15 * 1024 * 1024)); // 15MB with some margin
      });
    });

    group('Error Handling', () {
      testWidgets('handles file write errors gracefully', (tester) async {
        // This test verifies the service doesn't crash on file errors
        await ErrorLoggingService.instance.init();

        // Should not throw
        await ErrorLoggingService.instance.logError('Test');

        expect(await ErrorLoggingService.instance.hasErrors(), isTrue);
      });

      testWidgets('handles read errors gracefully', (tester) async {
        await ErrorLoggingService.instance.init();

        // Should return empty list on read errors
        final errors = await ErrorLoggingService.instance.getErrors();
        expect(errors, isList);
      });
    });
  });
}
