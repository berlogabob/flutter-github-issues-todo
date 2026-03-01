import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/widgets/status_badge.dart';
import 'package:gitdoit/models/item.dart';

void main() {
  testWidgets('StatusBadge displays open status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge(status: ItemStatus.open)),
      ),
    );

    final finder = find.byType(Container);
    expect(finder, findsOneWidget);

    final container = tester.widget<Container>(finder);
    expect(container.decoration, isA<BoxDecoration>());
  });

  testWidgets('StatusBadge displays closed status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge(status: ItemStatus.closed)),
      ),
    );

    final finder = find.byType(Container);
    expect(finder, findsOneWidget);
  });
}
