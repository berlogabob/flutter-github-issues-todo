import '../models/issue_item.dart';
import '../models/item.dart';
import 'github_api_service.dart';

/// Service for issue-related business logic
class IssueService {
  final GitHubApiService _githubApi;

  IssueService({GitHubApiService? githubApi})
    : _githubApi = githubApi ?? GitHubApiService();

  /// Toggle issue status (open/close)
  Future<IssueItem> toggleIssueStatus(
    IssueItem issue,
    String owner,
    String repo,
  ) async {
    if (issue.isLocalOnly || issue.number == null) {
      // Local issue - just update state
      return issue.copyWith(
        status: issue.status == ItemStatus.open
            ? ItemStatus.closed
            : ItemStatus.open,
      );
    }

    // GitHub issue - call API
    final newStatus = issue.status == ItemStatus.open ? 'closed' : 'open';
    return await _githubApi.updateIssue(
      owner,
      repo,
      issue.number!,
      state: newStatus,
    );
  }

  /// Close issue
  Future<IssueItem> closeIssue(
    IssueItem issue,
    String owner,
    String repo,
  ) async {
    if (issue.isLocalOnly || issue.number == null) {
      return issue.copyWith(status: ItemStatus.closed);
    }
    return await _githubApi.updateIssue(
      owner,
      repo,
      issue.number!,
      state: 'closed',
    );
  }

  /// Reopen issue
  Future<IssueItem> reopenIssue(
    IssueItem issue,
    String owner,
    String repo,
  ) async {
    if (issue.isLocalOnly || issue.number == null) {
      return issue.copyWith(status: ItemStatus.open);
    }
    return await _githubApi.updateIssue(
      owner,
      repo,
      issue.number!,
      state: 'open',
    );
  }
}
