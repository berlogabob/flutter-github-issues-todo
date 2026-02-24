import 'package:flutter/foundation.dart';

import '../models/issue.dart';
import '../services/github_issues_api.dart';
import '../services/github_repositories_api.dart';
import '../services/github_service.dart';
import '../utils/logger.dart';

/// Issues Repository - Handles GitHub API operations for issues
///
/// Responsible for:
/// - Fetching issues from GitHub API
/// - Creating new issues
/// - Updating existing issues
/// - Closing/reopening issues
/// - Repository validation
class IssuesRepository extends ChangeNotifier {
  final GitHubService _baseService = GitHubService();
  late GitHubIssuesApi _issuesApi;
  late GitHubRepositoriesApi _reposApi;

  IssuesRepository() {
    _issuesApi = GitHubIssuesApi(_baseService);
    _reposApi = GitHubRepositoriesApi(_baseService);
  }

  // Current state
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch issues from GitHub API
  Future<List<Issue>> fetchIssues({
    required String owner,
    required String repo,
    String state = 'open',
    int perPage = 50,
  }) async {
    final metric = Logger.startMetric('fetchIssues', 'IssuesRepository');
    Logger.d(
      'Fetching issues: $owner/$repo (state: $state)',
      context: 'IssuesRepository',
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final issues = await _issuesApi.fetchIssues(
        owner: owner,
        repo: repo,
        state: state,
        perPage: perPage,
      );

      Logger.i('Fetched ${issues.length} issues', context: 'IssuesRepository');
      metric.complete(success: true);
      return issues;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to fetch issues',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesRepository',
      );
      _error = e.toString().replaceAll('Exception: ', '');
      metric.complete(success: false, errorMessage: _error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new issue on GitHub
  Future<Issue> createIssue({
    required String owner,
    required String repo,
    required String title,
    String? body,
    List<String>? labels,
  }) async {
    final metric = Logger.startMetric('createIssue', 'IssuesRepository');
    Logger.d('Creating issue: "$title" in $owner/$repo', context: 'IssuesRepository');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final issue = await _issuesApi.createIssue(
        owner: owner,
        repo: repo,
        title: title,
        body: body,
        labels: labels,
      );

      Logger.i('Created issue #${issue.number}', context: 'IssuesRepository');
      metric.complete(success: true);
      return issue;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to create issue',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesRepository',
      );
      _error = e.toString().replaceAll('Exception: ', '');
      metric.complete(success: false, errorMessage: _error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing issue on GitHub
  Future<Issue> updateIssue({
    required String owner,
    required String repo,
    required int issueNumber,
    String? title,
    String? body,
    String? state,
    List<String>? labels,
  }) async {
    final metric = Logger.startMetric('updateIssue', 'IssuesRepository');
    Logger.d('Updating issue #$issueNumber in $owner/$repo', context: 'IssuesRepository');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final issue = await _issuesApi.updateIssue(
        owner: owner,
        repo: repo,
        issueNumber: issueNumber,
        title: title,
        body: body,
        state: state,
        labels: labels,
      );

      Logger.i('Updated issue #${issue.number}', context: 'IssuesRepository');
      metric.complete(success: true);
      return issue;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to update issue',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesRepository',
      );
      _error = e.toString().replaceAll('Exception: ', '');
      metric.complete(success: false, errorMessage: _error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Close an issue on GitHub
  Future<Issue> closeIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    Logger.d('Closing issue #$issueNumber', context: 'IssuesRepository');
    return _issuesApi.closeIssue(
      owner: owner,
      repo: repo,
      issueNumber: issueNumber,
    );
  }

  /// Reopen a closed issue on GitHub
  Future<Issue> reopenIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    Logger.d('Reopening issue #$issueNumber', context: 'IssuesRepository');
    return _issuesApi.reopenIssue(
      owner: owner,
      repo: repo,
      issueNumber: issueNumber,
    );
  }

  /// Validate that a repository exists on GitHub
  Future<bool> validateRepository({
    required String owner,
    required String repo,
  }) async {
    final metric = Logger.startMetric('validateRepository', 'IssuesRepository');
    Logger.d('Validating repository: $owner/$repo', context: 'IssuesRepository');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isValid = await _reposApi.validateRepository(
        owner: owner,
        repo: repo,
      );

      Logger.i(
        'Repository validation: ${isValid ? "valid" : "invalid"}',
        context: 'IssuesRepository',
      );
      metric.complete(success: true);
      return isValid;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to validate repository',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesRepository',
      );
      _error = e.toString().replaceAll('Exception: ', '');
      metric.complete(success: false, errorMessage: _error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _issuesApi.dispose();
    _reposApi.dispose();
    _baseService.dispose();
    Logger.d('IssuesRepository disposed', context: 'IssuesRepository');
    super.dispose();
  }
}
