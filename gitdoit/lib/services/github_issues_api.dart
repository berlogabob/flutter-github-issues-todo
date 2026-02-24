import 'dart:convert';
import 'package:http/http.dart' as http;

import 'github_service.dart';
import '../models/issue.dart' as issue_models;
import '../utils/logger.dart';

/// GitHub Issues API - Issue-related operations
///
/// Handles:
/// - Fetching issues
/// - Creating issues
/// - Updating issues
/// - Closing/reopening issues
class GitHubIssuesApi {
  final GitHubService _baseService;
  final http.Client _client;

  GitHubIssuesApi(this._baseService) : _client = http.Client();

  /// Fetch issues from a repository
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
      final uri = Uri.parse(
        '${GitHubService.baseUrl}/repos/$owner/$repo/issues?state=$state&per_page=$perPage',
      );

      final response = await _client.get(uri, headers: await _baseService.headers);

      Logger.d(
        'GitHub API response: ${response.statusCode}',
        context: 'GitHub',
        metadata: {'status_code': response.statusCode},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final issues = jsonList.map((json) => issue_models.Issue.fromJson(json)).toList();

        Logger.i('Fetched ${issues.length} issues', context: 'GitHub');
        metric.complete(success: true);
        return issues;
      } else {
        Logger.e('Failed to fetch issues', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
        });
        metric.complete(success: false, errorCode: response.statusCode);
        throw Exception('Failed to fetch issues: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error fetching issues', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e('Error fetching issues', error: e, stackTrace: stackTrace, context: 'GitHub');
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
    Logger.d('Creating issue: "$title" in $owner/$repo', context: 'GitHub');

    try {
      final uri = Uri.parse('${GitHubService.baseUrl}/repos/$owner/$repo/issues');

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
        headers: await _baseService.headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final issue = issue_models.Issue.fromJson(json.decode(response.body));
        Logger.i('Created issue #${issue.number}', context: 'GitHub');
        metric.complete(success: true);
        return issue;
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = errorBody['message'] as String? ?? 'Unknown error';
        Logger.e('Failed to create issue', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
          'error': errorMessage,
        });
        metric.complete(success: false, errorCode: response.statusCode, errorMessage: errorMessage);
        throw Exception('Failed to create issue: $errorMessage');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error creating issue', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e('Error creating issue', error: e, stackTrace: stackTrace, context: 'GitHub');
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
    Logger.d('Updating issue #$issueNumber in $owner/$repo', context: 'GitHub');

    try {
      final uri = Uri.parse('${GitHubService.baseUrl}/repos/$owner/$repo/issues/$issueNumber');

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
        headers: await _baseService.headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final issue = issue_models.Issue.fromJson(json.decode(response.body));
        Logger.i('Updated issue #${issue.number}', context: 'GitHub');
        metric.complete(success: true);
        return issue;
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = errorBody['message'] as String? ?? 'Unknown error';
        Logger.e('Failed to update issue', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
          'error': errorMessage,
        });
        metric.complete(success: false, errorCode: response.statusCode, errorMessage: errorMessage);
        throw Exception('Failed to update issue: $errorMessage');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error updating issue', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e('Error updating issue', error: e, stackTrace: stackTrace, context: 'GitHub');
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

  /// Dispose HTTP client
  void dispose() {
    _client.close();
    Logger.d('GitHubIssuesApi disposed', context: 'GitHub');
  }
}
