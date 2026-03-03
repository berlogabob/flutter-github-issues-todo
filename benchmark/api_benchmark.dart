// Benchmark: API Call Latency
// Measures API response times for various endpoints

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/github_api_service.dart';
import 'package:gitdoit/services/cache_service.dart';

void main() {
  group('API Performance Benchmarks', () {
    testWidgets('API call latency - Get Current User', (tester) async {
      final api = GitHubApiService();
      final cache = CacheService();

      // Clear cache for accurate measurement
      await cache.clear();

      final stopwatch = Stopwatch()..start();

      try {
        final user = await api.getCurrentUser();
        stopwatch.stop();

        debugPrint('=== API LATENCY BENCHMARK: Get User ===');
        debugPrint('Response Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('Target: <1000ms');
        debugPrint('Status: ${stopwatch.elapsedMilliseconds < 1000 ? "PASS" : "REVIEW"}');
        debugPrint('===========================');

        if (user != null) {
          debugPrint('User: ${user['login']}');
        }
      } catch (e) {
        stopwatch.stop();
        debugPrint('=== API LATENCY BENCHMARK: Get User ===');
        debugPrint('Error: $e');
        debugPrint('Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('===========================');
      }
    });

    testWidgets('API call latency - Fetch Repositories', (tester) async {
      final api = GitHubApiService();
      final cache = CacheService();

      await cache.clear();

      final stopwatch = Stopwatch()..start();

      try {
        final repos = await api.fetchMyRepositories(perPage: 30);
        stopwatch.stop();

        debugPrint('=== API LATENCY BENCHMARK: Fetch Repos ===');
        debugPrint('Response Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('Repos Fetched: ${repos.length}');
        debugPrint('Target: <1500ms');
        debugPrint('Status: ${stopwatch.elapsedMilliseconds < 1500 ? "PASS" : "REVIEW"}');
        debugPrint('===========================');
      } catch (e) {
        stopwatch.stop();
        debugPrint('=== API LATENCY BENCHMARK: Fetch Repos ===');
        debugPrint('Error: $e');
        debugPrint('Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('===========================');
      }
    });

    testWidgets('API call latency - Fetch Issues', (tester) async {
      final api = GitHubApiService();
      final cache = CacheService();

      await cache.clear();

      final stopwatch = Stopwatch()..start();

      try {
        // Using a public repo for testing
        final issues = await api.fetchIssues('flutter', 'flutter');
        stopwatch.stop();

        debugPrint('=== API LATENCY BENCHMARK: Fetch Issues ===');
        debugPrint('Response Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('Issues Fetched: ${issues.length}');
        debugPrint('Target: <2000ms');
        debugPrint('Status: ${stopwatch.elapsedMilliseconds < 2000 ? "PASS" : "REVIEW"}');
        debugPrint('===========================');
      } catch (e) {
        stopwatch.stop();
        debugPrint('=== API LATENCY BENCHMARK: Fetch Issues ===');
        debugPrint('Error: $e');
        debugPrint('Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('===========================');
      }
    });

    testWidgets('API call latency - Fetch Projects', (tester) async {
      final api = GitHubApiService();
      final cache = CacheService();

      await cache.clear();

      final stopwatch = Stopwatch()..start();

      try {
        final projects = await api.fetchProjects();
        stopwatch.stop();

        debugPrint('=== API LATENCY BENCHMARK: Fetch Projects ===');
        debugPrint('Response Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('Projects Fetched: ${projects.length}');
        debugPrint('Target: <1500ms');
        debugPrint('Status: ${stopwatch.elapsedMilliseconds < 1500 ? "PASS" : "REVIEW"}');
        debugPrint('===========================');
      } catch (e) {
        stopwatch.stop();
        debugPrint('=== API LATENCY BENCHMARK: Fetch Projects ===');
        debugPrint('Error: $e');
        debugPrint('Time: ${stopwatch.elapsedMilliseconds}ms');
        debugPrint('===========================');
      }
    });

    testWidgets('API caching effectiveness', (tester) async {
      final api = GitHubApiService();
      final cache = CacheService();

      await cache.clear();

      // First call (uncached)
      final firstStopwatch = Stopwatch()..start();
      try {
        await api.fetchMyRepositories(perPage: 30);
      } catch (_) {}
      firstStopwatch.stop();
      final firstTime = firstStopwatch.elapsedMilliseconds;

      // Second call (cached)
      final secondStopwatch = Stopwatch()..start();
      try {
        await api.fetchMyRepositories(perPage: 30);
      } catch (_) {}
      secondStopwatch.stop();
      final secondTime = secondStopwatch.elapsedMilliseconds;

      debugPrint('=== API CACHING BENCHMARK ===');
      debugPrint('First Call (uncached): ${firstTime}ms');
      debugPrint('Second Call (cached): ${secondTime}ms');
      debugPrint('Cache Improvement: ${firstTime > 0 ? ((firstTime - secondTime) / firstTime * 100).toStringAsFixed(1) : 0}%');
      debugPrint('===========================');
    });

    testWidgets('Concurrent API calls', (tester) async {
      final api = GitHubApiService();

      final stopwatch = Stopwatch()..start();

      // Make multiple concurrent API calls
      final futures = [
        api.getCurrentUser(),
        api.fetchMyRepositories(perPage: 10),
        api.fetchProjects(),
      ];

      try {
        await Future.wait(futures);
      } catch (_) {}

      stopwatch.stop();

      debugPrint('=== CONCURRENT API BENCHMARK ===');
      debugPrint('Concurrent Calls: 3');
      debugPrint('Total Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('Avg Per Call: ${(stopwatch.elapsedMilliseconds / 3).toStringAsFixed(2)}ms');
      debugPrint('===========================');
    });

    testWidgets('API retry mechanism performance', (tester) async {
      final api = GitHubApiService();

      // This tests the retry mechanism with an invalid request
      final stopwatch = Stopwatch()..start();

      try {
        // Attempt to fetch with invalid parameters
        await api.fetchIssues('', '');
      } catch (_) {
        // Expected to fail
      }

      stopwatch.stop();

      debugPrint('=== API RETRY BENCHMARK ===');
      debugPrint('Failed Request Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('(Includes retry attempts)');
      debugPrint('===========================');
    });
  });
}
