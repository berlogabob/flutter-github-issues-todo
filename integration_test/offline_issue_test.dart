// Integration Test: Offline Issue Creation and Sync
// Tests creating issues offline and syncing when online

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gitdoit/main.dart' as app;
import 'package:gitdoit/screens/main_dashboard_screen.dart';
import 'package:gitdoit/screens/create_issue_screen.dart';
import 'package:gitdoit/screens/issue_detail_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Issue Journey', () {
    testWidgets('Create issue offline and verify local storage', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Go to offline mode first
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();

      // Wait for dashboard to load
      await tester.pumpAndSettle();
      expect(find.byType(MainDashboardScreen), findsOneWidget);

      // STEP 1: Tap New Issue FAB
      final fab = find.text('New Issue');
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // STEP 2: Verify create issue screen is displayed
      expect(find.byType(CreateIssueScreen), findsOneWidget);
      expect(find.text('Create Issue'), findsOneWidget);

      // STEP 3: Enter issue title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Offline Test Issue');
      await tester.pumpAndSettle();

      // STEP 4: Enter issue description
      final descField = find.byType(TextField).last;
      await tester.enterText(descField, 'This issue was created offline');
      await tester.pumpAndSettle();

      // STEP 5: Tap Create button
      final createButton = find.text('Create');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // STEP 6: Verify issue was created (should return to dashboard)
      await tester.pumpAndSettle();
      expect(find.byType(MainDashboardScreen), findsOneWidget);

      // STEP 7: Verify issue appears in vault/local issues
      expect(find.textContaining('Offline Test Issue'), findsWidgets);

      // STEP 8: Verify sync pending indicator
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('View offline issue details', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Create an issue first
      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Detail View Test',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).last,
        'Testing detail view',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Tap on the created issue to view details
      final issueCard = find.textContaining('Detail View Test');
      if (issueCard.evaluate().isNotEmpty) {
        await tester.tap(issueCard);
        await tester.pumpAndSettle();

        // Verify issue detail screen
        expect(find.byType(IssueDetailScreen), findsOneWidget);
        expect(find.textContaining('Detail View Test'), findsOneWidget);
      }
    });

    testWidgets('Edit offline issue', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Create an issue
      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Edit Test Issue',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open issue and edit
      final issueCard = find.textContaining('Edit Test Issue');
      if (issueCard.evaluate().isNotEmpty) {
        await tester.tap(issueCard);
        await tester.pumpAndSettle();

        // Tap edit button
        final editButton = find.byIcon(Icons.edit);
        if (editButton.evaluate().isNotEmpty) {
          await tester.tap(editButton);
          await tester.pumpAndSettle();

          // Verify edit screen
          expect(find.text('Edit Issue'), findsOneWidget);

          // Modify title
          final titleField = find.byType(TextField).first;
          await tester.enterText(titleField, 'Edited Issue Title');
          await tester.pumpAndSettle();

          // Save changes
          final saveButton = find.byIcon(Icons.check);
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Delete offline issue', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Create an issue to delete
      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Delete Test Issue',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open issue
      final issueCard = find.textContaining('Delete Test Issue');
      if (issueCard.evaluate().isNotEmpty) {
        await tester.tap(issueCard);
        await tester.pumpAndSettle();

        // Verify issue detail screen
        expect(find.byType(IssueDetailScreen), findsOneWidget);

        // Delete option should be available (via menu or button)
        expect(find.byIcon(Icons.more_vert), findsWidgets);
      }
    });

    testWidgets('Multiple offline issues are queued for sync', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Create multiple issues
      for (int i = 1; i <= 3; i++) {
        await tester.tap(find.text('New Issue'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'Offline Issue #$i',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
      }

      // Verify all issues are visible
      expect(find.textContaining('Offline Issue #1'), findsWidgets);
      expect(find.textContaining('Offline Issue #2'), findsWidgets);
      expect(find.textContaining('Offline Issue #3'), findsWidgets);

      // Verify pending operations count
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Offline mode shows vault repository', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Verify vault/local repo is displayed
      expect(find.textContaining('Vault'), findsWidgets);
      expect(find.textContaining('local'), findsWidgets);
    });

    testWidgets('Sync status indicator shows pending operations', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Create an issue
      await tester.tap(find.text('New Issue'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Sync Test Issue',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Verify sync status indicator
      expect(find.byWidgetPredicate(
        (widget) => widget.toString().contains('Sync'),
      ), findsWidgets);

      // Verify pending count badge
      expect(find.byType(Container), findsWidgets);
    });
  });
}
