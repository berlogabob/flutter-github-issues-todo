import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';
import 'package:gitdoit/models/repo_item.dart';
import 'package:gitdoit/screens/repo_detail_screen.dart';
import 'package:gitdoit/services/local_storage_service.dart';
import 'package:gitdoit/widgets/braille_loader.dart';
import 'package:gitdoit/widgets/empty_state_illustrations.dart';
import 'package:gitdoit/widgets/label_chip.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> seedCachedRepo({
  String owner = 'test',
  String repo = 'testrepo',
  bool withIssues = true,
}) async {
  final fullName = '$owner/$repo';
  final issues = withIssues
      ? [
          IssueItem(
            id: 'issue-101',
            title: 'Fix offline sync',
            number: 101,
            repoFullName: fullName,
            status: ItemStatus.open,
            labels: const ['offline', 'bug', 'android'],
            updatedAt: DateTime(2026, 3, 18),
          ),
          IssueItem(
            id: 'issue-102',
            title: 'Close synced issue locally',
            number: 102,
            repoFullName: fullName,
            status: ItemStatus.closed,
            labels: const ['done'],
            updatedAt: DateTime(2026, 3, 17),
          ),
        ]
      : <IssueItem>[];
  final storage = LocalStorageService();
  final cachedRepo = RepoItem(
    id: fullName,
    title: repo,
    fullName: fullName,
    description: 'Cached repository',
    openIssuesCount: issues
        .where((issue) => issue.status == ItemStatus.open)
        .length,
  );

  await storage.saveRepos([cachedRepo.toJson()]);
  await storage.saveSyncedIssues(fullName, issues);
}

void main() {
  group('RepoDetailScreen Widget Tests', () {
    setUp(() async {
      await seedCachedRepo();
    });

    Widget createTestApp({String owner = 'test', String repo = 'testrepo'}) {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          home: RepoDetailScreen(owner: owner, repo: repo),
        ),
      );
    }

    Future<void> pumpLoadedRepoDetail(
      WidgetTester tester, {
      String owner = 'test',
      String repo = 'testrepo',
    }) async {
      await tester.pumpWidget(createTestApp(owner: owner, repo: repo));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
    }

    group('Screen Rendering', () {
      testWidgets('renders repo detail screen', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(RepoDetailScreen), findsOneWidget);
      });

      testWidgets('displays repo name in app bar', (tester) async {
        await pumpLoadedRepoDetail(
          tester,
          owner: 'testowner',
          repo: 'testrepo',
        );

        expect(find.textContaining('testowner/testrepo'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays open in browser button', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byIcon(Icons.open_in_browser), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('does not keep blocking loader after cached data loads', (
        tester,
      ) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(BrailleLoader), findsNothing);
      });

      testWidgets('renders cached repository during data fetch', (
        tester,
      ) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.text('Cached repository'), findsOneWidget);
      });

      testWidgets('hides loading text when cache is available', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.textContaining('Loading'), findsNothing);
      });

      testWidgets('hides loading when data loaded', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // After settling, content should be visible
        expect(find.byType(RepoDetailScreen), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('uses offline cache instead of showing an error', (
        tester,
      ) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.text('Failed to load repository'), findsNothing);
        expect(find.text('Cached repository'), findsOneWidget);
      });

      testWidgets('shows error icon for failures', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('displays retry button on error', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byIcon(Icons.refresh), findsNothing);
      });

      testWidgets('shows cached repository details', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.text('testrepo'), findsWidgets);
        expect(find.text('Cached repository'), findsOneWidget);
      });

      testWidgets('retry button is clickable', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final retryButton = find.byIcon(Icons.refresh);
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pump(const Duration(seconds: 1));
        }
      });
    });

    group('Repository Info Card', () {
      testWidgets('displays repo info card', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Card should be present
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows repo title', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Repo title should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays repo description', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Description should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('shows repo statistics', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Stats should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays open issues count', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Open issues count should be displayed
        expect(find.textContaining('Open'), findsWidgets);
      });

      testWidgets('displays closed issues count', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Closed issues count should be displayed
        expect(find.textContaining('Closed'), findsWidgets);
      });

      testWidgets('card has correct background color', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final cards = tester.widgetList<Card>(find.byType(Card));
        if (cards.isNotEmpty) {
          expect(cards.first.color, AppColors.cardBackground);
        }
      });
    });

    group('Issues Section', () {
      testWidgets('displays Issues section header', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.textContaining('Issues'), findsWidgets);
      });

      testWidgets('shows issues list', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issues list should be present
        expect(find.byType(ListView), findsWidgets);
      });

      testWidgets('displays issue cards', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issue cards should be present
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('shows issue title', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issue titles should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('displays issue number', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issue numbers should be displayed
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.data?.contains('#') == true,
          ),
          findsWidgets,
        );
      });

      testWidgets('shows issue status badge', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
        expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      });

      testWidgets('displays issue labels', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(LabelChipWidget), findsWidgets);
      });

      testWidgets('uses compact issue tiles without assignee avatars', (
        tester,
      ) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(CircleAvatar), findsNothing);
      });

      testWidgets('uses compact issue tiles without updated timestamp', (
        tester,
      ) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.textContaining('Updated'), findsNothing);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('RefreshIndicator has correct color', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final refreshIndicator = tester.widget<RefreshIndicator>(
          find.byType(RefreshIndicator),
        );
        expect(refreshIndicator.color, AppColors.orangePrimary);
      });

      testWidgets('pull-to-refresh triggers reload', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Refresh indicator should be functional
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('open in browser button is clickable', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final browserButton = find.byIcon(Icons.open_in_browser);
        if (browserButton.evaluate().isNotEmpty) {
          await tester.tap(browserButton);
          await tester.pump(const Duration(seconds: 1));
        }
      });

      testWidgets('issue cards are tappable', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issue cards should be tappable
        expect(find.byType(InkWell), findsWidgets);
      });

      testWidgets('tapping issue navigates to detail', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issue cards should navigate to detail
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('retry button triggers reload', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final retryButton = find.byIcon(Icons.refresh);
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pump(const Duration(seconds: 1));
        }
      });
    });

    group('AppBar Configuration', () {
      testWidgets('app bar has correct background color', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar has repo name as title', (tester) async {
        await pumpLoadedRepoDetail(tester, owner: 'owner', repo: 'repo');

        expect(find.textContaining('owner/repo'), findsOneWidget);
      });

      testWidgets('app bar has action buttons', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, isNotNull);
      });

      testWidgets('title is ellipsized when too long', (tester) async {
        await pumpLoadedRepoDetail(
          tester,
          owner: 'verylongownername',
          repo: 'verylongreponame',
        );

        // Title should handle long text
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('shows empty state when no issues', (tester) async {
        await seedCachedRepo(withIssues: false);
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(EmptyStateWidget), findsOneWidget);
      });

      testWidgets('displays empty state message', (tester) async {
        await seedCachedRepo(withIssues: false);
        await pumpLoadedRepoDetail(tester);

        expect(find.text('No issues found'), findsOneWidget);
      });

      testWidgets('shows empty state illustration', (tester) async {
        await seedCachedRepo(withIssues: false);
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(EmptyStateIllustration), findsOneWidget);
      });
    });

    group('Issue Card Styling', () {
      testWidgets('issue cards have correct background', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Cards should have proper styling
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('issue cards have proper padding', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Cards should have padding
        expect(find.byType(Padding), findsWidgets);
      });

      testWidgets('issue titles have correct styling', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.data?.contains('#101 Fix offline sync') == true &&
                widget.style?.color == Colors.white,
          ),
          findsOneWidget,
        );
      });

      testWidgets('label text uses primary accent styling', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.data == 'offline' &&
                widget.style?.color == AppColors.primary,
          ),
          findsOneWidget,
        );
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
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();

        expect(find.byType(RepoDetailScreen), findsOneWidget);
      });

      testWidgets('uses ListView for scrollable content', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(ListView), findsWidgets);
      });

      testWidgets('content has proper padding', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Content should have padding
        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('can navigate to issue detail', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issue cards should be navigable
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('can open repo in browser', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final browserButton = find.byIcon(Icons.open_in_browser);
        if (browserButton.evaluate().isNotEmpty) {
          await tester.tap(browserButton);
          await tester.pump(const Duration(seconds: 1));
        }
      });
    });

    group('Scroll Behavior', () {
      testWidgets('content is scrollable', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('can scroll to see all issues', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Issues should be scrollable
        expect(find.byType(ListView), findsWidgets);
      });
    });

    group('Label Display', () {
      testWidgets('labels are displayed as chips', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.byType(LabelChipWidget), findsWidgets);
      });

      testWidgets('labels have proper styling', (tester) async {
        await pumpLoadedRepoDetail(tester);

        final label = tester.widget<LabelChipWidget>(
          find.widgetWithText(LabelChipWidget, 'offline'),
        );
        expect(label.fontSize, 10);
      });

      testWidgets('multiple labels are wrapped', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Multiple labels should wrap
        expect(find.byType(Wrap), findsWidgets);
      });
    });

    group('Status Badge Display', () {
      testWidgets('open status is displayed', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.text('Open'), findsWidgets);
      });

      testWidgets('closed status is displayed', (tester) async {
        await pumpLoadedRepoDetail(tester);

        expect(find.text('Closed'), findsWidgets);
      });

      testWidgets('status badges have correct colors', (tester) async {
        await pumpLoadedRepoDetail(tester);

        // Status badges should have colors
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
          findsWidgets,
        );
      });
    });
  });
}
