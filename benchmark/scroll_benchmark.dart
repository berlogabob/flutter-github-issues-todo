// Benchmark: Scroll Performance Measurement
// Measures FPS and scroll performance for long lists

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/constants/app_colors.dart';

/// Scroll Performance Benchmark
/// Tests scrolling performance with 1000 items
void main() {
  group('Scroll Performance Benchmarks', () {
    testWidgets('Scroll FPS with 1000 items', (tester) async {
      // Create a list with 1000 items
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: ListView.builder(
              itemCount: 1000,
              itemBuilder: (context, index) {
                return Container(
                  height: 60,
                  padding: const EdgeInsets.all(16),
                  child: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Measure scroll performance
      final stopwatch = Stopwatch()..start();
      
      // Scroll down
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pump();
      
      // Scroll more
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pump();

      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pump();

      stopwatch.stop();

      final scrollTime = stopwatch.elapsedMilliseconds;
      final avgTimePerScroll = scrollTime / 3;

      debugPrint('=== SCROLL FPS BENCHMARK ===');
      debugPrint('Items: 1000');
      debugPrint('Total Scroll Time: ${scrollTime}ms');
      debugPrint('Avg Time Per Scroll: ${avgTimePerScroll.toStringAsFixed(2)}ms');
      debugPrint('Estimated FPS: ${(1000 / avgTimePerScroll * 16).toStringAsFixed(1)}');
      debugPrint('Target FPS: 60');
      debugPrint('===========================');

      // Verify items are rendered
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 999'), findsWidgets);
    });

    testWidgets('Scroll jank detection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: ListView.builder(
              itemCount: 500,
              itemBuilder: (context, index) {
                return Card(
                  color: AppColors.cardBackground,
                  child: ListTile(
                    title: Text('Issue #$index'),
                    subtitle: Text('Description for issue $index'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform multiple scrolls and measure consistency
      final scrollTimes = <int>[];
      
      for (int i = 0; i < 5; i++) {
        final stopwatch = Stopwatch()..start();
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump();
        stopwatch.stop();
        scrollTimes.add(stopwatch.elapsedMilliseconds);
      }

      final avgTime = scrollTimes.reduce((a, b) => a + b) / scrollTimes.length;
      final maxTime = scrollTimes.reduce((a, b) => a > b ? a : b);
      final minTime = scrollTimes.reduce((a, b) => a < b ? a : b);
      final jank = maxTime - minTime;

      debugPrint('=== SCROLL JANK BENCHMARK ===');
      debugPrint('Scrolls: 5');
      debugPrint('Avg Time: ${avgTime.toStringAsFixed(2)}ms');
      debugPrint('Min Time: ${minTime}ms');
      debugPrint('Max Time: ${maxTime}ms');
      debugPrint('Jank (Max - Min): ${jank}ms');
      debugPrint('Target Jank: <50ms');
      debugPrint('Status: ${jank < 50 ? "PASS" : "REVIEW"}');
      debugPrint('===========================');
    });

    testWidgets('Scroll with complex widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: ListView.builder(
              itemCount: 200,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.orangePrimary,
                            child: Text('$index'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Issue Title $index',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Description text for issue $index',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: const Text('Open'),
                            backgroundColor: AppColors.issueOpen,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          Chip(
                            label: const Text('bug'),
                            backgroundColor: AppColors.red.withValues(alpha: 0.2),
                          ),
                          Chip(
                            label: const Text('urgent'),
                            backgroundColor: AppColors.orangePrimary.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();
      
      // Scroll through complex list
      for (int i = 0; i < 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }

      stopwatch.stop();

      debugPrint('=== COMPLEX WIDGET SCROLL BENCHMARK ===');
      debugPrint('Complex Items: 200');
      debugPrint('Scroll Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('===========================');
    });

    testWidgets('Scroll to end and back', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: ListView.builder(
              itemCount: 1000,
              itemBuilder: (context, index) => SizedBox(
                height: 50,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Scroll to end
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Scroll back to start
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();

      stopwatch.stop();

      debugPrint('=== SCROLL ROUND-TRIP BENCHMARK ===');
      debugPrint('Round-trip Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('===========================');

      // Verify first item is visible again
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('Scroll physics performance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: List.generate(
                500,
                (index) => SizedBox(
                  height: 60,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test bounce physics
      final stopwatch = Stopwatch()..start();
      
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      stopwatch.stop();

      debugPrint('=== SCROLL PHYSICS BENCHMARK ===');
      debugPrint('Bounce Scroll Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('===========================');
    });
  });
}
