import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../services/github_api_service.dart';
import '../services/pending_operations_service.dart';
import '../services/network_service.dart';
import '../models/repo_item.dart';
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

  /// List of available projects for assignment.
  final List<Map<String, dynamic>>? projects;

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
    this.projects,
    this.availableRepos,
  });

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final PendingOperationsService _pendingOps = PendingOperationsService();
  final NetworkService _networkService = NetworkService();

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  final List<String> _labels = [];
  String? _assignee;
  String? _selectedRepoFullName;
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
    _selectedRepoFullName = widget.repo;

    // Load repo data after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedRepoFullName != null) {
        _loadRepoData();
      }
    });
  }

  /// Load repository labels and assignees with caching support.
  ///
  /// FIX (Task 19.4): Improved error handling and loading states
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

  /// Show success message.
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error message.
  void _showErrorMessage(String message) {
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
                            color: AppColors.primary.withValues(
                              alpha: 0.7,
                            ),
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
                      value: _selectedRepoFullName ?? widget.repo,
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
                                value: widget.repo,
                                child: Text(
                                  '${widget.owner}/${widget.repo}',
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
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                        ),
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
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                        ),
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

  /// Create issue with validation and offline support.
  ///
  /// FIX (Task 19.5):
  /// - Added comprehensive input validation
  /// - Better error messages for API failures
  /// - Proper offline queue handling
  /// - State management fixes
  Future<void> _createIssue() async {
    // Validate title
    final title = _titleController.text.trim();
    final titleError = _validateTitle(title);
    if (titleError != null) {
      _showValidationError(titleError);
      return;
    }

    // Validate body
    final body = _bodyController.text.trim();
    final bodyError = _validateBody(body);
    if (bodyError != null) {
      _showValidationError(bodyError);
      return;
    }

    final repoFullName = _selectedRepoFullName ?? widget.repo;
    if (repoFullName == null) {
      _showValidationError('No repository selected');
      return;
    }

    final parts = repoFullName.split('/');
    if (parts.length != 2) {
      _showValidationError('Invalid repository name');
      return;
    }

    final owner = parts[0];
    final repo = parts[1];

    setState(() => _isSaving = true);

    // CHECK NETWORK
    final isOnline = await _networkService.checkConnectivity();

    if (!isOnline) {
      // OFFLINE: Queue operation
      try {
        final operationId = 'create_${DateTime.now().millisecondsSinceEpoch}';
        final operation = PendingOperation.createIssue(
          id: operationId,
          owner: owner,
          repo: repo,
          data: {
            'title': title,
            'body': body.isNotEmpty ? body : null,
            'labels': _labels.isNotEmpty ? _labels : null,
            'assignee': _assignee,
          },
        );

        await _pendingOps.addOperation(operation);

        if (mounted) {
          _showSuccessMessage('Issue queued for sync when online');
          Navigator.pop(context);
        }
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isSaving = false);
        _showErrorMessage('Failed to queue issue: ${e.toString()}');
      }
    } else {
      // ONLINE: Create immediately
      try {
        final createdIssue = await _githubApi.createIssue(
          owner,
          repo,
          title: title,
          body: body.isNotEmpty ? body : null,
          labels: _labels.isNotEmpty ? _labels : null,
          assignee: _assignee,
        );

        if (mounted) {
          _showSuccessMessage(
            'Issue #${createdIssue.number} created successfully',
          );
          Navigator.pop(context, createdIssue);
        }
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isSaving = false);

        // Provide specific error messages based on error type
        final errorMessage = e.toString();
        if (errorMessage.contains('422')) {
          _showErrorMessage(
            'Invalid issue data. Please check your input and try again.',
          );
        } else if (errorMessage.contains('401') ||
            errorMessage.contains('unauthorized')) {
          _showErrorMessage('Authentication failed. Please login again.');
        } else if (errorMessage.contains('403') ||
            errorMessage.contains('forbidden')) {
          _showErrorMessage(
            'You do not have permission to create issues in this repository.',
          );
        } else if (errorMessage.contains('Network') ||
            errorMessage.contains('SocketException')) {
          // Network error during online attempt - queue for later
          _showErrorMessage(
            'Network error. Issue saved locally and will be synced when online.',
          );
          // Optionally queue the operation
          await _queueIssueForLater(owner, repo, title, body);
        } else {
          _showErrorMessage('Failed to create issue: ${e.toString()}');
        }
      }
    }
  }

  /// Queue issue for later sync when network fails during online attempt.
  Future<void> _queueIssueForLater(
    String owner,
    String repo,
    String title,
    String body,
  ) async {
    try {
      final operationId = 'create_${DateTime.now().millisecondsSinceEpoch}';
      final operation = PendingOperation.createIssue(
        id: operationId,
        owner: owner,
        repo: repo,
        data: {
          'title': title,
          'body': body.isNotEmpty ? body : null,
          'labels': _labels.isNotEmpty ? _labels : null,
          'assignee': _assignee,
        },
      );

      await _pendingOps.addOperation(operation);
      debugPrint('Issue queued for later sync: $operationId');
    } catch (e) {
      debugPrint('Failed to queue issue: $e');
    }
  }
}
