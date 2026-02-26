import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/logging.dart';

/// OAuth Service - GitHub OAuth Device Flow
///
/// Implements GitHub OAuth Device Flow for mobile apps
/// Reference: https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps#device-flow
///
/// Flow:
/// 1. Request device code from GitHub
/// 2. Show user verification URI and user code
/// 3. Open browser for user authorization
/// 4. Poll for access token
/// 5. Save token securely
class OAuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // OAuth Client Configuration
  // TODO: Replace with actual values from GitHub OAuth App
  static const String clientId = String.fromEnvironment(
    'GITHUB_OAUTH_CLIENT_ID',
    defaultValue: 'YOUR_GITHUB_OAUTH_CLIENT_ID',
  );
  
  static const String clientSecret = String.fromEnvironment(
    'GITHUB_OAUTH_CLIENT_SECRET',
    defaultValue: 'YOUR_GITHUB_OAUTH_CLIENT_SECRET',
  );

  // Device Flow endpoints
  static const String deviceCodeUrl = 'https://github.com/login/device/code';
  static const String accessTokenUrl = 'https://github.com/login/oauth/access_token';
  
  // OAuth scopes
  static const String scopes = 'repo,user,read:project';

  // Device code state
  String? _deviceCode;
  String? _userCode;
  String? _verificationUri;
  int? _expiresIn;
  int? _interval;
  bool _isPolling = false;

  // Getters
  String? get deviceCode => _deviceCode;
  String? get userCode => _userCode;
  String? get verificationUri => _verificationUri;
  bool get isPolling => _isPolling;

  /// Step 1: Request device code from GitHub
  ///
  /// Returns device code, user code, verification URI, and polling interval
  Future<Map<String, dynamic>> requestDeviceCode() async {
    final metric = Logger.startMetric('requestDeviceCode', 'OAuth');
    Logger.i('Requesting device code', context: 'OAuth');

    try {
      final response = await http.post(
        Uri.parse(deviceCodeUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'client_id': clientId,
          'scope': scopes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        _deviceCode = data['device_code'] as String?;
        _userCode = data['user_code'] as String?;
        _verificationUri = data['verification_uri'] as String?;
        _expiresIn = data['expires_in'] as int?;
        _interval = data['interval'] as int?;

        Logger.i(
          'Device code received',
          context: 'OAuth',
          metadata: {
            'user_code': _userCode,
            'verification_uri': _verificationUri,
            'expires_in': _expiresIn,
          },
        );

        metric.complete(success: true);

        return {
          'device_code': _deviceCode,
          'user_code': _userCode,
          'verification_uri': _verificationUri,
          'expires_in': _expiresIn,
          'interval': _interval,
        };
      } else {
        Logger.e(
          'Failed to request device code',
          context: 'OAuth',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(success: false, errorCode: response.statusCode);
        throw Exception('Failed to request device code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Logger.e(
        'Error requesting device code',
        error: e,
        stackTrace: stackTrace,
        context: 'OAuth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Step 2: Open verification URI in browser
  ///
  /// Opens GitHub authorization page where user enters user code
  Future<bool> openVerificationUri() async {
    final metric = Logger.startMetric('openVerificationUri', 'OAuth');
    Logger.d('Opening verification URI', context: 'OAuth');

    try {
      if (_verificationUri == null) {
        throw Exception('No verification URI available');
      }

      final uri = Uri.parse(_verificationUri!);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.i('Verification URI opened', context: 'OAuth');
        metric.complete(success: true);
        return true;
      } else {
        Logger.e('Cannot launch verification URI', context: 'OAuth');
        metric.complete(success: false, errorMessage: 'Cannot launch URI');
        throw Exception('Cannot open verification URI');
      }
    } catch (e, stackTrace) {
      Logger.e(
        'Error opening verification URI',
        error: e,
        stackTrace: stackTrace,
        context: 'OAuth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Step 3: Poll for access token
  ///
  /// Polls GitHub until user authorizes or code expires
  /// Returns access token when successful
  Future<String> pollForAccessToken({
    void Function(String status)? onStatusChange,
  }) async {
    final metric = Logger.startMetric('pollForAccessToken', 'OAuth');
    Logger.i('Polling for access token', context: 'OAuth');

    if (_deviceCode == null) {
      throw Exception('No device code available');
    }

    _isPolling = true;
    final pollInterval = Duration(seconds: _interval ?? 5);
    final expiryTime = DateTime.now().add(Duration(seconds: _expiresIn ?? 900));

    try {
      while (_isPolling && DateTime.now().isBefore(expiryTime)) {
        onStatusChange?.call('Waiting for authorization...');

        await Future.delayed(pollInterval);

        final result = await _checkForToken();

        if (result['status'] == 'success') {
          final accessToken = result['access_token'] as String;
          Logger.i('Access token obtained', context: 'OAuth');
          metric.complete(success: true);
          _isPolling = false;
          return accessToken;
        } else if (result['status'] == 'error') {
          Logger.e('Token polling failed', context: 'OAuth');
          metric.complete(success: false, errorMessage: result['error'] as String);
          _isPolling = false;
          throw Exception(result['error']);
        }
        // Continue polling if 'pending'
      }

      Logger.e('Device code expired', context: 'OAuth');
      metric.complete(success: false, errorMessage: 'Device code expired');
      _isPolling = false;
      throw Exception('Authorization timeout. Please try again.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error polling for access token',
        error: e,
        stackTrace: stackTrace,
        context: 'OAuth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _isPolling = false;
      rethrow;
    }
  }

  /// Check for access token (single poll)
  Future<Map<String, dynamic>> _checkForToken() async {
    try {
      final response = await http.post(
        Uri.parse(accessTokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'client_id': clientId,
          'device_code': _deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['access_token'] != null) {
          return {
            'status': 'success',
            'access_token': data['access_token'] as String,
          };
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final error = data['error'] as String?;

        if (error == 'authorization_pending') {
          return {'status': 'pending'};
        } else if (error == 'slow_down') {
          return {'status': 'slow_down'};
        } else if (error == 'expired_token') {
          return {
            'status': 'error',
            'error': 'Device code expired',
          };
        } else if (error == 'incorrect_client_credentials' ||
                   error == 'device_code_unknown') {
          return {
            'status': 'error',
            'error': 'Invalid device code',
          };
        }
      }

      return {
        'status': 'error',
        'error': 'Unknown error',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Stop polling
  void stopPolling() {
    Logger.d('Stopping OAuth polling', context: 'OAuth');
    _isPolling = false;
  }

  /// Save access token securely
  Future<void> saveAccessToken(String token) async {
    final metric = Logger.startMetric('saveAccessToken', 'OAuth');
    Logger.d('Saving access token', context: 'OAuth');

    try {
      await _storage.write(key: 'github_token', value: token);
      await _storage.write(key: 'auth_type', value: 'oauth');
      Logger.i('Access token saved', context: 'OAuth');
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to save access token',
        error: e,
        stackTrace: stackTrace,
        context: 'OAuth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Get saved access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: 'github_token');
      final authType = await _storage.read(key: 'auth_type');
      
      if (authType == 'oauth' && token != null && token.isNotEmpty) {
        return token;
      }
      return null;
    } catch (e) {
      Logger.e('Failed to get access token', error: e, context: 'OAuth');
      return null;
    }
  }

  /// Clear OAuth token
  Future<void> clearToken() async {
    final metric = Logger.startMetric('clearToken', 'OAuth');
    Logger.d('Clearing OAuth token', context: 'OAuth');

    try {
      await _storage.delete(key: 'github_token');
      await _storage.delete(key: 'auth_type');
      Logger.i('OAuth token cleared', context: 'OAuth');
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to clear token',
        error: e,
        stackTrace: stackTrace,
        context: 'OAuth',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Check if OAuth token exists
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
    Logger.d('OAuthService disposed', context: 'OAuth');
  }
}
