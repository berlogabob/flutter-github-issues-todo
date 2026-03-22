import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/search_history_service.dart';

void main() {
  group('SearchHistoryService', () {
    late SearchHistoryService service;

    setUp(() {
      service = SearchHistoryService();
    });

    test('should create singleton instance', () {
      final service2 = SearchHistoryService();
      expect(identical(service, service2), isTrue);
    });

    test('should return empty history initially', () async {
      final history = await service.getHistory();
      expect(history, isEmpty);
    });

    test('should add query to history', () async {
      await service.addToHistory('test query');
      final history = await service.getHistory();
      
      expect(history, isNotEmpty);
      expect(history.first, equals('test query'));
      
      // Cleanup
      await service.clearHistory();
    });

    test('should not add empty query', () async {
      await service.addToHistory('');
      await service.addToHistory('   ');
      final history = await service.getHistory();
      
      expect(history.isEmpty, isTrue);
    });

    test('should limit history to max 10 items', () async {
      // Add 15 queries
      for (int i = 0; i < 15; i++) {
        await service.addToHistory('query $i');
      }
      
      final history = await service.getHistory();
      expect(history.length, equals(10));
      expect(history.first, equals('query 14'));
      
      // Cleanup
      await service.clearHistory();
    });

    test('should move recent query to top', () async {
      await service.addToHistory('query 1');
      await service.addToHistory('query 2');
      await service.addToHistory('query 3');
      
      // Re-add query 1
      await service.addToHistory('query 1');
      
      final history = await service.getHistory();
      expect(history.first, equals('query 1'));
      expect(history.length, equals(3));
      
      // Cleanup
      await service.clearHistory();
    });

    test('should remove specific query', () async {
      await service.addToHistory('query 1');
      await service.addToHistory('query 2');
      await service.addToHistory('query 3');
      
      await service.removeFromHistory('query 2');
      
      final history = await service.getHistory();
      expect(history, contains('query 1'));
      expect(history, isNot(contains('query 2')));
      expect(history, contains('query 3'));
      expect(history.length, equals(2));
      
      // Cleanup
      await service.clearHistory();
    });

    test('should clear all history', () async {
      await service.addToHistory('query 1');
      await service.addToHistory('query 2');
      
      await service.clearHistory();
      
      final history = await service.getHistory();
      expect(history, isEmpty);
    });

    test('should handle duplicate queries', () async {
      await service.addToHistory('query 1');
      await service.addToHistory('query 2');
      await service.addToHistory('query 1');
      
      final history = await service.getHistory();
      expect(history.length, equals(2));
      expect(history.first, equals('query 1'));
      
      // Cleanup
      await service.clearHistory();
    });
  });
}
