import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../services/issue_service.dart';
import '../utils/relative_time.dart';
import '../widgets/braille_loader.dart';
import '../widgets/label_chip.dart';
import 'edit_issue_screen.dart';

/// Screen displaying detailed information about a single GitHub issue.
///
/// Features:
/// - Full issue details with Markdown rendering
/// - Status toggle (open/close)
/// - Labels display and management
/// - Assignee information
/// - Comments section with Markdown support
/// - Activity timeline
/// - Edit functionality
/// - Sync status banner
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => IssueDetailScreen(
///       issue: issueItem,
///       owner: 'owner',
///       repo: 'repo',
///     ),
///   ),
/// );
/// ```
class IssueDetailScreen extends ConsumerStatefulWidget {
  /// The issue to display.
  final IssueItem issue;

  /// Repository owner login.
  final String? owner;

  /// Repository name.
  final String? repo;

  /// Creates the issue detail screen.
  ///
  /// [issue] is the issue to display (required).
  /// [owner] and [repo] specify the target repository for GitHub-synced issues.
  const IssueDetailScreen({
    super.key,
    required this.issue,
    this.owner,
    this.repo,
  });

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final IssueService _issueService = IssueService();
  late IssueItem _currentIssue;
  bool _isUpdating = false;
  bool _isDescExpanded = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _currentIssue = widget.issue;
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (_currentIssue.isLocalOnly || _currentIssue.number == null) return;

    setState(() => _isLoadingComments = true);
    try {
      final effectiveOwner = widget.owner ?? 'berlogabob';
      final effectiveRepo = widget.repo ?? 'gitdoit';
      final comments = await _githubApi.fetchIssueComments(
        effectiveOwner,
        effectiveRepo,
        _currentIssue.number!,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load comments: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  String get _effectiveOwner => widget.owner ?? 'berlogabob';
  String get _effectiveRepo => widget.repo ?? 'gitdoit';

  @override
  Widget build(BuildContext context) {
    final isOpen = _currentIssue.status == ItemStatus.open;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSyncBanner(),
          Expanded(
            child: _isUpdating
                ? const Center(child: BrailleLoader(size: 32))
                : CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(isOpen),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBreadcrumbs(),
                              SizedBox(height: 12.h),
                              _buildTitle(),
                              SizedBox(height: 20.h),
                              _buildMetadataRow(isOpen),
                              SizedBox(height: 24.h),
                              _buildLabels(),
                              SizedBox(height: 32.h),
                              _buildDescription(),
                              SizedBox(height: 32.h),
                              _buildTimeline(),
                              SizedBox(height: 32.h),
                              _buildCommentsSection(),
                              SizedBox(height: 100.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          _buildBottomActionBar(isOpen),
        ],
      ),
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.orangeSecondary,
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CACHED – LAST SYN ${RelativeTime.format(DateTime.now().subtract(const Duration(minutes: 15)))}',
            style: TextStyle(
              color: Colors.black,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          GestureDetector(
            onTap: _refresh,
            child: Icon(Icons.refresh, size: 12.sp, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isOpen) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      expandedHeight: 100.h,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'GitDoIt',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20.sp,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _editIssue,
              icon: Icon(Icons.edit, size: 16.sp, color: Colors.black),
              label: Text(
                'Edit',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Divider(height: 1, color: AppColors.borderColor),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Text(
      '$_effectiveOwner/$_effectiveRepo > #${_currentIssue.number ?? '---'}',
      style: TextStyle(
        color: AppColors.orangeSecondary,
        fontSize: 12.sp,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _currentIssue.title,
      style: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.2,
      ),
    );
  }

  Widget _buildMetadataRow(bool isOpen) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStatusBadge(isOpen),
        _buildIconText(
          Icons.access_time,
          RelativeTime.format(_currentIssue.updatedAt ?? DateTime.now()),
        ),
        if (_currentIssue.assigneeLogin != null)
          _buildIconText(
            Icons.person_outline,
            '@${_currentIssue.assigneeLogin}',
            color: AppColors.orangeSecondary,
            isBold: true,
          ),
        _buildIconText(Icons.visibility_outlined, '0'),
        if (_currentIssue.projectColumnName != null)
          _buildMilestoneBadge(_currentIssue.projectColumnName!),
      ],
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.orangeSecondary),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8.sp,
            color: isOpen ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 6.w),
          Text(
            isOpen ? 'open' : 'closed',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(
    IconData icon,
    String text, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color ?? AppColors.secondaryText),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: color ?? AppColors.secondaryText,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.borderColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLabels() {
    if (_currentIssue.labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _currentIssue.labels
          .map((label) => LabelChipWidget(label: label))
          .toList(),
    );
  }

  Color _getLabelColor(String label) {
    final labelLower = label.toLowerCase();
    if (labelLower.contains('bug')) return const Color(0xFFD73A4A);
    if (labelLower.contains('high')) return const Color(0xFFF9D0C4);
    if (labelLower.contains('ios')) return const Color(0xFF007AFF);
    if (labelLower.contains('enhancement')) return const Color(0xFF238636);
    if (labelLower.contains('documentation')) return const Color(0xFF6E7781);
    if (labelLower.contains('help')) return const Color(0xFFA371F7);
    return AppColors.orangeSecondary;
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Description'),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentIssue.bodyMarkdown != null &&
                  _currentIssue.bodyMarkdown!.isNotEmpty) ...[
                MarkdownBody(
                  data: _currentIssue.bodyMarkdown!,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      height: 1.5,
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                    h1: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    h2: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    h3: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    code: TextStyle(
                      color: AppColors.orangeSecondary,
                      backgroundColor: const Color(0xFF2D2D2D),
                      fontSize: 12.sp,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    blockquote: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                    listBullet: TextStyle(color: AppColors.orangeSecondary),
                  ),
                  shrinkWrap: !_isDescExpanded,
                ),
                if (_currentIssue.bodyMarkdown!.length > 150)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isDescExpanded = !_isDescExpanded),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: Text(
                          _isDescExpanded ? 'SHOW LESS' : 'READ MORE',
                          style: TextStyle(
                            color: AppColors.orangeSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else
                Text(
                  'No description provided.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14.sp,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Divider(color: AppColors.borderColor.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Activity Timeline'),
        _buildTimelineItem(
          'Created issue',
          _currentIssue.updatedAt,
          Icons.circle_outlined,
        ),
        if (_currentIssue.labels.isNotEmpty)
          _buildTimelineItem(
            "Labels added: ${_currentIssue.labels.join(', ')}",
            _currentIssue.updatedAt,
            Icons.label_outline,
          ),
        if (_currentIssue.assigneeLogin != null)
          _buildTimelineItem(
            'Assigned to @${_currentIssue.assigneeLogin}',
            _currentIssue.updatedAt,
            Icons.person_add_alt,
            isAccent: true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String text,
    DateTime? time,
    IconData icon, {
    bool isAccent = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: isAccent
                      ? AppColors.orangeSecondary
                      : AppColors.secondaryText,
                ),
                Expanded(
                  child: VerticalDivider(
                    color: AppColors.borderColor,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            SizedBox(width: 16.w),
            Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(fontSize: 14.sp, color: Colors.white),
                  ),
                  if (time != null)
                    Text(
                      RelativeTime.format(time),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Comments (${_comments.length})'),
        if (_isLoadingComments)
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: BrailleLoader(size: 24),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              border: Border.all(color: const Color(0xFF222222)),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text(
                'No comments yet',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14.sp,
                ),
              ),
            ),
          )
        else
          ...(_comments.map((comment) => _buildCommentTile(comment)).toList()),
      ],
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>?;
    final login = user?['login'] as String? ?? 'unknown';
    final avatarUrl = user?['avatar_url'] as String?;
    final body = comment['body'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border.all(color: const Color(0xFF222222)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundColor: AppColors.orangeSecondary,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        login.isNotEmpty ? login[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 8.w),
              Text(
                '@$login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              if (createdAt != null)
                Text(
                  RelativeTime.format(DateTime.parse(createdAt)),
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11.sp,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          MarkdownBody(
            data: body,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 14.sp, height: 1.4, color: Colors.white),
              code: TextStyle(
                color: AppColors.orangeSecondary,
                backgroundColor: const Color(0xFF2D2D2D),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isOpen) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40.h,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _toggleStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  isOpen ? 'CLOSE' : 'REOPEN',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _buildSquareAction(Icons.person_outline, _showAssigneeDialog),
          SizedBox(width: 4.w),
          _buildSquareAction(Icons.label_outline, _showLabelsDialog),
          SizedBox(width: 4.w),
          _buildSquareAction(Icons.comment_outlined, _addComment),
        ],
      ),
    );
  }

  Widget _buildSquareAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: AppColors.secondaryText, size: 20.sp),
      ),
    );
  }

  Future<void> _toggleStatus() async {
    if (_currentIssue.isLocalOnly) {
      setState(() {
        _currentIssue = IssueItem(
          id: _currentIssue.id,
          title: _currentIssue.title,
          number: _currentIssue.number,
          status: _currentIssue.status == ItemStatus.open
              ? ItemStatus.closed
              : ItemStatus.open,
          updatedAt: DateTime.now(),
          bodyMarkdown: _currentIssue.bodyMarkdown,
          assigneeLogin: _currentIssue.assigneeLogin,
          labels: _currentIssue.labels,
          projectColumnName: _currentIssue.projectColumnName,
          isLocalOnly: true,
        );
      });
      _showSnackBar(
        _currentIssue.status == ItemStatus.open
            ? 'Issue reopened'
            : 'Issue closed',
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final updatedIssue = await _issueService.toggleIssueStatus(
        _currentIssue,
        _effectiveOwner,
        _effectiveRepo,
      );

      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });

      _showSnackBar(
        updatedIssue.status == ItemStatus.open
            ? 'Issue reopened'
            : 'Issue closed',
      );
    } catch (e) {
      debugPrint('Failed to update issue status: $e');
      setState(() => _isUpdating = false);
      _showErrorSnackBar('Failed to update: ${e.toString()}');
    }
  }

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

  void _showAssigneeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignee',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            if (_currentIssue.assigneeLogin != null)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.orangeSecondary,
                  child: Text(
                    _currentIssue.assigneeLogin![0].toUpperCase(),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                title: Text(
                  '@${_currentIssue.assigneeLogin}',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _removeAssignee();
                  },
                ),
              )
            else
              Text(
                'No assignee',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14.sp,
                ),
              ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addAssignee();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeSecondary,
                ),
                child: const Text(
                  'Add Assignee',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLabelsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Labels',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              if (_currentIssue.labels.isNotEmpty) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _currentIssue.labels
                      .map(
                        (label) => Chip(
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _getLabelColor(label),
                            ),
                          ),
                          backgroundColor: _getLabelColor(
                            label,
                          ).withValues(alpha: 0.2),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            Navigator.pop(context);
                            _removeLabel(label);
                          },
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 16.h),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _addLabel();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Label'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangeSecondary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeAssignee() async {
    if (_currentIssue.isLocalOnly) {
      setState(() {
        _currentIssue = IssueItem(
          id: _currentIssue.id,
          title: _currentIssue.title,
          number: _currentIssue.number,
          status: _currentIssue.status,
          updatedAt: DateTime.now(),
          bodyMarkdown: _currentIssue.bodyMarkdown,
          assigneeLogin: null,
          labels: _currentIssue.labels,
          projectColumnName: _currentIssue.projectColumnName,
          isLocalOnly: true,
        );
      });
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final updatedIssue = await _githubApi.updateIssue(
        _effectiveOwner,
        _effectiveRepo,
        _currentIssue.number!,
        assignees: [],
      );
      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });
    } catch (e) {
      setState(() => _isUpdating = false);
      _showErrorSnackBar('Failed to remove assignee');
    }
  }

  Future<void> _addAssignee() async {
    _showErrorSnackBar('Assignee selection coming soon');
  }

  Future<void> _removeLabel(String label) async {
    if (_currentIssue.isLocalOnly) {
      final newLabels = List<String>.from(_currentIssue.labels)..remove(label);
      setState(() {
        _currentIssue = IssueItem(
          id: _currentIssue.id,
          title: _currentIssue.title,
          number: _currentIssue.number,
          status: _currentIssue.status,
          updatedAt: DateTime.now(),
          bodyMarkdown: _currentIssue.bodyMarkdown,
          assigneeLogin: _currentIssue.assigneeLogin,
          labels: newLabels,
          projectColumnName: _currentIssue.projectColumnName,
          isLocalOnly: true,
        );
      });
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final updatedIssue = await _githubApi.removeIssueLabel(
        _effectiveOwner,
        _effectiveRepo,
        _currentIssue.number!,
        label,
      );
      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });
    } catch (e) {
      setState(() => _isUpdating = false);
      _showErrorSnackBar('Failed to remove label');
    }
  }

  Future<void> _addLabel() async {
    _showErrorSnackBar('Label selection coming soon');
  }

  void _addComment() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24.w,
          right: 24.w,
          top: 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Comment',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              maxLines: 5,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitComment(controller.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeSecondary,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment(String body) async {
    if (body.trim().isEmpty) return;

    if (_currentIssue.isLocalOnly) {
      _showErrorSnackBar('Cannot add comments to local issues');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await _githubApi.addIssueComment(
        _effectiveOwner,
        _effectiveRepo,
        _currentIssue.number!,
        body,
      );
      await _loadComments();
      setState(() => _isUpdating = false);
      _showSnackBar('Comment added');
    } catch (e) {
      setState(() => _isUpdating = false);
      _showErrorSnackBar('Failed to add comment');
    }
  }

  Future<void> _refresh() async {
    setState(() => _isUpdating = true);
    try {
      final issue = await _githubApi.fetchIssue(
        _effectiveOwner,
        _effectiveRepo,
        _currentIssue.number!,
      );
      setState(() {
        _currentIssue = issue;
        _isUpdating = false;
      });
      await _loadComments();
    } catch (e) {
      setState(() => _isUpdating = false);
      _showErrorSnackBar('Failed to refresh');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.orangeSecondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
