import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Singleton SecureStorageService - Use this everywhere instead of creating new instances
class SecureStorageService {
  static final FlutterSecureStorage _instance = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static FlutterSecureStorage get instance => _instance;

  // Prevent instantiation
  SecureStorageService._();

  /// Read value with graceful error handling
  static Future<String?> read({required String key}) async {
    try {
      return await _instance.read(key: key);
    } catch (e) {
      debugPrint('SecureStorage: Read error for $key: $e');
      return null;
    }
  }

  /// Write value with graceful error handling
  static Future<void> write({required String key, required String value}) async {
    try {
      await _instance.write(key: key, value: value);
      debugPrint('SecureStorage: Saved $key');
    } catch (e) {
      debugPrint('SecureStorage: Write error for $key: $e');
    }
  }

  /// Delete value with graceful error handling
  static Future<void> delete({required String key}) async {
    try {
      await _instance.delete(key: key);
      debugPrint('SecureStorage: Deleted $key');
    } catch (e) {
      debugPrint('SecureStorage: Delete error for $key: $e');
    }
  }

  /// Clear all stored data (for logout)
  static Future<void> clearAll() async {
    try {
      await _instance.deleteAll();
      debugPrint('SecureStorage: All data cleared');
    } catch (e) {
      debugPrint('SecureStorage: Clear all error: $e');
    }
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    try {
      final token = await _instance.read(key: 'github_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('SecureStorage: hasToken error: $e');
      return false;
    }
  }

  /// Get token with optional cache bypass
  static Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        debugPrint('SecureStorage: Force refresh token');
      }
      final token = await _instance.read(key: 'github_token');
      debugPrint(
        'SecureStorage: Token ${token != null ? "exists (${token.length} chars)" : "not found"}',
      );
      return token;
    } catch (e) {
      debugPrint('SecureStorage: getToken error: $e');
      return null;
    }
  }

  /// Save token
  static Future<void> saveToken(String token) async {
    try {
      await _instance.write(key: 'github_token', value: token);
      debugPrint('SecureStorage: Token saved (${token.length} chars)');
    } catch (e) {
      debugPrint('SecureStorage: saveToken error: $e');
    }
  }

  /// Delete token
  static Future<void> deleteToken() async {
    try {
      await _instance.delete(key: 'github_token');
      debugPrint('SecureStorage: Token deleted');
    } catch (e) {
      debugPrint('SecureStorage: deleteToken error: $e');
    }
  }
}
