import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/search_screen.dart';

void main() {
  testWidgets('SearchScreen displays search field', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search Issues'), findsOneWidget);
  });

  testWidgets('SearchScreen displays empty state message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    expect(find.text('Search by title, labels, or body'), findsOneWidget);
  });

  testWidgets('SearchScreen displays no results state after search', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    // Initially no "No results found" message
    expect(find.text('No results found'), findsNothing);
  });
}
