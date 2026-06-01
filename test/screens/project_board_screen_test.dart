import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:gitdoit/screens/project_board_screen.dart';
import 'package:gitdoit/widgets/braille_loader.dart';

import '../support/test_harness.dart';
import '../support/widget_pump_helpers.dart';

void main() {
  final harness = TestHarness.shared;

  setUpAll(() async {
    await harness.install();
  });

  setUp(() async {
    await harness.reset();
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  Future<void> pumpProjectBoard(
    WidgetTester tester, {
    Size designSize = defaultTestDesignSize,
  }) async {
    await tester.pumpTestApp(
      const ProjectBoardScreen(),
      designSize: designSize,
    );
    await tester.pump();
  }

  group('ProjectBoardScreen', () {
    testWidgets('renders screen chrome immediately', (tester) async {
      await pumpProjectBoard(tester);

      expect(find.byType(ProjectBoardScreen), findsOneWidget);
      expect(find.text('Project Board'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byType(RefreshIndicator), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.background);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppColors.background);
      expect(appBar.actions, isNotNull);
    });

    testWidgets(
      'uses BrailleLoader instead of CircularProgressIndicator while loading',
      (tester) async {
        await pumpProjectBoard(tester);

        expect(find.byType(BrailleLoader), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'keeps loading state bounded without requiring settled animations',
      (tester) async {
        await pumpProjectBoard(tester);
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.byType(ProjectBoardScreen), findsOneWidget);
        expect(find.byType(BrailleLoader), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('add button shows current create-issue guidance', (
      tester,
    ) async {
      await pumpProjectBoard(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Create issues from the Dashboard'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('mounts at tablet design size without settling animations', (
      tester,
    ) async {
      await pumpProjectBoard(tester, designSize: const Size(768, 1024));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(ProjectBoardScreen), findsOneWidget);
      expect(find.text('Project Board'), findsOneWidget);
    });
  });
}
