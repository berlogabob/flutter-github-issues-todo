import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../widgets/braille_loader.dart';
import '../widgets/label_chip.dart';
import 'issue_detail_screen.dart';

/// Screen displaying detailed information about a single GitHub repository.
///
/// Features:
/// - Repository information and description
/// - Issue statistics (open/closed counts)
/// - List of all repository issues
/// - Pull-to-refresh functionality
/// - Open repository in browser
/// - Navigate to issue details
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => RepoDetailScreen(
///       owner: 'owner',
///       repo: 'repo',
///     ),
///   ),
/// );
/// ```
class RepoDetailScreen extends ConsumerStatefulWidget {
  /// Repository owner login.
  final String owner;

  /// Repository name.
  final String repo;

  /// Creates the repository detail screen.
  ///
  /// [owner] is the repository owner login (required).
  /// [repo] is the repository name (required).
  const RepoDetailScreen({super.key, required this.owner, required this.repo});

  @override
  ConsumerState<RepoDetailScreen> createState() => _RepoDetailScreenState();
}

class _RepoDetailScreenState extends ConsumerState<RepoDetailScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  RepoItem? _repoInfo;
  List<IssueItem> _issues = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRepoDetails();
  }

  Future<void> _loadRepoDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch repo details
      final repos = await _githubApi.fetchMyRepositories(perPage: 100);
      final repo = repos.firstWhere(
        (r) => r.fullName == '${widget.owner}/${widget.repo}',
        orElse: () => throw Exception('Repository not found'),
      );

      // Fetch issues
      final issues = await _githubApi.fetchIssues(widget.owner, widget.repo);

      if (mounted) {
        setState(() {
          _repoInfo = repo;
          _issues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '${widget.owner}/${widget.repo}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: AppColors.link),
            onPressed: _openInBrowser,
            tooltip: 'Open on GitHub',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrailleLoader(size: 32),
            SizedBox(height: 16),
            Text(
              'Loading repository...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load repository',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRepoDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRepoDetails,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRepoInfoCard(),
          const SizedBox(height: 24),
          _buildIssuesSection(),
        ],
      ),
    );
  }

  Widget _buildRepoInfoCard() {
    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _repoInfo?.title ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_repoInfo?.description != null &&
                _repoInfo!.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _repoInfo!.description!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  Icons.bug_report,
                  '${_issues.where((i) => i.status == ItemStatus.open).length}',
                  'Open',
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.check_circle_outline,
                  '${_issues.where((i) => i.status == ItemStatus.closed).length}',
                  'Closed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Issues (${_issues.length})',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_issues.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No issues found',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ..._issues.map((issue) => _buildIssueTile(issue)),
      ],
    );
  }

  Widget _buildIssueTile(IssueItem issue) {
    final isOpen = issue.status == ItemStatus.open;

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isOpen ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: isOpen ? Colors.green : Colors.red,
          size: 24,
        ),
        title: Text(
          '#${issue.number} ${issue.title}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: issue.labels.isNotEmpty
            ? Wrap(
                spacing: 4,
                runSpacing: 4,
                children: issue.labels
                    .take(3)
                    .map((label) => LabelChipWidget(label: label))
                    .toList(),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.error,
          size: 20,
        ),
        onTap: () => _openIssue(issue),
      ),
    );
  }

  void _openIssue(IssueItem issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IssueDetailScreen(
          issue: issue,
          owner: widget.owner,
          repo: widget.repo,
        ),
      ),
    );
  }

  void _openInBrowser() async {
    final url = 'https://github.com/${widget.owner}/${widget.repo}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
