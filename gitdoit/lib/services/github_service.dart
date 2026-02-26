import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/issue.dart' as issue_models;
import '../models/github_repository.dart' as repo_models;
import 'github_issues_api.dart';
import 'github_repositories_api.dart';
import '../utils/logging.dart';

/// GitHub Service - Base service with shared functionality
///
/// Handles:
/// - Token management
/// - HTTP client management
/// - OAuth configuration
/// - Common headers
class GitHubService {
  final FlutterSecureStorage _storage;

  // Constructor with optional storage injection for testing
  GitHubService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // GitHub API base URL
  static const String baseUrl = 'https://api.github.com';

  // OAuth configuration
  static const String oauthClientId = 'YOUR_GITHUB_OAUTH_CLIENT_ID';
  static const String oauthClientSecret = 'YOUR_GITHUB_OAUTH_CLIENT_SECRET';
  static const String oauthRedirectUri = 'gitdoit://auth/callback';
  static const String oauthScope = 'repo,user';

  // HTTP client
  final http.Client _client = http.Client();

  // Get authenticated token
  Future<String> get _token async {
    try {
      final token = await _storage.read(key: 'github_token');
      if (token == null || token.isEmpty) {
        Logger.e('No token found', context: 'GitHub');
        throw Exception('No GitHub token found. Please login first.');
      }
      return token;
    } on MissingPluginException catch (e) {
      // Handle missing plugin gracefully (e.g., in tests or unsupported platforms)
      Logger.e(
        'Secure storage not available',
        error: e,
        context: 'GitHub',
      );
      throw Exception('Secure storage not available. Please try again.');
    } catch (e) {
      Logger.e('Failed to read token from storage', error: e, context: 'GitHub');
      if (e is MissingPluginException) {
        rethrow;
      }
      throw Exception('No GitHub token found. Please login first.');
    }
  }

  // Common headers for all requests (public for API classes)
  Future<Map<String, String>> get headers async {
    final token = await _token;
    return {
      'Authorization': 'token $token',
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitDoIt-App',
      'Content-Type': 'application/json',
    };
  }

  /// Get OAuth authorization URL
  String getOAuthUrl() {
    final state = _generateState();
    final params = {
      'client_id': oauthClientId,
      'redirect_uri': oauthRedirectUri,
      'scope': oauthScope,
      'state': state,
    };
    final uri = Uri.parse('https://github.com/login/oauth/authorize')
        .replace(queryParameters: params);
    Logger.d('OAuth URL generated', context: 'GitHub');
    return uri.toString();
  }

  /// Launch OAuth flow in browser
  Future<bool> launchOAuthFlow() async {
    final url = getOAuthUrl();
    Logger.d('Launching OAuth flow', context: 'GitHub');
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.i('OAuth flow launched', context: 'GitHub');
        return true;
      } else {
        Logger.e('Cannot launch OAuth URL', context: 'GitHub');
        return false;
      }
    } catch (e) {
      Logger.e('Failed to launch OAuth flow', error: e, context: 'GitHub');
      return false;
    }
  }

  /// Handle OAuth callback
  Future<Map<String, String>> handleOAuthCallback(Uri uri) async {
    Logger.d('Handling OAuth callback', context: 'GitHub');
    
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      Logger.e('OAuth error: $error', context: 'GitHub');
      throw Exception('OAuth error: $error');
    }

    if (code == null) {
      Logger.e('No code in OAuth callback', context: 'GitHub');
      throw Exception('No code in OAuth callback');
    }

    Logger.d('OAuth code received', context: 'GitHub');
    
    return {
      'code': code,
      'state': state ?? '',
    };
  }

  /// Exchange OAuth code for access token
  Future<String> exchangeCodeForToken({
    required String code,
    String? state,
  }) async {
    Logger.d('Exchanging OAuth code for token', context: 'GitHub');

    try {
      final response = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'client_id': oauthClientId,
          'client_secret': oauthClientSecret,
          'code': code,
          'redirect_uri': oauthRedirectUri,
          'state': state ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        
        if (accessToken != null) {
          Logger.i('OAuth token obtained', context: 'GitHub');
          return accessToken;
        } else {
          Logger.e('No access token in response', context: 'GitHub');
          throw Exception('No access token in response');
        }
      } else {
        Logger.e('Token exchange failed', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
        });
        throw Exception('Token exchange failed: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e('Failed to exchange code for token', error: e, context: 'GitHub');
      rethrow;
    }
  }

  /// Generate random state for OAuth
  String _generateState() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return random.toString();
  }

  /// Get current authenticated user
  Future<Map<String, dynamic>> getCurrentUser() async {
    Logger.d('Fetching current user', context: 'GitHub');

    try {
      final uri = Uri.parse('$baseUrl/user');
      final response = await _client.get(uri, headers: await headers);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        Logger.e('Failed to get user', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
        });
        throw Exception('Failed to get user: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e('Error getting user', error: e, context: 'GitHub');
      rethrow;
    }
  }

  /// Check token permissions (scopes)
  Future<Map<String, bool>> checkTokenPermissions() async {
    Logger.d('Checking token permissions', context: 'GitHub');

    try {
      final uri = Uri.parse('$baseUrl/user');
      final response = await _client.get(uri, headers: await headers);

      if (response.statusCode == 200) {
        final scopesHeader = response.headers['x-oauth-scopes'] ?? '';
        final scopes = scopesHeader.split(',').map((s) => s.trim()).toList();

        Logger.d('Token scopes: $scopes', context: 'GitHub');

        return {
          'repo': scopes.contains('repo'),
          'issues': scopes.contains('public_repo') || scopes.contains('repo'),
          'user': scopes.contains('user'),
        };
      } else {
        Logger.e('Failed to check permissions', context: 'GitHub');
        return {};
      }
    } catch (e) {
      Logger.e('Error checking permissions', error: e, context: 'GitHub');
      return {};
    }
  }

  /// Dispose HTTP client
  void dispose() {
    _client.close();
    Logger.d('GitHubService disposed', context: 'GitHub');
  }

  // Wrapper methods for backward compatibility
  Future<List<issue_models.Issue>> fetchIssues({
    required String owner,
    required String repo,
    String state = 'open',
    int perPage = 50,
  }) {
    final api = GitHubIssuesApi(this);
    return api.fetchIssues(owner: owner, repo: repo, state: state, perPage: perPage);
  }

  Future<issue_models.Issue> createIssue({
    required String owner,
    required String repo,
    required String title,
    String? body,
    List<String>? labels,
  }) {
    final api = GitHubIssuesApi(this);
    return api.createIssue(owner: owner, repo: repo, title: title, body: body, labels: labels);
  }

  Future<issue_models.Issue> updateIssue({
    required String owner,
    required String repo,
    required int issueNumber,
    String? title,
    String? body,
    String? state,
    List<String>? labels,
  }) {
    final api = GitHubIssuesApi(this);
    return api.updateIssue(
      owner: owner, repo: repo, issueNumber: issueNumber,
      title: title, body: body, state: state, labels: labels,
    );
  }

  Future<issue_models.Issue> closeIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    final api = GitHubIssuesApi(this);
    return api.closeIssue(owner: owner, repo: repo, issueNumber: issueNumber);
  }

  Future<issue_models.Issue> reopenIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    final api = GitHubIssuesApi(this);
    return api.reopenIssue(owner: owner, repo: repo, issueNumber: issueNumber);
  }

  Future<bool> validateRepository({
    required String owner,
    required String repo,
  }) {
    final api = GitHubRepositoriesApi(this);
    return api.validateRepository(owner: owner, repo: repo);
  }

  Future<List<repo_models.GitHubRepository>> getUserRepositories({
    String? token,
    String visibility = 'all',
    int perPage = 100,
  }) {
    final api = GitHubRepositoriesApi(this);
    return api.getUserRepositories(token: token, visibility: visibility, perPage: perPage);
  }

  Future<repo_models.GitHubRepository> createRepository({
    required String name,
    String? description,
    bool isPrivate = false,
    bool hasIssues = true,
    bool hasWiki = false,
    bool autoInit = true,
  }) {
    final api = GitHubRepositoriesApi(this);
    return api.createRepository(
      name: name, description: description, isPrivate: isPrivate,
      hasIssues: hasIssues, hasWiki: hasWiki, autoInit: autoInit,
    );
  }
}
