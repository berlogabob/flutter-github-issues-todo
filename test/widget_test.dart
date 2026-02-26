import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen displays logo and title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Verify that the logo icon is displayed.
    expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);

    // Verify that the title is displayed.
    expect(find.text('GitDoIt'), findsOneWidget);

    // Verify login buttons are present.
    expect(find.text('Login with GitHub'), findsOneWidget);
    expect(find.text('Use Personal Access Token'), findsOneWidget);
    expect(find.text('Continue Offline'), findsOneWidget);
  });
}
