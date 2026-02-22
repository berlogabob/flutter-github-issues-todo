import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GitDoIt app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GitDoItApp());

    // Verify that the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
