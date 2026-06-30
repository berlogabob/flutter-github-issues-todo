import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/widgets/empty_state_illustrations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('Task 17.3 - Empty States', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('EmptyStateType Enum', () {
      test('All 5 empty state types are defined', () {
        expect(
          EmptyStateType.values.length,
          equals(5),
          reason: 'EmptyStateType has 5 defined types',
        );
      });
    });

    group('EmptyStateIllustration Widget', () {
      testWidgets('EmptyStateIllustration renders without crashing', (
        tester,
      ) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => const MaterialApp(
              home: Scaffold(
                body: EmptyStateIllustration(
                  type: EmptyStateType.noIssues,
                  animate: false,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(EmptyStateIllustration), findsOneWidget);
      });

      testWidgets('EmptyStateIllustration uses CustomPaint', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => const MaterialApp(
              home: Scaffold(
                body: EmptyStateIllustration(
                  type: EmptyStateType.noIssues,
                  animate: false,
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('EmptyStateWidget', () {
      testWidgets('EmptyStateWidget renders with title', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => const MaterialApp(
              home: Scaffold(
                body: EmptyStateWidget(
                  type: EmptyStateType.noIssues,
                  title: 'No Issues',
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('No Issues'), findsOneWidget);
      });

      testWidgets('EmptyStateWidget displays subtitle', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => const MaterialApp(
              home: Scaffold(
                body: EmptyStateWidget(
                  type: EmptyStateType.noIssues,
                  title: 'No Issues',
                  subtitle: 'Create one to start',
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Create one to start'), findsOneWidget);
      });

      testWidgets('EmptyStateWidget displays action button', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: const EmptyStateWidget(
                  type: EmptyStateType.noIssues,
                  title: 'No Issues',
                  action: ElevatedButton(
                    onPressed: null,
                    child: Text('Create'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('Create'), findsOneWidget);
      });
    });
  });
}
