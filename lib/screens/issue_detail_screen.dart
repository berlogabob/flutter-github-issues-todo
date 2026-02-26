import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../utils/responsive_utils.dart';
import 'edit_issue_screen.dart';

/// IssueDetailScreen - Detailed view of an issue
/// Implements brief section 7, screen 3
class IssueDetailScreen extends ConsumerStatefulWidget {
  final IssueItem issue;
  final String? owner;
  final String? repo;

  const IssueDetailScreen({super.key, required this.issue, this.owner, this.repo});

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  late IssueItem _currentIssue;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentIssue = widget.issue;
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _currentIssue.status == ItemStatus.open;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '#${_currentIssue.number ?? '---'} ${_currentIssue.title}',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isOpen ? Icons.check_circle_outline : Icons.refresh,
              color: isOpen ? Colors.green : AppColors.orange,
            ),
            onPressed: _isUpdating ? null : _toggleStatus,
            tooltip: isOpen ? 'Close Issue' : 'Reopen Issue',
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            )
          : ConstrainedContent(
              padding: EdgeInsets.all(16.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metadata
                    _buildMetadata(isOpen),
                    SizedBox(height: 16.h),
                    // Labels
                    if (_currentIssue.labels.isNotEmpty) ...[
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _currentIssue.labels.map((label) => _buildLabelChip(label)).toList(),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    // Project Column (if in project)
                    if (_currentIssue.projectColumnName != null) ...[
                      _buildProjectColumn(),
                      SizedBox(height: 16.h),
                    ],
                    // Body
                    _buildBody(),
                    SizedBox(height: 24.h),
                    // Actions
                    _buildActions(isOpen),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetadata(bool isOpen) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOpen ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isOpen ? 'Open' : 'Closed',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 16),
        if (_currentIssue.assigneeLogin != null) ...[
          const Icon(Icons.person, size: 16, color: AppColors.blue),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _currentIssue.assigneeLogin!,
              style: const TextStyle(color: AppColors.blue, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
        ],
        const Icon(Icons.access_time, size: 16, color: AppColors.red),
        const SizedBox(width: 4),
        Text(
          _formatRelativeTime(_currentIssue.updatedAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLabelChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: AppColors.orange.withValues(alpha: 0.2),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildProjectColumn() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.view_kanban, color: AppColors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            'Project Column:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currentIssue.projectColumnName!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: AppColors.orange),
            onPressed: _changeProjectColumn,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final bodyText = _currentIssue.bodyMarkdown;
    
    if (bodyText == null || bodyText.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No description provided.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: MarkdownBody(
        data: bodyText,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          code: const TextStyle(
            color: AppColors.orange,
            backgroundColor: Color(0xFF2D2D2D),
            fontSize: 12,
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
          listBullet: const TextStyle(color: AppColors.orange),
        ),
      ),
    );
  }

  Widget _buildActions(bool isOpen) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit Issue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _editIssue,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: isOpen
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Close Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _toggleStatus,
                )
              : OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reopen Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _toggleStatus,
                ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.comment),
            label: const Text('Add Comment'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _addComment,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Issue'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _deleteIssue,
          ),
        ),
      ],
    );
  }

  /// Toggle issue status (close/reopen)
  Future<void> _toggleStatus() async {
    if (_currentIssue.isLocalOnly) {
      // Local issue - update locally
      setState(() {
        _currentIssue = IssueItem(
          id: _currentIssue.id,
          title: _currentIssue.title,
          number: _currentIssue.number,
          status: _currentIssue.status == ItemStatus.open ? ItemStatus.closed : ItemStatus.open,
          updatedAt: DateTime.now(),
          bodyMarkdown: _currentIssue.bodyMarkdown,
          assigneeLogin: _currentIssue.assigneeLogin,
          labels: _currentIssue.labels,
          projectColumnName: _currentIssue.projectColumnName,
          isLocalOnly: true,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _currentIssue.status == ItemStatus.open ? Icons.refresh : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentIssue.status == ItemStatus.open ? 'Issue reopened' : 'Issue closed',
                ),
              ],
            ),
            backgroundColor: AppColors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // GitHub issue - update via API
    setState(() => _isUpdating = true);

    try {
      // Use owner/repo from widget params, or extract from issue, or use defaults
      final effectiveOwner = widget.owner ?? 'berlogabob';
      final effectiveRepo = widget.repo ?? 'gitdoit';

      final newStatus = _currentIssue.status == ItemStatus.open ? 'closed' : 'open';

      debugPrint('Updating issue #${_currentIssue.number} status to: $newStatus in $effectiveOwner/$effectiveRepo');

      // Call GitHub API to update issue
      final updatedIssue = await _githubApi.updateIssue(
        effectiveOwner,
        effectiveRepo,
        _currentIssue.number!,
        state: newStatus,
      );
      
      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _currentIssue.status == ItemStatus.open ? Icons.refresh : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentIssue.status == ItemStatus.open ? 'Issue reopened' : 'Issue closed',
                ),
              ],
            ),
            backgroundColor: AppColors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to update issue status: $e');
      
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _toggleStatus,
            ),
          ),
        );
      }
    }
  }

  /// Edit issue - navigate to EditIssueScreen
  Future<void> _editIssue() async {
    final result = await Navigator.push<IssueItem>(
      context,
      MaterialPageRoute(
        builder: (context) => EditIssueScreen(
          issue: _currentIssue,
          owner: widget.owner,
          repo: widget.repo,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentIssue = result;
      });
    }
  }

  /// Change project column - stub
  void _changeProjectColumn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change column feature coming soon'),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  /// Add comment - stub
  void _addComment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add comment feature coming soon'),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  /// Delete issue - stub
  void _deleteIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Delete Issue?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this issue? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete feature coming soon'),
                  backgroundColor: AppColors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Format relative time
  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
