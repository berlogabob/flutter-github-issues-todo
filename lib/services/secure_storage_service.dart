import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Singleton SecureStorageService - Use this everywhere instead of creating new instances
class SecureStorageService {
  static final FlutterSecureStorage _instance = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static FlutterSecureStorage get instance => _instance;

  // Prevent instantiation
  SecureStorageService._();

  /// Clear all stored data (for logout)
  static Future<void> clearAll() async {
    await _instance.deleteAll();
    debugPrint('SecureStorage: All data cleared');
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final token = await _instance.read(key: 'github_token');
    return token != null && token.isNotEmpty;
  }

  /// Get token with optional cache bypass
  static Future<String?> getToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      debugPrint('SecureStorage: Force refresh token');
    }
    final token = await _instance.read(key: 'github_token');
    debugPrint('SecureStorage: Token ${token != null ? "exists (${token.length} chars)" : "not found"}');
    return token;
  }

  /// Save token
  static Future<void> saveToken(String token) async {
    await _instance.write(key: 'github_token', value: token);
    debugPrint('SecureStorage: Token saved (${token.length} chars)');
  }

  /// Delete token
  static Future<void> deleteToken() async {
    await _instance.delete(key: 'github_token');
    debugPrint('SecureStorage: Token deleted');
  }
}
