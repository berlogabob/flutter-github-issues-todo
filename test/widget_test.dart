import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/main.dart';
import 'package:gitdoit/screens/main_dashboard_screen.dart';
import 'package:gitdoit/screens/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen displays logo and title', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Verify that the logo icon is displayed.
    expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);

    // Verify that the title is displayed.
    expect(find.text('GitDoIt'), findsOneWidget);

    // Verify auth actions are present.
    expect(find.text('Use Personal Access Token'), findsOneWidget);
    expect(find.text('Continue Offline'), findsOneWidget);
  });

  testWidgets('app starts on onboarding without auth', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GitDoItApp()));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('app starts on dashboard in offline mode', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GitDoItApp(initialAuthType: 'offline')),
    );

    expect(find.byType(MainDashboardScreen), findsOneWidget);
  });
}
