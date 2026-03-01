import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reorderables/reorderables.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/braille_loader.dart';
import 'issue_detail_screen.dart';

/// ProjectBoardScreen - Kanban-style project board with real GitHub data
/// Implements brief section 7, screen 4
class ProjectBoardScreen extends ConsumerStatefulWidget {
  const ProjectBoardScreen({super.key});

  @override
  ConsumerState<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends ConsumerState<ProjectBoardScreen> {
  final GitHubApiService _githubApi = GitHubApiService();

  // Standard columns for Status field
  final List<String> _columns = ['Todo', 'In Progress', 'Review', 'Done'];

  // Project data
  String? _projectId;
  String? _statusFieldId;
  final Map<String, String> _columnOptionIds = {}; // columnName -> optionId

  // Issues grouped by column
  Map<String, List<IssueItem>> _columnItems = {};

  bool _isLoading = true;
  bool _isMoving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  /// Load project and its items from GitHub
  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch user's projects
      final projects = await _githubApi.fetchProjects();

      if (projects.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No projects found. Create a project on GitHub first.';
        });
        return;
      }

      // Use the first open project
      final project = projects.firstWhere(
        (p) => !(p['closed'] as bool),
        orElse: () => projects.first,
      );

      _projectId = project['id'] as String;
      final projectTitle = project['title'] as String;

      debugPrint('Using project: $projectTitle ($_projectId)');

      // Fetch project fields to find Status field
      final fields = await _githubApi.getProjectFields(_projectId!);

      if (fields == null || fields.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load project fields';
        });
        return;
      }

      // Find the Status field (single select)
      String? statusFieldName;
      for (final field in fields) {
        if (field['__typename'] == 'ProjectV2SingleSelectField') {
          _statusFieldId = field['id'] as String;
          statusFieldName = field['name'] as String;

          // Get column option IDs
          final options = field['options'] as List? ?? [];
          for (final option in options) {
            final optionName = option['name'] as String;
            final optionId = option['id'] as String;
            _columnOptionIds[optionName] = optionId;
          }

          debugPrint('Found status field: $statusFieldName ($_statusFieldId)');
          debugPrint('Column options: ${_columnOptionIds.keys.toList()}');
          break;
        }
      }

      if (_statusFieldId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Project has no Status field (single select)';
        });
        return;
      }

      // Fetch project items (issues)
      final itemsByColumn = await _githubApi.getProjectItems(
        projectId: _projectId!,
        statusFieldId: _statusFieldId!,
      );

      // Convert to IssueItem objects
      final columnItems = <String, List<IssueItem>>{};

      for (final entry in itemsByColumn.entries) {
        final columnName = entry.key;
        final issues = entry.value;

        columnItems[columnName] = issues.map((issue) {
          return IssueItem(
            id: issue['id'] as String,
            title: issue['title'] as String,
            number: issue['number'] as int,
            bodyMarkdown: issue['body'] as String?,
            status: (issue['state'] as String) == 'open'
                ? ItemStatus.open
                : ItemStatus.closed,
            updatedAt: issue['updatedAt'] != null
                ? DateTime.parse(issue['updatedAt'] as String)
                : null,
            assigneeLogin: issue['assignee']?['login'] as String?,
            labels:
                (issue['labels']?['nodes'] as List?)
                    ?.map((l) => l['name'] as String)
                    .toList() ??
                [],
            isLocalOnly: false,
            projectColumnName: columnName,
          );
        }).toList();
      }

      // Ensure all standard columns exist (even if empty)
      for (final column in _columns) {
        if (!columnItems.containsKey(column)) {
          columnItems[column] = [];
        }
      }

      setState(() {
        _columnItems = columnItems;
        _isLoading = false;
      });

      debugPrint(
        'Loaded ${itemsByColumn.values.fold<int>(0, (sum, list) => sum + list.length)} issues across ${columnItems.length} columns',
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading project data: $e');
      debugPrint('Stack: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load project: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Project Board',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orangePrimary),
            onPressed: _isLoading ? null : _loadProjectData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addNewIssue,
            tooltip: 'New Issue',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: BrailleLoader(size: 32));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProjectData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangePrimary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_columnItems.isEmpty ||
        _columnItems.values.every((list) => list.isEmpty)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_kanban,
              color: Colors.white.withValues(alpha: 0.3),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'No issues in this project',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create an issue',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return _buildBoard();
  }

  Widget _buildBoard() {
    final columnWidth = AppResponsive.isDesktop(context) ? 360.w : 300.w;
    final padding = AppResponsive.isDesktop(context) ? 24.w : 16.w;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(padding),
      itemCount: _columns.length,
      itemBuilder: (context, index) {
        final column = _columns[index];
        return _buildColumn(column, columnWidth);
      },
    );
  }

  Widget _buildColumn(String columnName, double columnWidth) {
    final items = _columnItems[columnName] ?? [];

    return Container(
      width: columnWidth,
      margin: EdgeInsets.only(right: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getColumnColor(columnName),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  columnName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Cards
          Expanded(child: _buildCardList(columnName, items)),
        ],
      ),
    );
  }

  Color _getColumnColor(String columnName) {
    switch (columnName) {
      case 'Todo':
        return Colors.grey;
      case 'In Progress':
        return AppColors.orangePrimary;
      case 'Review':
        return AppColors.blue;
      case 'Done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCardList(String columnName, List<IssueItem> items) {
    if (items.isEmpty) {
      return DragTarget<IssueItem>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) async {
          await _moveItemToColumn(details.data, columnName);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? AppColors.orangePrimary.withValues(alpha: 0.1)
                  : AppColors.cardBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? AppColors.orangePrimary
                    : AppColors.cardBackground.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No issues',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  if (candidateData.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Drop here',
                      style: TextStyle(
                        color: AppColors.orangePrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    return DragTarget<IssueItem>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) async {
        await _moveItemToColumn(details.data, columnName);
      },
      builder: (context, candidateData, rejectedData) {
        return ReorderableColumn(
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex == newIndex) return;

            final item = items.removeAt(oldIndex);
            items.insert(newIndex, item);

            setState(() {
              _columnItems[columnName] = items;
              _isMoving = true;
            });

            // Update project item status via GraphQL
            await _moveItemToColumn(item, columnName);

            setState(() {
              _isMoving = false;
            });
          },
          children: items
              .map((item) => _buildDraggableCard(item, columnName))
              .toList(),
        );
      },
    );
  }

  /// Build a draggable card that can be moved between columns
  Widget _buildDraggableCard(IssueItem item, String columnName) {
    return LongPressDraggable<IssueItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 280,
          child: Opacity(opacity: 0.9, child: _buildCardContent(item)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCard(item, columnName),
      ),
      child: _buildCard(item, columnName),
    );
  }

  /// Card content (without the Card wrapper - for reuse in drag feedback)
  Widget _buildCardContent(IssueItem item) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${item.number} ${item.title}',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.labels.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Wrap(
                spacing: 4.w,
                children: item.labels.take(2).map((label) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orangePrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.orangePrimary,
                        fontSize: 10.sp,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Move item to different column using GraphQL mutation
  Future<void> _moveItemToColumn(IssueItem item, String newColumnName) async {
    // Find current column of this item
    String? oldColumn;
    for (final entry in _columnItems.entries) {
      if (entry.value.any((i) => i.id == item.id)) {
        oldColumn = entry.key;
        break;
      }
    }

    // If moving within same column, just return
    if (oldColumn == newColumnName) {
      return;
    }

    // Remove from old column, add to new column in local state
    if (oldColumn != null) {
      final oldList = List<IssueItem>.from(_columnItems[oldColumn] ?? []);
      oldList.removeWhere((i) => i.id == item.id);
      _columnItems[oldColumn] = oldList;
    }

    final newList = List<IssueItem>.from(_columnItems[newColumnName] ?? []);
    newList.add(item);
    _columnItems[newColumnName] = newList;

    setState(() {});

    if (_projectId == null || _statusFieldId == null) {
      debugPrint('Project not initialized, local update only');
      return;
    }

    final optionId = _columnOptionIds[newColumnName];
    if (optionId == null) {
      debugPrint('No option ID for column: $newColumnName');
      return;
    }

    debugPrint('Moving issue #${item.number} to column: $newColumnName');

    try {
      final success = await _githubApi.moveProjectItem(
        projectId: _projectId!,
        itemId: item.id,
        fieldId: _statusFieldId!,
        optionId: optionId,
      );

      if (success) {
        debugPrint(
          '✓ Successfully moved issue #${item.number} to $newColumnName',
        );

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('Issue #${item.number} moved to $newColumnName'),
                ],
              ),
              backgroundColor: AppColors.orangePrimary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('✗ Failed to move issue #${item.number}');
        _showMoveError(item, newColumnName);
      }
    } catch (e) {
      debugPrint('✗ Error moving issue: $e');
      _showMoveError(item, newColumnName);
    }
  }

  void _showMoveError(IssueItem item, String columnName) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to move issue #${item.number}')),
          ],
        ),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () => _moveItemToColumn(item, columnName),
        ),
      ),
    );
  }

  Widget _buildCard(IssueItem item, String columnName) {
    return Card(
      color: AppColors.cardBackground,
      margin: EdgeInsets.only(bottom: 8.h),
      child: Opacity(
        opacity: _isMoving ? 0.5 : 1.0,
        child: ListTile(
          title: Text(
            '#${item.number} ${item.title}',
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.labels.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 4.w,
                  children: item.labels.take(2).map((label) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orangePrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: AppColors.orangePrimary,
                          fontSize: 10.sp,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (item.assigneeLogin != null) ...[
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.person, size: 12.w, color: AppColors.blue),
                    SizedBox(width: 4.w),
                    Text(
                      item.assigneeLogin!,
                      style: TextStyle(color: AppColors.blue, fontSize: 11.sp),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12.w, color: AppColors.red),
                  SizedBox(width: 4.w),
                  Text(
                    _formatRelativeTime(item.updatedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: _isMoving
              ? BrailleLoader(size: 20)
              : Icon(Icons.drag_handle, color: AppColors.red, size: 20.w),
          onTap: () => _openIssueDetail(item),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  void _addNewIssue() {
    // Navigate back to dashboard to create issue
    // This is a temporary solution - in production, we'd have a dedicated create flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Create issues from the Dashboard'),
          ],
        ),
        backgroundColor: AppColors.orangePrimary,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _openIssueDetail(IssueItem issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IssueDetailScreen(
          issue: issue,
          // owner/repo would need to be fetched or passed separately
        ),
      ),
    );
  }
}
