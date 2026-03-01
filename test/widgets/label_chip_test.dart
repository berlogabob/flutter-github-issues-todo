import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/widgets/label_chip.dart';

void main() {
  testWidgets('LabelChipWidget displays label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LabelChipWidget(label: 'bug')),
      ),
    );

    expect(find.text('bug'), findsOneWidget);
  });

  testWidgets('LabelChipWidget applies custom color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LabelChipWidget(label: 'feature', colorHex: 'ff0000'),
        ),
      ),
    );

    expect(find.text('feature'), findsOneWidget);
  });
}
