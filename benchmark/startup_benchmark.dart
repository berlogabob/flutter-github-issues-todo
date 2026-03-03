// Benchmark: Startup Time Measurement
// Measures cold start and warm start times for the application

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:gitdoit/main.dart' as app;
import 'package:gitdoit/screens/onboarding_screen.dart';
import 'package:gitdoit/screens/main_dashboard_screen.dart';

/// Measures cold start time - time from app launch to first frame rendered
class StartupBenchmark extends BenchmarkBase {
  StartupBenchmark() : super('Startup Benchmark');

  @override
  void run() {
    // This is measured externally via test
  }
}

void main() {
  group('Startup Performance Benchmarks', () {
    testWidgets('Cold start time measurement', (tester) async {
      final stopwatch = Stopwatch()..start();

      // Start the app (cold start)
      app.main();
      
      // Pump until first frame
      await tester.pump();
      await tester.pumpAndSettle();

      stopwatch.stop();
      final coldStartTime = stopwatch.elapsedMilliseconds;

      // Verify app started
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Log result
      debugPrint('=== COLD START BENCHMARK ===');
      debugPrint('Cold Start Time: ${coldStartTime}ms');
      debugPrint('Target: <1000ms');
      debugPrint('Status: ${coldStartTime < 1000 ? "PASS" : "FAIL"}');
      debugPrint('===========================');

      // Store result for reporting
      expect(coldStartTime, lessThan(2000), reason: 'Cold start should be under 2 seconds');
    });

    testWidgets('Warm start time measurement', (tester) async {
      // First start (cold)
      app.main();
      await tester.pumpAndSettle();

      // Simulate going to background and returning
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Trigger rebuild (warm start simulation)
      await tester.pump();
      await tester.pumpAndSettle();

      stopwatch.stop();
      final warmStartTime = stopwatch.elapsedMilliseconds;

      debugPrint('=== WARM START BENCHMARK ===');
      debugPrint('Warm Start Time: ${warmStartTime}ms');
      debugPrint('Target: <500ms');
      debugPrint('Status: ${warmStartTime < 500 ? "PASS" : "FAIL"}');
      debugPrint('===========================');

      expect(warmStartTime, lessThan(1000), reason: 'Warm start should be under 1 second');
    });

    testWidgets('Navigation to dashboard time', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Continue Offline'));
      
      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      final navigationTime = stopwatch.elapsedMilliseconds;

      expect(find.byType(MainDashboardScreen), findsOneWidget);

      debugPrint('=== NAVIGATION BENCHMARK ===');
      debugPrint('Navigation Time: ${navigationTime}ms');
      debugPrint('Target: <500ms');
      debugPrint('===========================');

      expect(navigationTime, lessThan(1000), reason: 'Navigation should be under 1 second');
    });

    testWidgets('Screen transition animation time', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Measure time for screen transition
      final stopwatch = Stopwatch()..start();
      
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();

      stopwatch.stop();
      final transitionTime = stopwatch.elapsedMilliseconds;

      debugPrint('=== TRANSITION BENCHMARK ===');
      debugPrint('Transition Time: ${transitionTime}ms');
      debugPrint('===========================');
    });
  });
}
