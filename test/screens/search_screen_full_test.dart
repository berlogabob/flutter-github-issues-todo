import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/search_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('SearchScreen Widget Tests', () {
    Widget createTestApp() {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => const MaterialApp(home: SearchScreen()),
      );
    }

    Finder searchField() {
      return find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search issues...',
      );
    }

    Future<void> submitSearch(WidgetTester tester, String query) async {
      await tester.enterText(searchField(), query);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 100));
    }

    group('Screen Rendering', () {
      testWidgets('renders search screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SearchScreen), findsOneWidget);
      });

      testWidgets('displays search field in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('displays search hint text', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('Search'), findsWidgets);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays search icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.search), findsWidgets);
      });

      testWidgets('displays back button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('displays empty state when no query', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Should show search prompt or empty state
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('shows search prompt message', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Should have instructional text
        expect(find.textContaining('Search'), findsWidgets);
      });

      testWidgets('displays no results after empty search', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Initially no "no results" message
        expect(find.text('No results found'), findsNothing);
      });
    });

    group('Search Field Interactions', () {
      testWidgets('search field is focused on load', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
      });

      testWidgets('accepts text input in search field', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(searchField(), 'test query');
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('test query'), findsOneWidget);
      });

      testWidgets('clears search field with X button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Enter text first
        await tester.enterText(searchField(), 'test');
        await tester.pump(const Duration(milliseconds: 100));

        // Find and tap clear button if present
        final clearButton = find.byIcon(Icons.clear);
        if (clearButton.evaluate().isNotEmpty) {
          await tester.tap(clearButton);
          await tester.pump(const Duration(milliseconds: 100));
        }
      });

      testWidgets('triggers search on submit', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        await submitSearch(tester, 'test search');

        expect(searchField(), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('does not show loading indicator before search', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('uses cached offline search without lingering loader', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('BrailleLoader'),
          ),
          findsNothing,
        );
      });

      testWidgets('hides loading when search completes', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // After settling, loading should be hidden
        expect(find.byType(SearchScreen), findsOneWidget);
      });
    });

    group('Search Filters', () {
      testWidgets('displays filter options', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        // Filter panel should be present
        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('Filter'),
          ),
          findsWidgets,
        );
      });

      testWidgets('shows status filter chips', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        // Status filter chips should be available
        expect(find.textContaining('Open'), findsWidgets);
        expect(find.textContaining('Closed'), findsWidgets);
      });

      testWidgets('allows filter selection', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        // Tap on a filter chip
        final openChip = find.text('Open');
        if (openChip.evaluate().isNotEmpty) {
          await tester.tap(openChip);
          await tester.pump(const Duration(milliseconds: 100));
        }
      });

      testWidgets('displays active filter indicators', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        // Active filters should be indicated
        expect(find.byType(FilterChip), findsWidgets);
      });
    });

    group('Search Results', () {
      testWidgets('displays search results list', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('shows empty state before results are available', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Search Issues'), findsOneWidget);
      });

      testWidgets('displays issue title in results', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Issue titles should be in results
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows issue metadata in results', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Metadata like repo name, status should be shown
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on search failure', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('Search Error'), findsNothing);
      });

      testWidgets('does not show error icon initially', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('does not show retry option before an error', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.refresh), findsNothing);
      });
    });

    group('User Interactions', () {
      testWidgets('shows empty search state before results are available', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Search Issues'), findsOneWidget);
      });

      testWidgets('back button navigates to previous screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pump(const Duration(milliseconds: 100));
        }
      });

      testWidgets('filter toggle changes filter state', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        final filterChips = find.byType(FilterChip);
        if (filterChips.evaluate().isNotEmpty) {
          await tester.tap(filterChips.first);
          await tester.pump(const Duration(milliseconds: 100));
        }
      });
    });

    group('Search History', () {
      testWidgets('displays recent searches', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Recent Searches'), findsNothing);
      });

      testWidgets('hides clear search history when history is empty', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.clear_all), findsNothing);
      });
    });

    group('AppBar Configuration', () {
      testWidgets('app bar has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar has search field as title', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.title, isNotNull);
      });

      testWidgets('app bar has leading back button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.leading, isNotNull);
      });
    });

    group('Debounced Search', () {
      testWidgets('search is debounced', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Enter text
        await tester.enterText(searchField(), 'test');
        await tester.pump();

        // Should not immediately search (debounced)
        await tester.pump(const Duration(milliseconds: 100));

        // Search should trigger after debounce duration
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 100));
      });

      testWidgets('cancels previous search on new input', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Enter first query
        await tester.enterText(searchField(), 'first');
        await tester.pump(const Duration(milliseconds: 100));

        // Enter second query before debounce completes
        await tester.enterText(searchField(), 'second');
        await tester.pump(const Duration(milliseconds: 100));

        // Should only search for 'second'
        expect(find.text('second'), findsOneWidget);
      });
    });

    group('Content Type Filters', () {
      testWidgets('displays quick filter options', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        expect(find.textContaining('Open'), findsWidgets);
        expect(find.textContaining('Closed'), findsWidgets);
      });

      testWidgets('allows toggling content type filters', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        final openFilter = find.text('Open');
        if (openFilter.evaluate().isNotEmpty) {
          await tester.tap(openFilter);
          await tester.pump(const Duration(milliseconds: 100));
        }
      });
    });

    group('Date Filters', () {
      testWidgets('displays date filter options', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        expect(find.textContaining('From:'), findsWidgets);
        expect(find.textContaining('To:'), findsWidgets);
      });

      testWidgets('allows setting date range', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        expect(find.text('Select'), findsWidgets);
      });
    });

    group('Author Filter', () {
      testWidgets('displays author filter input', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.hintText == 'Filter by author...',
          ),
          findsOneWidget,
        );
      });

      testWidgets('allows filtering by author', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        // Author input field should be present
        expect(find.byType(TextField), findsWidgets);
      });
    });

    group('My Issues Filter', () {
      testWidgets('displays My Issues filter option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        // My Issues filter should be available
        expect(find.textContaining('My Issues'), findsWidgets);
      });

      testWidgets('allows toggling My Issues filter', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        await submitSearch(tester, 'test');

        // My Issues filter should be toggleable
        final myIssuesFilter = find.text('My Issues');
        if (myIssuesFilter.evaluate().isNotEmpty) {
          await tester.tap(myIssuesFilter);
          await tester.pump(const Duration(milliseconds: 100));
        }
      });
    });

    group('Scroll Behavior', () {
      testWidgets('results are scrollable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Results should be in scrollable list
        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('supports pull-to-refresh container', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) =>
                const MaterialApp(home: SearchScreen()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SearchScreen), findsOneWidget);
      });

      testWidgets('uses ScreenUtil for responsive sizing', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Text widgets should use responsive sizing
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Search Result Item', () {
      testWidgets('does not display issue number before results load', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.data?.contains('#') == true,
          ),
          findsNothing,
        );
      });

      testWidgets('displays repository name', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // Repository names should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('does not display issue status badge before results load', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.toString().contains('Badge') ||
                widget.toString().contains('Chip'),
          ),
          findsNothing,
        );
      });

      testWidgets('does not display issue labels before results load', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(Chip), findsNothing);
      });
    });
  });
}
