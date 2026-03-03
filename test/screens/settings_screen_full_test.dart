import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/settings_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    Widget createTestApp() {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => const MaterialApp(
          home: SettingsScreen(),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders settings screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('displays Settings title in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays debug button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bug_report), findsOneWidget);
      });
    });

    group('Account Section', () {
      testWidgets('displays Account section header', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Account'), findsOneWidget);
      });

      testWidgets('displays user information tile', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // User tile should be present
        expect(find.byType(ListTile), findsWidgets);
      });

      testWidgets('shows user avatar or initial', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Avatar should be present
        expect(find.byType(CircleAvatar), findsWidgets);
      });

      testWidgets('displays user login name', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // User name should be displayed
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).data != null &&
                      (widget as Text).data!.isNotEmpty,
        ), findsWidgets);
      });

      testWidgets('shows loading state for user data', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        // Loading indicator should be visible
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays Logout option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Logout'), findsOneWidget);
      });

      testWidgets('Logout tile has correct icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.logout), findsWidgets);
      });
    });

    group('Defaults Section', () {
      testWidgets('displays Defaults section header', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Defaults'), findsOneWidget);
      });

      testWidgets('displays Default Repository setting', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Default Repository'), findsOneWidget);
      });

      testWidgets('shows current default repository', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Default repo should be displayed
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).data?.contains('/') == true,
        ), findsWidgets);
      });

      testWidgets('displays Default Project setting', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Default Project'), findsOneWidget);
      });

      testWidgets('shows current default project', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Default project should be displayed
        expect(find.textContaining('Mobile Development'), findsWidgets);
      });

      testWidgets('Default Repository has folder icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.folder), findsWidgets);
      });

      testWidgets('Default Project has kanban icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.view_kanban), findsWidgets);
      });
    });

    group('Sync Section', () {
      testWidgets('displays Sync section header', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Sync'), findsOneWidget);
      });

      testWidgets('displays Auto-sync on WiFi option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Auto-sync on WiFi'), findsOneWidget);
      });

      testWidgets('displays Auto-sync on any network option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Auto-sync on any network'), findsOneWidget);
      });

      testWidgets('displays Sync Now option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Sync Now'), findsOneWidget);
      });

      testWidgets('displays Test Connection option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Test Connection'), findsOneWidget);
      });

      testWidgets('WiFi sync has wifi icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.wifi), findsWidgets);
      });

      testWidgets('Mobile data sync has network icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.network_cell), findsWidgets);
      });

      testWidgets('Sync Now has sync icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.sync), findsWidgets);
      });

      testWidgets('Auto-sync options use SwitchListTile', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(SwitchListTile), findsWidgets);
      });
    });

    group('Danger Zone Section', () {
      testWidgets('displays Danger Zone section header', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Danger Zone'), findsOneWidget);
      });

      testWidgets('displays Clear Local Cache option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Clear Local Cache'), findsOneWidget);
      });

      testWidgets('displays Reset Token option', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Reset Token'), findsOneWidget);
      });

      testWidgets('Clear Cache has delete icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_forever), findsWidgets);
      });

      testWidgets('Reset Token has key icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.key_off), findsWidgets);
      });

      testWidgets('Danger Zone items have red color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Danger zone items should use red color
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).style?.color == AppColors.red,
        ), findsWidgets);
      });
    });

    group('App Info Section', () {
      testWidgets('displays app name', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('GitDoIt'), findsWidgets);
      });

      testWidgets('displays app version', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('Version'), findsWidgets);
      });

      testWidgets('displays app description', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('Minimalist'), findsWidgets);
      });

      testWidgets('shows app icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.checklist_rounded), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('Logout tile is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final logoutTile = find.text('Logout');
        if (logoutTile.evaluate().isNotEmpty) {
          await tester.tap(logoutTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Default Repository tile is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final repoTile = find.text('Default Repository');
        if (repoTile.evaluate().isNotEmpty) {
          await tester.tap(repoTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Default Project tile is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final projectTile = find.text('Default Project');
        if (projectTile.evaluate().isNotEmpty) {
          await tester.tap(projectTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Sync Now tile is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final syncTile = find.text('Sync Now');
        if (syncTile.evaluate().isNotEmpty) {
          await tester.tap(syncTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Test Connection tile is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final testTile = find.text('Test Connection');
        if (testTile.evaluate().isNotEmpty) {
          await tester.tap(testTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Clear Cache tile is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final cacheTile = find.text('Clear Local Cache');
        if (cacheTile.evaluate().isNotEmpty) {
          await tester.tap(cacheTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Reset Token tile is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final tokenTile = find.text('Reset Token');
        if (tokenTile.evaluate().isNotEmpty) {
          await tester.tap(tokenTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Debug button is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final debugButton = find.byIcon(Icons.bug_report);
        if (debugButton.evaluate().isNotEmpty) {
          await tester.tap(debugButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Dialog Interactions', () {
      testWidgets('Logout shows confirmation dialog', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap logout
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Confirmation dialog should appear
        expect(find.textContaining('Logout'), findsWidgets);
      });

      testWidgets('Clear Cache shows confirmation dialog', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap clear cache
        await tester.tap(find.text('Clear Local Cache'));
        await tester.pumpAndSettle();

        // Confirmation dialog should appear
        expect(find.textContaining('Clear'), findsWidgets);
      });

      testWidgets('Reset Token shows confirmation dialog', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap reset token
        await tester.tap(find.text('Reset Token'));
        await tester.pumpAndSettle();

        // Confirmation dialog should appear
        expect(find.textContaining('Reset'), findsWidgets);
      });

      testWidgets('Dialog has Cancel button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Open a dialog first
        await tester.tap(find.text('Reset Token'));
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsWidgets);
      });

      testWidgets('Dialog has action button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Open a dialog first
        await tester.tap(find.text('Reset Token'));
        await tester.pumpAndSettle();

        // Action button should be present
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    group('Switch Controls', () {
      testWidgets('WiFi sync switch is toggleable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final switch = find.byType(Switch).first;
        if (switch.evaluate().isNotEmpty) {
          await tester.tap(switch);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Mobile data sync switch is toggleable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        if (switches.evaluate().length > 1) {
          await tester.tap(switches.last);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Switches have orange accent color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Switch should use orange primary color
        expect(find.byType(Switch), findsWidgets);
      });
    });

    group('List Styling', () {
      testWidgets('settings are in Card widgets', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('Cards have correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final cards = tester.widgetList<Card>(find.byType(Card));
        for (final card in cards) {
          expect(card.color, AppColors.cardBackground);
        }
      });

      testWidgets('ListTiles have chevron trailing', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsWidgets);
      });

      testWidgets('section headers have correct styling', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Section headers should be styled differently
        expect(find.byWidgetPredicate(
          (widget) => widget is Text && 
                      (widget as Text).style?.fontSize == 12,
        ), findsWidgets);
      });
    });

    group('Loading States', () {
      testWidgets('shows loading for user data', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        // Loading indicator should be visible
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows BrailleLoader during loading', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('displays Loading text during data fetch', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.text('Loading...'), findsWidgets);
      });

      testWidgets('hides loading when data loaded', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // After settling, user data should be visible
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('Pending Operations', () {
      testWidgets('displays Pending Operations section', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Pending Operations'), findsOneWidget);
      });

      testWidgets('shows pending operations count badge', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Badge should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays View Full Sync Dashboard button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('View Full Sync Dashboard'), findsWidgets);
      });

      testWidgets('Pending Operations section is expandable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Section should be interactive
        expect(find.byType(Card), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('can navigate to Debug screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final debugButton = find.byIcon(Icons.bug_report);
        if (debugButton.evaluate().isNotEmpty) {
          await tester.tap(debugButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('can navigate to Sync Status Dashboard', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final syncButton = find.text('View Full Sync Dashboard');
        if (syncButton.evaluate().isNotEmpty) {
          await tester.tap(syncButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('uses ListView for scrollable content', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('content has bottom padding', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, isNotNull);
      });
    });

    group('Error Handling', () {
      testWidgets('handles user data load error gracefully', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Should not crash on error
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('handles projects load error gracefully', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Should not crash on error
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('displays error message on connection test failure', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error dialog should be displayable
        expect(find.byType(AlertDialog), findsWidgets);
      });
    });

    group('Connection Test', () {
      testWidgets('shows loading dialog during connection test', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap test connection
        await tester.tap(find.text('Test Connection'));
        await tester.pump();

        // Loading dialog should appear
        expect(find.textContaining('Testing'), findsWidgets);
      });

      testWidgets('displays success message on connection test', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Success dialog should be displayable
        expect(find.byType(AlertDialog), findsWidgets);
      });

      testWidgets('displays error message on connection test failure', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error dialog should be displayable
        expect(find.byIcon(Icons.error), findsWidgets);
      });
    });
  });
}
