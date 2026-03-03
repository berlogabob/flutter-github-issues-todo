// Benchmark: Image Loading Performance
// Measures image load times for cached and uncached images

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gitdoit/constants/app_colors.dart';

void main() {
  group('Image Loading Benchmarks', () {
    testWidgets('Cached image load time', (tester) async {
      // Using a reliable test image URL
      const imageUrl = 'https://via.placeholder.com/100';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      
      // Wait for image to load
      await tester.pumpAndSettle();
      
      stopwatch.stop();

      debugPrint('=== CACHED IMAGE BENCHMARK ===');
      debugPrint('Image Load Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('Target: <100ms (cached)');
      debugPrint('===========================');

      // Image should be loaded
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('Multiple cached images load time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 50,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: 'https://via.placeholder.com/100?text=$index',
                  placeholder: (context, url) => Container(
                    color: AppColors.cardBackground,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      debugPrint('=== MULTIPLE CACHED IMAGES BENCHMARK ===');
      debugPrint('Images: 50');
      debugPrint('Total Load Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('Avg Per Image: ${(stopwatch.elapsedMilliseconds / 50).toStringAsFixed(2)}ms');
      debugPrint('===========================');
    });

    testWidgets('Image cache efficiency', (tester) async {
      // Load same image multiple times
      const imageUrl = 'https://via.placeholder.com/100';
      
      final loadTimes = <int>[];

      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();
        await tester.pumpAndSettle();
        stopwatch.stop();
        loadTimes.add(stopwatch.elapsedMilliseconds);
      }

      final avgTime = loadTimes.reduce((a, b) => a + b) / loadTimes.length;
      final firstLoad = loadTimes.first;
      final lastLoad = loadTimes.last;

      debugPrint('=== IMAGE CACHE EFFICIENCY BENCHMARK ===');
      debugPrint('First Load: ${firstLoad}ms');
      debugPrint('Last Load (cached): ${lastLoad}ms');
      debugPrint('Average: ${avgTime.toStringAsFixed(2)}ms');
      debugPrint('Cache Improvement: ${((firstLoad - lastLoad) / firstLoad * 100).toStringAsFixed(1)}%');
      debugPrint('===========================');
    });

    testWidgets('Image with different sizes', (tester) async {
      final sizes = [50, 100, 200, 400];
      final loadTimes = <int>[];

      for (final size in sizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CachedNetworkImage(
                imageUrl: 'https://via.placeholder.com/$size',
                imageBuilder: (context, imageProvider) => Container(
                  width: size.toDouble(),
                  height: size.toDouble(),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();
        await tester.pumpAndSettle();
        stopwatch.stop();
        loadTimes.add(stopwatch.elapsedMilliseconds);
      }

      debugPrint('=== IMAGE SIZE BENCHMARK ===');
      for (int i = 0; i < sizes.length; i++) {
        debugPrint('${sizes[i]}x${sizes[i]}: ${loadTimes[i]}ms');
      }
      debugPrint('===========================');
    });

    testWidgets('Image error handling performance', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CachedNetworkImage(
              imageUrl: 'https://invalid-url-that-does-not-exist.com/image.jpg',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      debugPrint('=== IMAGE ERROR HANDLING BENCHMARK ===');
      debugPrint('Error Detection Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('===========================');

      // Error widget should be displayed
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}
