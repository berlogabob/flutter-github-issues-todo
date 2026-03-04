import 'package:flutter/material.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import 'expandable_repo.dart';

/// Repository list widget for main dashboard
class RepoList extends StatelessWidget {
  final List<RepoItem> repositories;
  final GitHubApiService githubApi;
  final String? expandedRepoId;
  final Function(String, bool)? onExpandToggle;
  final ValueChanged<IssueItem>? onIssueTap;
  final String filterStatus;
  final bool hideUsernameInRepo;
  final Set<String> pinnedRepos;
  final ValueChanged<String> onPinToggle;

  const RepoList({
    super.key,
    required this.repositories,
    required this.githubApi,
    this.expandedRepoId,
    this.onExpandToggle,
    this.onIssueTap,
    required this.filterStatus,
    required this.hideUsernameInRepo,
    required this.pinnedRepos,
    required this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Filter repositories and issues based on selected filter
    final filteredRepos = _filterRepos();

    // Sort repos - pinned ones first
    final sortedFilteredRepos = _getSortedRepos(filteredRepos);

    // Find the index where unpinned repos start
    int? dividerIndex;
    for (int i = 0; i < sortedFilteredRepos.length; i++) {
      if (!pinnedRepos.contains(sortedFilteredRepos[i].fullName)) {
        if (i > 0) {
          dividerIndex = i;
        }
        break;
      }
    }

    // Add top padding if first repo is pinned to avoid overlap with filters
    final double topPadding =
        (dividerIndex != null ||
            (sortedFilteredRepos.isNotEmpty &&
                pinnedRepos.contains(sortedFilteredRepos.first.fullName)))
        ? 8.0
        : 0.0;

    return ListView.builder(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.02,
        right: MediaQuery.of(context).size.width * 0.02,
        top: topPadding,
      ),
      itemCount: sortedFilteredRepos.length,
      itemBuilder: (context, index) {
        final repo = sortedFilteredRepos[index];
        final isPinned = pinnedRepos.contains(repo.fullName);

        // Add divider after pinned repos
        if (dividerIndex != null && index == dividerIndex) {
          return Column(
            children: [
              _buildRepoItem(repo, isPinned),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          );
        }

        return _buildRepoItem(repo, isPinned);
      },
    );
  }

  Widget _buildRepoItem(RepoItem repo, bool isPinned) {
    return ExpandableRepo(
      key: ValueKey('repo-${repo.id}'),
      repo: repo,
      githubApi: githubApi,
      onIssueTap: onIssueTap,
      isExpanded: expandedRepoId == repo.id,
      onExpandToggle: (expanded) => onExpandToggle?.call(repo.id, expanded),
      hideUsernameInRepo: hideUsernameInRepo,
      isPinned: isPinned,
      onPinToggle: () => onPinToggle(repo.fullName),
    );
  }

  List<RepoItem> _filterRepos() {
    final filteredRepos = <RepoItem>[];
    for (final repo in repositories) {
      final filteredIssues = repo.children.where((item) {
        // Cast to IssueItem for filtering
        final issue = item is IssueItem ? item : null;
        if (issue == null) return false;

        // Filter by status
        if (filterStatus == 'all') {
          // Continue
        } else if (filterStatus == 'open') {
          if (issue.status != ItemStatus.open) return false;
        } else if (filterStatus == 'closed') {
          if (issue.status != ItemStatus.closed) return false;
        }

        return true;
      }).toList();

      // Include repo if:
      // 1. Filter is 'all' - always show
      // 2. Filter is 'open' or 'closed' - show if has matching issues OR issues not loaded yet (children.isEmpty)
      final bool shouldIncludeRepo = filterStatus == 'all' 
          || filteredIssues.isNotEmpty 
          || repo.children.isEmpty;
      
      if (shouldIncludeRepo) {
        final filteredRepo = RepoItem(
          id: repo.id,
          title: repo.title,
          fullName: repo.fullName,
          description: repo.description,
          status: repo.status,
          children: filteredIssues,
        );
        filteredRepos.add(filteredRepo);
      }
    }
    return filteredRepos;
  }

  List<RepoItem> _getSortedRepos(List<RepoItem> repos) {
    final sorted = List<RepoItem>.from(repos);
    sorted.sort((a, b) {
      final aPinned = pinnedRepos.contains(a.fullName);
      final bPinned = pinnedRepos.contains(b.fullName);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });
    return sorted;
  }
}
