import 'package:flutter/foundation.dart';

import '../models/issue.dart';
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
  final GitHubService _githubService = GitHubService();

  // Current state
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch issues from GitHub API
  ///
  /// [owner] - Repository owner
  /// [repo] - Repository name
  /// [state] - Filter by state: 'open', 'closed', or 'all'
  /// [perPage] - Number of issues per page (max 100)
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
      final issues = await _githubService.fetchIssues(
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
  ///
  /// [owner] - Repository owner
  /// [repo] - Repository name
  /// [title] - Issue title
  /// [body] - Issue description (optional)
  /// [labels] - Issue labels (optional)
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
      final issue = await _githubService.createIssue(
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
  ///
  /// [owner] - Repository owner
  /// [repo] - Repository name
  /// [issueNumber] - Issue number to update
  /// [title] - New title (optional)
  /// [body] - New description (optional)
  /// [state] - New state: 'open' or 'closed' (optional)
  /// [labels] - New labels (optional)
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
      final issue = await _githubService.updateIssue(
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
  ///
  /// [owner] - Repository owner
  /// [repo] - Repository name
  /// [issueNumber] - Issue number to close
  Future<Issue> closeIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    Logger.d('Closing issue #$issueNumber', context: 'IssuesRepository');
    return updateIssue(
      owner: owner,
      repo: repo,
      issueNumber: issueNumber,
      state: 'closed',
    );
  }

  /// Reopen a closed issue on GitHub
  ///
  /// [owner] - Repository owner
  /// [repo] - Repository name
  /// [issueNumber] - Issue number to reopen
  Future<Issue> reopenIssue({
    required String owner,
    required String repo,
    required int issueNumber,
  }) {
    Logger.d('Reopening issue #$issueNumber', context: 'IssuesRepository');
    return updateIssue(
      owner: owner,
      repo: repo,
      issueNumber: issueNumber,
      state: 'open',
    );
  }

  /// Validate that a repository exists on GitHub
  ///
  /// [owner] - Repository owner
  /// [repo] - Repository name
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
      final isValid = await _githubService.validateRepository(
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
    _githubService.dispose();
    Logger.d('IssuesRepository disposed', context: 'IssuesRepository');
    super.dispose();
  }
}
