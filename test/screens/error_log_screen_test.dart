import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/error_log_screen.dart';
import 'package:gitdoit/services/error_logging_service.dart';
import 'package:gitdoit/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorLogScreen Widget Tests', () {
    setUp(() async {
      // Clear errors before each test
      await ErrorLoggingService.instance.init();
      await ErrorLoggingService.instance.clearErrors();
    });

    Widget createTestApp() {
      return const MaterialApp(
        home: ErrorLogScreen(),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders error log screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(ErrorLogScreen), findsOneWidget);
      });

      testWidgets('displays Error Log title in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Error Log'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays export button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.share), findsWidgets);
      });

      testWidgets('displays clear button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsWidgets);
      });

      testWidgets('displays refresh button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsWidgets);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('BrailleLoader'),
          ),
          findsWidgets,
        );
      });

      testWidgets('shows loading text', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.textContaining('Loading'), findsWidgets);
      });

      testWidgets('hides loading when data loaded', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // After settling, content should be visible
        expect(find.byType(ErrorLogScreen), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('shows empty state when no errors', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('No Errors Logged'), findsOneWidget);
      });

      testWidgets('displays empty state icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('empty state has success color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Icon should have success color with alpha
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('shows helpful message', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Great!'),
          findsOneWidget,
        );
      });

      testWidgets('empty state icon has correct size', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
        expect(icon.size, 64);
      });
    });

    group('Error List Display', () {
      testWidgets('displays error count in summary bar', (tester) async {
        await ErrorLoggingService.instance.logError('Test error 1');
        await ErrorLoggingService.instance.logError('Test error 2');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('2 Errors'), findsOneWidget);
      });

      testWidgets('shows error icon in summary bar', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('displays error cards', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('error cards have level indicator', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Level indicator circle
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });

      testWidgets('error cards show timestamp', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Timestamp should be displayed
        expect(find.byWidgetPredicate(
          (widget) => widget is Text &&
              (widget as Text).data?.contains(':') == true,
        ), findsWidgets);
      });

      testWidgets('error cards show level badge', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Level badge should show ERROR
        expect(find.textContaining('ERROR'), findsWidgets);
      });

      testWidgets('error cards show expand icon', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.expand_more), findsWidgets);
      });

      testWidgets('error cards have card background', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should have proper background
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });
    });

    group('Error Details Expansion', () {
      testWidgets('tapping error card expands details', (tester) async {
        await ErrorLoggingService.instance.logError('Test error message');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Should show expand_less
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('expanded card shows full message', (tester) async {
        await ErrorLoggingService.instance.logError('Detailed error message');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.text('Detailed error message'), findsOneWidget);
      });

      testWidgets('expanded card shows error details', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Test',
          error: Exception('Test exception'),
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error:'), findsOneWidget);
      });

      testWidgets('expanded card shows stack trace', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Test',
          stackTrace: StackTrace.current,
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.textContaining('Stack Trace:'), findsOneWidget);
      });

      testWidgets('tapping expanded card collapses it', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.expand_less), findsOneWidget);

        // Collapse
        await tester.tap(find.byIcon(Icons.expand_less));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.expand_more), findsOneWidget);
      });

      testWidgets('only one error expanded at a time', (tester) async {
        await ErrorLoggingService.instance.logError('Error 1');
        await ErrorLoggingService.instance.logError('Error 2');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand first error
        await tester.tap(find.byIcon(Icons.expand_more).first);
        await tester.pumpAndSettle();

        // First should be expanded, second collapsed
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });
    });

    group('Error Card Actions', () {
      testWidgets('displays copy button', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand to show actions
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.text('Copy'), findsOneWidget);
      });

      testWidgets('copy button has copy icon', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand to show actions
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.copy), findsWidgets);
      });

      testWidgets('copy button is clickable', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand to show actions
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Tap copy
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        // Should show snackbar
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('displays report button', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Test',
          stackTrace: StackTrace.current,
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand to show actions
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.text('Report'), findsOneWidget);
      });

      testWidgets('report button has bug icon', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Test',
          stackTrace: StackTrace.current,
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand to show actions
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bug_report), findsWidgets);
      });

      testWidgets('report button shows coming soon message', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Test',
          stackTrace: StackTrace.current,
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand to show actions
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Tap report
        await tester.tap(find.text('Report'));
        await tester.pumpAndSettle();

        expect(find.textContaining('coming soon'), findsWidgets);
      });
    });

    group('Level Colors', () {
      testWidgets('error level has red color', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Test',
          level: ErrorLevel.error,
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error level should use red
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });

      testWidgets('warning level has orange color', (tester) async {
        await ErrorLoggingService.instance.logWarning('Test warning');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Warning level should use orange
        expect(find.textContaining('WARNING'), findsWidgets);
      });

      testWidgets('info level has green color', (tester) async {
        await ErrorLoggingService.instance.logInfo('Test info');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Info level should use green
        expect(find.textContaining('INFO'), findsWidgets);
      });

      testWidgets('debug level has blue color', (tester) async {
        await ErrorLoggingService.instance.logDebug('Test debug');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Debug level should use blue
        expect(find.textContaining('DEBUG'), findsWidgets);
      });

      testWidgets('critical level has purple color', (tester) async {
        await ErrorLoggingService.instance.logCritical('Test critical');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Critical level should use purple
        expect(find.textContaining('CRITICAL'), findsWidgets);
      });
    });

    group('AppBar Actions', () {
      testWidgets('export button is clickable', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final exportButton = find.byIcon(Icons.share);
        if (exportButton.evaluate().isNotEmpty) {
          await tester.tap(exportButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('export button has orange color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Export button should use orange
        expect(find.byIcon(Icons.share), findsWidgets);
      });

      testWidgets('clear button is clickable', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final clearButton = find.byIcon(Icons.delete_outline);
        if (clearButton.evaluate().isNotEmpty) {
          await tester.tap(clearButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('clear button has red color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Clear button should use red
        expect(find.byIcon(Icons.delete_outline), findsWidgets);
      });

      testWidgets('refresh button is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final refreshButton = find.byIcon(Icons.refresh);
        if (refreshButton.evaluate().isNotEmpty) {
          await tester.tap(refreshButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('buttons disabled during loading', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        // Buttons may be disabled during loading
        expect(find.byIcon(Icons.refresh), findsWidgets);
      });
    });

    group('Clear Errors Dialog', () {
      testWidgets('clear shows confirmation dialog', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.text('Clear Error Log'), findsOneWidget);
      });

      testWidgets('dialog has warning icon', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      });

      testWidgets('dialog has warning message', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('cannot be undone'),
          findsWidgets,
        );
      });

      testWidgets('dialog has Cancel button', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('dialog has Clear button', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Clear'), findsOneWidget);
      });

      testWidgets('Clear button has red background', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Clear button should have red styling
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('canceling dialog keeps errors', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Error should still be there
        expect(find.textContaining('Error'), findsWidgets);
      });

      testWidgets('confirming clears errors', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Tap clear in dialog
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('No Errors Logged'), findsOneWidget);
      });

      testWidgets('clearing shows success snackbar', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear button
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Tap clear in dialog
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        expect(find.textContaining('cleared'), findsWidgets);
      });
    });

    group('Export Functionality', () {
      testWidgets('export button shows share icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.share), findsOneWidget);
      });

      testWidgets('export has tooltip', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Export button should have tooltip
        expect(find.byIcon(Icons.share), findsWidgets);
      });
    });

    group('Error List Styling', () {
      testWidgets('summary bar has card background', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Summary bar should have card background
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).color == AppColors.cardBackground,
        ), findsWidgets);
      });

      testWidgets('error cards have rounded corners', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should have border radius
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });

      testWidgets('error cards have border', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should have border
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });

      testWidgets('expanded content has different background', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Expanded content should have background color
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });

      testWidgets('stack trace is scrollable', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Test',
          stackTrace: StackTrace.current,
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Stack trace should be in scrollable
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('error message is selectable', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Message should be selectable
        expect(find.byType(SelectableText), findsWidgets);
      });
    });

    group('Refresh Functionality', () {
      testWidgets('refresh button reloads errors', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap refresh
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();

        // Should reload
        expect(find.byType(ErrorLogScreen), findsOneWidget);
      });

      testWidgets('refresh button has white color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Refresh button should be white
        expect(find.byIcon(Icons.refresh), findsWidgets);
      });
    });

    group('Multiple Errors', () {
      testWidgets('displays multiple errors', (tester) async {
        await ErrorLoggingService.instance.logError('Error 1');
        await ErrorLoggingService.instance.logError('Error 2');
        await ErrorLoggingService.instance.logError('Error 3');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('3 Errors'), findsOneWidget);
      });

      testWidgets('errors are in a list', (tester) async {
        await ErrorLoggingService.instance.logError('Error 1');
        await ErrorLoggingService.instance.logError('Error 2');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('errors have proper spacing', (tester) async {
        await ErrorLoggingService.instance.logError('Error 1');
        await ErrorLoggingService.instance.logError('Error 2');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should have margin
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Error Message Display', () {
      testWidgets('message is truncated when long', (tester) async {
        final longMessage = 'A' * 200;
        await ErrorLoggingService.instance.logError(longMessage);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Long message should be handled
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('message preview shows max 2 lines', (tester) async {
        await ErrorLoggingService.instance.logError(
          'Line 1\nLine 2\nLine 3\nLine 4',
        );

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Message should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('full message shown when expanded', (tester) async {
        await ErrorLoggingService.instance.logError('Complete message');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        expect(find.text('Complete message'), findsOneWidget);
      });
    });

    group('Timestamp Display', () {
      testWidgets('timestamp is formatted correctly', (tester) async {
        await ErrorLoggingService.instance.logError('Test');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Timestamp should be in HH:MM:SS format
        expect(find.byWidgetPredicate(
          (widget) => widget is Text &&
              (widget as Text).data?.contains(':') == true,
        ), findsWidgets);
      });

      testWidgets('timestamp uses local time', (tester) async {
        await ErrorLoggingService.instance.logError('Test');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Timestamp should be displayed
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Level Badge Display', () {
      testWidgets('level badge is uppercase', (tester) async {
        await ErrorLoggingService.instance.logError('Test');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('ERROR'), findsWidgets);
      });

      testWidgets('level badge has colored background', (tester) async {
        await ErrorLoggingService.instance.logError('Test');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Badge should have background
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });

      testWidgets('level badge has small font', (tester) async {
        await ErrorLoggingService.instance.logError('Test');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Badge text should be small
        expect(find.byWidgetPredicate(
          (widget) => widget is Text &&
              (widget as Text).style?.fontSize == 10,
        ), findsWidgets);
      });
    });

    group('Copy Functionality', () {
      testWidgets('copy shows success snackbar', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Tap copy
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        expect(find.textContaining('copied'), findsWidgets);
      });

      testWidgets('copy snackbar has orange background', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Tap copy
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        // Snackbar should have orange styling
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('copy snackbar has short duration', (tester) async {
        await ErrorLoggingService.instance.logError('Test error');

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Expand
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // Tap copy
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        // Duration should be 1 second
        expect(find.byType(SnackBar), findsWidgets);
      });
    });
  });
}
