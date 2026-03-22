import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:gitdoit/services/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;
    late Directory hiveTestDir;

    setUpAll(() async {
      hiveTestDir = await Directory.systemTemp.createTemp(
        'gitdoit_cache_service_test_',
      );
      Hive.init(hiveTestDir.path);
    });

    tearDownAll(() async {
      await Hive.close();
      if (await hiveTestDir.exists()) {
        await hiveTestDir.delete(recursive: true);
      }
    });

    setUp(() async {
      cache = CacheService();
      await cache.init();
    });

    tearDown(() async {
      await cache.clear();
    });

    test('should initialize successfully', () async {
      expect(cache.hasValid('any_key'), isFalse);
    });

    test('should set and get value with default TTL', () async {
      const key = 'test_key';
      const value = {'data': 'test'};

      await cache.set(key, value);
      final result = cache.get<Map>(key);

      expect(result, isNotNull);
      expect(result?['data'], equals('test'));
    });

    test('should return null for non-existent key', () async {
      final result = cache.get<Map>('non_existent');
      expect(result, isNull);
    });

    test('should remove value', () async {
      const key = 'test_remove';
      await cache.set(key, {'data': 'test'});
      
      await cache.remove(key);
      final result = cache.get<Map>(key);
      
      expect(result, isNull);
    });

    test('should clear all cache', () async {
      await cache.set('key1', {'data': 'test1'});
      await cache.set('key2', {'data': 'test2'});
      
      await cache.clear();
      
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });

    test('should invalidate cache', () async {
      const key = 'test_invalidate';
      await cache.set(key, {'data': 'test'});
      
      await cache.invalidate(key);
      expect(cache.get(key), isNull);
    });

    test('should return stats', () async {
      await cache.set('key1', {'data': 'test1'});
      await cache.set('key2', {'data': 'test2'});
      
      final stats = cache.getStats();
      
      expect(stats['initialized'], isTrue);
      expect(stats['size'], equals(2));
      expect(stats['keys'], contains('key1'));
      expect(stats['keys'], contains('key2'));
    });

    test('should refresh cache entry', () async {
      const key = 'test_refresh';
      await cache.set(key, {'data': 'old'});
      
      final refreshed = await cache.refresh(
        key,
        () async => {'data': 'new'},
      );
      
      expect(refreshed['data'], equals('new'));
      final result = cache.get<Map>(key);
      expect(result?['data'], equals('new'));
    });

    test('hasValid should return false for expired cache', () async {
      const key = 'test_expired';
      await cache.set(key, {'data': 'test'}, ttl: const Duration(milliseconds: 100));
      
      expect(cache.hasValid(key), isTrue);
      
      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));
      
      expect(cache.hasValid(key), isFalse);
    });
  });
}
