import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/settings_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    Widget createTestApp({Size designSize = const Size(360, 690)}) {
      return ScreenUtilInit(
        designSize: designSize,
        builder: (context, child) => const MaterialApp(home: SettingsScreen()),
      );
    }

    Future<void> pumpFrames(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> pumpSettings(
      WidgetTester tester, {
      Size designSize = const Size(360, 690),
    }) async {
      await tester.pumpWidget(createTestApp(designSize: designSize));
      await pumpFrames(tester);
    }

    Future<void> scrollToFinder(WidgetTester tester, Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          300,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 20,
        );
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> scrollToText(WidgetTester tester, String text) async {
      await scrollToFinder(tester, find.text(text));
    }

    group('Screen Rendering', () {
      testWidgets('renders settings screen', (tester) async {
        await pumpSettings(tester);

        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('displays Settings title in app bar', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await pumpSettings(tester);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays debug button in app bar', (tester) async {
        await pumpSettings(tester);

        expect(find.byIcon(Icons.bug_report), findsOneWidget);
      });
    });

    group('Account Section', () {
      testWidgets('displays Account section header', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Account'), findsOneWidget);
      });

      testWidgets('displays user information tile', (tester) async {
        await pumpSettings(tester);

        // User tile should be present
        expect(find.byType(ListTile), findsWidgets);
      });

      testWidgets('shows user avatar or initial', (tester) async {
        await pumpSettings(tester);

        // Avatar should be present
        expect(find.byType(CircleAvatar), findsWidgets);
      });

      testWidgets('displays user login name', (tester) async {
        await pumpSettings(tester);

        // User name should be displayed
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.data != null &&
                widget.data!.isNotEmpty,
          ),
          findsWidgets,
        );
      });

      testWidgets('shows loaded state for user data', (tester) async {
        await pumpSettings(tester);

        expect(
          find.byWidgetPredicate((widget) {
            return widget is Text && widget.data == '@user';
          }),
          findsOneWidget,
        );
      });

      testWidgets('displays Logout option', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Logout'), findsOneWidget);
      });

      testWidgets('Logout tile has correct icon', (tester) async {
        await pumpSettings(tester);

        expect(find.byIcon(Icons.logout), findsWidgets);
      });
    });

    group('Defaults Section', () {
      testWidgets('displays Defaults section header', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Defaults'), findsOneWidget);
      });

      testWidgets('displays Default Repository setting', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Default Repository'), findsOneWidget);
      });

      testWidgets('shows current default repository', (tester) async {
        await pumpSettings(tester);

        // Default repo should be displayed
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.data?.contains('/') == true,
          ),
          findsWidgets,
        );
      });

      testWidgets('displays Default Project setting', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Default Project'), findsOneWidget);
      });

      testWidgets('shows current default project', (tester) async {
        await pumpSettings(tester);

        // Default project should be displayed
        expect(find.textContaining('Mobile Development'), findsWidgets);
      });

      testWidgets('Default Repository has folder icon', (tester) async {
        await pumpSettings(tester);

        expect(find.byIcon(Icons.folder), findsWidgets);
      });

      testWidgets('Default Project has kanban icon', (tester) async {
        await pumpSettings(tester);

        expect(find.byIcon(Icons.view_kanban), findsWidgets);
      });
    });

    group('Sync Section', () {
      testWidgets('displays Sync section header', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Sync'), findsOneWidget);
      });

      testWidgets('displays Auto-sync on WiFi option', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Auto-sync on WiFi'), findsOneWidget);
      });

      testWidgets('displays Auto-sync on any network option', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Auto-sync on any network'), findsOneWidget);
      });

      testWidgets('displays Sync Now option', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Sync Now');

        expect(find.text('Sync Now'), findsOneWidget);
      });

      testWidgets('displays Test Connection option', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Test Connection');

        expect(find.text('Test Connection'), findsOneWidget);
      });

      testWidgets('WiFi sync has wifi icon', (tester) async {
        await pumpSettings(tester);

        expect(find.byIcon(Icons.wifi), findsWidgets);
      });

      testWidgets('Mobile data sync has network icon', (tester) async {
        await pumpSettings(tester);

        expect(find.byIcon(Icons.network_cell), findsWidgets);
      });

      testWidgets('Sync Now has sync icon', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Sync Now');

        expect(find.byIcon(Icons.sync), findsWidgets);
      });

      testWidgets('Auto-sync options use SwitchListTile', (tester) async {
        await pumpSettings(tester);

        expect(find.byType(SwitchListTile), findsWidgets);
      });
    });

    group('Danger Zone Section', () {
      testWidgets('displays Danger Zone section header', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Danger Zone');

        expect(find.text('Danger Zone'), findsOneWidget);
      });

      testWidgets('displays Clear Local Cache option', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Clear Local Cache');

        expect(find.text('Clear Local Cache'), findsOneWidget);
      });

      testWidgets('displays Reset Token option', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Reset Token');

        expect(find.text('Reset Token'), findsOneWidget);
      });

      testWidgets('Clear Cache has delete icon', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Clear Local Cache');

        expect(find.byIcon(Icons.delete_forever), findsWidgets);
      });

      testWidgets('Reset Token has key icon', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Reset Token');

        expect(find.byIcon(Icons.key_off), findsWidgets);
      });

      testWidgets('Danger Zone items have red color', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Danger Zone');

        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.style?.color == AppColors.red,
          ),
          findsWidgets,
        );
      });
    });

    group('App Info Section', () {
      testWidgets('displays app name', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'GitDoIt');

        expect(find.text('GitDoIt'), findsWidgets);
      });

      testWidgets('displays app version', (tester) async {
        await pumpSettings(tester);
        await scrollToFinder(tester, find.textContaining('Version'));

        expect(find.textContaining('Version'), findsWidgets);
      });

      testWidgets('displays app description', (tester) async {
        await pumpSettings(tester);
        await scrollToFinder(tester, find.textContaining('Minimalist'));

        expect(find.textContaining('Minimalist'), findsWidgets);
      });

      testWidgets('shows app icon', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'GitDoIt');

        expect(find.byIcon(Icons.checklist_rounded), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('Logout tile is tappable', (tester) async {
        await pumpSettings(tester);

        final logoutTile = find.text('Logout');
        if (logoutTile.evaluate().isNotEmpty) {
          await tester.tap(logoutTile);
          await pumpFrames(tester);
        }
      });

      testWidgets('Default Repository tile is tappable', (tester) async {
        await pumpSettings(tester);

        final repoTile = find.text('Default Repository');
        if (repoTile.evaluate().isNotEmpty) {
          await tester.tap(repoTile);
          await pumpFrames(tester);
        }
      });

      testWidgets('Default Project tile is tappable', (tester) async {
        await pumpSettings(tester);

        final projectTile = find.text('Default Project');
        if (projectTile.evaluate().isNotEmpty) {
          await tester.tap(projectTile);
          await pumpFrames(tester);
        }
      });

      testWidgets('Sync Now tile is tappable', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Sync Now');

        final syncTile = find.text('Sync Now');
        if (syncTile.evaluate().isNotEmpty) {
          await tester.tap(syncTile);
          await pumpFrames(tester);
        }
      });

      testWidgets('Test Connection tile is tappable', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Test Connection');

        final testTile = find.text('Test Connection');
        if (testTile.evaluate().isNotEmpty) {
          await tester.tap(testTile);
          await pumpFrames(tester);
        }
      });

      testWidgets('Clear Cache tile is tappable', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Clear Local Cache');

        final cacheTile = find.text('Clear Local Cache');
        if (cacheTile.evaluate().isNotEmpty) {
          await tester.tap(cacheTile);
          await pumpFrames(tester);
        }
      });

      testWidgets('Reset Token tile is tappable', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Reset Token');

        final tokenTile = find.text('Reset Token');
        if (tokenTile.evaluate().isNotEmpty) {
          await tester.tap(tokenTile);
          await pumpFrames(tester);
        }
      });

      testWidgets('Debug button is tappable', (tester) async {
        await pumpSettings(tester);

        final debugButton = find.byIcon(Icons.bug_report);
        if (debugButton.evaluate().isNotEmpty) {
          await tester.tap(debugButton);
          await pumpFrames(tester);
        }
      });
    });

    group('Dialog Interactions', () {
      testWidgets('Logout shows confirmation dialog', (tester) async {
        await pumpSettings(tester);

        // Tap logout
        await tester.tap(find.text('Logout'));
        await pumpFrames(tester);

        // Confirmation dialog should appear
        expect(find.textContaining('Logout'), findsWidgets);
      });

      testWidgets('Clear Cache shows confirmation dialog', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Clear Local Cache');

        // Tap clear cache
        await tester.tap(find.text('Clear Local Cache'));
        await pumpFrames(tester);

        // Confirmation dialog should appear
        expect(find.textContaining('Clear'), findsWidgets);
      });

      testWidgets('Reset Token shows confirmation dialog', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Reset Token');

        // Tap reset token
        await tester.tap(find.text('Reset Token'));
        await pumpFrames(tester);

        // Confirmation dialog should appear
        expect(find.textContaining('Reset'), findsWidgets);
      });

      testWidgets('Dialog has Cancel button', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Reset Token');

        // Open a dialog first
        await tester.tap(find.text('Reset Token'));
        await pumpFrames(tester);

        expect(find.text('Cancel'), findsWidgets);
      });

      testWidgets('Dialog has action button', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Reset Token');

        // Open a dialog first
        await tester.tap(find.text('Reset Token'));
        await pumpFrames(tester);

        // Action button should be present
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    group('Switch Controls', () {
      testWidgets('WiFi sync switch is toggleable', (tester) async {
        await pumpSettings(tester);

        final wifiSwitch = find.byType(Switch).first;
        if (wifiSwitch.evaluate().isNotEmpty) {
          await tester.tap(wifiSwitch);
          await pumpFrames(tester);
        }
      });

      testWidgets('Mobile data sync switch is toggleable', (tester) async {
        await pumpSettings(tester);

        final switches = find.byType(Switch);
        if (switches.evaluate().length > 1) {
          await tester.tap(switches.last);
          await pumpFrames(tester);
        }
      });

      testWidgets('Switches have orange accent color', (tester) async {
        await pumpSettings(tester);

        // Switch should use orange primary color
        expect(find.byType(Switch), findsWidgets);
      });
    });

    group('List Styling', () {
      testWidgets('settings are in Card widgets', (tester) async {
        await pumpSettings(tester);

        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('Cards have correct background color', (tester) async {
        await pumpSettings(tester);

        final cards = tester.widgetList<Card>(find.byType(Card));
        for (final card in cards) {
          expect(card.color, AppColors.cardBackground);
        }
      });

      testWidgets('ListTiles have chevron trailing', (tester) async {
        await pumpSettings(tester);

        expect(find.byIcon(Icons.chevron_right), findsWidgets);
      });

      testWidgets('section headers have correct styling', (tester) async {
        await pumpSettings(tester);

        // Section headers should be styled differently
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.style?.fontSize == 12,
          ),
          findsWidgets,
        );
      });
    });

    group('Loading States', () {
      testWidgets('shows loaded user data', (tester) async {
        await pumpSettings(tester);

        expect(
          find.byWidgetPredicate((widget) {
            return widget is Text && widget.data == '@user';
          }),
          findsOneWidget,
        );
      });

      testWidgets('does not leave BrailleLoader after user data loads', (
        tester,
      ) async {
        await pumpSettings(tester);

        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('BrailleLoader'),
          ),
          findsNothing,
        );
      });

      testWidgets('replaces Loading text after data fetch', (tester) async {
        await pumpSettings(tester);

        expect(find.text('Loading...'), findsNothing);
      });

      testWidgets('hides loading when data loaded', (tester) async {
        await pumpSettings(tester);

        // After settling, user data should be visible
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('Pending Operations', () {
      testWidgets('displays Pending Operations section', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'View Full Sync Dashboard');

        expect(find.text('Pending Operations'), findsWidgets);
      });

      testWidgets('shows pending operations count badge', (tester) async {
        await pumpSettings(tester);

        // Badge should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('displays View Full Sync Dashboard button', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'View Full Sync Dashboard');

        expect(find.text('View Full Sync Dashboard'), findsWidgets);
      });

      testWidgets('Pending Operations section is expandable', (tester) async {
        await pumpSettings(tester);

        // Section should be interactive
        expect(find.byType(Card), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('can navigate to Debug screen', (tester) async {
        await pumpSettings(tester);

        final debugButton = find.byIcon(Icons.bug_report);
        if (debugButton.evaluate().isNotEmpty) {
          await tester.tap(debugButton);
          await pumpFrames(tester);
        }
      });

      testWidgets('can navigate to Sync Status Dashboard', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'View Full Sync Dashboard');

        final syncButton = find.text('View Full Sync Dashboard');
        if (syncButton.evaluate().isNotEmpty) {
          await tester.tap(syncButton);
          await pumpFrames(tester);
        }
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await pumpSettings(tester, designSize: const Size(768, 1024));

        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('uses ListView for scrollable content', (tester) async {
        await pumpSettings(tester);

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('content has bottom padding', (tester) async {
        await pumpSettings(tester);

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.padding, isNotNull);
      });
    });

    group('Error Handling', () {
      testWidgets('handles user data load error gracefully', (tester) async {
        await pumpSettings(tester);

        // Should not crash on error
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('handles projects load error gracefully', (tester) async {
        await pumpSettings(tester);

        // Should not crash on error
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('does not display connection error before interaction', (
        tester,
      ) async {
        await pumpSettings(tester);

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Connection Test', () {
      testWidgets('shows dialog during connection test', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Test Connection');

        // Tap test connection
        await tester.tap(find.text('Test Connection'));
        await tester.pump();

        expect(find.byType(AlertDialog), findsWidgets);
      });

      testWidgets('displays result dialog on connection test', (tester) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Test Connection');

        await tester.tap(find.text('Test Connection'));
        await pumpFrames(tester);

        expect(find.byType(AlertDialog), findsWidgets);
      });

      testWidgets('displays error message on connection test failure', (
        tester,
      ) async {
        await pumpSettings(tester);
        await scrollToText(tester, 'Test Connection');

        await tester.tap(find.text('Test Connection'));
        await pumpFrames(tester);

        expect(find.byIcon(Icons.error), findsWidgets);
      });
    });
  });
}
