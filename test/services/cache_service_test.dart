import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/cache_service.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late CacheService cacheService;

  setUpAll(() async {
    Hive.init('test_cache');
  });

  setUp(() async {
    cacheService = CacheService();
    await cacheService.init();
  });

  tearDown(() async {
    await cacheService.clear();
  });

  test('set and get value', () async {
    await cacheService.set('test_key', 'test_value');

    final result = cacheService.get<String>('test_key');

    expect(result, 'test_value');
  });

  test('get returns null for non-existent key', () {
    final result = cacheService.get<String>('non_existent');

    expect(result, isNull);
  });

  test('set with TTL expires value', () async {
    await cacheService.set(
      'ttl_key',
      'ttl_value',
      ttl: const Duration(milliseconds: 100),
    );

    // Should exist immediately
    expect(cacheService.get<String>('ttl_key'), 'ttl_value');

    // Wait for expiration
    await Future.delayed(const Duration(milliseconds: 150));

    // Should be expired
    expect(cacheService.get<String>('ttl_key'), isNull);
  });

  test('remove deletes value', () async {
    await cacheService.set('remove_key', 'remove_value');
    await cacheService.remove('remove_key');

    expect(cacheService.get<String>('remove_key'), isNull);
  });

  test('clear removes all values', () async {
    await cacheService.set('key1', 'value1');
    await cacheService.set('key2', 'value2');

    await cacheService.clear();

    expect(cacheService.get<String>('key1'), isNull);
    expect(cacheService.get<String>('key2'), isNull);
  });
}
