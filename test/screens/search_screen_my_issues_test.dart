import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/search_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('Task 15.3 - My Issues Filter', () {
    Widget createTestApp() {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => const MaterialApp(home: SearchScreen()),
      );
    }

    Future<void> showFilters(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).first, 'offline');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('SearchScreen has My Issues filter toggle', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(milliseconds: 100));
      await showFilters(tester);

      // The "My Issues" filter toggle should exist
      expect(find.text('My Issues'), findsOneWidget);
    });

    testWidgets('My Issues filter can be toggled', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(milliseconds: 100));
      await showFilters(tester);

      // Find the filter toggle
      final filterToggle = find.text('My Issues');
      expect(filterToggle, findsOneWidget);

      // Tap to toggle
      await tester.tap(filterToggle);
      await tester.pump(const Duration(milliseconds: 100));

      final chip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('My Issues'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('My Issues filter handles loading state gracefully', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      // Screen should work even before user login is loaded
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
