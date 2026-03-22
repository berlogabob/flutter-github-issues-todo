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

  static bool _isSensitiveKey(String key) {
    return key == 'github_token' || key == 'auth_type';
  }

  static String _safeKeyLabel(String key) {
    return _isSensitiveKey(key) ? 'sensitive key' : key;
  }

  /// Read value with graceful error handling
  static Future<String?> read({required String key}) async {
    try {
      return await _instance.read(key: key);
    } catch (e) {
      debugPrint(
        'SecureStorage: Read error for ${_safeKeyLabel(key)}: ${e.runtimeType}',
      );
      if (_isSensitiveKey(key)) {
        throw Exception('Unable to access saved authentication data.');
      }
      return null;
    }
  }

  /// Write value with graceful error handling
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _instance.write(key: key, value: value);
      debugPrint('SecureStorage: Saved ${_safeKeyLabel(key)}');
    } catch (e) {
      debugPrint(
        'SecureStorage: Write error for ${_safeKeyLabel(key)}: ${e.runtimeType}',
      );
      if (_isSensitiveKey(key)) {
        throw Exception('Unable to securely save authentication settings.');
      }
    }
  }

  /// Delete value with graceful error handling
  static Future<void> delete({required String key}) async {
    try {
      await _instance.delete(key: key);
      debugPrint('SecureStorage: Deleted ${_safeKeyLabel(key)}');
    } catch (e) {
      debugPrint(
        'SecureStorage: Delete error for ${_safeKeyLabel(key)}: ${e.runtimeType}',
      );
      if (_isSensitiveKey(key)) {
        throw Exception('Unable to clear saved authentication settings.');
      }
    }
  }

  /// Clear all stored data (for logout)
  static Future<void> clearAll() async {
    try {
      await _instance.deleteAll();
      debugPrint('SecureStorage: All data cleared');
    } catch (e) {
      debugPrint('SecureStorage: Clear all error: ${e.runtimeType}');
    }
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    try {
      final token = await _instance.read(key: 'github_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('SecureStorage: hasToken error: ${e.runtimeType}');
      return false;
    }
  }

  /// Get token with optional cache bypass
  static Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        debugPrint('SecureStorage: Force refresh token');
      }
      return await _instance.read(key: 'github_token');
    } catch (e) {
      debugPrint('SecureStorage: getToken error: ${e.runtimeType}');
      throw Exception(
        'Unable to access saved authentication data. Please login again.',
      );
    }
  }

  /// Save token
  static Future<void> saveToken(String token) async {
    try {
      await _instance.write(key: 'github_token', value: token);
      debugPrint('SecureStorage: Token saved');
    } catch (e) {
      debugPrint('SecureStorage: saveToken error: ${e.runtimeType}');
      throw Exception('Failed to securely save authentication token.');
    }
  }

  /// Delete token
  static Future<void> deleteToken() async {
    try {
      await _instance.delete(key: 'github_token');
      debugPrint('SecureStorage: Token deleted');
    } catch (e) {
      debugPrint('SecureStorage: deleteToken error: ${e.runtimeType}');
      throw Exception('Failed to clear saved authentication token.');
    }
  }
}
