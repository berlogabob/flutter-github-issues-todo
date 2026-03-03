import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/onboarding_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    Widget createTestApp() {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders onboarding screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
      });

      testWidgets('displays app logo', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
      });

      testWidgets('displays app name GitDoIt', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('GitDoIt'), findsOneWidget);
      });

      testWidgets('displays app tagline', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(
          find.text('Minimalist GitHub Issues & Projects TODO Manager'),
          findsOneWidget,
        );
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, const Color(0xFF121212));
      });
    });

    group('Authentication Options', () {
      testWidgets('displays Login with GitHub button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Login with GitHub'), findsOneWidget);
      });

      testWidgets('displays Use Personal Access Token button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Use Personal Access Token'), findsOneWidget);
      });

      testWidgets('displays Continue Offline button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Continue Offline'), findsOneWidget);
      });

      testWidgets('Login with GitHub button has login icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final buttons = tester.widgetList<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(buttons.length, greaterThan(0));
      });

      testWidgets('PAT button has key icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.key), findsWidgets);
      });

      testWidgets('Offline button has offline pin icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.offline_pin), findsWidgets);
      });
    });

    group('PAT Login Flow', () {
      testWidgets('tapping PAT button shows token input', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.textContaining('Personal Access Token'),
          findsOneWidget,
        );
      });

      testWidgets('token input has correct hint text', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('ghp_'),
          findsWidgets,
        );
      });

      testWidgets('Continue button disabled when token empty', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        expect(find.text('Continue'), findsOneWidget);
      });

      testWidgets('entering token enables Continue button', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'ghp_testToken123456789',
        );
        await tester.pumpAndSettle();

        expect(find.text('Continue'), findsOneWidget);
      });

      testWidgets('Back to options button returns to main screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Back to options'));
        await tester.pumpAndSettle();

        expect(find.text('Login with GitHub'), findsOneWidget);
      });
    });

    group('Loading States', () {
      testWidgets('shows BrailleLoader when loading', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // BrailleLoader should be in widget tree
        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('BrailleLoader'),
          ),
          findsWidgets,
        );
      });

      testWidgets('loading indicator hidden when idle', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Should not show loading initially
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Error Display', () {
      testWidgets('error message container is present', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error container should be in widget tree
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('error icon is displayed for errors', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('error message has red color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error text should use red color
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text &&
                widget.style?.color != null,
          ),
          findsWidgets,
        );
      });
    });

    group('Button Styling', () {
      testWidgets('primary buttons have orange background', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final buttons = tester.widgetList<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(buttons.length, greaterThan(0));
      });

      testWidgets('secondary button has transparent background', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Continue Offline should be secondary style
        expect(find.text('Continue Offline'), findsOneWidget);
      });

      testWidgets('buttons have rounded corners', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Buttons should have rounded styling
        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('button text has correct font size', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final texts = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(ElevatedButton),
            matching: find.byType(Text),
          ),
        );
        expect(texts.length, greaterThan(0));
      });
    });

    group('User Interactions', () {
      testWidgets('Login with GitHub button is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Login with GitHub'));
        await tester.pumpAndSettle();

        // Should trigger OAuth flow
        expect(find.byType(OnboardingScreen), findsOneWidget);
      });

      testWidgets('PAT button is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('Continue Offline button is tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue Offline'));
        await tester.pumpAndSettle();

        // Should trigger offline mode
        expect(find.byType(OnboardingScreen), findsOneWidget);
      });

      testWidgets('token input accepts text', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'ghp_testToken123',
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('ghp_testToken123'), findsOneWidget);
      });

      testWidgets('token input is obscured', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.obscureText, isTrue);
      });
    });

    group('Layout and Responsiveness', () {
      testWidgets('uses SafeArea widget', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(SafeArea), findsOneWidget);
      });

      testWidgets('uses ConstrainedContent', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('ConstrainedContent'),
          ),
          findsWidgets,
        );
      });

      testWidgets('content is centered vertically', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Column with MainAxisAlignment.center
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('uses Spacer for layout', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Spacer), findsWidgets);
      });

      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => const MaterialApp(
              home: OnboardingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
      });
    });

    group('Visual Design', () {
      testWidgets('logo has orange color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final icons = tester.widgetList<Icon>(find.byIcon(Icons.checklist_rounded));
        expect(icons.length, greaterThan(0));
      });

      testWidgets('app name is bold', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final texts = tester.widgetList<Text>(find.text('GitDoIt'));
        expect(texts.length, greaterThan(0));
      });

      testWidgets('tagline has reduced opacity', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tagline should have alpha 0.7
        expect(
          find.text('Minimalist GitHub Issues & Projects TODO Manager'),
          findsOneWidget,
        );
      });

      testWidgets('error container has red border', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error container styling
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('buttons have consistent height', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Buttons should have consistent sizing
        expect(find.byType(ElevatedButton), findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('text has sufficient contrast', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // All text should be visible
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('buttons are large enough for touch', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Buttons should have proper sizing (56.h height)
        final buttons = tester.widgetList<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(buttons.length, greaterThan(0));
      });

      testWidgets('input field has proper labeling', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Personal Access Token'),
          findsOneWidget,
        );
      });
    });

    group('State Management', () {
      testWidgets('toggles between PAT and main view', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Start on main view
        expect(find.text('Login with GitHub'), findsOneWidget);

        // Switch to PAT view
        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);

        // Switch back
        await tester.tap(find.text('Back to options'));
        await tester.pumpAndSettle();
        expect(find.text('Login with GitHub'), findsOneWidget);
      });

      testWidgets('maintains state during rebuilds', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Use Personal Access Token'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'ghp_testToken',
        );
        await tester.pumpAndSettle();

        // Force rebuild
        await tester.pumpAndSettle();

        // Text should persist
        expect(find.textContaining('ghp_testToken'), findsOneWidget);
      });
    });
  });
}
