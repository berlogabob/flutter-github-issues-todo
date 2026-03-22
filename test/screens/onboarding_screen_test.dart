import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    Future<void> pumpOnboarding(
      WidgetTester tester, {
      Size viewport = const Size(800, 1200),
    }) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) =>
              const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapAuthButton(WidgetTester tester, String textPart) async {
      final labelFinder = find.textContaining(textPart);
      expect(labelFinder, findsOneWidget);

      final buttonFinder = find.ancestor(
        of: labelFinder.first,
        matching: find.byType(ElevatedButton),
      );
      expect(buttonFinder, findsOneWidget);

      await tester.ensureVisible(labelFinder.first);
      await tester.tap(labelFinder.first);
      await tester.pumpAndSettle();
    }

    testWidgets('renders core onboarding content on constrained viewport', (
      tester,
    ) async {
      await pumpOnboarding(tester, viewport: const Size(360, 640));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
      expect(find.text('GitDoIt'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows PAT and offline auth actions', (tester) async {
      await pumpOnboarding(tester);

      expect(find.textContaining('Personal Access Token'), findsOneWidget);
      expect(find.textContaining('Continue Offline'), findsOneWidget);
      expect(find.byIcon(Icons.key), findsWidgets);
      expect(find.byIcon(Icons.offline_pin), findsOneWidget);
    });

    testWidgets('opens PAT dialog and allows cancel back to onboarding', (
      tester,
    ) async {
      await pumpOnboarding(tester);

      await tapAuthButton(tester, 'Personal Access Token');

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Personal Access Token'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('PAT input field uses obscured password mode', (tester) async {
      await pumpOnboarding(tester);
      await tapAuthButton(tester, 'Personal Access Token');

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(find.textContaining('ghp_'), findsOneWidget);
    });

    testWidgets('invalid PAT shows inline auth error and closes dialog', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await tapAuthButton(tester, 'Personal Access Token');

      await tester.enterText(find.byType(TextField), 'bad-token');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Invalid token format'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('PAT dialog clears token after cancel', (tester) async {
      await pumpOnboarding(tester);
      await tapAuthButton(tester, 'Personal Access Token');

      await tester.enterText(find.byType(TextField), 'ghp_temporaryToken12345');
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tapAuthButton(tester, 'Personal Access Token');
      final reopenedField = tester.widget<TextField>(find.byType(TextField));
      expect(reopenedField.controller?.text ?? '', isEmpty);
    });
  });
}
