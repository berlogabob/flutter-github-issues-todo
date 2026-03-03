// Integration Test: Complete Issue Creation Flow
// Tests the full issue creation journey from start to finish

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gitdoit/main.dart' as app;
import 'package:gitdoit/screens/main_dashboard_screen.dart';
import 'package:gitdoit/screens/create_issue_screen.dart';
import 'package:gitdoit/screens/issue_detail_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Create Issue Full Journey', () {
    testWidgets('Complete issue creation with all fields', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Go offline for testing
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // STEP 1: Tap New Issue FAB
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      // STEP 2: Verify create issue screen
      expect(find.byType(CreateIssueScreen), findsOneWidget);
      expect(find.text('Create Issue'), findsOneWidget);

      // STEP 3: Enter title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Complete Test Issue');
      await tester.pumpAndSettle();

      // STEP 4: Enter description with Markdown
      final descField = find.byType(TextField).last;
      await tester.enterText(
        descField,
        '## Description\n\nThis is a **test** issue with _Markdown_.',
      );
      await tester.pumpAndSettle();

      // STEP 5: Add labels
      final addLabelButton = find.byIcon(Icons.add);
      if (addLabelButton.evaluate().isNotEmpty) {
        await tester.tap(addLabelButton);
        await tester.pumpAndSettle();
      }

      // STEP 6: Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // STEP 7: Verify issue created
      await tester.pumpAndSettle();
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.textContaining('Complete Test Issue'), findsWidgets);
    });

    testWidgets('Issue creation validates required fields', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Tap New Issue
      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      // Try to create without title
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.byType(SnackBar), findsWidgets);

      // Now enter title
      await tester.enterText(
        find.byType(TextField).first,
        'Valid Title',
      );
      await tester.pumpAndSettle();

      // Create should work now
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
    });

    testWidgets('Issue creation with labels', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.byType(TextField).first,
        'Issue with Labels',
      );
      await tester.pumpAndSettle();

      // Add labels
      final addLabelButton = find.byIcon(Icons.add);
      if (addLabelButton.evaluate().isNotEmpty) {
        await tester.tap(addLabelButton);
        await tester.pumpAndSettle();

        // Select a label from the dialog
        expect(find.byType(Dialog), findsWidgets);
      }

      // Create issue
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
    });

    testWidgets('Issue creation with assignee', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.byType(TextField).first,
        'Issue with Assignee',
      );
      await tester.pumpAndSettle();

      // Select assignee
      final assigneeTile = find.text('Assignee');
      if (assigneeTile.evaluate().isNotEmpty) {
        await tester.tap(assigneeTile);
        await tester.pumpAndSettle();
      }

      // Create issue
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
    });

    testWidgets('Cancel issue creation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      // Enter some data
      await tester.enterText(
        find.byType(TextField).first,
        'Cancelled Issue',
      );
      await tester.pumpAndSettle();

      // Tap close button
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      // Should return to dashboard without creating issue
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.textContaining('Cancelled Issue'), findsNothing);
    });

    testWidgets('Issue creation shows loading state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Loading Test Issue',
      );
      await tester.pumpAndSettle();

      // Tap create and check for loading
      await tester.tap(find.text('Create'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byWidgetPredicate(
        (widget) => widget.toString().contains('BrailleLoader') ||
                    widget is CircularProgressIndicator,
      ), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('Issue creation with long title', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      // Enter very long title
      final longTitle = 'A' * 200;
      await tester.enterText(
        find.byType(TextField).first,
        longTitle,
      );
      await tester.pumpAndSettle();

      // Should accept long title
      expect(find.text(longTitle), findsOneWidget);

      // Create issue
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
    });

    testWidgets('Issue creation with multiline description', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Multiline Description Issue',
      );
      await tester.pumpAndSettle();

      // Enter multiline description
      final multilineDesc = '''
# Heading

## Subheading

This is a paragraph with **bold** and _italic_ text.

- List item 1
- List item 2
- List item 3

```dart
code block
```
''';
      await tester.enterText(
        find.byType(TextField).last,
        multilineDesc,
      );
      await tester.pumpAndSettle();

      // Create issue
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
    });

    testWidgets('Issue creation success message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Success Message Test',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Navigate to issue detail after creation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Navigate Test Issue',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Tap on created issue
      final issueCard = find.textContaining('Navigate Test Issue');
      if (issueCard.evaluate().isNotEmpty) {
        await tester.tap(issueCard);
        await tester.pumpAndSettle();

        // Should navigate to detail screen
        expect(find.byType(IssueDetailScreen), findsOneWidget);
      }
    });
  });
}
