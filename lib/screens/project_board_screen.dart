import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../models/project_item.dart';
import '../models/repo_item.dart';
import '../providers/repositories_provider.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../widgets/braille_loader.dart';
import 'create_issue_screen.dart';
import 'issue_detail_screen.dart';

/// Local-first kanban for a real GitHub Projects V2 project.
class ProjectBoardScreen extends ConsumerStatefulWidget {
  final ProjectV2? project;
  final ProjectV2Board? initialBoard;

  const ProjectBoardScreen({super.key, this.project, this.initialBoard});

  @override
  ConsumerState<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends ConsumerState<ProjectBoardScreen> {
  final SyncService _sync = SyncService();
  final LocalStorageService _storage = LocalStorageService();

  List<ProjectV2> _projects = const [];
  ProjectV2? _selectedProject;
  ProjectV2Board? _board;
  String _query = '';
  String? _repoFilter;
  String? _error;
  bool _loading = true;
  bool _refreshing = false;
  VoidCallback? _syncListener;

  @override
  void initState() {
    super.initState();
    if (widget.initialBoard != null) {
      _board = widget.initialBoard;
      _selectedProject = widget.initialBoard!.project;
      _projects = [widget.initialBoard!.project];
      _loading = false;
      return;
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    await _sync.init();
    _syncListener = () {
      if (_selectedProject != null &&
          (_sync.syncPhase == SyncPhase.success ||
              _sync.syncPhase == SyncPhase.partial)) {
        unawaited(_reloadCachedBoard());
      }
    };
    _sync.addListener(_syncListener!);

    var projects = await _sync.loadProjectsFromCache();
    if (widget.project != null &&
        projects.every((project) => project.id != widget.project!.id)) {
      projects = [widget.project!, ...projects];
    }

    ProjectV2? selected = widget.project;
    final savedDefault = await _storage.getDefaultProject();
    if (selected == null && savedDefault != null) {
      selected = _findProject(projects, savedDefault);
      if (selected != null && savedDefault != selected.id) {
        await _storage.saveDefaultProject(selected.id);
      }
    }
    if (selected == null && projects.length == 1) {
      selected = projects.single;
    }

    if (mounted) {
      setState(() {
        _projects = projects;
        _selectedProject = selected;
        _loading = selected != null;
      });
    }

    if (selected != null) {
      await _loadBoard(selected);
    } else if (_sync.isNetworkAvailable) {
      await _refreshProjects();
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  ProjectV2? _findProject(List<ProjectV2> projects, String idOrTitle) {
    for (final project in projects) {
      if (project.id == idOrTitle || project.title == idOrTitle) return project;
    }
    return null;
  }

  Future<void> _refreshProjects() async {
    if (mounted) setState(() => _refreshing = true);
    try {
      await _sync.syncProjects(forceRefresh: true);
      final projects = await _sync.loadProjectsFromCache();
      if (mounted) {
        setState(() {
          _projects = projects;
          _loading = false;
          _refreshing = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _selectProject(ProjectV2 project) async {
    await _storage.saveDefaultProject(project.id);
    if (!mounted) return;
    setState(() {
      _selectedProject = project;
      _board = null;
      _error = null;
      _loading = true;
      _repoFilter = null;
    });
    await _loadBoard(project);
  }

  Future<void> _loadBoard(ProjectV2 project) async {
    final cached = await _sync.loadProjectBoardFromCache(project.id);
    if (mounted) {
      setState(() {
        _board = cached;
        _loading = cached == null;
      });
    }
    if (_sync.isNetworkAvailable) {
      await _refreshBoard();
    } else if (cached == null && mounted) {
      setState(() {
        _loading = false;
        _error = 'No cached board yet. Connect once to download this project.';
      });
    }
  }

  Future<void> _refreshBoard() async {
    final project = _selectedProject;
    if (project == null || _refreshing) return;
    if (mounted) setState(() => _refreshing = true);
    try {
      final board = await _sync.syncProjectBoard(project);
      if (mounted) {
        setState(() {
          _board = board;
          _selectedProject = board.project;
          _error = null;
          _loading = false;
          _refreshing = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _reloadCachedBoard() async {
    final project = _selectedProject;
    if (project == null) return;
    final board = await _sync.loadProjectBoardFromCache(project.id);
    if (mounted && board != null) setState(() => _board = board);
  }

  @override
  void dispose() {
    final listener = _syncListener;
    if (listener != null) _sync.removeListener(listener);
    _sync.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          _selectedProject?.displayName ?? 'Project Board',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_projects.isNotEmpty)
            PopupMenuButton<ProjectV2>(
              tooltip: 'Choose project',
              icon: const Icon(Icons.view_kanban),
              onSelected: _selectProject,
              itemBuilder: (context) => _projects
                  .map(
                    (project) => PopupMenuItem(
                      value: project,
                      child: Text(
                        project.displayName,
                        style: TextStyle(
                          color: project.closed ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (_selectedProject != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New issue in this project',
              onPressed: _selectedProject!.viewerCanUpdate
                  ? _addNewIssue
                  : null,
            ),
          IconButton(
            icon: _refreshing
                ? const BrailleLoader(size: 20)
                : const Icon(Icons.refresh),
            tooltip: 'Sync projects',
            onPressed: _refreshing
                ? null
                : (_selectedProject == null ? _refreshProjects : _refreshBoard),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedProject == null) return _buildProjectPicker();
    if (_loading && _board == null) {
      return const Center(child: BrailleLoader(size: 32));
    }
    if (_board == null) return _buildError();
    if (_board!.statusFieldId == null) {
      return _message(
        Icons.view_column_outlined,
        'This project has no Status field. Add one on GitHub to use kanban.',
      );
    }

    return Column(
      children: [
        _buildToolbar(),
        if (_error != null)
          MaterialBanner(
            content: Text('Showing offline data. $_error'),
            actions: [
              TextButton(onPressed: _refreshBoard, child: const Text('RETRY')),
            ],
          ),
        Expanded(child: _buildBoard()),
      ],
    );
  }

  Widget _buildProjectPicker() {
    if (_loading || _refreshing) {
      return const Center(child: BrailleLoader(size: 32));
    }
    if (_projects.isEmpty) {
      return _message(
        Icons.view_kanban_outlined,
        _error ?? 'No cached projects. Connect and tap refresh.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choose a project',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        for (final project in _projects)
          Card(
            color: AppColors.card,
            child: ListTile(
              leading: Icon(
                project.ownerType == ProjectOwnerType.organization
                    ? Icons.business
                    : Icons.person,
                color: AppColors.primary,
              ),
              title: Text(project.title),
              subtitle: Text(project.ownerLogin),
              trailing: project.closed
                  ? const Text('Closed')
                  : const Icon(Icons.chevron_right),
              onTap: () => _selectProject(project),
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return _message(Icons.error_outline, _error ?? 'Project board unavailable');
  }

  Widget _message(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.error, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final repos =
        _board!.items
            .map((item) => item.repoFullName)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search title, number, or repository',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              SizedBox(width: 12.w),
              DropdownButton<String?>(
                value: repos.contains(_repoFilter) ? _repoFilter : null,
                hint: const Text('All repos'),
                dropdownColor: AppColors.card,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All repos')),
                  ...repos.map(
                    (repo) => DropdownMenuItem(value: repo, child: Text(repo)),
                  ),
                ],
                onChanged: (value) => setState(() => _repoFilter = value),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Last synced ${_formatAge(_board!.fetchedAt)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatAge(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  List<ProjectV2BoardItem> get _visibleItems {
    final query = _query.trim().toLowerCase();
    return _board!.items.where((item) {
      if (_repoFilter != null && item.repoFullName != _repoFilter) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.number?.toString().contains(query) == true ||
          item.repoFullName?.toLowerCase().contains(query) == true;
    }).toList();
  }

  Widget _buildBoard() {
    final width = MediaQuery.sizeOf(context).width >= 900 ? 360.w : 300.w;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(16.w),
      children: [
        for (final column in _board!.columns) _buildColumn(column, width),
      ],
    );
  }

  Widget _buildColumn(ProjectV2Column column, double width) {
    final items = _visibleItems
        .where((item) => item.statusOptionId == column.optionId)
        .toList();
    final canMove = _board!.project.viewerCanUpdate;
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  color: _columnColor(column.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    column.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${items.length}'),
              ],
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: DragTarget<ProjectV2BoardItem>(
                onWillAcceptWithDetails: (details) =>
                    canMove &&
                    !details.data.projectItemId.startsWith('pending_') &&
                    details.data.statusOptionId != column.optionId,
                onAcceptWithDetails: (details) => _move(details.data, column),
                builder: (context, candidates, rejected) => Container(
                  decoration: BoxDecoration(
                    color: candidates.isEmpty
                        ? Colors.transparent
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: candidates.isEmpty
                        ? null
                        : Border.all(color: AppColors.primary),
                  ),
                  child: ListView(
                    children: [
                      for (final item in items) _buildDraggable(item, canMove),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No items')),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggable(ProjectV2BoardItem item, bool canMove) {
    final card = _buildCard(item);
    if (!canMove || item.projectItemId.startsWith('pending_')) return card;
    return LongPressDraggable<ProjectV2BoardItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 280, child: _buildCard(item)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }

  Widget _buildCard(ProjectV2BoardItem item) {
    return Card(
      color: AppColors.card,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(_contentIcon(item.contentType), color: AppColors.link),
        title: Text(
          '${item.number == null ? '' : '#${item.number} '}${item.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.repoFullName != null) Text(item.repoFullName!),
            if (item.labels.isNotEmpty)
              Wrap(
                spacing: 4,
                children: item.labels
                    .take(2)
                    .map((label) => Chip(label: Text(label)))
                    .toList(),
              ),
          ],
        ),
        trailing: switch (item.syncState) {
          ProjectItemSyncState.pending => const Icon(
            Icons.cloud_upload_outlined,
            color: AppColors.warning,
          ),
          ProjectItemSyncState.failed => const Icon(
            Icons.sync_problem,
            color: AppColors.error,
          ),
          ProjectItemSyncState.synced => null,
        },
        onTap: () => _openItem(item),
      ),
    );
  }

  Future<void> _move(ProjectV2BoardItem item, ProjectV2Column column) async {
    final board = _board;
    if (board == null) return;
    final updated = await _sync.queueProjectItemStatus(
      board: board,
      item: item,
      column: column,
    );
    if (mounted) setState(() => _board = updated);
  }

  Future<void> _addNewIssue() async {
    final project = _selectedProject;
    if (project == null) return;
    final repos = ref
        .read(repositoriesProvider)
        .where((repo) => repo.id != 'vault')
        .toList();
    final savedRepo = await _storage.getDefaultRepo();
    RepoItem? repo;
    for (final candidate in repos) {
      if (candidate.fullName == savedRepo) {
        repo = candidate;
        break;
      }
    }
    repo ??= repos.isEmpty ? null : repos.first;
    if (repo == null || !mounted) return;
    final selectedRepo = repo;
    final parts = selectedRepo.fullName.split('/');
    final result = await Navigator.of(context).push<CreateIssueResult>(
      MaterialPageRoute(
        builder: (context) => CreateIssueScreen(
          owner: parts.first,
          repo: parts.last,
          expandedRepoFullName: selectedRepo.fullName,
          defaultProjectId: project.id,
          projects: _projects,
          availableRepos: repos,
        ),
      ),
    );
    if (result?.issue != null && _board != null) {
      final issue = result!.issue!;
      final pendingItem = ProjectV2BoardItem(
        projectItemId: 'pending_${issue.id}',
        contentId: issue.id,
        contentType: ProjectContentType.issue,
        title: issue.title,
        number: issue.number,
        body: issue.bodyMarkdown,
        state: issue.status == ItemStatus.open ? 'open' : 'closed',
        repoFullName: issue.repoFullName,
        updatedAt: issue.updatedAt,
        assigneeLogin: issue.assigneeLogin,
        labels: issue.labels,
        syncState: ProjectItemSyncState.pending,
      );
      final updated = _board!.copyWith(items: [..._board!.items, pendingItem]);
      await _sync.saveProjectBoardSnapshot(updated);
      if (mounted) setState(() => _board = updated);
    }
  }

  Future<void> _openItem(ProjectV2BoardItem item) async {
    if (item.contentType == ProjectContentType.issue &&
        item.repoFullName != null &&
        item.number != null) {
      final parts = item.repoFullName!.split('/');
      if (parts.length != 2 || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IssueDetailScreen(
            issue: IssueItem(
              id: item.contentId ?? item.projectItemId,
              title: item.title,
              number: item.number,
              bodyMarkdown: item.body,
              repoFullName: item.repoFullName,
              status: item.state == 'closed'
                  ? ItemStatus.closed
                  : ItemStatus.open,
              updatedAt: item.updatedAt,
              assigneeLogin: item.assigneeLogin,
              labels: item.labels,
            ),
            owner: parts.first,
            repo: parts.last,
          ),
        ),
      );
      return;
    }
    final url = item.url;
    if (url != null) await launchUrl(Uri.parse(url));
  }

  IconData _contentIcon(ProjectContentType type) => switch (type) {
    ProjectContentType.issue => Icons.adjust,
    ProjectContentType.pullRequest => Icons.call_merge,
    ProjectContentType.draftIssue => Icons.edit_note,
    ProjectContentType.redacted => Icons.visibility_off,
  };

  Color _columnColor(String color) => switch (color.toUpperCase()) {
    'BLUE' => Colors.blue,
    'GREEN' => Colors.green,
    'YELLOW' => Colors.yellow,
    'ORANGE' => Colors.orange,
    'RED' => Colors.red,
    'PINK' => Colors.pink,
    'PURPLE' => Colors.purple,
    _ => Colors.grey,
  };
}
