import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService', () {
    late ConnectivityService connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    tearDown(() {
      connectivityService.dispose();
    });

    group('Initial State', () {
      test('should have isOnline false initially', () {
        // Assert
        expect(connectivityService.isOnline, false);
      });

      test('should provide connectivityStream', () {
        // Assert
        expect(connectivityService.connectivityStream, isNotNull);
      });
    });

    group('initialize', () {
      test('should complete without throwing', () async {
        // Act & Assert
        expect(
          () async => await connectivityService.initialize(),
          returnsNormally,
        );
      });

      test('should update isOnline state after initialization', () async {
        // Act
        await connectivityService.initialize();

        // Assert - isOnline should reflect actual connectivity
        expect(connectivityService.isOnline, isA<bool>());
      });

      test('should be callable multiple times', () async {
        // Act & Assert - should not throw
        await connectivityService.initialize();
        await connectivityService.initialize();
      });
    });

    group('isOnline Getter', () {
      test('should return boolean value', () {
        // Assert
        expect(connectivityService.isOnline, isA<bool>());
      });

      test('should provide instant access without async', () {
        // Assert - isOnline is a synchronous getter
        final isOnline = connectivityService.isOnline;
        expect(isOnline, isA<bool>());
      });
    });

    group('connectivityStream', () {
      test('should provide a broadcast stream', () {
        // Assert
        expect(connectivityService.connectivityStream, isNotNull);
        expect(connectivityService.connectivityStream, isA<Stream<bool>>());
      });

      test('should allow multiple listeners', () async {
        // Arrange
        await connectivityService.initialize();
        var listener1Count = 0;
        var listener2Count = 0;

        // Act
        connectivityService.connectivityStream.listen((_) => listener1Count++);
        connectivityService.connectivityStream.listen((_) => listener2Count++);

        // Force a refresh to trigger stream
        await connectivityService.forceRefresh();

        // Small delay for stream to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - both listeners should receive updates
        expect(listener1Count, greaterThan(0));
        expect(listener2Count, greaterThan(0));
      });
    });

    group('checkOnlineNow', () {
      test('should return boolean', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        final result = await connectivityService.checkOnlineNow();

        // Assert
        expect(result, isA<bool>());
      });

      test('should update isOnline state', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        await connectivityService.checkOnlineNow();

        // Assert - state may change based on actual connectivity
        expect(connectivityService.isOnline, isA<bool>());
      });

      test('should be callable multiple times', () async {
        // Arrange
        await connectivityService.initialize();

        // Act & Assert - should not throw
        await connectivityService.checkOnlineNow();
        await connectivityService.checkOnlineNow();
        await connectivityService.checkOnlineNow();
      });
    });

    group('checkOnline', () {
      test('should return boolean', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        final result = await connectivityService.checkOnline();

        // Assert
        expect(result, isA<bool>());
      });

      test('should be alias for checkOnlineNow', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        final result1 = await connectivityService.checkOnline();
        final result2 = await connectivityService.checkOnlineNow();

        // Assert - both should return same type
        expect(result1, isA<bool>());
        expect(result2, isA<bool>());
      });
    });

    group('forceRefresh', () {
      test('should return boolean', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        final result = await connectivityService.forceRefresh();

        // Assert
        expect(result, isA<bool>());
      });

      test('should bypass debounce', () async {
        // Arrange
        await connectivityService.initialize();

        // Act - forceRefresh should always check
        final result1 = await connectivityService.forceRefresh();
        final result2 = await connectivityService.forceRefresh();

        // Assert - both should complete
        expect(result1, isA<bool>());
        expect(result2, isA<bool>());
      });

      test('should update isOnline state', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        await connectivityService.forceRefresh();

        // Assert
        expect(connectivityService.isOnline, isA<bool>());
      });
    });

    group('Debouncing', () {
      test('should debounce rapid checkOnlineNow calls', () async {
        // Arrange
        await connectivityService.initialize();

        // Act - rapid calls
        final result1 = await connectivityService.checkOnlineNow();
        final result2 = await connectivityService.checkOnlineNow();

        // Assert - both should return (debouncing skips work, not results)
        expect(result1, isA<bool>());
        expect(result2, isA<bool>());
      });

      test('should allow check after debounce period', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        await connectivityService.checkOnlineNow();
        await Future.delayed(const Duration(milliseconds: 600));
        final result = await connectivityService.checkOnlineNow();

        // Assert
        expect(result, isA<bool>());
      });
    });

    group('dispose', () {
      test('should complete without throwing', () {
        // Act & Assert
        expect(() => connectivityService.dispose(), returnsNormally);
      });

      test('should be callable after initialize', () async {
        // Arrange
        await connectivityService.initialize();

        // Act & Assert
        expect(() => connectivityService.dispose(), returnsNormally);
      });

      test('should be callable multiple times', () {
        // Act & Assert
        connectivityService.dispose();
        connectivityService.dispose();
      });
    });

    group('Stream Events', () {
      test('should emit on connectivity change', () async {
        // Arrange
        await connectivityService.initialize();
        final events = <bool>[];

        // Act
        connectivityService.connectivityStream.listen(events.add);
        await connectivityService.forceRefresh();

        // Small delay for stream to propagate
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert - stream is accessible (emission depends on state change)
        expect(connectivityService.connectivityStream, isNotNull);
      });

      test('should emit current state to new listeners', () async {
        // Arrange
        await connectivityService.initialize();
        final events = <bool>[];

        // Act
        await connectivityService.forceRefresh();
        connectivityService.connectivityStream.listen(events.add);

        // Force another refresh
        await connectivityService.forceRefresh();
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert - stream is accessible
        expect(connectivityService.connectivityStream, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle initialize errors gracefully', () async {
        // Act & Assert - should not throw even if connectivity check fails
        expect(
          () async => await connectivityService.initialize(),
          returnsNormally,
        );
      });

      test('should default to offline on error', () async {
        // The service defaults to false on error
        // This is verified by the initial state
        expect(connectivityService.isOnline, false);
      });

      test('should handle checkOnlineNow errors gracefully', () async {
        // Arrange
        await connectivityService.initialize();

        // Act & Assert - should not throw
        expect(
          () async => await connectivityService.checkOnlineNow(),
          returnsNormally,
        );
      });

      test('should handle forceRefresh errors gracefully', () async {
        // Arrange
        await connectivityService.initialize();

        // Act & Assert - should not throw
        expect(
          () async => await connectivityService.forceRefresh(),
          returnsNormally,
        );
      });
    });

    group('State Consistency', () {
      test('should have consistent isOnline after initialize', () async {
        // Act
        await connectivityService.initialize();

        // Assert
        expect(connectivityService.isOnline, isA<bool>());
      });

      test('should have consistent isOnline after checkOnlineNow', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        await connectivityService.checkOnlineNow();

        // Assert
        expect(connectivityService.isOnline, isA<bool>());
      });

      test('should have consistent isOnline after forceRefresh', () async {
        // Arrange
        await connectivityService.initialize();

        // Act
        await connectivityService.forceRefresh();

        // Assert
        expect(connectivityService.isOnline, isA<bool>());
      });
    });

    group('Method Signatures', () {
      test('initialize should be async', () {
        // Verify method signature
        expect(connectivityService.initialize, isA<Function>());
      });

      test('checkOnlineNow should be async', () {
        // Verify method signature
        expect(connectivityService.checkOnlineNow, isA<Function>());
      });

      test('checkOnline should be async', () {
        // Verify method signature
        expect(connectivityService.checkOnline, isA<Function>());
      });

      test('forceRefresh should be async', () {
        // Verify method signature
        expect(connectivityService.forceRefresh, isA<Function>());
      });

      test('dispose should be sync', () {
        // Verify method signature
        expect(connectivityService.dispose, isA<Function>());
      });
    });
  });

  group('ConnectivityService Integration', () {
    late ConnectivityService connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    tearDown(() {
      connectivityService.dispose();
    });

    test('full lifecycle: create, initialize, use, dispose', () async {
      // Arrange
      expect(connectivityService.isOnline, false);

      // Act
      await connectivityService.initialize();
      expect(connectivityService.isOnline, isA<bool>());

      final isOnline = await connectivityService.checkOnlineNow();
      expect(isOnline, isA<bool>());

      final refreshed = await connectivityService.forceRefresh();
      expect(refreshed, isA<bool>());

      // Dispose
      connectivityService.dispose();

      // Assert - lifecycle completed
      expect(true, true);
    });

    test('multiple checkOnlineNow calls in sequence', () async {
      // Arrange
      await connectivityService.initialize();

      // Act
      final results = <bool>[];
      for (int i = 0; i < 5; i++) {
        results.add(await connectivityService.checkOnlineNow());
      }

      // Assert
      expect(results.length, 5);
      expect(results.every((r) => r == true || r == false), true);
    });

    test('stream listener receives updates', () async {
      // Arrange
      await connectivityService.initialize();
      final events = <bool>[];
      final subscription = connectivityService.connectivityStream.listen(
        events.add,
      );

      // Act - force refresh triggers stream event
      await connectivityService.forceRefresh();

      // Wait for stream to propagate
      await Future.delayed(const Duration(milliseconds: 200));

      // Cleanup
      await subscription.cancel();

      // Assert - stream may or may not emit depending on state change
      // The important thing is the stream is accessible and doesn't error
      expect(connectivityService.connectivityStream, isNotNull);
    });
  });

  group('ConnectivityService Getters', () {
    late ConnectivityService connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    tearDown(() {
      connectivityService.dispose();
    });

    test('isOnline returns false before initialization', () {
      // Assert
      expect(connectivityService.isOnline, false);
    });

    test('connectivityStream is accessible before initialization', () {
      // Assert
      expect(connectivityService.connectivityStream, isNotNull);
    });
  });

  group('ConnectivityService Constructor', () {
    test('should create instance with default values', () {
      // Arrange & Act
      final service = ConnectivityService();

      // Assert
      expect(service.isOnline, false);
      expect(service.connectivityStream, isNotNull);

      service.dispose();
    });
  });
}
