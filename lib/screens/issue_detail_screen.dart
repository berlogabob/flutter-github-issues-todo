import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../models/pending_operation.dart';
import '../services/github_api_service.dart';
import '../services/network_service.dart';
import '../services/pending_operations_service.dart';
import '../services/cache_service.dart';
import '../services/local_storage_service.dart';
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
  final PendingOperationsService _pendingOps = PendingOperationsService();
  final NetworkService _networkService = NetworkService();
  final CacheService _cache = CacheService();
  final LocalStorageService _localStorage = LocalStorageService();
  late IssueItem _currentIssue;
  bool _isUpdating = false;
  bool _isDescExpanded = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  String? _currentUserLogin;
  int _commentsPage = 1;
  static const int _commentsPerPage = 20;
  bool _hasMoreComments = true;
  bool _isLoadingMoreComments = false;

  // Assignee picker state
  List<Map<String, dynamic>> _assignees = [];
  bool _isLoadingAssignees = false;

  // Label picker state
  List<Map<String, dynamic>> _labels = [];
  bool _isLoadingLabels = false;

  @override
  void initState() {
    super.initState();
    _currentIssue = widget.issue;
    _loadCurrentUser();
    _loadComments();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserLogin = await _localStorage.getUserLogin();
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
        page: _commentsPage,
        perPage: _commentsPerPage,
      );
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
          _hasMoreComments = comments.length >= _commentsPerPage;
        });
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      debugPrint('Failed to load comments: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMoreComments || !_hasMoreComments) return;
    if (_currentIssue.isLocalOnly || _currentIssue.number == null) return;

    setState(() => _isLoadingMoreComments = true);
    try {
      _commentsPage++;
      final effectiveOwner = widget.owner ?? 'berlogabob';
      final effectiveRepo = widget.repo ?? 'gitdoit';
      final newComments = await _githubApi.fetchIssueComments(
        effectiveOwner,
        effectiveRepo,
        _currentIssue.number!,
        page: _commentsPage,
        perPage: _commentsPerPage,
      );
      if (mounted) {
        setState(() {
          _comments.addAll(newComments);
          _isLoadingMoreComments = false;
          _hasMoreComments = newComments.length >= _commentsPerPage;
        });
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      debugPrint('Failed to load more comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingMoreComments = false;
          _commentsPage--; // Revert page counter on error
        });
      }
    }
  }

  /// Deletes a comment with confirmation dialog.
  ///
  /// Shows confirmation dialog before deletion.
  /// Uses optimistic UI update - removes comment immediately.
  /// Queues for sync when offline.
  Future<void> _deleteComment(Map<String, dynamic> comment, int commentId) async {
    // Trigger haptic feedback
    HapticFeedback.lightImpact();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            SizedBox(width: 8.w),
            Text(
              'Delete Comment?',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            child: Text(
              'DELETE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final isOnline = await _networkService.checkConnectivity();

    // Optimistic UI update - remove immediately
    setState(() {
      _comments.removeWhere((c) => c['id'] == commentId);
    });

    if (!isOnline) {
      // Queue for sync when offline
      try {
        final operationId = 'delete_comment_${commentId}_${DateTime.now().millisecondsSinceEpoch}';
        final operation = PendingOperation.deleteComment(
          id: operationId,
          commentId: commentId,
          issueNumber: _currentIssue.number!,
          owner: _effectiveOwner,
          repo: _effectiveRepo,
        );
        await _pendingOps.addOperation(operation);
        _showSnackBar('Comment deletion queued for sync');
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        // Re-add comment on error
        setState(() {
          _comments.add(comment);
        });
        _showErrorSnackBar('Failed to queue comment deletion');
      }
      return;
    }

    // Online - delete immediately
    try {
      await _githubApi.deleteIssueComment(_effectiveOwner, _effectiveRepo, commentId);
      if (mounted) {
        _showSnackBar('Comment deleted successfully');
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      // Re-add comment on error
      if (mounted) {
        setState(() {
          _comments.add(comment);
        });
        _showErrorSnackBar('Failed to delete comment');
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
        else ...[
          ..._comments.map((comment) => _buildCommentTile(comment)).toList(),
          if (_hasMoreComments)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Center(
                child: _isLoadingMoreComments
                    ? BrailleLoader(size: 20)
                    : TextButton(
                        onPressed: _loadMoreComments,
                        child: Text(
                          'LOAD MORE COMMENTS',
                          style: TextStyle(
                            color: AppColors.orangeSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>?;
    final login = user?['login'] as String? ?? 'unknown';
    final avatarUrl = user?['avatar_url'] as String?;
    final body = comment['body'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;
    final commentId = comment['id'] as int?;
    final isOwnComment = _currentUserLogin != null && login == _currentUserLogin;

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
                    ? CachedNetworkImageProvider(avatarUrl)
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
              Expanded(
                child: Text(
                  '@$login',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              if (createdAt != null)
                Text(
                  RelativeTime.format(DateTime.parse(createdAt)),
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11.sp,
                  ),
                ),
              if (isOwnComment && commentId != null) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _deleteComment(comment, commentId),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18.sp,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
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
      // Local issue - just update state
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

    // CHECK NETWORK
    final isOnline = await _networkService.checkConnectivity();

    if (!isOnline) {
      // Queue operation
      try {
        final operationId =
            'toggle_${_currentIssue.id}_${DateTime.now().millisecondsSinceEpoch}';
        final operation = PendingOperation(
          id: operationId,
          type: _currentIssue.status == ItemStatus.open
              ? OperationType.closeIssue
              : OperationType.reopenIssue,
          issueId: _currentIssue.id,
          issueNumber: _currentIssue.number,
          owner: widget.owner,
          repo: widget.repo,
          data: {},
          createdAt: DateTime.now(),
        );

        await _pendingOps.addOperation(operation);

        // Update UI optimistically
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
            isLocalOnly: _currentIssue.isLocalOnly,
          );
        });

        _showSnackBar('Issue queued for sync');
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      }
    } else {
      // Online - update immediately
      setState(() => _isUpdating = true);

      try {
        final newStatus = _currentIssue.status == ItemStatus.open
            ? 'closed'
            : 'open';
        final updatedIssue = await _githubApi.updateIssue(
          _effectiveOwner,
          _effectiveRepo,
          _currentIssue.number!,
          state: newStatus,
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
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isUpdating = false);
        _showErrorSnackBar('Failed to update: ${e.toString()}');
      }
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

  /// Shows the assignee picker dialog with real GitHub API data.
  ///
  /// Fetches assignees from GitHub API with 5-minute caching.
  /// Supports offline mode by showing cached assignees.
  Future<void> _showAssigneeDialog() async {
    // Trigger haptic feedback
    HapticFeedback.selectionClick();
    
    // Load assignees
    await _loadAssignees();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
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
              if (_isLoadingAssignees)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.h),
                    child: BrailleLoader(size: 24),
                  ),
                )
              else if (_assignees.isEmpty)
                Text(
                  'No assignees available',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14.sp,
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _assignees.length,
                    itemBuilder: (context, index) {
                      final assignee = _assignees[index];
                      final login = assignee['login'] as String? ?? '';
                      final avatarUrl = assignee['avatar_url'] as String?;
                      final isAssigned = _currentIssue.assigneeLogin == login;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16.r,
                          backgroundColor: AppColors.orangeSecondary,
                          backgroundImage: avatarUrl != null
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  login.isNotEmpty ? login[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.black),
                                )
                              : null,
                        ),
                        title: Text(
                          '@$login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isAssigned ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isAssigned
                            ? Icon(
                                Icons.check_circle,
                                color: AppColors.orangeSecondary,
                                size: 20.sp,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          if (isAssigned) {
                            _removeAssignee();
                          } else {
                            _setAssignee(login);
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loads assignees from GitHub API or cache.
  ///
  /// Caches results for 5 minutes. Falls back to cached data in offline mode.
  Future<void> _loadAssignees() async {
    if (_isLoadingAssignees) return;

    final cacheKey = 'assignees_${_effectiveOwner}_${_effectiveRepo}';
    
    // Try cache first
    final cachedAssignees = _cache.get<List>(cacheKey);
    if (cachedAssignees != null) {
      setState(() {
        _assignees = cachedAssignees.cast<Map<String, dynamic>>();
      });
      return;
    }
    
    // Check network
    final isOnline = await _networkService.checkConnectivity();
    if (!isOnline) {
      _showSnackBar('Offline - showing cached data');
      return;
    }
    
    setState(() => _isLoadingAssignees = true);
    
    try {
      final assignees = await _githubApi.fetchRepoCollaborators(
        _effectiveOwner,
        _effectiveRepo,
      );
      
      if (!mounted) return;
      
      setState(() {
        _assignees = assignees;
        _isLoadingAssignees = false;
      });
      
      // Cache for 5 minutes
      await _cache.set(
        cacheKey,
        assignees,
        ttl: const Duration(minutes: 5),
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      if (mounted) {
        setState(() => _isLoadingAssignees = false);
      }
    }
  }

  /// Sets the assignee for the current issue.
  Future<void> _setAssignee(String login) async {
    if (_currentIssue.isLocalOnly) {
      // Local issue - update state only
      setState(() {
        _currentIssue = IssueItem(
          id: _currentIssue.id,
          title: _currentIssue.title,
          number: _currentIssue.number,
          status: _currentIssue.status,
          updatedAt: DateTime.now(),
          bodyMarkdown: _currentIssue.bodyMarkdown,
          assigneeLogin: login,
          labels: _currentIssue.labels,
          projectColumnName: _currentIssue.projectColumnName,
          isLocalOnly: true,
        );
      });
      _showSnackBar('Assignee set to @$login');
      return;
    }
    
    // Check network
    final isOnline = await _networkService.checkConnectivity();
    
    if (!isOnline) {
      // Queue operation for later sync
      try {
        final operationId = 'assignee_${_currentIssue.id}_${DateTime.now().millisecondsSinceEpoch}';
        final operation = PendingOperation(
          id: operationId,
          type: OperationType.updateIssue,
          issueId: _currentIssue.id,
          issueNumber: _currentIssue.number,
          owner: widget.owner,
          repo: widget.repo,
          data: {'assignees': [login]},
          createdAt: DateTime.now(),
        );
        
        await _pendingOps.addOperation(operation);
        
        // Update UI optimistically
        setState(() {
          _currentIssue = IssueItem(
            id: _currentIssue.id,
            title: _currentIssue.title,
            number: _currentIssue.number,
            status: _currentIssue.status,
            updatedAt: DateTime.now(),
            bodyMarkdown: _currentIssue.bodyMarkdown,
            assigneeLogin: login,
            labels: _currentIssue.labels,
            projectColumnName: _currentIssue.projectColumnName,
            isLocalOnly: _currentIssue.isLocalOnly,
          );
        });
        
        _showSnackBar('Assignee queued for sync');
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      }
      return;
    }
    
    // Online - update immediately
    setState(() => _isUpdating = true);
    
    try {
      final updatedIssue = await _githubApi.updateIssue(
        _effectiveOwner,
        _effectiveRepo,
        _currentIssue.number!,
        assignees: [login],
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });
      
      _showSnackBar('Assignee set to @$login');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      if (mounted) {
        setState(() => _isUpdating = false);
      }
      _showErrorSnackBar('Failed to set assignee');
    }
  }

  /// Shows the label picker dialog with real GitHub API data.
  ///
  /// Fetches labels from GitHub API with 5-minute caching.
  /// Supports offline mode by showing cached labels.
  /// Allows adding new labels to the issue.
  Future<void> _showLabelsDialog() async {
    // Trigger haptic feedback
    HapticFeedback.selectionClick();
    
    // Load labels
    await _loadLabels();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
              if (_isLoadingLabels)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.h),
                    child: BrailleLoader(size: 24),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      // Current labels section
                      if (_currentIssue.labels.isNotEmpty) ...[
                        Text(
                          'Current Labels',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        SizedBox(height: 8.h),
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
                        Divider(color: AppColors.borderColor),
                        SizedBox(height: 8.h),
                      ],
                      // Available labels section
                      Text(
                        'Available Labels',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Expanded(
                        child: _labels.isEmpty
                            ? Center(
                                child: Text(
                                  'No labels available',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _labels.length,
                                itemBuilder: (context, index) {
                                  final label = _labels[index];
                                  final labelName = label['name'] as String? ?? '';
                                  final labelColor = label['color'] as String? ?? '000000';
                                  final isAdded = _currentIssue.labels.contains(labelName);
                                  
                                  return CheckboxListTile(
                                    value: isAdded,
                                    title: Row(
                                      children: [
                                        Container(
                                          width: 12.w,
                                          height: 12.h,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse('FF$labelColor', radix: 16)),
                                            borderRadius: BorderRadius.circular(4.r),
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          labelName,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    activeColor: AppColors.orangeSecondary,
                                    onChanged: (value) {
                                      if (value == true) {
                                        Navigator.pop(context);
                                        _addLabel(labelName);
                                      } else if (value == false) {
                                        Navigator.pop(context);
                                        _removeLabel(labelName);
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Loads labels from GitHub API or cache.
  ///
  /// Caches results for 5 minutes. Falls back to cached data in offline mode.
  Future<void> _loadLabels() async {
    if (_isLoadingLabels) return;

    final cacheKey = 'labels_${_effectiveOwner}_${_effectiveRepo}';
    
    // Try cache first
    final cachedLabels = _cache.get<List>(cacheKey);
    if (cachedLabels != null) {
      setState(() {
        _labels = cachedLabels.cast<Map<String, dynamic>>();
      });
      return;
    }
    
    // Check network
    final isOnline = await _networkService.checkConnectivity();
    if (!isOnline) {
      _showSnackBar('Offline - showing cached data');
      return;
    }
    
    setState(() => _isLoadingLabels = true);
    
    try {
      final labels = await _githubApi.fetchRepoLabels(
        _effectiveOwner,
        _effectiveRepo,
      );
      
      if (!mounted) return;
      
      setState(() {
        _labels = labels;
        _isLoadingLabels = false;
      });
      
      // Cache for 5 minutes
      await _cache.set(
        cacheKey,
        labels,
        ttl: const Duration(minutes: 5),
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      if (mounted) {
        setState(() => _isLoadingLabels = false);
      }
    }
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
      if (!mounted) return;
      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to remove assignee: $e');
      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isUpdating = false);
        _showErrorSnackBar('Failed to remove assignee');
      }
    }
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
      if (!mounted) return;
      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to remove label: $e');
      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isUpdating = false);
        _showErrorSnackBar('Failed to remove label');
      }
    }
  }

  /// Adds a label to the current issue.
  ///
  /// [labelName] The name of the label to add.
  Future<void> _addLabel(String labelName) async {
    if (_currentIssue.isLocalOnly) {
      // Local issue - update state only
      final newLabels = List<String>.from(_currentIssue.labels)..add(labelName);
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
      _showSnackBar('Label "$labelName" added');
      return;
    }
    
    // Check network
    final isOnline = await _networkService.checkConnectivity();
    
    if (!isOnline) {
      // Queue operation for later sync
      try {
        final operationId = 'label_add_${_currentIssue.id}_${DateTime.now().millisecondsSinceEpoch}';
        final operation = PendingOperation(
          id: operationId,
          type: OperationType.updateIssue,
          issueId: _currentIssue.id,
          issueNumber: _currentIssue.number,
          owner: widget.owner,
          repo: widget.repo,
          data: {'labels': [..._currentIssue.labels, labelName]},
          createdAt: DateTime.now(),
        );
        
        await _pendingOps.addOperation(operation);
        
        // Update UI optimistically
        final newLabels = List<String>.from(_currentIssue.labels)..add(labelName);
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
            isLocalOnly: _currentIssue.isLocalOnly,
          );
        });
        
        _showSnackBar('Label queued for sync');
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      }
      return;
    }
    
    // Online - update immediately
    setState(() => _isUpdating = true);
    
    try {
      final updatedIssue = await _githubApi.addIssueLabel(
        _effectiveOwner,
        _effectiveRepo,
        _currentIssue.number!,
        labelName,
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentIssue = updatedIssue;
        _isUpdating = false;
      });
      
      _showSnackBar('Label "$labelName" added');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      if (mounted) {
        setState(() => _isUpdating = false);
      }
      _showErrorSnackBar('Failed to add label');
    }
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
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
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
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
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
