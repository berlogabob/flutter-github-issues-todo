import 'repo_item.dart';
import 'issue_item.dart';

/// Model for cached dashboard data
class CachedDashboardData {
  final List<RepoItem> repositories;
  final List<Map<String, dynamic>> projects;
  final List<IssueItem> localIssues;
  final DateTime? timestamp;

  CachedDashboardData({
    required this.repositories,
    required this.projects,
    required this.localIssues,
    this.timestamp,
  });

  /// Check if cached data is stale (>5 minutes old)
  bool get isStale {
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp!).inMinutes > 5;
  }

  /// Check if cached data exists
  bool get hasData => repositories.isNotEmpty || localIssues.isNotEmpty;
}
