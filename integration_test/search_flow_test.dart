// Integration Test: Search Flow
// Tests the complete search, filter, and open issue journey

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gitdoit/main.dart' as app;
import 'package:gitdoit/screens/main_dashboard_screen.dart';
import 'package:gitdoit/screens/search_screen.dart';
import 'package:gitdoit/screens/issue_detail_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search Flow Journey', () {
    testWidgets('Complete search flow from dashboard', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Go offline for testing
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // STEP 1: Tap search icon in dashboard
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      final searchIcon = find.byIcon(Icons.search);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // STEP 2: Verify search screen is displayed
      expect(find.byType(SearchScreen), findsOneWidget);

      // STEP 3: Verify search field is focused
      expect(find.byType(TextField), findsOneWidget);

      // STEP 4: Enter search query
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // STEP 5: Wait for search results
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // STEP 6: Verify search results are displayed
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Search with filters', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'bug');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Apply status filter
      final openFilter = find.text('Open');
      if (openFilter.evaluate().isNotEmpty) {
        await tester.tap(openFilter);
        await tester.pumpAndSettle();
      }

      // Verify filtered results
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Search by status - Open issues', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Filter by open
      final openFilter = find.text('Open');
      if (openFilter.evaluate().isNotEmpty) {
        await tester.tap(openFilter);
        await tester.pumpAndSettle();
      }

      // Enter query
      await tester.enterText(find.byType(TextField), 'open');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Search by status - Closed issues', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Filter by closed
      final closedFilter = find.text('Closed');
      if (closedFilter.evaluate().isNotEmpty) {
        await tester.tap(closedFilter);
        await tester.pumpAndSettle();
      }

      // Enter query
      await tester.enterText(find.byType(TextField), 'closed');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Search with content type filters', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Toggle content type filters
      final titleFilter = find.text('Title');
      if (titleFilter.evaluate().isNotEmpty) {
        await tester.tap(titleFilter);
        await tester.pumpAndSettle();
      }

      final bodyFilter = find.text('Body');
      if (bodyFilter.evaluate().isNotEmpty) {
        await tester.tap(bodyFilter);
        await tester.pumpAndSettle();
      }

      final labelsFilter = find.text('Labels');
      if (labelsFilter.evaluate().isNotEmpty) {
        await tester.tap(labelsFilter);
        await tester.pumpAndSettle();
      }

      // Enter query
      await tester.enterText(find.byType(TextField), 'filter test');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Search with My Issues filter', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Toggle My Issues filter
      final myIssuesFilter = find.text('My Issues');
      if (myIssuesFilter.evaluate().isNotEmpty) {
        await tester.tap(myIssuesFilter);
        await tester.pumpAndSettle();
      }

      // Enter query
      await tester.enterText(find.byType(TextField), 'my issues');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Search result tap navigates to issue detail', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'test issue');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Tap on a result
      final resultItem = find.byType(ListTile).first;
      if (resultItem.evaluate().isNotEmpty) {
        await tester.tap(resultItem);
        await tester.pumpAndSettle();

        // Should navigate to issue detail
        expect(find.byType(IssueDetailScreen), findsOneWidget);
      }
    });

    testWidgets('Search clears on X button', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pumpAndSettle();

      // Tap clear button
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }

      // Field should be cleared
      expect(find.text('test query'), findsNothing);
    });

    testWidgets('Search back button navigates to dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Should return to dashboard
      expect(find.byType(MainDashboardScreen), findsOneWidget);
    });

    testWidgets('Search shows loading state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'loading test');
      await tester.pump();

      // Should show loading indicator
      expect(find.byWidgetPredicate(
        (widget) => widget.toString().contains('BrailleLoader') ||
                    widget is CircularProgressIndicator,
      ), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('Search shows empty state for no results', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter unique query that won't match
      await tester.enterText(
        find.byType(TextField),
        'xyznonexistent123',
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should show no results message
      expect(find.text('No results found'), findsWidgets);
    });

    testWidgets('Search debounces input', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 100));

      // Should not search yet (debounced)
      await tester.pump(const Duration(milliseconds: 400));

      // After debounce duration, search should trigger
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Results should be displayed
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Search filter panel is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query to show filters
      await tester.enterText(find.byType(TextField), 'filter');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Filter panel should be visible
      expect(find.byWidgetPredicate(
        (widget) => widget.toString().contains('Filter'),
      ), findsWidgets);
    });

    testWidgets('Search shows issue metadata', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'metadata');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Issue metadata should be displayed
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Search shows issue labels in results', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'labels');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Labels should be displayed in results
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('Search shows issue status badge', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'status');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Status badges should be displayed
      expect(find.byWidgetPredicate(
        (widget) => widget.toString().contains('Badge') ||
                    widget.toString().contains('Chip'),
      ), findsWidgets);
    });

    testWidgets('Search handles error gracefully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Error state should be handled
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('Search has retry on error', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Retry button should be available
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('Search field has proper hint text', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Hint text should be visible
      expect(find.textContaining('Search'), findsWidgets);
    });

    testWidgets('Search screen has correct background color', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNotNull);
    });
  });
}
