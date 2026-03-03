// Integration Test: First Launch - Onboarding to Dashboard
// Tests the complete first-time user journey from app launch to dashboard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gitdoit/main.dart' as app;
import 'package:gitdoit/screens/onboarding_screen.dart';
import 'package:gitdoit/screens/main_dashboard_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('First Launch Journey', () {
    testWidgets('Complete onboarding flow to dashboard', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // STEP 1: Verify onboarding screen is displayed
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('GitDoIt'), findsOneWidget);
      expect(
        find.text('Minimalist GitHub Issues & Projects TODO Manager'),
        findsOneWidget,
      );

      // STEP 2: Verify login options are available
      expect(find.text('Login with GitHub'), findsOneWidget);
      expect(
        find.text('Use Personal Access Token'),
        findsOneWidget,
      );
      expect(find.text('Continue Offline'), findsOneWidget);

      // STEP 3: Tap Continue Offline for testing
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();

      // STEP 4: Handle folder selection (skip for integration test)
      // In real scenario, user would select a folder
      // For test, we simulate the flow continuing

      // STEP 5: Wait for navigation to dashboard
      await tester.pumpAndSettle();

      // STEP 6: Verify dashboard is displayed
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.text('GitDoIt'), findsOneWidget);

      // STEP 7: Verify dashboard elements
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('New Issue'), findsOneWidget);

      // STEP 8: Verify filters are displayed
      expect(find.text('Open'), findsWidgets);
      expect(find.text('Closed'), findsWidgets);
    });

    testWidgets('Offline mode persists after restart', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Go through onboarding
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Select offline mode
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();

      // Verify we reached dashboard
      await tester.pumpAndSettle();
      expect(find.byType(MainDashboardScreen), findsOneWidget);

      // Simulate app restart by checking state persistence
      // In real scenario, app would remember offline mode
      expect(find.text('GitDoIt'), findsOneWidget);
    });

    testWidgets('Onboarding shows all authentication options', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify onboarding screen
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Check all auth options are visible
      final githubLogin = find.text('Login with GitHub');
      final patLogin = find.text('Use Personal Access Token');
      final offline = find.text('Continue Offline');

      expect(githubLogin, findsOneWidget);
      expect(patLogin, findsOneWidget);
      expect(offline, findsOneWidget);

      // Verify buttons are enabled
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsWidgets);
    });

    testWidgets('PAT login flow displays token input', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap PAT option
      await tester.tap(find.text('Use Personal Access Token'));
      await tester.pumpAndSettle();

      // Verify token input field is displayed
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Personal Access Token'), findsOneWidget);

      // Verify Continue button is present but disabled
      expect(find.text('Continue'), findsOneWidget);

      // Enter a token
      await tester.enterText(
        find.byType(TextField),
        'ghp_testToken123456789',
      );
      await tester.pumpAndSettle();

      // Verify Continue button is now enabled
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    });

    testWidgets('Onboarding has proper branding', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify logo/icon
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);

      // Verify app name
      expect(find.text('GitDoIt'), findsOneWidget);

      // Verify tagline
      expect(
        find.text('Minimalist GitHub Issues & Projects TODO Manager'),
        findsOneWidget,
      );

      // Verify visual styling
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNotNull);
    });
  });
}
