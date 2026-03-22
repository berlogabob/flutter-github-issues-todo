import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:gitdoit/models/repo_item.dart';
import 'package:gitdoit/providers/pinned_repos_provider.dart';
import 'package:gitdoit/providers/repositories_provider.dart';
import 'package:gitdoit/screens/main_dashboard_screen.dart';

class _TestRepositoriesNotifier extends RepositoriesNotifier {
  _TestRepositoriesNotifier(this._repos);

  final List<RepoItem> _repos;

  @override
  List<RepoItem> build() => _repos;
}

class _TestPinnedReposNotifier extends PinnedReposNotifier {
  _TestPinnedReposNotifier(this._pinnedRepos);

  final List<String> _pinnedRepos;

  @override
  List<String> build() => _pinnedRepos;
}

class _TestMainRepoNotifier extends MainRepoNotifier {
  _TestMainRepoNotifier(this._mainRepo);

  final String? _mainRepo;

  @override
  String? build() => _mainRepo;
}

void main() {
  group('MainDashboardScreen Widget Tests', () {
    Widget createTestApp({
      List<RepoItem>? repos,
      List<String>? pinnedRepos,
      String? mainRepo,
    }) {
      return ProviderScope(
        overrides: [
          repositoriesProvider.overrideWith(
            () => _TestRepositoriesNotifier(repos ?? const []),
          ),
          pinnedReposProvider.overrideWith(
            () => _TestPinnedReposNotifier(pinnedRepos ?? const []),
          ),
          mainRepoProvider.overrideWith(() => _TestMainRepoNotifier(mainRepo)),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => const MaterialApp(
            home: MainDashboardScreen(),
          ),
        ),
      );
    }

    Future<void> pumpDashboard(
      WidgetTester tester, {
      List<RepoItem>? repos,
      List<String>? pinnedRepos,
      String? mainRepo,
    }) async {
      await tester.pumpWidget(
        createTestApp(
          repos: repos,
          pinnedRepos: pinnedRepos,
          mainRepo: mainRepo,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    testWidgets('renders main dashboard shell', (tester) async {
      await pumpDashboard(tester);

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.text('GitDoIt'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows app bar actions and floating action button', (
      tester,
    ) async {
      await pumpDashboard(tester);

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Issue'), findsOneWidget);
    });

    testWidgets('uses expected screen theming', (tester) async {
      await pumpDashboard(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      expect(scaffold.backgroundColor, AppColors.background);
      expect(appBar.backgroundColor, AppColors.background);
    });

    testWidgets('handles empty repositories deterministically', (tester) async {
      await pumpDashboard(tester, repos: const []);

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('GitDoIt'), findsOneWidget);
    });

    testWidgets('renders repository list when repositories are provided', (
      tester,
    ) async {
      final repos = <RepoItem>[
        RepoItem(
          id: 'repo-1',
          title: 'Repo One',
          fullName: 'user/repo-one',
          description: 'First repo',
        ),
        RepoItem(
          id: 'repo-2',
          title: 'Repo Two',
          fullName: 'user/repo-two',
          description: 'Second repo',
        ),
      ];

      await pumpDashboard(tester, repos: repos);

      expect(find.text('repo-one'), findsOneWidget);
      expect(find.text('repo-two'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('filters area is rendered', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });
  });
}
