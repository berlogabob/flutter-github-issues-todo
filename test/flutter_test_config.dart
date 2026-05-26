import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final harness = TestHarness.shared;

  await harness.install();

  setUp(() async {
    await harness.reset();
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  await testMain();
}
