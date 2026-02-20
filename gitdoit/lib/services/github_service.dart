import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/issue.dart';
import '../utils/logger.dart';

/// GitHub Service - All GitHub API interactions
///
/// Handles:
/// - Authentication with PAT
/// - Fetching issues
/// - Creating/updating issues
/// - Error handling and retry logic
class GitHubService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // GitHub API base URL
  static const String baseUrl = 'https://api.github.com';

  // HTTP client
  final http.Client _client = http.Client();

  // Get authenticated token
  Future<String> get _token async {
    final token = await _storage.read(key: 'github_token');
    if (token == null || token.isEmpty) {
      Logger.e('No token found', context: 'GitHub');
      throw Exception('No GitHub token found. Please login first.');
    }
    return token;
  }

  // Common headers for all requests
  Future<Map<String, String>> get _headers async {
    final token = await _token;
    return {
      'Authorization': 'Bearer $token',
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
  Future<List<Issue>> fetchIssues({
    required String owner,
    required String repo,
    String state = 'open',
    int perPage = 50,
  }) async {
    Logger.d(
      'Fetching issues: $owner/$repo (state: $state)',
      context: 'GitHub',
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
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final issues = jsonList.map((json) => Issue.fromJson(json)).toList();

        Logger.i('Fetched ${issues.length} issues', context: 'GitHub');

        return issues;
      } else {
        Logger.e(
          'Failed to fetch issues: ${response.statusCode}',
          context: 'GitHub',
        );
        throw Exception('Failed to fetch issues: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error fetching issues', error: e, context: 'GitHub');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      Logger.e('Error fetching issues', error: e, context: 'GitHub');
      rethrow;
    }
  }

  /// Create a new issue
  Future<Issue> createIssue({
    required String owner,
    required String repo,
    required String title,
    String? body,
    List<String>? labels,
    int? milestone,
    List<String>? assignees,
  }) async {
    Logger.d('Creating issue: "$title" in $owner/$repo', context: 'GitHub');

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
        final issue = Issue.fromJson(json.decode(response.body));
        Logger.i('Created issue #${issue.number}', context: 'GitHub');
        return issue;
      } else {
        Logger.e(
          'Failed to create issue: ${response.statusCode}',
          context: 'GitHub',
        );
        throw Exception('Failed to create issue: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error creating issue', error: e, context: 'GitHub');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      Logger.e('Error creating issue', error: e, context: 'GitHub');
      rethrow;
    }
  }

  /// Update an existing issue
  Future<Issue> updateIssue({
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
    Logger.d('Updating issue #$issueNumber in $owner/$repo', context: 'GitHub');

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
        final issue = Issue.fromJson(json.decode(response.body));
        Logger.i('Updated issue #${issue.number}', context: 'GitHub');
        return issue;
      } else {
        Logger.e(
          'Failed to update issue: ${response.statusCode}',
          context: 'GitHub',
        );
        throw Exception('Failed to update issue: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error updating issue', error: e, context: 'GitHub');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      Logger.e('Error updating issue', error: e, context: 'GitHub');
      rethrow;
    }
  }

  /// Close an issue
  Future<Issue> closeIssue({
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
  Future<Issue> reopenIssue({
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
  Future<User> getCurrentUser() async {
    Logger.d('Fetching current user', context: 'GitHub');

    try {
      final uri = Uri.parse('$baseUrl/user');
      final response = await _client.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
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

  /// Dispose - clean up HTTP client
  void dispose() {
    _client.close();
    Logger.d('GitHubService disposed', context: 'GitHub');
  }
}
