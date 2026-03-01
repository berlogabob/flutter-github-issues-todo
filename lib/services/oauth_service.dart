import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/app_error_handler.dart';

part 'oauth_service.g.dart';

/// OAuth Device Flow Service
/// Implements GitHub OAuth Device Flow for authentication
///
/// Flow:
/// 1. Request device code from GitHub
/// 2. Show user code and verification URL
/// 3. User enters code on GitHub website
/// 4. Poll for access token
/// 5. Store access token
class OAuthService {
  OAuthService();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // GitHub OAuth credentials
  // Security: Client ID must be provided via environment variable
  // Never hardcode credentials in source code
  static const String _clientId = String.fromEnvironment('GITHUB_CLIENT_ID');

  // Validate client ID at initialization
  static void _validateClientId() {
    if (_clientId.isEmpty) {
      throw Exception(
        'GITHUB_CLIENT_ID environment variable is not set.\n'
        'Please set the GITHUB_CLIENT_ID environment variable:\n'
        '  1. Copy .env.example to .env\n'
        '  2. Add your GitHub OAuth Client ID to .env\n'
        '  3. Run: flutter run --dart-define=GITHUB_CLIENT_ID=your_client_id\n'
        'See README.md for detailed setup instructions.',
      );
    }
  }

  static bool _validated = false;

  // Device code response
  DeviceCodeResponse? _deviceCode;
  Timer? _pollingTimer;
  bool _isPolling = false;

  /// Request device code from GitHub
  Future<DeviceCodeResponse?> requestDeviceCode() async {
    // Validate client ID before proceeding
    if (!_validated) {
      _validateClientId();
      _validated = true;
    }

    try {
      debugPrint('OAuthService: Requesting device code...');

      final response = await http
          .post(
            Uri.parse('https://github.com/login/device/code'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'client_id': _clientId, 'scope': 'repo user'},
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Device code response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _deviceCode = DeviceCodeResponse(
          deviceCode: data['device_code'] as String,
          userCode: data['user_code'] as String,
          verificationUri: data['verification_uri'] as String,
          expiresIn: data['expires_in'] as int,
          interval: data['interval'] as int,
        );

        debugPrint('Device code received: ${_deviceCode!.userCode}');
        return _deviceCode;
      } else {
        debugPrint('Failed to get device code: ${response.statusCode}');
        throw Exception(
          'Failed to request device code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('OAuthService: Error requesting device code: $e');
      return null;
    }
  }

  /// Open verification URL in browser
  Future<bool> openVerificationUrl() async {
    if (_deviceCode == null) {
      debugPrint('OAuthService: No device code available');
      return false;
    }

    try {
      final uri = Uri.parse(_deviceCode!.verificationUri);
      debugPrint('Opening verification URL: ${_deviceCode!.verificationUri}');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint('Cannot launch URL');
        return false;
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('OAuthService: Error opening URL: $e');
      return false;
    }
  }

  /// Start polling for access token
  Future<String?> startPolling() async {
    if (_deviceCode == null) {
      debugPrint('OAuthService: No device code available');
      return null;
    }

    if (_isPolling) {
      debugPrint('OAuthService: Already polling');
      return null;
    }

    _isPolling = true;
    final completer = Completer<String?>();
    final expiresAt = DateTime.now().add(
      Duration(seconds: _deviceCode!.expiresIn),
    );

    debugPrint(
      'OAuthService: Starting polling (expires in ${_deviceCode!.expiresIn}s)',
    );

    _pollingTimer = Timer.periodic(Duration(seconds: _deviceCode!.interval), (
      timer,
    ) async {
      // Check if expired
      if (DateTime.now().isAfter(expiresAt)) {
        debugPrint('OAuthService: Device code expired');
        timer.cancel();
        _isPolling = false;
        completer.complete(null);
        return;
      }

      // Poll for token
      final token = await _pollForToken();
      if (token != null) {
        debugPrint('OAuthService: Access token received');
        timer.cancel();
        _isPolling = false;
        await _saveToken(token);
        completer.complete(token);
      }
    });

    // First poll immediately
    final token = await _pollForToken();
    if (token != null) {
      _pollingTimer?.cancel();
      _isPolling = false;
      await _saveToken(token);
      completer.complete(token);
    }

    return completer.future;
  }

  /// Poll for access token
  Future<String?> _pollForToken() async {
    try {
      final response = await http
          .post(
            Uri.parse('https://github.com/login/oauth/access_token'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'client_id': _clientId,
              'device_code': _deviceCode!.deviceCode,
              'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Poll response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for error
        final error = data['error'] as String?;
        if (error == 'authorization_pending') {
          debugPrint('OAuthService: Authorization pending...');
          return null;
        } else if (error == 'slow_down') {
          debugPrint('OAuthService: Slow down - increasing interval');
          return null;
        } else if (error != null) {
          debugPrint('OAuthService: Error: $error');
          return null;
        }

        // Success - got access token
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          debugPrint(
            'OAuthService: Access token received (${accessToken.length} chars)',
          );
          return accessToken;
        }
      }

      return null;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('OAuthService: Error polling for token: $e');
      return null;
    }
  }

  /// Save access token to secure storage
  Future<void> _saveToken(String token) async {
    try {
      await _storage.write(key: 'github_token', value: token);
      debugPrint('OAuthService: Token saved to secure storage');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('OAuthService: Error saving token: $e');
    }
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _isPolling = false;
    debugPrint('OAuthService: Polling stopped');
  }

  /// Get current device code
  DeviceCodeResponse? getDeviceCode() => _deviceCode;

  /// Check if currently polling
  bool get isPolling => _isPolling;

  /// Clear OAuth data
  Future<void> clear() async {
    stopPolling();
    _deviceCode = null;
    await _storage.delete(key: 'github_token');
    debugPrint('OAuthService: Cleared');
  }
}

/// Device code response from GitHub
class DeviceCodeResponse {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final int expiresIn;
  final int interval;

  DeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
  });

  /// Get verification URL with user code pre-filled
  String get verificationUrlWithCode => '$verificationUri?user_code=$userCode';

  @override
  String toString() {
    return 'DeviceCodeResponse(userCode: $userCode, expiresIn: $expiresIn)';
  }
}

@Riverpod(keepAlive: true)
OAuthService oauthService(Ref ref) {
  return OAuthService();
}
