import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../services/github_api_service.dart';
import '../services/pending_operations_service.dart';
import '../services/network_service.dart';
import '../services/local_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../services/sync_service.dart';
import '../models/issue_item.dart';
import '../models/repo_item.dart';
import '../models/project_item.dart';
import '../models/pending_operation.dart';
import '../widgets/braille_loader.dart';

/// Screen for creating new GitHub issues.
///
/// Supports:
/// - Title and body input with Markdown support
/// - Label selection from available repository labels
/// - Assignee selection from repository collaborators
/// - Repository selection from user's repositories
/// - Real-time loading of labels and assignees
/// - Offline mode with operation queuing
/// - Input validation for required fields
///
/// FIXES (Task 19.4-19.5):
/// - Fixed repository selector state management
/// - Improved loading state indicators
/// - Added better error messages for API failures
/// - Added input validation for title length and special characters
/// - Proper error handling with user-friendly messages
/// - Queue operations for offline mode with proper error recovery
///
/// ISSUE #22 FIX:
/// - Auto-populates repo from expanded dashboard item
/// - Shows visual indicator when repo is pre-selected
/// - Clear indication of which repo will receive the issue
///
/// Usage:
/// ```dart
/// final result = await Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => CreateIssueScreen(
///       owner: 'owner',
///       repo: 'repo',
///       expandedRepoFullName: 'owner/repo', // Optional: indicates auto-selection
///     ),
///   ),
/// );
/// ```
class CreateIssueScreen extends StatefulWidget {
  /// Repository owner login.
  final String? owner;

  /// Repository name.
  final String? repo;

  /// Full name of expanded repo from dashboard (for visual indicator)
  /// If provided, shows indicator that repo was auto-selected
  final String? expandedRepoFullName;

  /// Default project name for assignment.
  final String? defaultProject;

  /// Stable Projects V2 node ID used for assignment.
  final String? defaultProjectId;

  /// List of available projects for assignment.
  final List<ProjectV2>? projects;

  /// List of available repositories for selection.
  final List<RepoItem>? availableRepos;

  /// Creates the create issue screen.
  ///
  /// [owner] and [repo] specify the target repository.
  /// [defaultProject] and [projects] are used for project assignment.
  /// [availableRepos] provides a list of repositories to choose from.
  /// [expandedRepoFullName] indicates auto-selected repo from dashboard.
  const CreateIssueScreen({
    super.key,
    this.owner,
    this.repo,
    this.expandedRepoFullName,
    this.defaultProject,
    this.defaultProjectId,
    this.projects,
    this.availableRepos,
  });

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class CreateIssueResult {
  final IssueItem? issue;
  final String? successMessage;

  const CreateIssueResult({this.issue, this.successMessage});
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final PendingOperationsService _pendingOps = PendingOperationsService();
  final NetworkService _networkService = NetworkService();
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  final List<String> _labels = [];
  String? _assignee;
  String? _selectedRepoFullName;
  String? _selectedProject;
  bool _isSaving = false;
  bool _isLoadingLabels = false;
  bool _isLoadingAssignees = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _availableLabels = [];
  List<Map<String, dynamic>> _availableAssignees = [];

  /// Maximum title length (GitHub limit is 256 characters)
  static const int _maxTitleLength = 256;

  /// Maximum body length (GitHub limit is 65536 characters)
  static const int _maxBodyLength = 65536;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    // Use expandedRepoFullName if available (from expanded repo on main screen),
    // otherwise fall back to repo parameter
    _selectedRepoFullName = widget.expandedRepoFullName ?? _defaultRepoFullName;
    final requestedProject = widget.defaultProjectId ?? widget.defaultProject;
    _selectedProject = widget.projects
        ?.where(
          (project) =>
              project.id == requestedProject ||
              project.title == requestedProject,
        )
        .firstOrNull
        ?.id;

    // Load repo data after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedRepoFullName != null) {
        _loadRepoData();
      }
    });
  }

  String? get _defaultRepoFullName {
    final repo = widget.repo;
    if (repo == null || repo.isEmpty) return null;
    if (repo.contains('/')) return repo;

    final owner = widget.owner;
    if (owner == null || owner.isEmpty) return repo;

    return '$owner/$repo';
  }

  /// Load repository labels and assignees with caching support.
  ///
  /// FIX (Task 19.4): Improved error handling and loading states
  /// FIX (Offline): Skip loading when offline to avoid timeout
  Future<void> _loadRepoData() async {
    final repoFullName = _selectedRepoFullName ?? widget.repo;
    if (repoFullName == null) return;

    final parts = repoFullName.split('/');
    if (parts.length != 2) {
      debugPrint('Invalid repository name: $repoFullName');
      return;
    }

    final owner = parts[0];
    final repo = parts[1];

    // FIX (Offline): Check network first, skip loading if offline
    final isOnline = await _networkService.checkConnectivity();
    if (!isOnline) {
      debugPrint('Offline mode - skipping labels/assignees loading');
      setState(() {
        _isLoadingLabels = false;
        _isLoadingAssignees = false;
        _availableLabels = [];
        _availableAssignees = [];
      });
      return;
    }

    debugPrint('Loading repo data for: $owner/$repo');

    setState(() {
      _isLoadingLabels = true;
      _isLoadingAssignees = true;
      _errorMessage = null;
    });

    try {
      // Fetch labels (with caching from github_api_service)
      debugPrint('Fetching labels...');
      final labels = await _githubApi.fetchRepoLabels(owner, repo);
      if (!mounted) return;
      debugPrint('Loaded ${labels.length} labels');
      setState(() {
        _availableLabels = labels;
        _isLoadingLabels = false;
      });

      // Fetch collaborators for assignee (with caching from github_api_service)
      debugPrint('Fetching collaborators...');
      final assignees = await _githubApi.fetchRepoCollaborators(owner, repo);
      if (!mounted) return;
      debugPrint('Loaded ${assignees.length} collaborators');
      setState(() {
        _availableAssignees = assignees;
        _isLoadingAssignees = false;
      });
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      debugPrint('Error loading repo data: $e');
      if (mounted) {
        setState(() {
          _isLoadingLabels = false;
          _isLoadingAssignees = false;
          _availableLabels = [];
          _availableAssignees = [];
          _errorMessage = 'Could not load labels/assignees: ${e.toString()}';
        });
        // Show error message but allow user to continue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load labels/assignees: ${e.toString()}'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _loadRepoData(),
            ),
          ),
        );
      }
    }
  }

  /// Handle repository selection change.
  ///
  /// FIX (Task 19.4): Properly update state and reload data
  void _onRepoChanged(String? newRepoFullName) {
    setState(() {
      _selectedRepoFullName = newRepoFullName;
      // Clear previous data when repo changes
      _availableLabels = [];
      _availableAssignees = [];
      _labels.clear();
      _assignee = null;
    });
    // Reload data for new repository
    _loadRepoData();
  }

  /// Validate title input.
  ///
  /// FIX (Task 19.5): Added comprehensive validation
  String? _validateTitle(String title) {
    if (title.isEmpty) {
      return 'Title is required';
    }
    if (title.trim().isEmpty) {
      return 'Title cannot be only whitespace';
    }
    if (title.length > _maxTitleLength) {
      return 'Title must be less than $_maxTitleLength characters';
    }
    // Check for potentially problematic characters
    if (title.contains('\n')) {
      return 'Title cannot contain line breaks';
    }
    return null;
  }

  /// Validate body input.
  ///
  /// FIX (Task 19.5): Added body validation
  String? _validateBody(String body) {
    if (body.length > _maxBodyLength) {
      return 'Description must be less than $_maxBodyLength characters';
    }
    return null;
  }

  /// Show validation error.
  void _showValidationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error message.
  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Create Issue',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _createIssue,
            child: Text(
              'Create',
              style: TextStyle(
                color: _isSaving ? Colors.white54 : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrailleLoader(size: 32),
                  SizedBox(height: 16),
                  Text(
                    'Creating issue...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message display
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Repository selector (always shown as dropdown)
                  // ISSUE #22: Visual indicator for auto-selected repo
                  if (widget.expandedRepoFullName != null &&
                      widget.expandedRepoFullName == widget.repo) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.folder_open,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Creating in expanded repository',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  widget.expandedRepoFullName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Repository',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedRepoFullName ?? _defaultRepoFullName,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.primary,
                      ),
                      items:
                          widget.availableRepos != null &&
                              widget.availableRepos!.isNotEmpty
                          ? widget.availableRepos!.map((repo) {
                              return DropdownMenuItem(
                                value: repo.fullName,
                                child: Text(
                                  repo.fullName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList()
                          : [
                              DropdownMenuItem(
                                value: _defaultRepoFullName,
                                child: Text(
                                  _defaultRepoFullName ?? 'Select repository',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                      onChanged: (value) {
                        _onRepoChanged(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Title',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Issue title (required)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      errorText: _validateTitle(_titleController.text),
                      counterText:
                          '${_titleController.text.length}/$_maxTitleLength',
                    ),
                    autofocus: true,
                    maxLength: _maxTitleLength,
                    onChanged: (_) {
                      // Trigger validation update
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a description (Markdown supported)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      counterText:
                          '${_bodyController.text.length}/$_maxBodyLength',
                    ),
                    maxLines: 8,
                    maxLength: _maxBodyLength,
                  ),
                  const SizedBox(height: 24),

                  // Labels
                  _buildLabelsSection(),
                  const SizedBox(height: 24),

                  // Assignee
                  _buildAssigneeSection(),
                  if (_hasProjects) ...[
                    const SizedBox(height: 24),
                    _buildProjectSection(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildLabelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Labels',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isLoadingLabels) BrailleLoader(size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _availableLabels.isEmpty
              ? Row(
                  children: [
                    if (_isLoadingLabels)
                      const Expanded(
                        child: Text(
                          'Loading labels...',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          'No labels available',
                          style: const TextStyle(color: Colors.white38),
                        ),
                      ),
                    if (!_isLoadingLabels)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: _loadRepoData,
                        tooltip: 'Refresh labels',
                      ),
                  ],
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._availableLabels.map((label) {
                      final name = label['name'] as String? ?? '';
                      final colorHex = label['color'] as String? ?? 'ffffff';
                      final color = Color(int.parse('FF$colorHex', radix: 16));
                      final isSelected = _labels.contains(name);

                      return FilterChip(
                        label: Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? Colors.black : color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: color,
                        backgroundColor: color.withValues(alpha: 0.2),
                        checkmarkColor: Colors.black,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _labels.add(name);
                            } else {
                              _labels.remove(name);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAssigneeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Assignee',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isLoadingAssignees) BrailleLoader(size: 16),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String?>(
            value: _assignee,
            hint: const Text(
              'Unassigned',
              style: TextStyle(color: Colors.white38),
            ),
            underline: const SizedBox(),
            isExpanded: true,
            dropdownColor: AppColors.card,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(
                  'Unassigned',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ..._availableAssignees.map((user) {
                final login = user['login'] as String? ?? '';
                final avatarUrl = user['avatar_url'] as String?;
                return DropdownMenuItem(
                  value: login,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: user['avatar_url'] == null
                            ? Text(
                                login.isNotEmpty ? login[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(login, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _assignee = value;
              });
            },
          ),
        ),
      ],
    );
  }

  bool get _hasProjects {
    return widget.defaultProjectId != null ||
        widget.defaultProject != null ||
        (widget.projects != null && widget.projects!.isNotEmpty);
  }

  Widget _buildProjectSection() {
    final projects = widget.projects ?? const <ProjectV2>[];
    final selectedProject =
        projects.any((project) => project.id == _selectedProject)
        ? _selectedProject
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String?>(
            value: selectedProject,
            hint: const Text(
              'No project',
              style: TextStyle(color: Colors.white38),
            ),
            underline: const SizedBox(),
            isExpanded: true,
            dropdownColor: AppColors.card,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(
                  'No project',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ...projects
                  .where((project) => !project.closed)
                  .map(
                    (project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(
                        project.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedProject = value;
              });
            },
          ),
        ),
      ],
    );
  }

  /// Create issue with validation and offline support.
  ///
  /// FIX (Task 19.5):
  /// - Added comprehensive input validation
  /// - Better error messages for API failures
  /// - Proper offline queue handling
  /// - State management fixes
  Future<void> _createIssue() async {
    final title = _titleController.text.trim();
    final titleError = _validateTitle(title);
    if (titleError != null) {
      _showValidationError(titleError);
      return;
    }
    final body = _bodyController.text.trim();
    final bodyError = _validateBody(body);
    if (bodyError != null) {
      _showValidationError(bodyError);
      return;
    }

    setState(() => _isSaving = true);
    final repoFullName = _selectedRepoFullName ?? widget.repo;
    final localIssue = await _saveAsLocalIssue(
      title,
      body,
      repoFullName: repoFullName,
    );
    if (localIssue == null || !mounted) return;

    final parts = repoFullName?.split('/') ?? const <String>[];
    if (parts.length == 2 && await SecureStorageService.hasToken()) {
      await _pendingOps.addOperation(
        PendingOperation.createIssue(
          id: 'create_${localIssue.id}',
          owner: parts.first,
          repo: parts.last,
          issueId: localIssue.id,
          data: {
            'title': title,
            'body': body.isEmpty ? null : body,
            'labels': _labels.isEmpty ? null : _labels,
            'assignee': _assignee,
            'projectId': _selectedProject,
          },
        ),
      );
      await _syncService.init();
      if (_syncService.isNetworkAvailable) {
        unawaited(_syncService.replayPendingOperations());
      }
    }

    if (mounted) {
      Navigator.pop(
        context,
        CreateIssueResult(
          issue: localIssue,
          successMessage: parts.length == 2
              ? 'Saved locally. Sync will publish it to GitHub.'
              : 'Saved as a local TODO.',
        ),
      );
    }
  }

  Future<IssueItem?> _saveAsLocalIssue(
    String title,
    String body, {
    String? repoFullName,
  }) async {
    try {
      final localIssue = _localStorage.createStructuredLocalIssue(
        title: title,
        bodyMarkdown: body.isNotEmpty ? body : null,
        labels: _labels,
        assigneeLogin: _assignee,
        repoFullName: repoFullName,
      );

      await _localStorage.saveLocalIssue(localIssue);
      return localIssue;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorMessage('Failed to save local TODO issue: $e');
      }
      return null;
    }
  }
}
