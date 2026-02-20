import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/logger.dart';

/// Authentication Provider - Manages GitHub PAT authentication state
///
/// Handles:
/// - Token storage and retrieval
/// - Token validation with GitHub API
/// - Authentication state management
class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // State
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _username;

  // Getters
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String? get username => _username;

  /// Load saved token from secure storage
  Future<void> loadSavedToken() async {
    Logger.d('Loading saved token', context: 'Auth');

    try {
      final token = await _storage.read(key: 'github_token');
      if (token != null && token.isNotEmpty) {
        _token = token;
        Logger.i('Token loaded from storage', context: 'Auth');

        // Validate the token
        await _validateTokenWithGitHub(token);
      } else {
        Logger.d('No saved token found', context: 'Auth');
      }
    } catch (e) {
      Logger.e('Failed to load token', error: e, context: 'Auth');
      _errorMessage = 'Failed to load saved token';
    }

    notifyListeners();
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
        Logger.i('Token saved successfully', context: 'Auth');
      }
    } catch (e) {
      Logger.e('Token validation failed', error: e, context: 'Auth');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
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
        Logger.i(
          'Token validated successfully for user: $_username',
          context: 'Auth',
        );
      } else if (response.statusCode == 401) {
        _isAuthenticated = false;
        _errorMessage =
            'Invalid token. Please check your GitHub Personal Access Token.';
        Logger.w('Token validation failed: 401 Unauthorized', context: 'Auth');
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
      throw Exception('Network error');
    } catch (e) {
      Logger.e('Token validation error', error: e, context: 'Auth');
      rethrow;
    }

    notifyListeners();
  }

  /// Check token permissions
  Future<Map<String, bool>> checkTokenPermissions() async {
    Logger.d('Checking token permissions', context: 'Auth');

    // TODO: Implement permission checking
    // For now, return assumed permissions
    return {'repo': true, 'issues': true};
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
}
