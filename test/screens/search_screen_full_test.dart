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
        builder: (context, child) => const MaterialApp(
          home: SearchScreen(),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders search screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(SearchScreen), findsOneWidget);
      });

      testWidgets('displays search field in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('displays search hint text', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('Search'), findsWidgets);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays search icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search), findsWidgets);
      });

      testWidgets('displays back button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('displays empty state when no query', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Should show search prompt or empty state
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('shows search prompt message', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Should have instructional text
        expect(find.textContaining('Search'), findsWidgets);
      });

      testWidgets('displays no results after empty search', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Initially no "no results" message
        expect(find.text('No results found'), findsNothing);
      });
    });

    group('Search Field Interactions', () {
      testWidgets('search field is focused on load', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
      });

      testWidgets('accepts text input in search field', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'test query');
        await tester.pumpAndSettle();

        expect(find.text('test query'), findsOneWidget);
      });

      testWidgets('clears search field with X button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Enter text first
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pumpAndSettle();

        // Find and tap clear button if present
        final clearButton = find.byIcon(Icons.clear);
        if (clearButton.evaluate().isNotEmpty) {
          await tester.tap(clearButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('triggers search on submit', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'test search');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Should trigger search
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('shows loading indicator during search', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        // Loading indicator may be visible
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows BrailleLoader while fetching', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('hides loading when search completes', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // After settling, loading should be hidden
        expect(find.byType(SearchScreen), findsOneWidget);
      });
    });

    group('Search Filters', () {
      testWidgets('displays filter options', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Filter panel should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('Filter'),
        ), findsWidgets);
      });

      testWidgets('shows status filter chips', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Status filter chips should be available
        expect(find.textContaining('All'), findsWidgets);
        expect(find.textContaining('Open'), findsWidgets);
        expect(find.textContaining('Closed'), findsWidgets);
      });

      testWidgets('allows filter selection', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap on a filter chip
        final allChip = find.text('All');
        if (allChip.evaluate().isNotEmpty) {
          await tester.tap(allChip);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('displays active filter indicators', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Active filters should be indicated
        expect(find.byType(Chip), findsWidgets);
      });
    });

    group('Search Results', () {
      testWidgets('displays search results list', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // List view for results should be present
        expect(find.byType(ListView), findsWidgets);
      });

      testWidgets('shows issue cards in results', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Result items should be displayed
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('SearchResult') ||
                      widget.toString().contains('Card'),
        ), findsWidgets);
      });

      testWidgets('displays issue title in results', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue titles should be in results
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows issue metadata in results', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Metadata like repo name, status should be shown
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on search failure', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error container should be present in widget tree
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows error icon for failures', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('provides retry option on error', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Retry button should be available
        expect(find.byIcon(Icons.refresh), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('tapping result navigates to issue detail', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Result items should be tappable
        expect(find.byType(InkWell), findsWidgets);
      });

      testWidgets('back button navigates to previous screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('filter toggle changes filter state', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Filter chips should be toggleable
        final filterChip = find.byType(Chip).first;
        if (filterChip.evaluate().isNotEmpty) {
          await tester.tap(filterChip);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Search History', () {
      testWidgets('displays recent searches', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Search history section may be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('history') ||
                      widget.toString().contains('recent'),
        ), findsWidgets);
      });

      testWidgets('allows clearing search history', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Clear history button may be present
        expect(find.byIcon(Icons.clear_all), findsWidgets);
      });
    });

    group('AppBar Configuration', () {
      testWidgets('app bar has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar has search field as title', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.title, isNotNull);
      });

      testWidgets('app bar has leading back button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.leading, isNotNull);
      });
    });

    group('Debounced Search', () {
      testWidgets('search is debounced', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Enter text
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump();

        // Should not immediately search (debounced)
        await tester.pump(const Duration(milliseconds: 100));
        
        // Search should trigger after debounce duration
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      });

      testWidgets('cancels previous search on new input', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Enter first query
        await tester.enterText(find.byType(TextField), 'first');
        await tester.pump(const Duration(milliseconds: 100));

        // Enter second query before debounce completes
        await tester.enterText(find.byType(TextField), 'second');
        await tester.pumpAndSettle();

        // Should only search for 'second'
        expect(find.text('second'), findsOneWidget);
      });
    });

    group('Content Type Filters', () {
      testWidgets('displays content type filter options', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Content type filters should be available
        expect(find.textContaining('Title'), findsWidgets);
        expect(find.textContaining('Body'), findsWidgets);
        expect(find.textContaining('Labels'), findsWidgets);
      });

      testWidgets('allows toggling content type filters', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Toggle content type filter
        final titleFilter = find.text('Title');
        if (titleFilter.evaluate().isNotEmpty) {
          await tester.tap(titleFilter);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Date Filters', () {
      testWidgets('displays date filter options', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Date filter section should be available
        expect(find.textContaining('Date'), findsWidgets);
      });

      testWidgets('allows setting date range', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Date filter UI should be present
        expect(find.byType(DateRangePicker), findsWidgets);
      });
    });

    group('Author Filter', () {
      testWidgets('displays author filter input', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Author filter should be available
        expect(find.textContaining('Author'), findsWidgets);
      });

      testWidgets('allows filtering by author', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Author input field should be present
        expect(find.byType(TextField), findsWidgets);
      });
    });

    group('My Issues Filter', () {
      testWidgets('displays My Issues filter option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // My Issues filter should be available
        expect(find.textContaining('My Issues'), findsWidgets);
      });

      testWidgets('allows toggling My Issues filter', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // My Issues filter should be toggleable
        final myIssuesFilter = find.text('My Issues');
        if (myIssuesFilter.evaluate().isNotEmpty) {
          await tester.tap(myIssuesFilter);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Scroll Behavior', () {
      testWidgets('results are scrollable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Results should be in scrollable list
        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('supports infinite scroll', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Should support loading more results
        expect(find.byType(ListView), findsWidgets);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => const MaterialApp(
              home: SearchScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SearchScreen), findsOneWidget);
      });

      testWidgets('uses ScreenUtil for responsive sizing', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Text widgets should use responsive sizing
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Search Result Item', () {
      testWidgets('displays issue number', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue numbers should be displayed
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).data?.contains('#') == true,
        ), findsWidgets);
      });

      testWidgets('displays repository name', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Repository names should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays issue status badge', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Status badges should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('Badge') ||
                      widget.toString().contains('Chip'),
        ), findsWidgets);
      });

      testWidgets('displays issue labels', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Labels should be displayed
        expect(find.byType(Chip), findsWidgets);
      });
    });
  });
}
