import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const Size defaultTestDesignSize = Size(360, 690);

/// Builds the standard widget-test shell used by GitDoIt screens.
Widget buildTestApp(
  Widget child, {
  List<Object?> overrides = const [],
  Size designSize = defaultTestDesignSize,
  ThemeData? theme,
  bool wrapWithProviderScope = true,
}) {
  Widget app = ScreenUtilInit(
    designSize: designSize,
    builder: (context, _) =>
        MaterialApp(theme: theme ?? ThemeData.dark(), home: child),
  );

  if (wrapWithProviderScope) {
    app = ProviderScope(overrides: overrides.cast(), child: app);
  }

  return app;
}

extension WidgetTesterPumpHelpers on WidgetTester {
  Future<void> pumpTestApp(
    Widget child, {
    List<Object?> overrides = const [],
    Size designSize = defaultTestDesignSize,
    ThemeData? theme,
    bool wrapWithProviderScope = true,
  }) async {
    await pumpWidget(
      buildTestApp(
        child,
        overrides: overrides,
        designSize: designSize,
        theme: theme,
        wrapWithProviderScope: wrapWithProviderScope,
      ),
    );
  }

  Future<void> pumpAndSettleTestApp(
    Widget child, {
    List<Object?> overrides = const [],
    Size designSize = defaultTestDesignSize,
    ThemeData? theme,
    bool wrapWithProviderScope = true,
    Duration duration = const Duration(milliseconds: 100),
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await pumpTestApp(
      child,
      overrides: overrides,
      designSize: designSize,
      theme: theme,
      wrapWithProviderScope: wrapWithProviderScope,
    );
    await pumpAndSettle(duration, phase, timeout);
  }
}
