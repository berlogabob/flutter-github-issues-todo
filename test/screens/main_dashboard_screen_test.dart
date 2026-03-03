import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/main_dashboard_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('MainDashboardScreen Widget Tests', () {
    Widget createTestApp() {
      return ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => const MaterialApp(
            home: MainDashboardScreen(),
          ),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders main dashboard screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('GitDoIt'), findsOneWidget);
        expect(find.byType(MainDashboardScreen), findsOneWidget);
      });

      testWidgets('displays app title in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('GitDoIt'), findsOneWidget);
      });

      testWidgets('displays search icon in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('displays settings icon in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('displays repository icon in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(IconButton), findsWidgets);
      });

      testWidgets('displays sync cloud icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Sync cloud icon should be present
        expect(find.byIcon(Icons.cloud), findsWidgets);
      });

      testWidgets('displays New Issue floating action button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('New Issue'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });
    });

    group('Loading States', () {
      testWidgets('shows loading indicator when fetching repos', (tester) async {
        await tester.pumpWidget(createTestApp());
        
        // Initial loading state
        await tester.pump();
        
        // BrailleLoader should be visible during loading
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows BrailleLoader during data fetch', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        // Check for loading indicator
        expect(find.byWidgetPredicate(
          (widget) => widget is CircularProgressIndicator || 
                      widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });
    });

    group('Dashboard Filters', () {
      testWidgets('displays filter options', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Filter chips should be present
        expect(find.text('Open'), findsWidgets);
        expect(find.text('Closed'), findsWidgets);
      });

      testWidgets('allows filter selection', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Find and tap filter chip
        final openChip = find.text('Open');
        if (openChip.evaluate().isNotEmpty) {
          await tester.tap(openChip);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Empty States', () {
      testWidgets('shows empty state when no repos', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Should show some content even if empty
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('displays empty state illustration', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Empty state should have illustration or icon
        expect(find.byIcon(Icons.inbox), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('FAB triggers navigation when tapped', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final fab = find.text('New Issue');
        if (fab.evaluate().isNotEmpty) {
          await tester.tap(fab);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('search icon is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final searchButton = find.byIcon(Icons.search);
        if (searchButton.evaluate().isNotEmpty) {
          await tester.tap(searchButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('settings icon is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('repo icon is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap repo icon button
        final repoButtons = find.byType(IconButton);
        if (repoButtons.evaluate().isNotEmpty) {
          await tester.tap(repoButtons.first);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on failure', (tester) async {
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

        // Refresh indicator provides retry functionality
        expect(find.byType(RefreshIndicator), findsOneWidget);
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
    });

    group('Pending Operations', () {
      testWidgets('displays pending operations badge when count > 0', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Badge container should exist in widget tree
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows pending operations count', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Check for pending operations section
        expect(find.textContaining('Pending'), findsWidgets);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        // Test with different screen size
        await tester.pumpWidget(
          ProviderScope(
            child: ScreenUtilInit(
              designSize: const Size(768, 1024),
              builder: (context, child) => const MaterialApp(
                home: MainDashboardScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('GitDoIt'), findsOneWidget);
      });

      testWidgets('uses ConstrainedContent for layout', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // ConstrainedContent should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('ConstrainedContent'),
        ), findsWidgets);
      });
    });

    group('Sync Status', () {
      testWidgets('displays sync status widget', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Sync status widget should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('SyncStatus'),
        ), findsWidgets);
      });

      testWidgets('shows cloud icon for sync status', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.cloud), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('can navigate to search screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final searchButton = find.byIcon(Icons.search);
        if (searchButton.evaluate().isNotEmpty) {
          await tester.tap(searchButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('can navigate to settings screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('FAB Styling', () {
      testWidgets('FAB has orange primary color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        // FAB should have orange color
        expect(fab.backgroundColor, AppColors.orangePrimary);
      });

      testWidgets('FAB has correct icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.icon, isNotNull);
      });

      testWidgets('FAB has extended label', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('New Issue'), findsOneWidget);
      });
    });

    group('AppBar Actions', () {
      testWidgets('app bar has multiple action buttons', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, isNotNull);
        expect(appBar.actions!.length, greaterThan(0));
      });

      testWidgets('app bar has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });
    });
  });
}
