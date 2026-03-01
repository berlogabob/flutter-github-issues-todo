import 'dart:convert';
import 'package:hive/hive.dart';

/// Cache service with TTL support
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late Box<String> _cache;
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> init() async {
    if (_isInitialized) return;
    _cache = await Hive.openBox('cache');
    _isInitialized = true;
  }

  /// Get cached value if not expired
  T? get<T>(String key) {
    if (!_isInitialized) return null;

    final data = _cache.get(key);
    if (data == null) return null;

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final expiry = DateTime.parse(decoded['expiry'] as String);

      if (DateTime.now().isAfter(expiry)) {
        _cache.delete(key);
        return null;
      }

      return jsonDecode(decoded['value'] as String) as T;
    } catch (e) {
      return null;
    }
  }

  /// Set value with TTL
  Future<void> set<T>(
    String key,
    T value, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final data = {
      'value': jsonEncode(value),
      'expiry': DateTime.now().add(ttl).toIso8601String(),
    };
    await _cache.put(key, jsonEncode(data));
  }

  /// Remove cached value
  Future<void> remove(String key) async {
    if (!_isInitialized) return;
    await _cache.delete(key);
  }

  /// Clear all cache
  Future<void> clear() async {
    if (!_isInitialized) return;
    await _cache.clear();
  }

  /// Check if cache has a valid (non-expired) value for key
  bool hasValid(String key) {
    return get(key) != null;
  }
}
