import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/github_service.dart';
import '../utils/logger.dart';

/// Authentication Provider - Manages GitHub PAT authentication state
///
/// OFFLINE-FIRST: App works without authentication
/// Token validation happens when online
///
/// Supports both Personal Access Token (PAT) and OAuth authentication
class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GitHubService _githubService = GitHubService();

  // State
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _username;
  bool _isOfflineMode = false;
  bool _isOAuthLoginInProgress = false;

  // Getters
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String? get username => _username;
  bool get isOfflineMode => _isOfflineMode;
  bool get isOAuthLoginInProgress => _isOAuthLoginInProgress;

  /// Initialize - update logger with user state
  AuthProvider() {
    Logger.setCurrentUser(null);
  }

  /// Load saved token from secure storage (don't auto-validate)
  Future<void> loadSavedToken() async {
    final metric = Logger.startMetric('loadSavedToken', 'Auth');
    Logger.d('Loading saved token', context: 'Auth');

    try {
      final token = await _storage.read(key: 'github_token');
      if (token != null && token.isNotEmpty) {
        _token = token;
        _isOfflineMode = false;
        Logger.i(
          'Token loaded from storage (not validated yet)',
          context: 'Auth',
          metadata: {'token_prefix': token.substring(0, 6)},
        );

        // Track journey event
        Logger.trackJourney(
          JourneyEventType.authEvent,
          'Auth',
          'token_loaded',
          metadata: {'has_token': true},
        );

        // Try to validate if online
        await _tryValidateToken(token);
      } else {
        _isOfflineMode = true;
        Logger.d('No saved token - offline mode', context: 'Auth');
        Logger.trackJourney(
          JourneyEventType.authEvent,
          'Auth',
          'no_token_found',
        );
      }
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to load token',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _isOfflineMode = true;
    }

    notifyListeners();
  }

  /// Try to validate token (silent, doesn't block UI)
  Future<void> _tryValidateToken(String token) async {
    try {
      await _validateTokenWithGitHub(token);
    } catch (e) {
      Logger.w(
        'Token validation failed - will retry later',
        context: 'Auth',
        metadata: {'error': e.toString()},
      );
      _isOfflineMode = true;
      notifyListeners();
    }
  }

  /// Validate and save token
  Future<void> validateAndSaveToken(String token) async {
    final metric = Logger.startMetric('validateAndSaveToken', 'Auth');
    Logger.i(
      'Validating and saving token',
      context: 'Auth',
      metadata: {'token_prefix': token.substring(0, 6)},
    );

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

        // Update logger with user info
        Logger.setCurrentUser(_username);

        Logger.i(
          'Token saved and validated',
          context: 'Auth',
          metadata: {'username': _username},
        );
        Logger.trackJourney(
          JourneyEventType.authEvent,
          'Auth',
          'authentication_success',
          metadata: {'username': _username},
        );
      }
      metric.complete(success: _isAuthenticated);
    } catch (e, stackTrace) {
      Logger.e(
        'Token validation failed',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _isOfflineMode = true;
      // Still save token for later validation
      await _storage.write(key: 'github_token', value: token);
      _token = token;

      Logger.trackJourney(
        JourneyEventType.authEvent,
        'Auth',
        'authentication_failed',
        metadata: {'error_type': e.runtimeType.toString()},
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate token with GitHub API
  Future<void> _validateTokenWithGitHub(String token) async {
    final metric = Logger.startMetric('validateTokenWithGitHub', 'Auth');
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
        metric.complete(success: true);
      } else if (response.statusCode == 401) {
        _isAuthenticated = false;
        _errorMessage =
            'Invalid token. Please check your GitHub Personal Access Token.';
        Logger.w('Token validation failed: 401', context: 'Auth');
        metric.complete(
          success: false,
          errorCode: 401,
          errorMessage: 'Unauthorized',
        );
        throw Exception('Invalid token');
      } else {
        _isAuthenticated = false;
        _errorMessage = 'GitHub API error: ${response.statusCode}';
        Logger.w(
          'Token validation failed: ${response.statusCode}',
          context: 'Auth',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: 'GitHub API error',
        );
        throw Exception('GitHub API error: ${response.statusCode}');
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error during validation',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      _errorMessage = 'Network error. Please check your internet connection.';
      _isOfflineMode = true;
      throw Exception('Network error');
    } catch (e, stackTrace) {
      Logger.e(
        'Token validation error',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }

    notifyListeners();
  }

  /// Logout - clear token and state
  Future<void> logout() async {
    Logger.i('Logging out', context: 'Auth', metadata: {'username': _username});

    try {
      await _storage.delete(key: 'github_token');
    } catch (e, stackTrace) {
      Logger.e(
        'Logout failed',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
    } finally {
      // Always clear state even if storage fails
      _token = null;
      _isAuthenticated = false;
      _username = null;
      _errorMessage = null;
      _isOfflineMode = true;

      // Clear user in logger
      Logger.setCurrentUser(null);

      Logger.i('Logout successful', context: 'Auth');
      Logger.trackJourney(
        JourneyEventType.authEvent,
        'Auth',
        'logout',
        metadata: {'was_authenticated': _isAuthenticated},
      );
    }

    notifyListeners();
  }

  /// Clear all authentication data
  ///
  /// Removes token, username, and all auth-related state
  Future<void> clearAllData() async {
    final metric = Logger.startMetric('clearAllData', 'Auth');
    Logger.i('Clearing all auth data', context: 'Auth');

    try {
      await _storage.delete(key: 'github_token');
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to clear auth data',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
      metric.complete(success: false, errorMessage: e.toString());
    } finally {
      // Always clear state even if storage fails
      _token = null;
      _isAuthenticated = false;
      _username = null;
      _errorMessage = null;
      _isOfflineMode = true;
      _isOAuthLoginInProgress = false;

      // Clear user in logger
      Logger.setCurrentUser(null);

      Logger.i('All auth data cleared', context: 'Auth');
      Logger.trackJourney(
        JourneyEventType.authEvent,
        'Auth',
        'auth_data_cleared',
        metadata: {'was_authenticated': _isAuthenticated},
      );
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
    if (_token != null && _token!.isNotEmpty) {
      Logger.i('Retrying token validation', context: 'Auth');
      await _tryValidateToken(_token!);
    }
  }

  // ==================== OAuth Methods ====================

  /// Start OAuth login flow
  ///
  /// Returns the OAuth URL to launch in browser
  Future<String> loginWithOAuth() async {
    final metric = Logger.startMetric('loginWithOAuth', 'Auth');
    Logger.i('Starting OAuth login flow', context: 'Auth');

    _isOAuthLoginInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final oauthUrl = _githubService.getOAuthUrl();
      Logger.d(
        'OAuth URL generated',
        context: 'Auth',
        metadata: {'url': oauthUrl},
      );
      metric.complete(success: true);
      return oauthUrl;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to start OAuth login',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _errorMessage = 'Failed to start OAuth login: ${e.toString()}';
      _isOAuthLoginInProgress = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Complete OAuth login with authorization code
  ///
  /// [code] - The authorization code received from GitHub callback
  /// [state] - The state parameter (optional, for verification)
  Future<void> completeOAuthLogin({required String code, String? state}) async {
    final metric = Logger.startMetric('completeOAuthLogin', 'Auth');
    Logger.i('Completing OAuth login', context: 'Auth');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Exchange code for token
      final accessToken = await _githubService.exchangeCodeForToken(
        code: code,
        state: state,
      );

      // Validate and save token
      await _validateTokenWithGitHub(accessToken);

      if (_isAuthenticated) {
        // Save token
        await _storage.write(key: 'github_token', value: accessToken);
        _token = accessToken;
        _isOfflineMode = false;

        // Update logger with user info
        Logger.setCurrentUser(_username);

        Logger.i(
          'OAuth login successful',
          context: 'Auth',
          metadata: {'username': _username},
        );
        Logger.trackJourney(
          JourneyEventType.authEvent,
          'Auth',
          'oauth_authentication_success',
          metadata: {'username': _username},
        );
      }

      metric.complete(success: _isAuthenticated);
    } catch (e, stackTrace) {
      Logger.e(
        'OAuth login failed',
        error: e,
        stackTrace: stackTrace,
        context: 'Auth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _isOfflineMode = true;

      Logger.trackJourney(
        JourneyEventType.authEvent,
        'Auth',
        'oauth_authentication_failed',
        metadata: {'error_type': e.runtimeType.toString()},
      );
    } finally {
      _isLoading = false;
      _isOAuthLoginInProgress = false;
      notifyListeners();
    }
  }

  /// Cancel OAuth login
  void cancelOAuthLogin() {
    Logger.w('OAuth login cancelled by user', context: 'Auth');
    _isOAuthLoginInProgress = false;
    _errorMessage = null;
    notifyListeners();
  }
}
