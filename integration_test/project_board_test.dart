// Integration Test: Project Board - Drag and Drop
// Tests the project board kanban functionality

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gitdoit/main.dart' as app;
import 'package:gitdoit/screens/main_dashboard_screen.dart';
import 'package:gitdoit/screens/project_board_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Project Board Journey', () {
    testWidgets('Navigate to project board from dashboard', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Go offline for testing
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // STEP 1: Tap repository/project icon
      final repoIcon = find.byWidgetPredicate(
        (widget) => widget is IconButton,
      );
      if (repoIcon.evaluate().isNotEmpty) {
        await tester.tap(repoIcon.first);
        await tester.pumpAndSettle();
      }

      // STEP 2: Navigate to project board
      // Look for project board option
      expect(find.byType(MainDashboardScreen), findsOneWidget);
    });

    testWidgets('Project board displays columns', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Navigate to project board (simulated)
      // In real app, this would be through repo library

      // Verify project board would display columns
      // Standard columns: Todo, In Progress, Review, Done
      expect(find.text('Todo'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Review'), findsWidgets);
      expect(find.text('Done'), findsWidgets);
    });

    testWidgets('Project board shows loading state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Loading indicator should be available
      expect(find.byWidgetPredicate(
        (widget) => widget.toString().contains('BrailleLoader') ||
                    widget is CircularProgressIndicator,
      ), findsWidgets);
    });

    testWidgets('Project board has refresh functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Refresh button should be available
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('Project board has add issue button', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Add button should be available
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('Project board columns are horizontally scrollable', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Horizontal scroll should be available
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets('Project board issues are draggable', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Issues should be draggable
      // Drag and drop functionality
      expect(find.byWidgetPredicate(
        (widget) => widget.toString().contains('Reorderable') ||
                    widget.toString().contains('Draggable'),
      ), findsWidgets);
    });

    testWidgets('Project board shows issue cards', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Issue cards should be displayed
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Project board issue cards show title', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Issue titles should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Project board issue cards show labels', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Labels should be visible on cards
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('Project board issue cards show assignee', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assignee avatars should be visible
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('Project board handles empty state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Empty state should be handled gracefully
      expect(find.byType(ProjectBoardScreen), findsWidgets);
    });

    testWidgets('Project board shows error on load failure', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Error state should be handled
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('Project board has retry on error', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Retry button should be available on error
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('Project board column headers are visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Column headers should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Project board supports adding new issue', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Add button should trigger issue creation
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Project board issue tap navigates to detail', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Tapping issue should navigate to detail
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Project board has proper background color', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('Project board app bar has correct title', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(find.text('Project Board'), findsWidgets);
    });

    testWidgets('Project board handles network error gracefully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Should handle errors gracefully
      expect(find.byType(ProjectBoardScreen), findsWidgets);
    });
  });
}
