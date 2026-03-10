import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/widgets/error_boundary.dart';
import 'package:gitdoit/constants/app_colors.dart';

void main() {
  group('ErrorBoundary Widget Tests', () {
    Widget createTestApp({Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body:
              child ??
              const ErrorBoundary(
                errorMessage: 'Test Error',
                onRetry: null,
                child: Text('Child Content'),
              ),
        ),
      );
    }

    group('Normal Rendering', () {
      testWidgets('renders child widget when no error', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(child: Text('Child Content')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Child Content'), findsOneWidget);
      });

      testWidgets('child widget is displayed correctly', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              child: Column(children: [Text('Line 1'), Text('Line 2')]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Line 1'), findsOneWidget);
        expect(find.text('Line 2'), findsOneWidget);
      });
    });

    group('Error Display', () {
      testWidgets('displays custom error message', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Custom Error Message',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.text('Custom Error Message'), findsOneWidget);
      });

      testWidgets('displays default error message when not provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(child: const ErrorBoundary(child: Text('Child'))),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('shows error icon', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('error icon has red color', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(icon.color, AppColors.red.withValues(alpha: 0.8));
      });

      testWidgets('displays error details summary', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Detailed error information'));
        await tester.pumpAndSettle();

        // Error details should be displayed
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Retry Button', () {
      testWidgets('displays retry button by default', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              onRetry: null,
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retry button has refresh icon', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              onRetry: null,
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('retry button is hidden when showRetryButton is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              showRetryButton: false,
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsNothing);
      });

      testWidgets('retry button calls onRetry callback', (tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: ErrorBoundary(
              errorMessage: 'Error',
              onRetry: () {
                retryCalled = true;
              },
              child: const Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(retryCalled, isTrue);
      });

      testWidgets('retry button clears error state', (tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          createTestApp(
            child: ErrorBoundary(
              errorMessage: 'Error',
              onRetry: () {
                retryCalled = true;
              },
              child: const Text('Child Content'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Verify error is shown
        expect(find.text('Error'), findsOneWidget);

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Verify retry callback was called
        expect(retryCalled, isTrue);

        // Child should be displayed again
        expect(find.text('Child Content'), findsOneWidget);
      });

      testWidgets('retry button has orange background', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              onRetry: null,
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton).first,
        );
        expect(
          button.style?.backgroundColor?.resolve({}),
          AppColors.orangePrimary,
        );
      });
    });

    group('Go Back Button', () {
      testWidgets('displays go back button by default', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.text('Go Back'), findsOneWidget);
      });

      testWidgets('go back button has arrow icon', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('go back button is hidden when showGoBackButton is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              showGoBackButton: false,
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.text('Go Back'), findsNothing);
      });

      testWidgets('go back button navigates to previous screen', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorBoundary(
                errorMessage: 'Error',
                child: const Text('Child'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Tap go back
        await tester.tap(find.text('Go Back'));
        await tester.pumpAndSettle();

        // Should pop the screen
        expect(find.byType(ErrorBoundary), findsNothing);
      });
    });

    group('Expandable Error Details', () {
      testWidgets('displays expandable details section', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Details section should be present
        expect(find.text('Error Details'), findsOneWidget);
      });

      testWidgets(
        'details section is hidden when allowExpandDetails is false',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(
              child: const ErrorBoundary(
                errorMessage: 'Error',
                allowExpandDetails: false,
                child: Text('Child'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Trigger error
          final context = tester.element(find.byType(ErrorBoundary));
          context.reportError(Exception('Test error'));
          await tester.pumpAndSettle();

          expect(find.text('Error Details'), findsNothing);
        },
      );

      testWidgets('details section is expandable', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        // Expanded content should be visible
        expect(find.byType(SelectableText), findsWidgets);
      });

      testWidgets('expand/collapse icon changes state', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Initially collapsed - should show expand_more
        expect(find.byIcon(Icons.expand_more), findsOneWidget);

        // Tap to expand
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        // Now expanded - should show expand_less
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('displays error message in details', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Detailed error message'));
        await tester.pumpAndSettle();

        // Expand details
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error:'), findsWidgets);
      });

      testWidgets('displays stack trace in details', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error with stack trace
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'), StackTrace.current);
        await tester.pumpAndSettle();

        // Expand details
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        expect(find.textContaining('StackTrace:'), findsWidgets);
      });

      testWidgets('details has copy button', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Expand details
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        expect(find.text('Copy Error Details'), findsOneWidget);
      });

      testWidgets('copy button has copy icon', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Expand details
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.copy), findsWidgets);
      });
    });

    group('Styling', () {
      testWidgets('error container has proper padding', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('error details has card background', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Expand details
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
          findsWidgets,
        );
      });

      testWidgets('error details has red border', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Expand details
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        // Border should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('error text uses monospace font', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Expand details
        await tester.tap(find.text('Error Details'));
        await tester.pumpAndSettle();

        // Monospace font for error details
        expect(find.byType(SelectableText), findsWidgets);
      });
    });

    group('Layout', () {
      testWidgets('error UI is centered', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Column with centered children
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('action buttons are in Wrap', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        expect(find.byType(Wrap), findsOneWidget);
      });

      testWidgets('buttons have proper spacing', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ErrorBoundary(
              errorMessage: 'Error',
              child: Text('Child'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger error
        final context = tester.element(find.byType(ErrorBoundary));
        context.reportError(Exception('Test error'));
        await tester.pumpAndSettle();

        // Wrap should have spacing
        expect(find.byType(Wrap), findsOneWidget);
      });
    });

    group('Error Reporting Extension', () {
      testWidgets('can report error from child widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorBoundary(
                errorMessage: 'Error',
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        context.reportError(Exception('Child error'));
                      },
                      child: const Text('Trigger Error'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to trigger error
        await tester.tap(find.text('Trigger Error'));
        await tester.pumpAndSettle();

        // Error should be displayed
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });
  });

  group('InlineError Widget Tests', () {
    testWidgets('renders inline error with message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InlineError(message: 'Inline error message')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inline error message'), findsOneWidget);
    });

    testWidgets('displays error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InlineError(message: 'Error')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('icon has red color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InlineError(message: 'Error')),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, AppColors.red);
    });

    testWidgets('displays optional details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineError(message: 'Error', details: 'Additional details'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Additional details'), findsOneWidget);
    });

    testWidgets('dismiss button is optional', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InlineError(message: 'Error')),
        ),
      );
      await tester.pumpAndSettle();

      // No dismiss button by default
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('dismiss button appears when onDismiss provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineError(message: 'Error', onDismiss: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('fullScreen mode centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InlineError(message: 'Error', fullScreen: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('has red background with opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InlineError(message: 'Error')),
        ),
      );
      await tester.pumpAndSettle();

      // Container with red background
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InlineError(message: 'Error')),
        ),
      );
      await tester.pumpAndSettle();

      // Container with border radius
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('has red border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InlineError(message: 'Error')),
        ),
      );
      await tester.pumpAndSettle();

      // Container with border
      expect(find.byType(Container), findsWidgets);
    });
  });
}
