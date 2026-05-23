import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/settings_screen.dart';
import 'package:hive_ce/hive_ce.dart';
import 'dart:io';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    hiveTestDir = await Directory.systemTemp.createTemp(
      'gitdoit_settings_project_test_',
    );
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveTestDir.exists()) {
      await hiveTestDir.delete(recursive: true);
    }
  });

  group('Task 15.4 - Project Picker', () {
    Future<void> pumpSettings(WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, _) => const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('Settings screen displays project controls', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Default Project'), findsOneWidget);
      expect(find.byIcon(Icons.view_kanban), findsWidgets);
    });

    testWidgets('project picker trigger is present', (tester) async {
      await pumpSettings(tester);

      final projectTileLabel = find.text('Default Project');
      expect(projectTileLabel, findsOneWidget);
    });

    testWidgets('project section remains stable after additional pumps', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Default Project'), findsOneWidget);
    });

    testWidgets('defaults section remains visible', (tester) async {
      await pumpSettings(tester);

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Defaults'), findsOneWidget);
      expect(find.text('Default Project'), findsOneWidget);
    });
  });
}
