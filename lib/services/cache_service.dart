import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Cache service with TTL (Time-To-Live) support for offline-first architecture.
///
/// This service provides a persistent cache layer using Hive storage with
/// automatic expiration based on configurable TTL values.
///
/// Features:
/// - TTL-based cache expiration (default: 5 minutes)
/// - Automatic initialization on first use
/// - Thread-safe operations
/// - Comprehensive error handling and logging
/// - Cache miss tracking for debugging
///
/// Usage:
/// ```dart
/// final cache = CacheService();
/// await cache.init();
///
/// // Set with default TTL (5 minutes)
/// await cache.set('user_data', userData);
///
/// // Set with custom TTL
/// await cache.set('session', sessionData, ttl: Duration(hours: 1));
///
/// // Get value (returns null if expired or not found)
/// final data = cache.get<Map>('user_data');
///
/// // Check if cache has valid (non-expired) value
/// if (cache.hasValid('user_data')) {
///   // Use cached value
/// }
/// ```
///
/// Cache Keys Convention:
/// - `assignees_${owner}_${repo}` - Repository assignees
/// - `labels_${owner}_${repo}` - Repository labels
/// - `current_user_login` - Authenticated user login
/// - `repos_page_${page}` - Paginated repository lists
/// - `projects_${user}` - User projects
/// - `issues_${owner}_${repo}_${state}` - Repository issues
class CacheService {
  /// Singleton instance for global access
  static final CacheService _instance = CacheService._internal();

  /// Factory constructor returns singleton instance
  factory CacheService() => _instance;

  /// Private internal constructor for singleton pattern
  CacheService._internal();

  /// Hive box for persistent cache storage
  late Box<String> _cache;

  /// Initialization flag to prevent race conditions
  bool _isInitialized = false;

  /// Lock to prevent concurrent initialization
  bool _isInitializing = false;

  /// Default TTL for cache entries (5 minutes)
  static const Duration defaultTtl = Duration(minutes: 5);

  /// TTL for user session data (1 hour)
  static const Duration sessionTtl = Duration(hours: 1);

  /// Initialize the cache service.
  ///
  /// Opens the Hive box for cache storage. Safe to call multiple times -
  /// subsequent calls will return immediately if already initialized.
  ///
  /// Example:
  /// ```dart
  /// final cache = CacheService();
  /// await cache.init();
  /// ```
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('CacheService: Already initialized');
      return;
    }

    if (_isInitializing) {
      debugPrint('CacheService: Initialization in progress, waiting...');
      // Wait for initialization to complete
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('CacheService: Initializing cache...');
      _cache = await Hive.openBox('cache');
      _isInitialized = true;
      debugPrint('CacheService: Initialized with ${_cache.length} cached items');
    } catch (e, stackTrace) {
      debugPrint('CacheService: Initialization failed: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Get cached value if not expired (auto-initializes if needed).
  ///
  /// Returns the cached value if it exists and has not expired.
  /// Returns `null` if:
  /// - Key does not exist
  /// - Value has expired (TTL exceeded)
  /// - Cache is not initialized
  /// - An error occurs during retrieval
  ///
  /// [key] The cache key to retrieve.
  /// [T] The expected type of the cached value.
  ///
  /// Returns the cached value of type `T`, or `null` if not found/expired.
  ///
  /// Example:
  /// ```dart
  /// final userData = cache.get<Map>('user_data');
  /// if (userData != null) {
  ///   // Use cached data
  /// } else {
  ///   // Cache miss - fetch from network
  /// }
  /// ```
  T? get<T>(String key) {
    // Auto-initialize if needed (synchronous check)
    if (!_isInitialized) {
      debugPrint('CacheService: Not initialized, attempting sync init...');
      // Try to initialize synchronously (will complete async)
      init();
      return null;
    }

    try {
      final data = _cache.get(key);
      if (data == null) {
        debugPrint('CacheService: Cache MISS for key: $key');
        return null;
      }

      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final expiry = DateTime.parse(decoded['expiry'] as String);

      // Check if expired
      if (DateTime.now().isAfter(expiry)) {
        debugPrint('CacheService: Cache EXPIRED for key: $key (expired at $expiry)');
        _cache.delete(key); // Clean up expired entry
        return null;
      }

      debugPrint('CacheService: Cache HIT for key: $key');
      return jsonDecode(decoded['value'] as String) as T;
    } catch (e, stackTrace) {
      debugPrint('CacheService: Error getting key $key: $e');
      debugPrint('Stack: $stackTrace');
      // On error, return null (cache miss behavior)
      return null;
    }
  }

  /// Set value with TTL (Time-To-Live).
  ///
  /// Stores the value in the cache with an expiration time.
  /// The value will be automatically considered expired after [ttl] duration.
  ///
  /// [key] The cache key to store.
  /// [value] The value to cache (must be JSON-serializable).
  /// [ttl] Time-to-live duration (default: 5 minutes).
  ///
  /// Example:
  /// ```dart
  /// // Default TTL (5 minutes)
  /// await cache.set('repos', repoList);
  ///
  /// // Custom TTL (1 hour)
  /// await cache.set('session', sessionData, ttl: Duration(hours: 1));
  /// ```
  Future<void> set<T>(
    String key,
    T value, {
    Duration ttl = defaultTtl,
  }) async {
    // Ensure initialization
    if (!_isInitialized) {
      await init();
    }

    try {
      final data = {
        'value': jsonEncode(value),
        'expiry': DateTime.now().add(ttl).toIso8601String(),
      };
      await _cache.put(key, jsonEncode(data));
      debugPrint('CacheService: Set key: $key with TTL: ${ttl.inSeconds}s');
    } catch (e, stackTrace) {
      debugPrint('CacheService: Error setting key $key: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Remove cached value.
  ///
  /// [key] The cache key to remove.
  ///
  /// Returns silently if key does not exist or cache is not initialized.
  Future<void> remove(String key) async {
    if (!_isInitialized) {
      debugPrint('CacheService: Not initialized, cannot remove key: $key');
      return;
    }

    try {
      await _cache.delete(key);
      debugPrint('CacheService: Removed key: $key');
    } catch (e, stackTrace) {
      debugPrint('CacheService: Error removing key $key: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Clear all cache.
  ///
  /// Removes all cached entries. Use with caution as this will
  /// invalidate all cached data.
  ///
  /// Example:
  /// ```dart
  /// // Clear cache on logout
  /// await cache.clear();
  /// ```
  Future<void> clear() async {
    if (!_isInitialized) {
      debugPrint('CacheService: Not initialized, cannot clear');
      return;
    }

    try {
      await _cache.clear();
      debugPrint('CacheService: Cleared all cache');
    } catch (e, stackTrace) {
      debugPrint('CacheService: Error clearing cache: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Check if cache has a valid (non-expired) value for key.
  ///
  /// [key] The cache key to check.
  ///
  /// Returns `true` if the key exists and has not expired.
  /// Returns `false` if the key does not exist, is expired, or an error occurs.
  ///
  /// Example:
  /// ```dart
  /// if (cache.hasValid('user_data')) {
  ///   // Use cached value
  ///   final data = cache.get('user_data');
  /// } else {
  ///   // Fetch fresh data
  /// }
  /// ```
  bool hasValid(String key) {
    return get(key) != null;
  }

  /// Invalidate cache entry immediately.
  ///
  /// Similar to [remove] but with explicit logging for cache invalidation events.
  /// Use this when you want to force a refresh of cached data.
  ///
  /// [key] The cache key to invalidate.
  /// [reason] Optional reason for invalidation (for debugging).
  Future<void> invalidate(String key, {String? reason}) async {
    if (!_isInitialized) {
      return;
    }

    try {
      final existed = _cache.containsKey(key);
      await _cache.delete(key);
      debugPrint(
        'CacheService: Invalidated key: $key'
        '${reason != null ? ' (reason: $reason)' : ''}'
        '${existed ? '' : ' (did not exist)'}',
      );
    } catch (e, stackTrace) {
      debugPrint('CacheService: Error invalidating key $key: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Get cache statistics for debugging.
  ///
  /// Returns a map with cache statistics:
  /// - `size`: Number of cached items
  /// - `keys`: List of all cache keys
  /// - `initialized`: Whether cache is initialized
  ///
  /// Example:
  /// ```dart
  /// final stats = cache.getStats();
  /// debugPrint('Cache has ${stats['size']} items');
  /// ```
  Map<String, dynamic> getStats() {
    if (!_isInitialized) {
      return {'initialized': false, 'size': 0, 'keys': []};
    }

    try {
      return {
        'initialized': true,
        'size': _cache.length,
        'keys': _cache.keys.toList(),
      };
    } catch (e, stackTrace) {
      debugPrint('CacheService: Error getting stats: $e');
      debugPrint('Stack: $stackTrace');
      return {'initialized': true, 'size': -1, 'keys': [], 'error': e.toString()};
    }
  }

  /// Refresh cache entry by executing a fetch function.
  ///
  /// Invalidates the existing cache entry (if any) and fetches fresh data.
  /// This is useful for pull-to-refresh scenarios.
  ///
  /// [key] The cache key to refresh.
  /// [fetch] Async function to fetch fresh data.
  /// [ttl] Optional custom TTL for the refreshed data.
  ///
  /// Returns the freshly fetched data.
  ///
  /// Example:
  /// ```dart
  /// final repos = await cache.refresh(
  ///   'repos_page_1',
  ///   () => githubApi.fetchMyRepositories(page: 1),
  /// );
  /// ```
  Future<T> refresh<T>(
    String key,
    Future<T> Function() fetch, {
    Duration? ttl,
  }) async {
    // Invalidate existing cache first
    await invalidate(key, reason: 'manual refresh');

    // Fetch fresh data
    final data = await fetch();

    // Cache the fresh data
    await set(key, data, ttl: ttl ?? defaultTtl);

    return data;
  }
}
