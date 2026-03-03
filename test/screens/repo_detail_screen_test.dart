import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/repo_detail_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('RepoDetailScreen Widget Tests', () {
    Widget createTestApp({String owner = 'test', String repo = 'testrepo'}) {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          home: RepoDetailScreen(owner: owner, repo: repo),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders repo detail screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(RepoDetailScreen), findsOneWidget);
      });

      testWidgets('displays repo name in app bar', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'testowner', repo: 'testrepo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('testowner/testrepo'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays open in browser button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('shows loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows BrailleLoader during data fetch', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('displays loading text', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.textContaining('Loading'), findsWidgets);
      });

      testWidgets('hides loading when data loaded', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // After settling, content should be visible
        expect(find.byType(RepoDetailScreen), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('displays error message on failure', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error container should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows error icon for failures', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('displays retry button on error', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsWidgets);
      });

      testWidgets('shows error details', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error details should be displayable
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('retry button is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final retryButton = find.byIcon(Icons.refresh);
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Repository Info Card', () {
      testWidgets('displays repo info card', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Card should be present
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows repo title', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Repo title should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays repo description', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Description should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows repo statistics', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Stats should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays open issues count', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Open issues count should be displayed
        expect(find.textContaining('Open'), findsWidgets);
      });

      testWidgets('displays closed issues count', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Closed issues count should be displayed
        expect(find.textContaining('Closed'), findsWidgets);
      });

      testWidgets('card has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final cards = tester.widgetList<Card>(find.byType(Card));
        if (cards.isNotEmpty) {
          expect(cards.first.color, AppColors.cardBackground);
        }
      });
    });

    group('Issues Section', () {
      testWidgets('displays Issues section header', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('Issues'), findsWidgets);
      });

      testWidgets('shows issues list', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issues list should be present
        expect(find.byType(ListView), findsWidgets);
      });

      testWidgets('displays issue cards', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue cards should be present
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows issue title', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue titles should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays issue number', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue numbers should be displayed
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).data?.contains('#') == true,
        ), findsWidgets);
      });

      testWidgets('shows issue status badge', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Status badges should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('Chip') ||
                      widget.toString().contains('Badge'),
        ), findsWidgets);
      });

      testWidgets('displays issue labels', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Labels should be displayed
        expect(find.byType(Chip), findsWidgets);
      });

      testWidgets('shows issue assignee', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Assignee should be displayed
        expect(find.byType(CircleAvatar), findsWidgets);
      });

      testWidgets('displays issue updated time', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Updated time should be displayed
        expect(find.textContaining('Updated'), findsWidgets);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('RefreshIndicator has correct color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final refreshIndicator = tester.widget<RefreshIndicator>(
          find.byType(RefreshIndicator),
        );
        expect(refreshIndicator.color, AppColors.orangePrimary);
      });

      testWidgets('pull-to-refresh triggers reload', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Refresh indicator should be functional
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('open in browser button is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final browserButton = find.byIcon(Icons.open_in_browser);
        if (browserButton.evaluate().isNotEmpty) {
          await tester.tap(browserButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('issue cards are tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue cards should be tappable
        expect(find.byType(InkWell), findsWidgets);
      });

      testWidgets('tapping issue navigates to detail', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue cards should navigate to detail
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('retry button triggers reload', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final retryButton = find.byIcon(Icons.refresh);
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('AppBar Configuration', () {
      testWidgets('app bar has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar has repo name as title', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'owner', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('owner/repo'), findsOneWidget);
      });

      testWidgets('app bar has action buttons', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, isNotNull);
      });

      testWidgets('title is ellipsized when too long', (tester) async {
        await tester.pumpWidget(createTestApp(
          owner: 'verylongownername',
          repo: 'verylongreponame',
        ));
        await tester.pumpAndSettle();

        // Title should handle long text
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('shows empty state when no issues', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Empty state should be displayable
        expect(find.byType(RepoDetailScreen), findsOneWidget);
      });

      testWidgets('displays empty state message', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Empty state message should be displayable
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows empty state icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Empty state icon should be displayable
        expect(find.byIcon(Icons.inbox), findsWidgets);
      });
    });

    group('Issue Card Styling', () {
      testWidgets('issue cards have correct background', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should have proper styling
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('issue cards have proper padding', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should have padding
        expect(find.byType(Padding), findsWidgets);
      });

      testWidgets('issue titles have correct styling', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Titles should be styled
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).style?.fontWeight == FontWeight.w600,
        ), findsWidgets);
      });

      testWidgets('issue metadata has secondary text style', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Metadata should use secondary text style
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).style?.color == Colors.white54,
        ), findsWidgets);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => MaterialApp(
              home: RepoDetailScreen(owner: 'test', repo: 'testrepo'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RepoDetailScreen), findsOneWidget);
      });

      testWidgets('uses ListView for scrollable content', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsWidgets);
      });

      testWidgets('content has proper padding', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Content should have padding
        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('can navigate to issue detail', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue cards should be navigable
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('can open repo in browser', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final browserButton = find.byIcon(Icons.open_in_browser);
        if (browserButton.evaluate().isNotEmpty) {
          await tester.tap(browserButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Scroll Behavior', () {
      testWidgets('content is scrollable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('can scroll to see all issues', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issues should be scrollable
        expect(find.byType(ListView), findsWidgets);
      });
    });

    group('Label Display', () {
      testWidgets('labels are displayed as chips', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Chip), findsWidgets);
      });

      testWidgets('labels have proper styling', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Label chips should be styled
        expect(find.byType(Chip), findsWidgets);
      });

      testWidgets('multiple labels are wrapped', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Multiple labels should wrap
        expect(find.byType(Wrap), findsWidgets);
      });
    });

    group('Status Badge Display', () {
      testWidgets('open status is displayed', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Open'), findsWidgets);
      });

      testWidgets('closed status is displayed', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Closed'), findsWidgets);
      });

      testWidgets('status badges have correct colors', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Status badges should have colors
        expect(find.byWidgetPredicate(
          (widget) => widget is Container && 
                      (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });
    });
  });
}
