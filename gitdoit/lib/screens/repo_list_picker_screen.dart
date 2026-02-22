import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/issues_provider.dart';
import '../services/github_service.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';

/// Repository List Picker Screen - Select from user's GitHub repositories
///
/// Features:
/// - List user's repositories from GitHub
/// - Three checkmark states:
///   - Unchecked: `Icons.circle_outlined` (empty circle)
///   - Newly selected: `Icons.check_circle` (check in circle)
///   - Previously selected: `Icons.check_circle` with bold/thicker style
/// - Bottom: "Cancel" and "Add" buttons
class RepoListPickerScreen extends StatefulWidget {
  const RepoListPickerScreen({super.key});

  @override
  State<RepoListPickerScreen> createState() => _RepoListPickerScreenState();
}

class _RepoListPickerScreenState extends State<RepoListPickerScreen> {
  final GitHubService _githubService = GitHubService();
  final Set<String> _selectedRepos = {};
  final Set<String> _previouslySelectedRepos = {};
  final TextEditingController _searchController = TextEditingController();

  List<GitHubRepository> _repositories = [];
  List<GitHubRepository> _filteredRepositories = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRepositories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _githubService.dispose();
    super.dispose();
  }

  Future<void> _loadRepositories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final issuesProvider = Provider.of<IssuesProvider>(
        context,
        listen: false,
      );
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Not authenticated. Please login first.';
          _isLoading = false;
        });
        return;
      }

      // Load previously selected repositories from IssuesProvider
      final configuredRepos = issuesProvider.repositories;
      for (final repo in configuredRepos) {
        _previouslySelectedRepos.add(repo.fullName);
      }

      final repos = await _githubService.getUserRepositories(token: token);

      setState(() {
        _repositories = repos;
        _filteredRepositories = repos;
        _isLoading = false;
      });

      Logger.i('Loaded ${repos.length} repositories', context: 'RepoPicker');
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to load repositories',
        error: e,
        stackTrace: stackTrace,
        context: 'RepoPicker',
      );
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _filterRepositories(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRepositories = _repositories;
      } else {
        _filteredRepositories = _repositories.where((repo) {
          final name = repo.name.toLowerCase().contains(query.toLowerCase());
          final desc =
              repo.description?.toLowerCase().contains(query.toLowerCase()) ==
              true;
          final owner = repo.ownerLogin.toLowerCase().contains(
            query.toLowerCase(),
          );
          return name || desc || owner;
        }).toList();
      }
    });
  }

  void _toggleSelection(String repoFullName) {
    setState(() {
      if (_selectedRepos.contains(repoFullName)) {
        _selectedRepos.remove(repoFullName);
      } else {
        _selectedRepos.add(repoFullName);
      }
    });
  }

  Future<void> _addSelectedRepos() async {
    if (_selectedRepos.isEmpty) {
      _showError('Please select at least one repository');
      return;
    }

    Logger.i(
      'Adding ${_selectedRepos.length} repositories',
      context: 'RepoPicker',
    );

    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);

    // Add all selected repos to the multi-repo config
    // Do NOT automatically set any as default - user must explicitly choose in Settings
    for (final fullName in _selectedRepos) {
      final parts = fullName.split('/');
      if (parts.length == 2) {
        issuesProvider.addRepository(parts[0], parts[1]);
      }
    }

    // Save the multi-repo config
    await issuesProvider.saveMultiRepositoryConfig();

    // Load issues for all repos
    await issuesProvider.loadIssues();

    if (!mounted) return;
    _showSuccess('Added ${_selectedRepos.length} repositories');
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.industrialTheme.statusError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.industrialTheme.statusSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: Text(
          'SELECT REPOSITORIES',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_outlined),
          color: industrialTheme.textSecondary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: IndustrialInput(
              label: 'SEARCH',
              hintText: 'Search repositories...',
              controller: _searchController,
              prefixIcon: Icon(
                Icons.search_outlined,
                size: 20,
                color: industrialTheme.textSecondary,
              ),
              onChanged: _filterRepositories,
            ),
          ),

          // Content
          Expanded(child: _buildContent(industrialTheme)),

          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: industrialTheme.surfaceElevated,
              border: Border(
                top: BorderSide(color: industrialTheme.borderPrimary, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Cancel button
                Expanded(
                  child: IndustrialButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'CANCEL',
                    variant: IndustrialButtonVariant.text,
                    size: IndustrialButtonSize.medium,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Add button
                Expanded(
                  child: IndustrialButton(
                    onPressed: _selectedRepos.isEmpty
                        ? null
                        : _addSelectedRepos,
                    label: 'ADD (${_selectedRepos.length})',
                    variant: IndustrialButtonVariant.primary,
                    size: IndustrialButtonSize.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(IndustrialThemeData industrialTheme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: industrialTheme.accentPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'LOADING REPOSITORIES',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: industrialTheme.statusError,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'ERROR',
              style: AppTypography.labelMedium.copyWith(
                color: industrialTheme.statusError,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(
                  color: industrialTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            IndustrialButton(
              onPressed: _loadRepositories,
              label: 'RETRY',
              variant: IndustrialButtonVariant.primary,
              size: IndustrialButtonSize.medium,
            ),
          ],
        ),
      );
    }

    if (_filteredRepositories.isEmpty) {
      final hasQuery = _searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off_outlined : Icons.folder_open_outlined,
              size: 48,
              color: industrialTheme.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasQuery ? 'NO MATCHING REPOSITORIES' : 'NO REPOSITORIES',
              style: AppTypography.labelMedium.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasQuery
                  ? 'Try a different search term'
                  : 'Create a repository on GitHub first',
              style: AppTypography.bodySmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _filteredRepositories.length,
      itemBuilder: (context, index) {
        final repo = _filteredRepositories[index];
        final isPreviouslySelected = _previouslySelectedRepos.contains(
          repo.fullName,
        );
        return _RepositoryTile(
          repository: repo,
          isSelected: _selectedRepos.contains(repo.fullName),
          isPreviouslySelected: isPreviouslySelected,
          onToggle: () => _toggleSelection(repo.fullName),
        );
      },
    );
  }
}

/// Repository tile widget with three-state checkmark indicator
///
/// Icon states:
/// - Unchecked: `Icons.circle_outlined` (empty circle)
/// - Newly selected: `Icons.check_circle` (check in circle)
/// - Previously selected: `Icons.check_circle` with bold/thicker style
class _RepositoryTile extends StatelessWidget {
  final GitHubRepository repository;
  final bool isSelected;
  final bool isPreviouslySelected;
  final VoidCallback onToggle;

  const _RepositoryTile({
    required this.repository,
    required this.isSelected,
    required this.isPreviouslySelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: IndustrialCard(
        type: IndustrialCardType.interactive,
        onTap: onToggle,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Three-state checkmark icon
            _buildCheckmarkIcon(industrialTheme),
            const SizedBox(width: AppSpacing.md),

            // Repository info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repository.fullName,
                    style: AppTypography.labelMedium.copyWith(
                      color: industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (repository.description != null &&
                      repository.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      repository.description!,
                      style: AppTypography.captionSmall.copyWith(
                        color: industrialTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Visibility icon
            Icon(
              repository.private ? Icons.lock_outline : Icons.public_outlined,
              size: 18,
              color: repository.private
                  ? industrialTheme.statusWarning
                  : industrialTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckmarkIcon(IndustrialThemeData industrialTheme) {
    if (isPreviouslySelected) {
      // Previously selected: check circle (bold) - ✓
      return Icon(
        Icons.check_circle,
        size: 24,
        color: industrialTheme.statusSuccess,
      );
    } else if (isSelected) {
      // Newly tapped: filled circle - ●
      return Icon(
        Icons.fiber_manual_record,
        size: 24,
        color: industrialTheme.statusSuccess,
      );
    } else {
      // Unchecked: empty circle - ○
      return Icon(
        Icons.circle_outlined,
        size: 24,
        color: industrialTheme.textTertiary,
      );
    }
  }
}
