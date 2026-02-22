import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/issue.dart' as issue_models;
import '../models/github_repository.dart' as repo_models;
import '../utils/logger.dart';

/// GitHub Service - All GitHub API interactions
///
/// Handles:
/// - Authentication with PAT and OAuth
/// - Fetching issues
/// - Creating/updating issues
/// - Error handling and retry logic
/// - Repository management
class GitHubService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // GitHub API base URL
  static const String baseUrl = 'https://api.github.com';

  // OAuth configuration
  // Note: For production, use a proper OAuth redirect URI registered with GitHub
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
    } catch (e) {
      Logger.e('Failed to read token from storage', error: e, context: 'GitHub');
      throw Exception('No GitHub token found. Please login first.');
    }
  }

  // Common headers for all requests
  Future<Map<String, String>> get _headers async {
    final token = await _token;
    return {
      'Authorization': 'token $token',
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitDoIt-App',
      'Content-Type': 'application/json',
    };
  }

  /// Fetch issues from a repository
  ///
  /// [owner] - Repository owner (username or org)
  /// [repo] - Repository name
  /// [state] - Filter by state: 'open', 'closed', or 'all'
  /// [perPage] - Number of issues per page (max 100)
  Future<List<issue_models.Issue>> fetchIssues({
    required String owner,
    required String repo,
    String state = 'open',
    int perPage = 50,
  }) async {
    final metric = Logger.startMetric('fetchIssues', 'GitHub');
    Logger.d(
      'Fetching issues: $owner/$repo (state: $state)',
      context: 'GitHub',
      metadata: {
        'repository': '$owner/$repo',
        'state': state,
        'per_page': perPage,
      },
    );

    try {
      // Build URL with query parameters
      final uri = Uri.parse(
        '$baseUrl/repos/$owner/$repo/issues?state=$state&per_page=$perPage',
      );

      final response = await _client.get(uri, headers: await _headers);

      Logger.d(
        'GitHub API response: ${response.statusCode}',
        context: 'GitHub',
        metadata: {'status_code': response.statusCode},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final issues = jsonList
            .map((json) => issue_models.Issue.fromJson(json))
            .toList();

        Logger.i('Fetched ${issues.length} issues', context: 'GitHub');
        metric.complete(success: true);
        return issues;
      } else {
        Logger.e(
          'Failed to fetch issues: ${response.statusCode}',
          context: 'GitHub',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        throw Exception('Failed to fetch issues: ${response.statusCode}');
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error fetching issues',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error fetching issues',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Create a new issue
  Future<issue_models.Issue> createIssue({
    required String owner,
    required String repo,
    required String title,
    String? body,
    List<String>? labels,
    int? milestone,
    List<String>? assignees,
  }) async {
    final metric = Logger.startMetric('createIssue', 'GitHub');
    Logger.d(
      'Creating issue: "$title" in $owner/$repo',
      context: 'GitHub',
      metadata: {'has_body': body != null, 'has_labels': labels != null},
    );

    try {
      final uri = Uri.parse('$baseUrl/repos/$owner/$repo/issues');

      // Build request body
      final requestBody = <String, dynamic>{'title': title};

      if (body != null && body.isNotEmpty) {
        requestBody['body'] = body;
      }

      if (labels != null && labels.isNotEmpty) {
        requestBody['labels'] = labels;
      }

      if (milestone != null) {
        requestBody['milestone'] = milestone;
      }

      if (assignees != null && assignees.isNotEmpty) {
        requestBody['assignees'] = assignees;
      }

      final response = await _client.post(
        uri,
        headers: await _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final issue = issue_models.Issue.fromJson(json.decode(response.body));
        Logger.i('Created issue #${issue.number}', context: 'GitHub');
        metric.complete(success: true);
        return issue;
      } else {
        Logger.e(
          'Failed to create issue: ${response.statusCode}',
          context: 'GitHub',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        throw Exception('Failed to create issue: ${response.statusCode}');
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error creating issue',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error creating issue',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Update an existing issue
  Future<issue_models.Issue> updateIssue({
    required String owner,
    required String repo,
    required int issueNumber,
    String? title,
    String? body,
    String? state,
    List<String>? labels,
    int? milestone,
    List<String>? assignees,
  }) async {
    final metric = Logger.startMetric('updateIssue', 'GitHub');
    Logger.d(
      'Updating issue #$issueNumber in $owner/$repo',
      context: 'GitHub',
      metadata: {'state': state},
    );

    try {
      final uri = Uri.parse('$baseUrl/repos/$owner/$repo/issues/$issueNumber');

      // Build request body with only provided fields
      final requestBody = <String, dynamic>{};

      if (title != null) {
        requestBody['title'] = title;
      }

      if (body != null) {
        requestBody['body'] = body;
      }

      if (state != null) {
        requestBody['state'] = state;
      }

      if (labels != null) {
        requestBody['labels'] = labels;
      }

      if (milestone != null) {
        requestBody['milestone'] = milestone;
      }

      if (assignees != null) {
        requestBody['assignees'] = assignees;
      }

      final response = await _client.patch(
        uri,
        headers: await _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final issue = issue_models.Issue.fromJson(json.decode(response.body));
        Logger.i('Updated issue #${issue.number}', context: 'GitHub');
        metric.complete(success: true);
        return issue;
      } else {
        Logger.e(
          'Failed to update issue: ${response.statusCode}',
          context: 'GitHub',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        throw Exception('Failed to update issue: ${response.statusCode}');
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error updating issue',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error updating issue',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Close an issue
  Future<issue_models.Issue> closeIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    Logger.d('Closing issue #$issueNumber', context: 'GitHub');

    return updateIssue(
      owner: owner,
      repo: repo,
      issueNumber: issueNumber,
      state: 'closed',
    );
  }

  /// Reopen a closed issue
  Future<issue_models.Issue> reopenIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    Logger.d('Reopening issue #$issueNumber', context: 'GitHub');

    return updateIssue(
      owner: owner,
      repo: repo,
      issueNumber: issueNumber,
      state: 'open',
    );
  }

  /// Get current authenticated user
  Future<repo_models.User> getCurrentUser() async {
    Logger.d('Fetching current user', context: 'GitHub');

    try {
      final uri = Uri.parse('$baseUrl/user');
      final response = await _client.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        return repo_models.User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get user: ${response.statusCode}');
      }
    } catch (e) {
      Logger.e('Error getting user', error: e, context: 'GitHub');
      rethrow;
    }
  }

  /// Check token permissions
  Future<Map<String, bool>> checkTokenPermissions() async {
    Logger.d('Checking token permissions', context: 'GitHub');

    try {
      // Get the X-OAuth-Scopes header from response
      final uri = Uri.parse('$baseUrl/user');
      final response = await _client.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final scopes = response.headers['x-oauth-scopes'] ?? '';
        Logger.d('Token scopes: $scopes', context: 'GitHub');

        // Parse scopes
        final scopeList = scopes.split(',').map((s) => s.trim()).toList();

        return {
          'repo': scopeList.contains('repo'),
          'issues':
              scopeList.contains('public_repo') || scopeList.contains('repo'),
          'user': scopeList.contains('user'),
        };
      } else {
        return {};
      }
    } catch (e) {
      Logger.e('Error checking permissions', error: e, context: 'GitHub');
      return {};
    }
  }

  /// Validate if a repository exists on GitHub
  ///
  /// Returns `true` if the repository exists and is accessible,
  /// `false` otherwise.
  Future<bool> validateRepository({
    required String owner,
    required String repo,
  }) async {
    final metric = Logger.startMetric('validateRepository', 'GitHub');
    Logger.d(
      'Validating repository: $owner/$repo',
      context: 'GitHub',
      metadata: {'repository': '$owner/$repo'},
    );

    try {
      final uri = Uri.parse('$baseUrl/repos/$owner/$repo');
      final response = await _client.get(uri, headers: await _headers);

      Logger.d(
        'Repository validation response: ${response.statusCode}',
        context: 'GitHub',
        metadata: {'status_code': response.statusCode},
      );

      if (response.statusCode == 200) {
        Logger.i('Repository validated: $owner/$repo', context: 'GitHub');
        metric.complete(success: true);
        return true;
      } else if (response.statusCode == 404) {
        Logger.w('Repository not found: $owner/$repo', context: 'GitHub');
        metric.complete(
          success: false,
          errorCode: 404,
          errorMessage: 'Repository not found',
        );
        return false;
      } else {
        Logger.e(
          'Failed to validate repository: ${response.statusCode}',
          context: 'GitHub',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        throw Exception(
          'Failed to validate repository: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error validating repository',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error validating repository',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // ==================== OAuth Methods ====================

  /// Generate OAuth URL for GitHub authentication
  ///
  /// Returns the URL to redirect user to for GitHub OAuth login
  String getOAuthUrl() {
    final uri = Uri.parse('https://github.com/login/oauth/authorize').replace(
      queryParameters: {
        'client_id': oauthClientId,
        'redirect_uri': oauthRedirectUri,
        'scope': oauthScope,
        'state': _generateState(),
      },
    );

    Logger.d(
      'Generated OAuth URL',
      context: 'GitHub',
      metadata: {'url': uri.toString()},
    );
    return uri.toString();
  }

  /// Generate a random state parameter for OAuth security
  String _generateState() {
    // In production, use a cryptographically secure random string
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'state_$now';
  }

  /// Handle OAuth callback - exchange code for access token
  ///
  /// [code] - The authorization code received from GitHub callback
  /// [state] - The state parameter to verify (optional)
  ///
  /// Returns the access token
  Future<String> handleOAuthCallback({
    required String code,
    String? state,
  }) async {
    final metric = Logger.startMetric('handleOAuthCallback', 'GitHub');
    Logger.d('Exchanging OAuth code for token', context: 'GitHub');

    try {
      final uri = Uri.parse('https://github.com/login/oauth/access_token');

      final response = await _client.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'client_id': oauthClientId,
          'client_secret': oauthClientSecret,
          'code': code,
          'redirect_uri': oauthRedirectUri,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data.containsKey('error')) {
          final error = data['error'] ?? 'Unknown OAuth error';
          Logger.e('OAuth error: $error', context: 'GitHub');
          metric.complete(success: false, errorMessage: error);
          throw Exception('OAuth error: $error');
        }

        final accessToken = data['access_token'] as String?;
        if (accessToken == null || accessToken.isEmpty) {
          Logger.e('No access token in OAuth response', context: 'GitHub');
          metric.complete(
            success: false,
            errorMessage: 'No access token received',
          );
          throw Exception('No access token received');
        }

        Logger.i('OAuth token obtained successfully', context: 'GitHub');
        metric.complete(success: true);
        return accessToken;
      } else {
        Logger.e(
          'Failed to exchange OAuth code: ${response.statusCode}',
          context: 'GitHub',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        throw Exception(
          'Failed to exchange OAuth code: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error during OAuth',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error handling OAuth callback',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Launch OAuth URL in browser
  ///
  /// [oauthUrl] - The OAuth URL to launch
  ///
  /// Returns true if the URL was launched successfully
  Future<bool> launchOAuthUrl(String oauthUrl) async {
    Logger.d('Launching OAuth URL in browser', context: 'GitHub');

    try {
      final uri = Uri.parse(oauthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.i('OAuth URL launched successfully', context: 'GitHub');
        return true;
      } else {
        Logger.e('Cannot launch OAuth URL', context: 'GitHub');
        throw Exception('Cannot open browser for authentication');
      }
    } catch (e, stackTrace) {
      Logger.e(
        'Error launching OAuth URL',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      rethrow;
    }
  }

  // ==================== Repository Methods ====================

  /// Get authenticated user's repositories
  ///
  /// [token] - GitHub access token
  /// [visibility] - Filter by visibility: 'all', 'public', or 'private'
  /// [affiliation] - Filter by affiliation: 'owner,collaborator,organization_member'
  /// [sort] - Sort by: 'created', 'updated', 'pushed', 'full_name'
  /// [direction] - Sort direction: 'asc' or 'desc'
  /// [perPage] - Number of repos per page (max 100)
  ///
  /// Returns list of repositories
  Future<List<repo_models.GitHubRepository>> getUserRepositories({
    required String token,
    String visibility = 'all',
    String affiliation = 'owner,collaborator,organization_member',
    String sort = 'updated',
    String direction = 'desc',
    int perPage = 100,
  }) async {
    final metric = Logger.startMetric('getUserRepositories', 'GitHub');
    Logger.d(
      'Fetching user repositories',
      context: 'GitHub',
      metadata: {'visibility': visibility, 'sort': sort, 'per_page': perPage},
    );

    try {
      final uri = Uri.parse('$baseUrl/user/repos').replace(
        queryParameters: {
          'visibility': visibility,
          'affiliation': affiliation,
          'sort': sort,
          'direction': direction,
          'per_page': perPage.toString(),
        },
      );

      final headers = {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'GitDoIt-App',
        'Content-Type': 'application/json',
      };

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final repositories = jsonList
            .map(
              (json) => repo_models.GitHubRepository.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();

        Logger.i(
          'Fetched ${repositories.length} repositories',
          context: 'GitHub',
        );
        metric.complete(success: true);
        return repositories;
      } else {
        Logger.e(
          'Failed to fetch repositories: ${response.statusCode}',
          context: 'GitHub',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: 'HTTP ${response.statusCode}',
        );
        throw Exception('Failed to fetch repositories: ${response.statusCode}');
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error fetching repositories',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error fetching repositories',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Create a new repository
  ///
  /// [token] - GitHub access token
  /// [name] - Repository name
  /// [description] - Repository description (optional)
  /// [private] - Whether repository should be private (default: false)
  /// [hasIssues] - Enable issues for this repository (default: true)
  ///
  /// Returns the created repository
  Future<repo_models.GitHubRepository> createRepository({
    required String token,
    required String name,
    String? description,
    bool private = false,
    bool hasIssues = true,
  }) async {
    final metric = Logger.startMetric('createRepository', 'GitHub');
    Logger.d(
      'Creating repository: "$name"',
      context: 'GitHub',
      metadata: {'name': name, 'private': private, 'has_issues': hasIssues},
    );

    try {
      final uri = Uri.parse('$baseUrl/user/repos');

      final headers = {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'GitDoIt-App',
        'Content-Type': 'application/json',
      };

      final requestBody = <String, dynamic>{
        'name': name,
        'private': private,
        'has_issues': hasIssues,
        'has_projects': true,
        'has_wiki': false,
        'auto_init': false,
      };

      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }

      final response = await _client.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final repository = repo_models.GitHubRepository.fromJson(
          json.decode(response.body),
        );
        Logger.i(
          'Created repository: ${repository.fullName}',
          context: 'GitHub',
        );
        metric.complete(success: true);
        return repository;
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorBody?['message'] ?? 'Unknown error';

        Logger.e(
          'Failed to create repository: ${response.statusCode} - $errorMessage',
          context: 'GitHub',
          metadata: {'status_code': response.statusCode},
        );
        metric.complete(
          success: false,
          errorCode: response.statusCode,
          errorMessage: errorMessage,
        );
        throw Exception('Failed to create repository: $errorMessage');
      }
    } on http.ClientException catch (e, stackTrace) {
      Logger.e(
        'Network error creating repository',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: 'Network error');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e(
        'Error creating repository',
        error: e,
        stackTrace: stackTrace,
        context: 'GitHub',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Dispose - clean up HTTP client
  void dispose() {
    _client.close();
    Logger.d('GitHubService disposed', context: 'GitHub');
  }
}
