import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/github_api_service.dart';
import '../models/repo_item.dart';
import '../widgets/braille_loader.dart';

/// Screen for creating new GitHub issues.
///
/// Supports:
/// - Title and body input with Markdown support
/// - Label selection from available repository labels
/// - Assignee selection from repository collaborators
/// - Repository selection from user's repositories
/// - Real-time loading of labels and assignees
///
/// Usage:
/// ```dart
/// final result = await Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => CreateIssueScreen(
///       owner: 'owner',
///       repo: 'repo',
///     ),
///   ),
/// );
/// ```
class CreateIssueScreen extends StatefulWidget {
  /// Repository owner login.
  final String? owner;

  /// Repository name.
  final String? repo;

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
  const CreateIssueScreen({
    super.key,
    this.owner,
    this.repo,
    this.defaultProject,
    this.projects,
    this.availableRepos,
  });

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final GitHubApiService _githubApi = GitHubApiService();

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  List<String> _labels = [];
  String? _assignee;
  String? _selectedRepoFullName;
  bool _isSaving = false;
  bool _isLoadingLabels = false;
  bool _isLoadingAssignees = false;

  List<Map<String, dynamic>> _availableLabels = [];
  List<Map<String, dynamic>> _availableAssignees = [];

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

  Future<void> _loadRepoData() async {
    final repoFullName = _selectedRepoFullName ?? widget.repo;
    if (repoFullName == null) return;

    final parts = repoFullName.split('/');
    if (parts.length != 2) return;

    final owner = parts[0];
    final repo = parts[1];

    debugPrint('Loading repo data for: $owner/$repo');

    setState(() {
      _isLoadingLabels = true;
      _isLoadingAssignees = true;
    });

    try {
      // Fetch labels
      debugPrint('Fetching labels...');
      final labels = await _githubApi.fetchRepoLabels(owner, repo);
      debugPrint('Loaded ${labels.length} labels');
      setState(() {
        _availableLabels = labels;
        _isLoadingLabels = false;
      });

      // Fetch collaborators for assignee
      debugPrint('Fetching collaborators...');
      final assignees = await _githubApi.fetchRepoCollaborators(owner, repo);
      debugPrint('Loaded ${assignees.length} collaborators');
      setState(() {
        _availableAssignees = assignees;
        _isLoadingAssignees = false;
      });
    } catch (e) {
      debugPrint('Error loading repo data: $e');
      if (mounted) {
        setState(() {
          _isLoadingLabels = false;
          _isLoadingAssignees = false;
          _availableLabels = [];
          _availableAssignees = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load labels/assignees: ${e.toString()}'),
            backgroundColor: AppColors.orangePrimary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onRepoChanged(String? newRepoFullName) {
    setState(() {
      _selectedRepoFullName = newRepoFullName;
    });
    _loadRepoData();
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
                color: _isSaving ? Colors.white54 : AppColors.orangePrimary,
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
                  // Repository selector (always shown as dropdown)
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
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.orangePrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedRepoFullName ?? widget.repo,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBackground,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.orangePrimary,
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
                      hintText: 'Issue title',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.orangePrimary,
                        ),
                      ),
                    ),
                    autofocus: true,
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
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.orangePrimary,
                        ),
                      ),
                    ),
                    maxLines: 8,
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
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _availableLabels.isEmpty
              ? Text(
                  _isLoadingLabels
                      ? 'Loading labels...'
                      : 'No labels available',
                  style: const TextStyle(color: Colors.white38),
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
            color: AppColors.cardBackground,
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
            dropdownColor: AppColors.cardBackground,
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
                return DropdownMenuItem(
                  value: login,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.orangePrimary,
                        backgroundImage: user['avatar_url'] != null
                            ? NetworkImage(user['avatar_url'] as String)
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

  Future<void> _createIssue() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title is required'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final repoFullName = _selectedRepoFullName ?? widget.repo;
    if (repoFullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No repository selected'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final parts = repoFullName.split('/');
    if (parts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid repository name'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final owner = parts[0];
    final repo = parts[1];

    setState(() => _isSaving = true);

    try {
      final body = _bodyController.text.trim();

      final createdIssue = await _githubApi.createIssue(
        owner,
        repo,
        title: title,
        body: body.isNotEmpty ? body : null,
        labels: _labels.isNotEmpty ? _labels : null,
        assignee: _assignee,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue #${createdIssue.number} created successfully'),
            backgroundColor: AppColors.orangePrimary,
          ),
        );
        Navigator.pop(context, createdIssue);
      }
    } catch (e) {
      debugPrint('Error creating issue: $e');
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create issue: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}
