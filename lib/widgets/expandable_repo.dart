import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../services/github_api_service.dart';
import 'issue_card.dart';

/// ExpandableRepo - Modular, reusable widget for displaying a repository with collapsible issues list
class ExpandableRepo extends StatefulWidget {
  final RepoItem repo;
  final GitHubApiService githubApi;
  final ValueChanged<IssueItem>? onIssueTap;
  final bool initiallyExpanded;
  final bool hideUsernameInRepo;
  final bool isPinned;
  final VoidCallback? onPinToggle;

  const ExpandableRepo({
    super.key,
    required this.repo,
    required this.githubApi,
    this.onIssueTap,
    this.initiallyExpanded = true,
    this.hideUsernameInRepo = false,
    this.isPinned = false,
    this.onPinToggle,
  });

  @override
  State<ExpandableRepo> createState() => _ExpandableRepoState();
}

class _ExpandableRepoState extends State<ExpandableRepo> {
  bool _isExpanded = true;
  bool _isLoadingIssues = false;
  bool _hasLoadedIssues = false;
  List<IssueItem> _issues = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    // Check if this is a vault repo (local)
    final isVaultRepo =
        widget.repo.id == 'vault' || widget.repo.fullName.startsWith('local/');

    // For vault repos, use local children directly without API call
    if (isVaultRepo) {
      _issues = widget.repo.children.whereType<IssueItem>().toList();
      _hasLoadedIssues = true;
    } else if (_isExpanded && widget.repo.children.isEmpty) {
      // Only fetch from GitHub for non-vault repos
      _loadIssues();
    }
  }

  Future<void> _loadIssues() async {
    if (_hasLoadedIssues || _isLoadingIssues) return;

    // Skip loading for vault repos
    final isVaultRepo =
        widget.repo.id == 'vault' || widget.repo.fullName.startsWith('local/');
    if (isVaultRepo) {
      _issues = widget.repo.children.whereType<IssueItem>().toList();
      _hasLoadedIssues = true;
      return;
    }

    setState(() {
      _isLoadingIssues = true;
      _errorMessage = null;
    });

    try {
      final parts = widget.repo.fullName.split('/');
      if (parts.length != 2) {
        throw Exception('Invalid repo name format');
      }

      debugPrint('Loading issues for ${widget.repo.fullName}...');
      final issues = await widget.githubApi.fetchIssues(parts[0], parts[1]);

      if (mounted) {
        setState(() {
          _issues = issues;
          _isLoadingIssues = false;
          _hasLoadedIssues = true;
        });
        debugPrint(
          'Loaded ${issues.length} issues for ${widget.repo.fullName}',
        );
      }
    } catch (e) {
      debugPrint('Error loading issues for ${widget.repo.fullName}: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingIssues = false;
        });
      }
    }
  }

  String _getDisplayName() {
    if (widget.hideUsernameInRepo) {
      final parts = widget.repo.fullName.split('/');
      if (parts.length == 2) {
        return parts[1];
      }
    }
    return widget.repo.fullName;
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Load issues when expanding for the first time
    if (_isExpanded && !_hasLoadedIssues && !_isLoadingIssues) {
      _loadIssues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.repo.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.orange,
        child: Icon(
          widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.orange,
        child: Icon(
          widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        widget.onPinToggle?.call();
        return false;
      },
      child: Card(
        color: AppColors.cardBackground,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repo Header (clickable)
            InkWell(
              onTap: _toggleExpand,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Expand/Collapse Icon
                    AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.arrow_right,
                        color: AppColors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Repo Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder, color: AppColors.orange),
                    ),
                    const SizedBox(width: 8),
                    // Pin icon for pinned repos
                    if (widget.isPinned)
                      const Icon(
                        Icons.push_pin,
                        color: AppColors.orange,
                        size: 16,
                      ),
                    if (widget.isPinned) const SizedBox(width: 4),
                    // Repo Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplayName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.repo.description != null &&
                              widget.repo.description!.isNotEmpty)
                            Text(
                              widget.repo.description!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Issue Count Badge
                    if (_hasLoadedIssues || widget.repo.children.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _issues.isNotEmpty
                              ? '${_issues.whereType<IssueItem>().length} issues'
                              : '${widget.repo.children.whereType<IssueItem>().length} issues',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Loading Indicator
                    if (_isLoadingIssues)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            // Issues List (collapsible)
            if (_isExpanded)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildIssuesList(),
                crossFadeState:
                    _hasLoadedIssues ||
                        widget.repo.children.isNotEmpty ||
                        _errorMessage != null
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesList() {
    // Show loading
    if (_isLoadingIssues) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
          ),
        ),
      );
    }

    // Show error
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load issues: $_errorMessage',
                style: const TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _loadIssues,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.orange),
              ),
            ),
          ],
        ),
      );
    }

    // Show issues from API
    if (_issues.isNotEmpty) {
      return Column(
        children: _issues
            .map((issue) => IssueCard(issue: issue, onTap: widget.onIssueTap))
            .toList(),
      );
    }

    // Show local issues
    if (widget.repo.children.isNotEmpty) {
      return Column(
        children: widget.repo.children
            .whereType<IssueItem>()
            .map((issue) => IssueCard(issue: issue, onTap: widget.onIssueTap))
            .toList(),
      );
    }

    // Show empty state
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No issues found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
