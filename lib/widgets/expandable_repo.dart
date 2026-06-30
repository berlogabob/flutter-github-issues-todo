import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/network_service.dart';
import '../services/pending_operations_service.dart';
import '../models/pending_operation.dart';
import '../screens/edit_issue_screen.dart';
import 'braille_loader.dart';
import 'loading_skeleton.dart'; // PERFORMANCE: Loading skeletons (Task 16.5)
import 'issue_card.dart';

/// ExpandableRepo - Modular, reusable widget for displaying a repository with collapsible issues list
///
/// PERFORMANCE OPTIMIZATION (Task 16.4):
/// - Uses ListView.builder for lazy loading
/// - itemExtent: 80.0 for fixed-height issue cards
/// - RepaintBoundary around static content
/// - ValueKey for list items (not Key)
/// - const constructors where possible
class ExpandableRepo extends StatefulWidget {
  final RepoItem repo;
  final GitHubApiService githubApi;
  final ValueChanged<IssueItem>? onIssueTap;
  final bool? isExpanded; // External control (optional)
  final bool initiallyExpanded; // Fallback if isExpanded is null
  final bool hideUsernameInRepo;
  final bool isPinned;
  final VoidCallback? onPinToggle;
  final ValueChanged<bool>? onExpandToggle; // Callback for external control
  final void Function(String repoFullName, IssueItem updatedIssue)?
  onIssueStateChanged;

  const ExpandableRepo({
    super.key,
    required this.repo,
    required this.githubApi,
    this.onIssueTap,
    this.isExpanded,
    this.initiallyExpanded = true,
    this.hideUsernameInRepo = false,
    this.isPinned = false,
    this.onPinToggle,
    this.onExpandToggle,
    this.onIssueStateChanged,
  });

  @override
  State<ExpandableRepo> createState() => _ExpandableRepoState();
}

class _ExpandableRepoState extends State<ExpandableRepo> {
  final LocalStorageService _localStorage = LocalStorageService();
  final NetworkService _networkService = NetworkService();
  final PendingOperationsService _pendingOps = PendingOperationsService();
  bool _isLoadingIssues = false;
  bool _hasLoadedIssues = false;
  List<IssueItem> _issues = [];
  String? _errorMessage;

  // Get current expanded state (external control or internal)
  bool get _isExpanded => widget.isExpanded ?? widget.initiallyExpanded;

  @override
  void initState() {
    super.initState();

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

  @override
  void didUpdateWidget(ExpandableRepo oldWidget) {
    super.didUpdateWidget(oldWidget);

    // FIX (#25): Update issues when repo.children changes (e.g., when filter changes)
    // This ensures filtered issues from parent widget are reflected in the UI
    if (widget.repo.children != oldWidget.repo.children) {
      _issues = widget.repo.children.whereType<IssueItem>().toList();
    }

    // Load issues when expanding externally for the first time
    if (_isExpanded && !_hasLoadedIssues && !_isLoadingIssues) {
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
      // FIX (#25): Fetch all issues (open + closed) to support filtering
      final issues = await widget.githubApi.fetchIssues(
        parts[0],
        parts[1],
        state: 'all',
      );

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

  void _openIssueForEdit(IssueItem issue) {
    // Navigate to edit issue screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditIssueScreen(
          issue: issue,
          owner: widget.repo.fullName.split('/').first,
          repo: widget.repo.fullName.split('/').last,
        ),
      ),
    );
  }

  Future<void> _closeIssue(IssueItem issue) async {
    // Don't close if already closed
    if (issue.status == ItemStatus.closed) {
      return;
    }

    // Close the issue immediately (no confirmation dialog)
    try {
      final parts = widget.repo.fullName.split('/');
      if (parts.length != 2) {
        throw Exception('Invalid repo name');
      }

      final owner = parts[0];
      final repo = parts[1];

      if (issue.isLocalOnly || issue.number == null) {
        await _closeIssueLocally(issue);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue closed (local)'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!await _networkService.checkConnectivity()) {
        await _closeIssueLocally(issue);
        final operationId =
            'close_${issue.id}_${DateTime.now().millisecondsSinceEpoch}';
        await _pendingOps.addOperation(
          PendingOperation.closeIssue(
            id: operationId,
            issueNumber: issue.number!,
            owner: owner,
            repo: repo,
          ),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.cloud_off, color: Colors.white),
                SizedBox(width: 8),
                Text('Issue closed locally and queued'),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // GitHub issue
        try {
          final closedIssue = await widget.githubApi.updateIssue(
            owner,
            repo,
            issue.number!,
            state: 'closed',
          );

          if (!mounted) return;

          // Update the issue in the list with closed status
          setState(() {
            final index = _issues.indexWhere((i) => i.id == issue.id);
            if (index != -1) {
              _issues[index] = closedIssue;
            }
          });
          widget.onIssueStateChanged?.call(widget.repo.fullName, closedIssue);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Issue closed'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (_) {
          final closedIssue = await _closeIssueLocally(issue);
          final operationId =
              'close_${issue.id}_${DateTime.now().millisecondsSinceEpoch}';
          await _pendingOps.addOperation(
            PendingOperation.closeIssue(
              id: operationId,
              issueNumber: issue.number!,
              owner: owner,
              repo: repo,
            ),
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Issue closed locally and queued: ${closedIssue.title}',
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to close issue: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to close issue: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<IssueItem> _closeIssueLocally(IssueItem issue) async {
    final updatedIssue = issue.copyWith(
      status: ItemStatus.closed,
      updatedAt: DateTime.now(),
      localUpdatedAt: DateTime.now(),
      repoFullName: widget.repo.fullName,
    );

    if (mounted) {
      setState(() {
        final index = _issues.indexWhere((i) => i.id == issue.id);
        if (index != -1) {
          _issues[index] = updatedIssue;
        }
      });
    }
    widget.onIssueStateChanged?.call(widget.repo.fullName, updatedIssue);

    await _localStorage.saveIssueForOfflineState(
      updatedIssue,
      repoFullName: widget.repo.fullName,
    );

    return updatedIssue;
  }

  void _toggleExpand() {
    final newExpandedState = !_isExpanded;

    // Use external callback if provided, otherwise manage internally
    if (widget.onExpandToggle != null) {
      widget.onExpandToggle!(newExpandedState);
    } else {
      setState(() {
        // Internal management (fallback)
      });
    }

    // Load issues when expanding for the first time
    if (newExpandedState && !_hasLoadedIssues && !_isLoadingIssues) {
      _loadIssues();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use fullName as unique key - more reliable than node_id
    // NOTE: Swipe disabled for repo cards on main dashboard (Issue #20)
    // Pin/Unpin only via repo_project_library_screen
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PERFORMANCE: RepaintBoundary around static repo header (Task 16.4)
          RepaintBoundary(
            child: InkWell(
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
                        color: AppColors.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Repo Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    // Pin icon for pinned repos
                    if (widget.isPinned)
                      const Icon(
                        Icons.push_pin,
                        color: AppColors.primary,
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
                    // Issue Count Badge - FIX (#33): Use openIssuesCount from repo (not filtered)
                    // This ensures count is always visible and shows actual open issues count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '${widget.repo.openIssuesCount} issues',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Loading Indicator
                    if (_isLoadingIssues) BrailleLoader(size: 20),
                  ],
                ),
              ),
            ),
          ), // RepaintBoundary
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
        ], // Column children
      ), // Column
    ); // Card
  }

  /// Build issues list with performance optimizations (Task 16.4)
  ///
  /// PERFORMANCE OPTIMIZATION:
  /// - Uses ListView.builder for lazy loading
  /// - itemExtent: 80.0 for fixed-height issue cards (improves scroll performance)
  /// - RepaintBoundary around static content
  /// - ValueKey for list items (not Key)
  Widget _buildIssuesList() {
    // Show loading - PERFORMANCE: Use LoadingSkeleton (Task 16.5)
    if (_isLoadingIssues) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Small header with loader
            Row(
              children: [
                BrailleLoader(size: 16),
                const SizedBox(width: 8),
                Text(
                  'Loading issues...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // PERFORMANCE: Loading skeleton for issues (Task 16.5)
            const LoadingSkeleton(
              height: 80, // Match issue card height
              itemCount: 4,
              spacing: 12,
            ),
          ],
        ),
      );
    }

    // Show error
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load issues: $_errorMessage',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _loadIssues,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    // PERFORMANCE: Use ListView.builder for large list optimization (Task 16.4)
    // itemExtent: 80.0 for fixed-height issue cards
    Widget buildIssueList(List<IssueItem> issues) {
      return ListView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(), // Parent handles scrolling
        itemCount: issues.length,
        itemExtent:
            80.0, // PERFORMANCE: Fixed height for better scroll performance
        itemBuilder: (context, index) {
          final issue = issues[index];
          return RepaintBoundary(
            // PERFORMANCE: Isolate repaints
            child: IssueCard(
              key: ValueKey(
                'issue-${issue.id}',
              ), // PERFORMANCE: ValueKey instead of Key
              issue: issue,
              onTap: widget.onIssueTap,
              onSwipeRight: () => _openIssueForEdit(issue),
              onSwipeLeft: () => _closeIssue(issue),
            ),
          );
        },
      );
    }

    // Show issues from API
    if (_issues.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 100,
        ),
        child: buildIssueList(_issues),
      );
    }

    // Show local issues
    if (widget.repo.children.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 100,
        ),
        child: buildIssueList(
          widget.repo.children.whereType<IssueItem>().toList(),
        ),
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
