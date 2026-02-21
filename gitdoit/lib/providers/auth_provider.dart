import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/logger.dart';

/// Authentication Provider - Manages GitHub PAT authentication state
///
/// OFFLINE-FIRST: App works without authentication
/// Token validation happens when online
class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // State
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _username;
  bool _isOfflineMode = false;

  // Getters
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String? get username => _username;
  bool get isOfflineMode => _isOfflineMode;

  /// Load saved token from secure storage (don't auto-validate)
  Future<void> loadSavedToken() async {
    Logger.d('Loading saved token', context: 'Auth');

    try {
      final token = await _storage.read(key: 'github_token');
      if (token != null && token.isNotEmpty) {
        _token = token;
        _isOfflineMode = false;
        Logger.i(
          'Token loaded from storage (not validated yet)',
          context: 'Auth',
        );

        // Try to validate if online
        await _tryValidateToken(token);
      } else {
        _isOfflineMode = true;
        Logger.d('No saved token - offline mode', context: 'Auth');
      }
    } catch (e) {
      Logger.e('Failed to load token', error: e, context: 'Auth');
      _isOfflineMode = true;
    }

    notifyListeners();
  }

  /// Try to validate token (silent, doesn't block UI)
  Future<void> _tryValidateToken(String token) async {
    try {
      await _validateTokenWithGitHub(token);
    } catch (e) {
      Logger.w('Token validation failed - will retry later', context: 'Auth');
      _isOfflineMode = true;
      notifyListeners();
    }
  }

  /// Validate and save token
  Future<void> validateAndSaveToken(String token) async {
    Logger.i('Validating and saving token', context: 'Auth');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate with GitHub API
      await _validateTokenWithGitHub(token);

      if (_isAuthenticated) {
        // Save token
        await _storage.write(key: 'github_token', value: token);
        _token = token;
        _isOfflineMode = false;
        Logger.i('Token saved and validated', context: 'Auth');
      }
    } catch (e) {
      Logger.e('Token validation failed', error: e, context: 'Auth');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _isOfflineMode = true;
      // Still save token for later validation
      await _storage.write(key: 'github_token', value: token);
      _token = token;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate token with GitHub API
  Future<void> _validateTokenWithGitHub(String token) async {
    Logger.d('Validating token with GitHub API', context: 'Auth');

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'GitDoIt-App',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _username = data['login'] ?? 'GitHub User';
        _token = token;
        _isAuthenticated = true;
        _errorMessage = null;
        _isOfflineMode = false;
        Logger.i('Token validated for user: $_username', context: 'Auth');
      } else if (response.statusCode == 401) {
        _isAuthenticated = false;
        _errorMessage =
            'Invalid token. Please check your GitHub Personal Access Token.';
        Logger.w('Token validation failed: 401', context: 'Auth');
        throw Exception('Invalid token');
      } else {
        _isAuthenticated = false;
        _errorMessage = 'GitHub API error: ${response.statusCode}';
        Logger.w(
          'Token validation failed: ${response.statusCode}',
          context: 'Auth',
        );
        throw Exception('GitHub API error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error during validation', error: e, context: 'Auth');
      _errorMessage = 'Network error. Please check your internet connection.';
      _isOfflineMode = true;
      throw Exception('Network error');
    } catch (e) {
      Logger.e('Token validation error', error: e, context: 'Auth');
      rethrow;
    }

    notifyListeners();
  }

  /// Logout - clear token and state
  Future<void> logout() async {
    Logger.i('Logging out', context: 'Auth');

    try {
      await _storage.delete(key: 'github_token');
      _token = null;
      _isAuthenticated = false;
      _username = null;
      _errorMessage = null;
      _isOfflineMode = true;
      Logger.i('Logout successful', context: 'Auth');
    } catch (e) {
      Logger.e('Logout failed', error: e, context: 'Auth');
    }

    notifyListeners();
  }

  /// Reset error state
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Retry token validation (when coming back online)
  Future<void> retryValidation() async {
    if (_token != null && !_token!.isEmpty) {
      Logger.i('Retrying token validation', context: 'Auth');
      await _tryValidateToken(_token!);
    }
  }
}
