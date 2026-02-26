import 'dart:convert';
import 'package:http/http.dart' as http;

import 'github_service.dart';
import '../utils/logging.dart';

/// GitHub Users API - User-related operations
///
/// Handles:
/// - Getting current user info
/// - Checking token permissions
class GitHubUsersApi {
  final GitHubService _baseService;
  final http.Client _client;

  GitHubUsersApi(this._baseService) : _client = http.Client();

  /// Get current authenticated user info
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    final metric = Logger.startMetric('getCurrentUserInfo', 'GitHub');
    Logger.d('Fetching current user info', context: 'GitHub');

    try {
      final uri = Uri.parse('${GitHubService.baseUrl}/user');
      final response = await _client.get(uri, headers: await _baseService.headers);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body) as Map<String, dynamic>;
        Logger.i('Fetched user info: ${userData['login']}', context: 'GitHub');
        metric.complete(success: true);
        return userData;
      } else {
        Logger.e('Failed to fetch user info', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
        });
        metric.complete(success: false, errorCode: response.statusCode);
        throw Exception('Failed to fetch user info: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error fetching user info', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e('Error fetching user info', error: e, stackTrace: stackTrace, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Get current user login
  Future<String> getCurrentUserLogin() async {
    final userData = await getCurrentUserInfo();
    return userData['login'] as String? ?? 'Unknown';
  }

  /// Check token permissions (scopes)
  Future<Map<String, bool>> getTokenPermissions() async {
    final metric = Logger.startMetric('getTokenPermissions', 'GitHub');
    Logger.d('Checking token permissions', context: 'GitHub');

    try {
      final uri = Uri.parse('${GitHubService.baseUrl}/user');
      final response = await _client.get(uri, headers: await _baseService.headers);

      if (response.statusCode == 200) {
        final scopesHeader = response.headers['x-oauth-scopes'] ?? '';
        final scopes = scopesHeader.split(',').map((s) => s.trim()).toList();

        Logger.d('Token scopes: $scopes', context: 'GitHub');

        final permissions = {
          'repo': scopes.contains('repo'),
          'issues': scopes.contains('public_repo') || scopes.contains('repo'),
          'user': scopes.contains('user'),
        };

        Logger.i('Token permissions checked', context: 'GitHub', metadata: permissions);
        metric.complete(success: true);
        return permissions;
      } else {
        Logger.e('Failed to check permissions', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
        });
        metric.complete(success: false, errorCode: response.statusCode);
        return {};
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error checking permissions', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      return {};
    } catch (e, stackTrace) {
      Logger.e('Error checking permissions', error: e, stackTrace: stackTrace, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      return {};
    }
  }

  /// Check if token has required scope
  Future<bool> hasScope(String requiredScope) async {
    final permissions = await getTokenPermissions();
    
    if (requiredScope == 'repo') {
      return permissions['repo'] == true;
    } else if (requiredScope == 'issues') {
      return permissions['issues'] == true;
    } else if (requiredScope == 'user') {
      return permissions['user'] == true;
    }
    
    return false;
  }

  /// Dispose HTTP client
  void dispose() {
    _client.close();
    Logger.d('GitHubUsersApi disposed', context: 'GitHub');
  }
}
