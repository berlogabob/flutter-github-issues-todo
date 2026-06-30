import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_error_handler.dart';

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
  OAuthService({Dio? dio, String? clientId})
    : _dio = dio ?? Dio(),
      _clientId = clientId ?? _configuredClientId;

  final Dio _dio;
  final String _clientId;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _configuredClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
  );

  /// Check if client ID is configured (for UI feedback before attempting OAuth)
  static bool get isClientIdConfigured => _configuredClientId.isNotEmpty;

  /// Validate client ID - throws if not configured
  /// Call this early to fail fast with a clear error
  void _validateClientId() {
    if (_clientId.isEmpty) {
      throw Exception(
        'GITHUB_CLIENT_ID is not configured.\n\n'
        'To fix this:\n'
        '1. Copy .env.example to .env\n'
        '   cp .env.example .env\n\n'
        '2. Get your GitHub OAuth Client ID:\n'
        '   - Go to https://github.com/settings/developers\n'
        '   - Create a new OAuth App\n'
        '   - Copy your Client ID\n\n'
        '3. Edit .env file and add:\n'
        '   GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx\n\n'
        '4. Restart the app\n\n'
        'See README.md or OAUTH_SETUP.md for detailed instructions.',
      );
    }
  }

  // Device code response
  DeviceCodeResponse? _deviceCode;
  Timer? _pollingTimer;
  bool _isPolling = false;

  Future<({int statusCode, Map<String, dynamic> data})> _postForm(
    Uri uri,
    Map<String, String> data, {
    required Duration timeout,
  }) async {
    final response = await _dio
        .post<dynamic>(
          uri.toString(),
          data: data,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: const {'Accept': 'application/json'},
            responseType: ResponseType.json,
            validateStatus: (_) => true,
          ),
        )
        .timeout(timeout);
    final body = response.data is String
        ? json.decode(response.data as String) as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map? ?? const {});
    return (statusCode: response.statusCode ?? 0, data: body);
  }

  /// Request device code from GitHub
  Future<DeviceCodeResponse?> requestDeviceCode() async {
    _validateClientId();

    try {
      debugPrint('OAuthService: Requesting device code...');

      final response = await _postForm(
        Uri.parse('https://github.com/login/device/code'),
        {'client_id': _clientId, 'scope': 'repo user'},
        timeout: const Duration(seconds: 15),
      );

      debugPrint('Device code response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        _deviceCode = DeviceCodeResponse(
          deviceCode: data['device_code'] as String,
          userCode: data['user_code'] as String,
          verificationUri: data['verification_uri'] as String,
          expiresIn: data['expires_in'] as int,
          interval: data['interval'] as int,
        );

        debugPrint('OAuthService: Device code received');
        return _deviceCode;
      } else {
        debugPrint('Failed to get device code: ${response.statusCode}');
        throw Exception(
          'Failed to request device code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint(
        'OAuthService: Error requesting device code (${e.runtimeType})',
      );
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
      debugPrint('OAuthService: Opening verification URL');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint('Cannot launch URL');
        return false;
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('OAuthService: Error opening URL (${e.runtimeType})');
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
      try {
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
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace);
        timer.cancel();
        _isPolling = false;
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(
              'Authentication failed while waiting for GitHub authorization. Please try again.',
            ),
          );
        }
      }
    });

    try {
      // First poll immediately
      final token = await _pollForToken();
      if (token != null) {
        _pollingTimer?.cancel();
        _isPolling = false;
        await _saveToken(token);
        completer.complete(token);
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      _pollingTimer?.cancel();
      _isPolling = false;
      if (!completer.isCompleted) {
        completer.completeError(
          Exception(
            'Unable to complete GitHub authentication. Please try again.',
          ),
        );
      }
    }

    return completer.future;
  }

  /// Poll for access token
  Future<String?> _pollForToken() async {
    try {
      final response = await _postForm(
        Uri.parse('https://github.com/login/oauth/access_token'),
        {
          'client_id': _clientId,
          'device_code': _deviceCode!.deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
        timeout: const Duration(seconds: 10),
      );

      debugPrint('Poll response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Check for error
        final error = data['error'] as String?;
        if (error == 'authorization_pending') {
          debugPrint('OAuthService: Authorization pending...');
          return null;
        } else if (error == 'slow_down') {
          debugPrint('OAuthService: Slow down - increasing interval');
          return null;
        } else if (error != null) {
          throw Exception('GitHub authorization error: $error');
        }

        // Success - got access token
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          debugPrint('OAuthService: Access token received');
          return accessToken;
        }
      }

      return null;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('OAuthService: Error polling for token (${e.runtimeType})');
      rethrow;
    }
  }

  /// Save access token to secure storage
  Future<void> _saveToken(String token) async {
    try {
      await _storage.write(key: 'github_token', value: token);
      debugPrint('OAuthService: Token saved to secure storage');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('OAuthService: Error saving token (${e.runtimeType})');
      throw Exception('Failed to save authentication token.');
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
    return 'DeviceCodeResponse(expiresIn: $expiresIn)';
  }
}
