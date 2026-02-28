import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/github_api_service.dart';
import '../models/repo_item.dart';
import '../widgets/braille_loader.dart';

class CreateIssueScreen extends StatefulWidget {
  final String? owner;
  final String? repo;
  final String? defaultProject;
  final List<Map<String, dynamic>>? projects;
  final List<RepoItem>? availableRepos;

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
    _loadRepoData();
  }

  Future<void> _loadRepoData() async {
    final repoFullName = _selectedRepoFullName ?? widget.repo;
    if (repoFullName == null) return;

    final parts = repoFullName.split('/');
    if (parts.length != 2) return;

    final owner = parts[0];
    final repo = parts[1];

    setState(() {
      _isLoadingLabels = true;
      _isLoadingAssignees = true;
    });

    try {
      // Fetch labels
      final labels = await _githubApi.fetchRepoLabels(owner, repo);
      setState(() {
        _availableLabels = labels;
        _isLoadingLabels = false;
      });

      // Fetch collaborators for assignee
      final assignees = await _githubApi.fetchRepoCollaborators(owner, repo);
      setState(() {
        _availableAssignees = assignees;
        _isLoadingAssignees = false;
      });
    } catch (e) {
      debugPrint('Error loading repo data: $e');
      setState(() {
        _isLoadingLabels = false;
        _isLoadingAssignees = false;
      });
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
                color: _isSaving ? Colors.white54 : AppColors.orange,
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
                  // Repository info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder,
                          color: AppColors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedRepoFullName ??
                              '${widget.owner}/${widget.repo}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Repository dropdown (if available repos provided)
                  if (widget.availableRepos != null &&
                      widget.availableRepos!.length > 1) ...[
                    const SizedBox(height: 24),
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
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRepoFullName ?? widget.repo,
                        isExpanded: true,
                        dropdownColor: AppColors.cardBackground,
                        underline: const SizedBox(),
                        items: widget.availableRepos!.map((repo) {
                          return DropdownMenuItem(
                            value: repo.fullName,
                            child: Text(
                              repo.fullName,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          _onRepoChanged(value);
                        },
                      ),
                    ),
                  ],
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
                        borderSide: const BorderSide(color: AppColors.orange),
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
                        borderSide: const BorderSide(color: AppColors.orange),
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
                        backgroundColor: AppColors.orange,
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
            backgroundColor: AppColors.orange,
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
