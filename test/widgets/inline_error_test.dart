import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/widgets/inline_error.dart';

void main() {
  testWidgets('shows message, details, and dismiss action', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InlineError(
            message: 'Failed',
            details: 'Try again',
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss error'));
    expect(dismissed, isTrue);
  });

  testWidgets('supports full-screen presentation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: InlineError(message: 'Fatal', fullScreen: true)),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Fatal'), findsOneWidget);
  });
}
