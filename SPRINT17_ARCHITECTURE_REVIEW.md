# Sprint 17: Architecture Review

**Review Date:** March 3, 2026
**Reviewer:** System Architect
**Status:** READY FOR IMPLEMENTATION
**Sprint Goal:** Implement comments display, comment deletion, empty state illustrations, tutorial tooltips, and code quality fixes

---

## Executive Summary

This review evaluates the existing codebase architecture against Sprint 17 requirements. The codebase provides **excellent foundational support** for all Sprint 17 tasks with well-designed services for API calls, caching, offline operations, and error handling.

### Overall Architecture Compliance: EXCELLENT

| Component | Status | Sprint 17 Relevance |
|-----------|--------|---------------------|
| `GitHubApiService.fetchIssueComments()` | ✅ Implemented | Task 17.1 |
| `CacheService` (5-min TTL) | ✅ Implemented | Task 17.1 |
| `PendingOperationsService` | ✅ Implemented | Task 17.2 |
| `NetworkService` | ✅ Implemented | Task 17.2 |
| `SecureStorageService` | ✅ Implemented | Task 17.2 |
| `AppErrorHandler` | ✅ Implemented | All tasks |
| `AppColors` (Dark Theme) | ✅ Implemented | Task 17.3 |
| `flutter_svg` package | ✅ Available | Task 17.3 |
| `LocalStorageService` | ✅ Implemented | Task 17.4 |

**Key Finding:** The architecture is well-prepared for Sprint 17. Only Task 17.2 requires a new API method (`deleteIssueComment()`), which should be added to `GitHubApiService`.

---

## Task-by-Task Architecture Review

### Task 17.1: Display Comments

**Requirement:** Use existing `GitHubApiService.fetchIssueComments()`, display in IssueDetailScreen bottom section, show avatar/username/timestamp/body, cache for 5 minutes, work offline.

#### Current Implementation Status: PARTIAL

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart`

**Current Code (Lines 95-115, 650-730):**
```dart
// State variables exist
List<Map<String, dynamic>> _comments = [];
bool _isLoadingComments = false;

// Load method exists but lacks caching
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
  } catch (e, stackTrace) {
    AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
    // Error handling but no offline fallback
  }
}

// UI section exists (Lines 650-730)
Widget _buildCommentsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader('Comments (${_comments.length})'),
      if (_isLoadingComments)
        Center(child: Padding(..., child: BrailleLoader(size: 24)))
      else if (_comments.isEmpty)
        Container(..., child: Text('No comments yet'))
      else
        ...(_comments.map((comment) => _buildCommentTile(comment)).toList()),
    ],
  );
}
```

**Comment Tile Implementation (Lines 695-730):**
```dart
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
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? Text(login[0].toUpperCase()) : null,
            ),
            SizedBox(width: 8.w),
            Text('@$login', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8.w),
            if (createdAt != null)
              Text(RelativeTime.format(DateTime.parse(createdAt))),
          ],
        ),
        SizedBox(height: 12.h),
        MarkdownBody(data: body, styleSheet: ...),
      ],
    ),
  );
}
```

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Use `fetchIssueComments()` | ✅ Complete | Method exists and is used |
| Display avatar | ✅ Complete | `CircleAvatar` with `NetworkImage` |
| Display username | ✅ Complete | `@$login` text |
| Display timestamp | ✅ Complete | `RelativeTime.format()` |
| Display body | ✅ Complete | `MarkdownBody` widget |
| Cache for 5 minutes | ❌ Missing | No caching in `_loadComments()` or API method |
| Work offline (cached) | ❌ Missing | No offline fallback to cached comments |

#### Existing Infrastructure

**GitHubApiService.fetchIssueComments()** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/github_api_service.dart`, Lines 526-565):
```dart
/// Fetch issue comments
Future<List<Map<String, dynamic>>> fetchIssueComments(
  String owner,
  String repo,
  int issueNumber,
) async {
  try {
    debugPrint('Fetching comments for issue #$issueNumber in $owner/$repo...');
    final headers = await _headers;

    final response = await http
        .get(
          Uri.parse(
            'https://api.github.com/repos/$owner/$repo/issues/$issueNumber/comments',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> commentsData = json.decode(response.body);
      return commentsData.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch comments');
    }
  } catch (e, stackTrace) {
    AppErrorHandler.handle(e, stackTrace: stackTrace);
    rethrow;
  }
}
```

**Issue:** Method lacks:
- Caching with 5-minute TTL
- Network connectivity check
- Offline fallback to cached data

**CacheService** (Available, 5-minute TTL support):
```dart
// CacheService usage pattern (from other methods)
final cacheKey = 'comments_${owner}_${repo}_$issueNumber';
final cachedComments = _cache.get<List>(cacheKey);
if (cachedComments != null) {
  return cachedComments.cast<Map<String, dynamic>>();
}
// ... fetch from API ...
await _cache.set(cacheKey, comments, ttl: const Duration(minutes: 5));
```

#### Recommendations

1. **Add caching to `fetchIssueComments()` in GitHubApiService:**

```dart
/// Fetch issue comments
/// 
/// Caching: Results cached for 5 minutes.
/// Offline: Returns cached comments if available when offline.
Future<List<Map<String, dynamic>>> fetchIssueComments(
  String owner,
  String repo,
  int issueNumber,
) async {
  try {
    // Check cache first (5-minute TTL)
    final cacheKey = 'comments_${owner}_${repo}_$issueNumber';
    final cachedComments = _cache.get<List>(cacheKey);
    if (cachedComments != null) {
      debugPrint('Cache hit for comments: $owner/$repo/#$issueNumber');
      return cachedComments.cast<Map<String, dynamic>>();
    }

    debugPrint('Fetching comments for issue #$issueNumber in $owner/$repo...');
    final headers = await _headers;

    final response = await http
        .get(
          Uri.parse(
            'https://api.github.com/repos/$owner/$repo/issues/$issueNumber/comments',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> commentsData = json.decode(response.body);
      final comments = commentsData.cast<Map<String, dynamic>>();
      
      // Cache for 5 minutes
      await _cache.set(
        cacheKey,
        comments,
        ttl: const Duration(minutes: 5),
      );
      
      return comments;
    } else {
      throw Exception('Failed to fetch comments');
    }
  } catch (e, stackTrace) {
    AppErrorHandler.handle(e, stackTrace: stackTrace);
    
    // Try to return cached data on error (graceful degradation)
    final cacheKey = 'comments_${owner}_${repo}_$issueNumber';
    final cachedComments = _cache.get<List>(cacheKey);
    if (cachedComments != null) {
      debugPrint('Returning stale cached comments due to error');
      return cachedComments.cast<Map<String, dynamic>>();
    }
    
    rethrow;
  }
}
```

2. **Update `_loadComments()` in IssueDetailScreen to handle offline gracefully:**

```dart
Future<void> _loadComments() async {
  if (_currentIssue.isLocalOnly || _currentIssue.number == null) {
    debugPrint('Skipping comments load for local issue');
    return;
  }

  setState(() => _isLoadingComments = true);
  try {
    final effectiveOwner = widget.owner ?? 'berlogabob';
    final effectiveRepo = widget.repo ?? 'gitdoit';
    
    // Check network status for UX messaging
    final isOnline = await _networkService.checkConnectivity();
    
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
      
      // Show offline indicator if using cached data
      if (!isOnline && comments.isNotEmpty) {
        _showSnackBar('Showing cached comments (offline)');
      }
    }
  } catch (e, stackTrace) {
    AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
    debugPrint('Failed to load comments: $e');
    
    if (mounted) {
      setState(() => _isLoadingComments = false);
      // Don't show error if we have cached data (handled in API)
      if (e.toString().contains('No internet')) {
        _showSnackBar('Offline - comments unavailable');
      }
    }
  }
}
```

3. **Consider adding "Last updated" indicator:**

```dart
// In _buildCommentsSection()
Row(
  children: [
    _buildSectionHeader('Comments (${_comments.length})'),
    const Spacer(),
    if (_comments.isNotEmpty)
      Text(
        'CACHED ${RelativeTime.format(DateTime.now().subtract(const Duration(minutes: 2)))}',
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 10.sp,
        ),
      ),
  ],
)
```

---

### Task 17.2: Comment Deletion

**Requirement:** Only allow deleting own comments, use `GitHubApiService.deleteIssueComment()`, add confirmation dialog, optimistic UI update, queue for sync when offline.

#### Current Implementation Status: NOT STARTED

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Delete own comments only | ❌ Missing | Need to compare comment author with current user |
| Use `deleteIssueComment()` | ❌ Missing | Method doesn't exist yet |
| Confirmation dialog | ❌ Missing | No UI implemented |
| Optimistic UI update | ❌ Missing | No implementation |
| Queue for offline sync | ❌ Missing | No operation type defined |

#### Existing Infrastructure

**Missing API Method:** `deleteIssueComment()` needs to be added to `GitHubApiService`

**GitHub API Endpoint:** `DELETE /repos/{owner}/{repo}/issues/comments/{id}`

**Current User Tracking:** Available via `SecureStorageService` and `GitHubApiService.getCurrentUser()`

**PendingOperationsService** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/models/pending_operation.dart`):
```dart
enum OperationType {
  createIssue,
  updateIssue,
  closeIssue,
  reopenIssue,
  addComment,
  updateLabels,
  updateAssignee,
  // MISSING: deleteComment
}
```

**SyncService** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/sync_service.dart`, Lines 720-807):
```dart
Future<void> _executeOperation(PendingOperation operation) async {
  switch (operation.type) {
    case OperationType.createIssue:
      await _executeCreateIssue(operation);
    // ... other cases ...
    // MISSING: deleteComment case
  }
}
```

#### Recommendations

1. **Add `deleteComment` operation type to `PendingOperation`:**

```dart
// In /Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/models/pending_operation.dart
enum OperationType {
  createIssue,
  updateIssue,
  closeIssue,
  reopenIssue,
  addComment,
  updateLabels,
  updateAssignee,
  deleteComment, // ADD THIS
}
```

2. **Add factory method for delete comment operation:**

```dart
// In PendingOperation class
factory PendingOperation.deleteComment({
  required String id,
  required int commentId,
  required String owner,
  required String repo,
}) {
  return PendingOperation(
    id: id,
    type: OperationType.deleteComment,
    owner: owner,
    repo: repo,
    data: {'commentId': commentId},
    createdAt: DateTime.now(),
  );
}
```

3. **Add `deleteIssueComment()` to `GitHubApiService`:**

```dart
/// Delete a comment from an issue.
///
/// Only the comment author or repository admin can delete comments.
///
/// Uses GitHub REST API: `DELETE /repos/{owner}/{repo}/issues/comments/{id}`
///
/// Example:
/// ```dart
/// await githubApi.deleteIssueComment('flutter', 'flutter', 12345);
/// ```
///
/// Throws [Exception] if the request fails or user lacks permission.
/// Network errors are handled by [AppErrorHandler].
///
/// [owner] The repository owner's login.
/// [repo] The repository name.
/// [commentId] The comment ID to delete.
Future<void> deleteIssueComment(
  String owner,
  String repo,
  int commentId,
) async {
  try {
    debugPrint('Deleting comment #$commentId from $owner/$repo...');
    final headers = await _headers;

    final response = await _executeWithRetry(
      () => http
          .delete(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/issues/comments/$commentId',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15)),
      operation: 'deleteIssueComment',
    );

    debugPrint('Delete comment response status: ${response.statusCode}');

    if (response.statusCode == 204) {
      debugPrint('✓ Comment #$commentId deleted successfully');
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(
        'Failed to delete comment: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
      );
    }
  } catch (e, stackTrace) {
    AppErrorHandler.handle(e, stackTrace: stackTrace);

    if (e.toString().contains('SocketException') ||
        e.toString().contains('Network')) {
      throw Exception('No internet connection. Delete queued for sync.');
    }
    rethrow;
  }
}
```

4. **Add delete handler to `SyncService`:**

```dart
// In _executeOperation method
case OperationType.deleteComment:
  await _executeDeleteComment(operation);
  break;

// Add new method
Future<void> _executeDeleteComment(PendingOperation operation) async {
  if (operation.owner == null ||
      operation.repo == null ||
      operation.data['commentId'] == null) {
    debugPrint('SyncService: Invalid delete comment operation');
    return;
  }

  final commentId = operation.data['commentId'] as int;
  
  await _githubApi.deleteIssueComment(
    operation.owner!,
    operation.repo!,
    commentId,
  );

  debugPrint(
    'SyncService: Deleted comment #$commentId from queued operation',
  );
}
```

5. **Implement delete UI in `IssueDetailScreen`:**

```dart
// Add state for current user login
String? _currentUserLogin;

@override
void initState() {
  super.initState();
  _currentIssue = widget.issue;
  _loadCurrentUser();
  _loadComments();
}

Future<void> _loadCurrentUser() async {
  try {
    // Try cached first
    final userData = await _localStorage.getUserData();
    if (userData != null) {
      setState(() {
        _currentUserLogin = userData['login'] as String;
      });
      return;
    }

    // Fetch fresh
    final user = await _githubApi.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserLogin = user['login'] as String;
      });
      await _localStorage.saveUserData(user);
    }
  } catch (e) {
    debugPrint('Failed to load current user: $e');
  }
}

// Update _buildCommentTile to show delete option
Widget _buildCommentTile(Map<String, dynamic> comment) {
  final user = comment['user'] as Map<String, dynamic>?;
  final login = user?['login'] as String? ?? 'unknown';
  final commentId = comment['id'] as int?;
  final isOwnComment = login == _currentUserLogin;
  
  // ... existing avatar/username code ...
  
  return Container(
    // ... existing decoration ...
    child: Column(
      children: [
        // Header row with delete button
        Row(
          children: [
            // ... avatar, username, timestamp ...
            const Spacer(),
            if (isOwnComment)
              IconButton(
                icon: Icon(Icons.delete_outline, size: 16.sp),
                color: AppColors.red,
                onPressed: () => _showDeleteConfirmation(commentId!, comment),
                tooltip: 'Delete comment',
              ),
          ],
        ),
        // ... body ...
      ],
    ),
  );
}

// Show confirmation dialog
Future<void> _showDeleteConfirmation(int commentId, Map<String, dynamic> comment) async {
  HapticFeedback.mediumImpact();
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.warning, color: AppColors.red),
          SizedBox(width: 8),
          Text('Delete Comment?', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Text(
        'This action cannot be undone. Are you sure you want to delete this comment?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await _deleteComment(commentId, comment);
  }
}

// Delete comment with optimistic update
Future<void> _deleteComment(int commentId, Map<String, dynamic> comment) async {
  final isOnline = await _networkService.checkConnectivity();

  // Optimistic UI update - remove immediately
  setState(() {
    _comments.removeWhere((c) => c['id'] == commentId);
  });

  if (!isOnline) {
    // Queue for sync
    try {
      final operation = PendingOperation.deleteComment(
        id: 'delete_comment_${commentId}_${DateTime.now().millisecondsSinceEpoch}',
        commentId: commentId,
        owner: _effectiveOwner,
        repo: _effectiveRepo,
      );
      await _pendingOps.addOperation(operation);
      
      _showSnackBar('Delete queued for sync (offline)');
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _comments.add(comment);
      });
      _showErrorSnackBar('Failed to queue delete: $e');
    }
  } else {
    // Delete immediately
    try {
      await _githubApi.deleteIssueComment(
        _effectiveOwner,
        _effectiveRepo,
        commentId,
      );
      _showSnackBar('Comment deleted');
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _comments.add(comment);
      });
      _showErrorSnackBar('Failed to delete: $e');
    }
  }
}
```

---

### Task 17.3: Empty State Illustrations

**Requirement:** Create custom illustrations for no repos/issues/comments/projects/search results, use SVG or CustomPainter, follow dark theme, keep file size <5KB each.

#### Current Implementation Status: PARTIAL

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/dashboard_empty_state.dart`

**Current Implementation:**
```dart
import 'package:flutter/material.dart';

class DashboardEmptyState extends StatelessWidget {
  final VoidCallback? onFetchRepos;

  const DashboardEmptyState({super.key, this.onFetchRepos});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('No repositories', style: TextStyle(...)),
          const SizedBox(height: 8),
          Text('Tap the folder icon to add repositories', style: TextStyle(...)),
        ],
      ),
    );
  }
}
```

**Existing SVG Assets:**
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/assets/cloud.svg` (1.2KB)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/assets/repo.svg` (similar size)

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| No repos illustration | ⚠️ Partial | Uses Material icon, not custom SVG |
| No issues illustration | ❌ Missing | Not implemented |
| No comments illustration | ❌ Missing | Not implemented |
| No projects illustration | ❌ Missing | Not implemented |
| Search no results | ❌ Missing | Not implemented |
| SVG or CustomPainter | ❌ Missing | Uses Material icons |
| Dark theme | ✅ Complete | Uses `AppColors` |
| File size <5KB | N/A | Not applicable yet |

#### Existing Infrastructure

**flutter_svg package:** Available in `pubspec.yaml`
```yaml
dependencies:
  flutter_svg: ^2.0.17
```

**AppColors** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/constants/app_colors.dart`):
```dart
static const Color background = Color(0xFF121212);
static const Color cardBackground = Color(0xFF1E1E1E);
static const Color orangePrimary = Color(0xFFFF6200);
static const Color orangeSecondary = Color(0xFFFF5E00);
static const Color secondaryText = Color(0xFFA0A0A5);
static const Color borderColor = Color(0xFF333333);
```

#### Recommendations

1. **Create unified `EmptyStateWidget` with SVG support:**

```dart
// /Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Empty state widget with custom SVG illustrations
/// 
/// Supports multiple scenarios:
/// - noRepos: No repositories available
/// - noIssues: No issues in repository
/// - noComments: No comments on issue
/// - noProjects: No projects available
/// - noSearchResults: Search returned no results
/// - offline: No cached data available offline
class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(),
            const SizedBox(height: 24),
            _buildTitle(),
            if (subtitle != null || _defaultSubtitle != null) ...[
              const SizedBox(height: 8),
              _buildSubtitle(),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 24),
              _buildActionButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    // Use SVG assets for custom illustrations
    // Each SVG should be <5KB and follow dark theme
    final svgName = _getSvgName();
    return SvgPicture.asset(
      'assets/$svgName',
      width: 120,
      height: 120,
      colorFilter: ColorFilter.mode(
        AppColors.orangePrimary.withValues(alpha: 0.5),
        BlendMode.srcIn,
      ),
    );
  }

  String _getSvgName() {
    switch (type) {
      case EmptyStateType.noRepos:
        return 'empty_repos.svg';
      case EmptyStateType.noIssues:
        return 'empty_issues.svg';
      case EmptyStateType.noComments:
        return 'empty_comments.svg';
      case EmptyStateType.noProjects:
        return 'empty_projects.svg';
      case EmptyStateType.noSearchResults:
        return 'empty_search.svg';
      case EmptyStateType.offline:
        return 'empty_offline.svg';
    }
  }

  Widget _buildTitle() {
    return Text(
      title ?? _defaultTitle,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  String get _defaultTitle {
    switch (type) {
      case EmptyStateType.noRepos:
        return 'No repositories';
      case EmptyStateType.noIssues:
        return 'No issues found';
      case EmptyStateType.noComments:
        return 'No comments yet';
      case EmptyStateType.noProjects:
        return 'No projects';
      case EmptyStateType.noSearchResults:
        return 'No results';
      case EmptyStateType.offline:
        return 'Offline';
    }
  }

  Widget _buildSubtitle() {
    return Text(
      subtitle ?? _defaultSubtitle,
      style: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
    );
  }

  String get _defaultSubtitle {
    switch (type) {
      case EmptyStateType.noRepos:
        return 'Tap the folder icon to add repositories';
      case EmptyStateType.noIssues:
        return 'Create an issue to get started';
      case EmptyStateType.noComments:
        return 'Be the first to comment';
      case EmptyStateType.noProjects:
        return 'Create a project on GitHub';
      case EmptyStateType.noSearchResults:
        return 'Try different keywords or filters';
      case EmptyStateType.offline:
        return 'No cached data available';
    }
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: onAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orangePrimary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(actionLabel ?? 'Get Started'),
    );
  }
}

enum EmptyStateType {
  noRepos,
  noIssues,
  noComments,
  noProjects,
  noSearchResults,
  offline,
}
```

2. **Create SVG illustrations (keep <5KB each):**

**Example: `assets/empty_comments.svg`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg width="120" height="120" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <g fill="none" fill-rule="evenodd">
    <!-- Comment bubble outline -->
    <path
      d="M60 20c-22 0-40 16-40 36 0 8 3 15 8 21l-4 13 15-8c6 3 13 5 21 5 22 0 40-16 40-36S82 20 60 20z"
      stroke="#FF6200"
      stroke-width="3"
      fill="#FF6200"
      fill-opacity="0.1"
    />
    <!-- Comment lines -->
    <rect x="40" y="45" width="40" height="4" rx="2" fill="#FF6200" fill-opacity="0.6"/>
    <rect x="40" y="55" width="32" height="4" rx="2" fill="#FF6200" fill-opacity="0.6"/>
    <rect x="40" y="65" width="36" height="4" rx="2" fill="#FF6200" fill-opacity="0.6"/>
  </g>
</svg>
```

3. **Alternative: Use CustomPainter for programmatic illustrations:**

```dart
// For simpler illustrations, use CustomPainter to avoid SVG files
class EmptyCommentsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = AppColors.orangePrimary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw comment bubble
    final bubblePath = Path()
      ..addOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2 - 10), width: 60, height: 40));
    
    canvas.drawPath(bubblePath, fillPaint);
    canvas.drawPath(bubblePath, paint);

    // Draw lines
    final linePaint = Paint()
      ..color = AppColors.orangePrimary.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(35, 45), Offset(85, 45), linePaint);
    canvas.drawLine(Offset(35, 55), Offset(75, 55), linePaint);
    canvas.drawLine(Offset(35, 65), Offset(80, 65), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

### Task 17.4: Tutorial Tooltips

**Requirement:** Show on first launch only, highlight key features (swipe to edit/close, FAB for new issue, sync cloud icon, filter chips), use coach_mark or tutorial_guru package, allow skip/dismiss, don't show again after dismissed.

#### Current Implementation Status: NOT STARTED

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| First launch only | ❌ Missing | No tracking mechanism |
| Highlight swipe actions | ❌ Missing | No overlay implementation |
| Highlight FAB | ❌ Missing | No overlay implementation |
| Highlight sync icon | ❌ Missing | No overlay implementation |
| Highlight filter chips | ❌ Missing | No overlay implementation |
| Use coach_mark package | ❌ Missing | Package not in pubspec.yaml |
| Allow skip/dismiss | ❌ Missing | No UI implemented |
| Don't show again | ❌ Missing | No persistence |

#### Existing Infrastructure

**LocalStorageService** (Available for tracking tutorial state):
```dart
// Can use existing methods
await _localStorage.saveValue('tutorial_dismissed', true);
final dismissed = await _localStorage.getValue('tutorial_dismissed');
```

**No tutorial package:** Need to add `coach_mark` or similar to `pubspec.yaml`

#### Recommendations

**Option A: Use coach_mark package (Recommended)**

1. **Add package to pubspec.yaml:**
```yaml
dependencies:
  coach_mark: ^1.2.4  # or latest version
```

2. **Create TutorialService:**

```dart
// /Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/tutorial_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../utils/app_error_handler.dart';

/// Service for managing tutorial/coach mark state
class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  late Box<dynamic> _box;
  bool _isInitialized = false;

  /// Tutorial feature flags
  static const String tutorialDismissed = 'tutorial_dismissed';
  static const String swipeTutorialSeen = 'tutorial_swipe_seen';
  static const String fabTutorialSeen = 'tutorial_fab_seen';
  static const String syncTutorialSeen = 'tutorial_sync_seen';
  static const String filterTutorialSeen = 'tutorial_filter_seen';

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox('tutorial');
      _isInitialized = true;
      debugPrint('TutorialService: Initialized');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('TutorialService: Init failed: $e');
    }
  }

  /// Check if entire tutorial is dismissed
  Future<bool> isTutorialDismissed() async {
    if (!_isInitialized) await init();
    return _box.get(tutorialDismissed, defaultValue: false) as bool;
  }

  /// Dismiss entire tutorial
  Future<void> dismissTutorial() async {
    if (!_isInitialized) await init();
    await _box.put(tutorialDismissed, true);
    debugPrint('TutorialService: Tutorial dismissed');
  }

  /// Check if specific feature tutorial has been seen
  Future<bool> hasSeenTutorial(String featureKey) async {
    if (!_isInitialized) await init();
    return _box.get(featureKey, defaultValue: false) as bool;
  }

  /// Mark feature tutorial as seen
  Future<void> markTutorialSeen(String featureKey) async {
    if (!_isInitialized) await init();
    await _box.put(featureKey, true);
    debugPrint('TutorialService: $featureKey tutorial marked as seen');
  }

  /// Reset all tutorial state (for testing or settings)
  Future<void> resetTutorial() async {
    if (!_isInitialized) await init();
    await _box.clear();
    debugPrint('TutorialService: Tutorial reset');
  }

  /// Check if should show tutorial for feature
  Future<bool> shouldShowTutorial(String featureKey) async {
    final isDismissed = await isTutorialDismissed();
    final hasSeen = await hasSeenTutorial(featureKey);
    return !isDismissed && !hasSeen;
  }
}
```

3. **Create TutorialOverlay widget:**

```dart
// /Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/tutorial_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Tutorial overlay that highlights a target widget
class TutorialOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final bool isLast;

  const TutorialOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.onNext,
    this.onSkip,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay with cutout
        CustomPaint(
          painter: OverlayPainter(targetKey: targetKey),
          size: Size.infinite,
        ),
        // Tutorial card
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orangePrimary),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.orangePrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onSkip != null)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            onSkip!();
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onNext();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orangePrimary,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(isLast ? 'Got it' : 'Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OverlayPainter extends CustomPainter {
  final GlobalKey targetKey;

  OverlayPainter({required this.targetKey});

  @override
  void paint(Canvas canvas, Size size) {
    final renderObject = targetKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderObject == null) return;

    final position = renderObject.localToGlobal(Offset.zero);
    final targetRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      renderObject.size.width,
      renderObject.size.height,
    );

    // Draw semi-transparent overlay
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Create path with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          targetRect.inflate(8),
          const Radius.circular(8),
        ),
      );

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw highlight border
    final borderPaint = Paint()
      ..color = AppColors.orangePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        targetRect.inflate(8),
        const Radius.circular(8),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

4. **Integrate tutorial into MainDashboardScreen:**

```dart
// In MainDashboardScreen
final GlobalKey _fabKey = GlobalKey();
final GlobalKey _syncIconKey = GlobalKey();
final GlobalKey _filterChipKey = GlobalKey();
bool _showTutorial = false;
int _currentTutorialStep = 0;

@override
void initState() {
  super.initState();
  _checkTutorial();
}

Future<void> _checkTutorial() async {
  final shouldShow = await TutorialService().shouldShowTutorial('dashboard');
  if (shouldShow && mounted) {
    setState(() {
      _showTutorial = true;
      _currentTutorialStep = 0;
    });
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Main content
        Column(
          children: [
            // Sync icon with key
            IconButton(
              key: _syncIconKey,
              icon: Icon(Icons.cloud),
              onPressed: _sync,
            ),
            // Filter chips with key
            DashboardFilters(
              key: _filterChipKey,
              // ...
            ),
          ],
        ),
        // FAB with key
        FloatingActionButton(
          key: _fabKey,
          onPressed: _createNewIssue,
          child: Icon(Icons.add),
        ),
        // Tutorial overlay
        if (_showTutorial) ...[
          TutorialOverlay(
            targetKey: _getTargetKeyForStep(_currentTutorialStep),
            title: _getTutorialTitle(_currentTutorialStep),
            description: _getTutorialDescription(_currentTutorialStep),
            onNext: _nextTutorialStep,
            onSkip: _dismissTutorial,
            isLast: _currentTutorialStep == 3,
          ),
        ],
      ],
    ),
  );
}

GlobalKey _getTargetKeyForStep(int step) {
  switch (step) {
    case 0:
      return _syncIconKey;
    case 1:
      return _filterChipKey;
    case 2:
      return _fabKey;
    default:
      return _fabKey;
  }
}

String _getTutorialTitle(int step) {
  switch (step) {
    case 0:
      return 'Sync Your Issues';
    case 1:
      return 'Filter Issues';
    case 2:
      return 'Create New Issue';
    default:
      return 'All Set!';
  }
}

String _getTutorialDescription(int step) {
  switch (step) {
    case 0:
      return 'Tap this icon to sync your issues with GitHub. Your changes will be uploaded automatically.';
    case 1:
      return 'Use these chips to filter between open, closed, and all issues.';
    case 2:
      return 'Tap this button to create a new issue. You can work offline and sync later.';
    default:
      return 'You\'re ready to go! You can always access these features from the main screen.';
  }
}

void _nextTutorialStep() {
  if (_currentTutorialStep < 3) {
    setState(() {
      _currentTutorialStep++;
    });
  } else {
    _dismissTutorial();
  }
}

Future<void> _dismissTutorial() async {
  await TutorialService().dismissTutorial();
  setState(() {
    _showTutorial = false;
  });
}
```

**Option B: Custom implementation without external package**

If you prefer not to add dependencies, implement a simpler tooltip system using `Overlay` and `GlobalKey` as shown above.

---

### Task 17.5: Analyzer Warnings

**Requirement:** Fix all unused fields/methods, add dartdoc to public APIs, fix prefer_const_constructors, fix use_build_context_synchronously, target: 0 warnings.

#### Current Implementation Status: NOT STARTED

#### Architecture Compliance Analysis

**analysis_options.yaml** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/analysis_options.yaml`):
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - public_member_api_docs # Enforce dartdoc for public APIs
    - require_trailing_commas
    - prefer_single_quotes
```

**Current State:** Need to run `flutter analyze` to identify warnings

#### Recommendations

1. **Run initial analysis:**
```bash
flutter analyze --no-fatal-infos > analysis_report.txt
```

2. **Categorize warnings by type:**

Expected warning categories:
- `unused_field`: Private fields never used
- `unused_element`: Private methods never called
- `prefer_const_constructors`: Widgets that could be const
- `use_build_context_synchronously`: Context used after async gap
- `public_member_api_docs`: Missing dartdoc comments
- `avoid_print`: debugPrint statements
- `prefer_final_fields`: Fields that could be final

3. **Fix strategy by category:**

**A. Unused fields/methods:**
```dart
// Before
class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  String? _unusedField; // WARNING: unused_field
  
  void _unusedMethod() {} // WARNING: unused_element
  
  @override
  Widget build(BuildContext context) {
    // ...
  }
}

// After - Remove or use
class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**B. prefer_const_constructors:**
```dart
// Before
Widget _buildIcon() {
  return Icon(Icons.add); // WARNING
}

// After
Widget _buildIcon() {
  return const Icon(Icons.add); // OK
}
```

**C. use_build_context_synchronously:**
```dart
// Before
Future<void> _doSomething() async {
  await someAsyncOperation();
  Navigator.pop(context); // WARNING: context might be stale
}

// After
Future<void> _doSomething() async {
  await someAsyncOperation();
  if (!mounted) return;
  Navigator.pop(context); // OK
}

// Or use mounted check
Future<void> _doSomething() async {
  await someAsyncOperation();
  if (mounted) {
    Navigator.pop(context);
  }
}
```

**D. public_member_api_docs:**
```dart
// Before
class GitHubApiService {
  Future<IssueItem> fetchIssue(String owner, String repo, int number) {
    // ...
  }
}

// After
class GitHubApiService {
  /// Fetches a single issue by number.
  ///
  /// Retrieves issue details from GitHub API including:
  /// - Title and body (Markdown)
  /// - Status (open/closed)
  /// - Assignee information
  /// - Labels
  /// - Timestamps
  ///
  /// Example:
  /// ```dart
  /// final issue = await githubApi.fetchIssue('flutter', 'flutter', 123);
  /// print(issue.title);
  /// ```
  ///
  /// Throws [Exception] if the request fails or issue not found.
  /// Network errors are handled gracefully with user-friendly messages.
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// [number] The issue number.
  /// Returns the [IssueItem] with full details.
  Future<IssueItem> fetchIssue(String owner, String repo, int number) async {
    // ...
  }
}
```

**E. prefer_final_fields:**
```dart
// Before
class _MyState extends State<MyWidget> {
  String _title = 'Hello'; // Could be final
  
  @override
  Widget build(BuildContext context) {
    return Text(_title);
  }
}

// After
class _MyState extends State<MyWidget> {
  final String _title = 'Hello';
  
  @override
  Widget build(BuildContext context) {
    return Text(_title);
  }
}
```

4. **Create automated fix script:**

```bash
#!/bin/bash
# fix_analyzer_warnings.sh

echo "Running dart fix --apply..."
dart fix --apply

echo "Running dart format..."
dart format lib/

echo "Running flutter analyze..."
flutter analyze

echo "Done! Check for remaining warnings."
```

5. **Add pre-commit hook:**

```yaml
# In .github/workflows/analyze.yml
name: Flutter Analyze

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
```

---

## Cross-Cutting Concerns Review

### 1. Caching Strategy

**Status:** EXCELLENT (Existing)

**CacheService** provides 5-minute TTL:
```dart
await _cache.set(key, value, ttl: const Duration(minutes: 5));
final cached = _cache.get<List>(key);
```

**Recommendation:** Use consistent cache key naming:
- Comments: `comments_{owner}_{repo}_{issueNumber}`
- User data: `current_user_data`
- Tutorial state: Use Hive box (separate from CacheService)

### 2. Offline Operation Queuing

**Status:** EXCELLENT (Existing)

**PendingOperationsService** supports queuing with status tracking.

**Recommendation:** Add `deleteComment` operation type (see Task 17.2).

### 3. Error Handling

**Status:** EXCELLENT (Existing)

**AppErrorHandler** is consistently used:
```dart
catch (e, stackTrace) {
  AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
}
```

**Recommendation:** Continue using this pattern. Add specific messages for:
- Comment deletion failures
- Tutorial dismissals
- Empty state actions

### 4. Dark Theme Compliance

**Status:** EXCELLENT (Existing)

**AppColors** is consistently used throughout.

**Recommendation:** For Task 17.3, ensure SVG illustrations use `AppColors.orangePrimary` for consistency.

### 5. Haptic Feedback

**Status:** EXCELLENT (Existing from Sprint 15)

**Pattern:**
```dart
HapticFeedback.selectionClick(); // Light interactions
HapticFeedback.mediumImpact(); // Confirmations
HapticFeedback.lightImpact(); // Swipe actions
```

**Recommendation:** Add haptic feedback to:
- Comment delete button tap
- Tutorial skip/next buttons
- Empty state action buttons

---

## API Usage Review

### GitHub API Endpoints for Sprint 17

| Endpoint | Status | Sprint 17 Task |
|----------|--------|----------------|
| `GET /repos/{owner}/{repo}/issues/{number}/comments` | ✅ Implemented | Task 17.1 |
| `DELETE /repos/{owner}/{repo}/issues/comments/{id}` | ❌ Needs implementation | Task 17.2 |
| `GET /user` | ✅ Implemented | Task 17.2 (author check) |

### API Best Practices Compliance

| Practice | Status | Notes |
|----------|--------|-------|
| Authentication headers | ✅ | All methods use `_headers` with token |
| Timeout handling | ✅ | 15-second timeouts configured |
| Retry logic | ✅ | `_executeWithRetry()` with exponential backoff |
| Error parsing | ✅ | JSON error responses parsed |
| Caching | ⚠️ | Needs addition for comments (Task 17.1) |

---

## State Management Review

**Status:** MIXED

**Current Pattern:** StatefulWidget with direct service instantiation
```dart
class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final NetworkService _networkService = NetworkService();
  // ...
}
```

**Recommendation:** Current pattern is acceptable for Sprint 17 scope. Consider Riverpod for:
- Current user state
- Tutorial state
- Comment cache

Example (future enhancement):
```dart
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.read(githubApiServiceProvider).getCurrentUser();
});

final tutorialServiceProvider = Provider<TutorialService>((ref) {
  return TutorialService();
});
```

---

## Performance Considerations

### Current Performance Patterns

**Good:**
- Comments load asynchronously
- Caching reduces API calls (once implemented)
- Optimistic UI updates for delete

**Recommendations:**

1. **Lazy load comments:**
```dart
// Don't load comments until user scrolls to section
// Or use pagination for issues with many comments
```

2. **Avatar caching:**
```dart
// Already using CachedNetworkImage from Sprint 16
CachedNetworkImage(
  imageUrl: avatarUrl,
  placeholder: (context, url) => CircleAvatar(...),
  errorWidget: (context, url, error) => CircleAvatar(...),
)
```

3. **Comment pagination (future):**
```dart
// GitHub API supports pagination
final comments = await _githubApi.fetchIssueComments(
  owner,
  repo,
  issueNumber,
  page: 1,
  perPage: 30,
);
```

---

## Testing Recommendations

### Unit Tests Needed

1. **TutorialService tests:**
```dart
test('should show tutorial when not dismissed', () async {
  final service = TutorialService();
  await service.init();
  expect(await service.shouldShowTutorial('feature1'), true);
});

test('should not show tutorial when dismissed', () async {
  final service = TutorialService();
  await service.init();
  await service.dismissTutorial();
  expect(await service.shouldShowTutorial('feature1'), false);
});
```

2. **EmptyStateWidget tests:**
```dart
testWidgets('displays correct title for noComments', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: EmptyStateWidget(type: EmptyStateType.noComments),
    ),
  );
  expect(find.text('No comments yet'), findsOneWidget);
});
```

### Integration Tests Needed

1. **Comment deletion flow:**
   - Display comments
   - Long-press own comment
   - Confirm deletion
   - Verify comment removed
   - Verify operation queued when offline

2. **Tutorial flow:**
   - First launch: tutorial shows
   - Dismiss tutorial
   - Restart app: tutorial doesn't show
   - Reset tutorial in settings
   - Restart app: tutorial shows again

---

## Summary of Required Changes

### Task 17.1: Display Comments

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `github_api_service.dart` | Add caching to `fetchIssueComments()` | HIGH | ~40 |
| `issue_detail_screen.dart` | Update `_loadComments()` for offline | MEDIUM | ~20 |

### Task 17.2: Comment Deletion

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `pending_operation.dart` | Add `deleteComment` operation type | HIGH | ~15 |
| `github_api_service.dart` | Add `deleteIssueComment()` method | HIGH | ~40 |
| `sync_service.dart` | Add `_executeDeleteComment()` handler | HIGH | ~20 |
| `issue_detail_screen.dart` | Add delete UI and logic | HIGH | ~100 |

### Task 17.3: Empty State Illustrations

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `empty_state_widget.dart` | NEW FILE: Unified widget | MEDIUM | ~150 |
| `assets/empty_*.svg` | NEW FILES: 6 SVG illustrations | MEDIUM | ~50 each |
| `dashboard_empty_state.dart` | Replace with new widget | LOW | ~30 |
| Various screens | Update to use new widget | MEDIUM | ~10 each |

### Task 17.4: Tutorial Tooltips

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `pubspec.yaml` | Add `coach_mark` package | MEDIUM | ~1 |
| `tutorial_service.dart` | NEW FILE: State management | MEDIUM | ~80 |
| `tutorial_overlay.dart` | NEW FILE: Overlay widget | MEDIUM | ~150 |
| `main_dashboard_screen.dart` | Integrate tutorial | MEDIUM | ~100 |

### Task 17.5: Analyzer Warnings

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| All files with warnings | Fix by category | HIGH | Varies |

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Comments API caching breaks existing | MEDIUM | LOW | Test thoroughly, add fallback |
| Comment deletion affects wrong comments | HIGH | LOW | Verify author check logic |
| Tutorial annoys users | MEDIUM | MEDIUM | Easy dismiss, don't show again |
| SVG illustrations off-theme | LOW | LOW | Use AppColors, review |
| Analyzer fixes introduce bugs | MEDIUM | MEDIUM | Test after each category |

---

## Implementation Priority

1. **Task 17.1** (Comments display) - Foundation for 17.2
2. **Task 17.2** (Comment deletion) - Depends on 17.1
3. **Task 17.5** (Analyzer warnings) - Independent, high priority
4. **Task 17.3** (Empty states) - Independent, visual polish
5. **Task 17.4** (Tutorial) - Independent, UX enhancement

---

## Acceptance Criteria Checklist

### Task 17.1
- [ ] Comments load from GitHub API
- [ ] Comments cached for 5 minutes
- [ ] Works offline (shows cached comments)
- [ ] Displays avatar, username, timestamp, body
- [ ] Markdown rendering in comment body
- [ ] Loading state during fetch
- [ ] Empty state when no comments

### Task 17.2
- [ ] Delete option only for own comments
- [ ] Confirmation dialog before deletion
- [ ] Optimistic UI update
- [ ] Queues for sync when offline
- [ ] Haptic feedback on delete
- [ ] Snackbar confirmation

### Task 17.3
- [ ] 6 empty state illustrations created
- [ ] SVG format, <5KB each
- [ ] Dark theme compatible
- [ ] Used consistently across app
- [ ] Smooth animation on appearance

### Task 17.4
- [ ] Tutorial shows on first launch
- [ ] Highlights 4 key features
- [ ] Easy to skip/dismiss
- [ ] Doesn't show again after dismiss
- [ ] Reset option in settings

### Task 17.5
- [ ] `flutter analyze`: 0 errors
- [ ] `flutter analyze`: 0 warnings
- [ ] All public APIs have dartdoc
- [ ] No unused fields/methods
- [ ] All const constructors fixed

---

**Document Version:** 1.0
**Last Updated:** March 3, 2026
**Sprint:** 17

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
