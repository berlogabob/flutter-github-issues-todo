import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/github_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/issues_provider.dart';
import '../services/github_service.dart';
import '../utils/logging.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';

/// Repository Picker Screen - Select or create GitHub repository
///
/// Features:
/// - List user's repositories
/// - Search/filter repositories
/// - Create new repository
/// - Select and save as default
class RepositoryPickerScreen extends StatefulWidget {
  const RepositoryPickerScreen({super.key});

  @override
  State<RepositoryPickerScreen> createState() => _RepositoryPickerScreenState();
}

class _RepositoryPickerScreenState extends State<RepositoryPickerScreen> {
  final GitHubService _githubService = GitHubService();
  final TextEditingController _searchController = TextEditingController();

  List<GitHubRepository> _repositories = [];
  List<GitHubRepository> _filteredRepositories = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // 'all', 'public', 'private'

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
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Not authenticated. Please login first.';
          _isLoading = false;
        });
        return;
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
    final filtered = _repositories.where((repo) {
      // Apply search query
      final matchesSearch =
          query.isEmpty ||
          repo.name.toLowerCase().contains(query.toLowerCase()) ||
          repo.description?.toLowerCase().contains(query.toLowerCase()) ==
              true ||
          repo.ownerLogin.toLowerCase().contains(query.toLowerCase());

      // Apply visibility filter
      final matchesFilter =
          _filter == 'all' ||
          (_filter == 'public' && !repo.private) ||
          (_filter == 'private' && repo.private);

      return matchesSearch && matchesFilter;
    }).toList();

    setState(() {
      _filteredRepositories = filtered;
    });
  }

  void _setFilter(String newFilter) {
    setState(() {
      _filter = newFilter;
    });
    _filterRepositories(_searchController.text);
  }

  Future<void> _selectRepository(GitHubRepository repo) async {
    Logger.i('Selected repository: ${repo.fullName}', context: 'RepoPicker');

    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    issuesProvider.setRepository(repo.ownerLogin, repo.name);

    // Validate repository
    try {
      final isValid = await issuesProvider.validateRepository(repo.ownerLogin, repo.name);

      if (!isValid) {
        if (!mounted) return;
        _showError('Repository validation failed');
        return;
      }

      // Load issues
      await issuesProvider.loadIssues();

      if (!mounted) return;
      _showSuccess('Repository set to ${repo.fullName}');

      // Navigate back
      if (!mounted) return;
      Navigator.pop(context, repo);
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to set repository',
        error: e,
        stackTrace: stackTrace,
        context: 'RepoPicker',
      );
      if (!mounted) return;
      _showError('Failed to set repository: ${e.toString()}');
    }
  }

  Future<void> _createNewRepository() async {
    Logger.d('Opening create repository dialog', context: 'RepoPicker');

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPrivate = false;
    final industrialTheme = context.industrialTheme;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: industrialTheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
            ),
            title: Text(
              'CREATE REPOSITORY',
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IndustrialInput(
                    label: 'REPOSITORY NAME',
                    hintText: 'my-awesome-repo',
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Repository name is required';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
                        return 'Only letters, numbers, dots, hyphens, and underscores allowed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  IndustrialInput(
                    label: 'DESCRIPTION (OPTIONAL)',
                    hintText: 'A brief description of your repository',
                    controller: descriptionController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'VISIBILITY',
                    style: AppTypography.labelMedium.copyWith(
                      color: industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _VisibilityOption(
                          title: 'Public',
                          description: 'Anyone can see',
                          selected: !isPrivate,
                          onTap: () => setDialogState(() => isPrivate = false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _VisibilityOption(
                          title: 'Private',
                          description: 'Only you can see',
                          selected: isPrivate,
                          onTap: () => setDialogState(() => isPrivate = true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IndustrialButton(
                onPressed: () => Navigator.pop(context),
                label: 'CANCEL',
                variant: IndustrialButtonVariant.text,
                size: IndustrialButtonSize.small,
              ),
              IndustrialButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    _showError('Repository name is required');
                    return;
                  }

                  try {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final token = authProvider.token;

                    if (token == null) {
                      throw Exception('Not authenticated');
                    }

                    // Close dialog
                    Navigator.pop(context);

                    // Show loading
                    setState(() => _isLoading = true);

                    final repo = await _githubService.createRepository(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      isPrivate: isPrivate,
                      hasIssues: true,
                    );

                    setState(() => _isLoading = false);

                    // Add to list and select
                    setState(() {
                      _repositories.insert(0, repo);
                      _filterRepositories(_searchController.text);
                    });

                    _showSuccess('Repository created successfully');
                    _selectRepository(repo);
                  } catch (e, stackTrace) {
                    Logger.e(
                      'Failed to create repository',
                      error: e,
                      stackTrace: stackTrace,
                      context: 'RepoPicker',
                    );
                    setState(() => _isLoading = false);
                    _showError('Failed to create: ${e.toString()}');
                  }
                },
                label: 'CREATE',
                variant: IndustrialButtonVariant.primary,
                size: IndustrialButtonSize.small,
              ),
            ],
          );
        },
      ),
    );
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
          'SELECT REPOSITORY',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_outlined),
            tooltip: 'Create new repository',
            color: industrialTheme.accentPrimary,
            onPressed: _isLoading ? null : _createNewRepository,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                IndustrialInput(
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onTap: () => _setFilter('all'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: 'Public',
                      selected: _filter == 'public',
                      onTap: () => _setFilter('public'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: 'Private',
                      selected: _filter == 'private',
                      onTap: () => _setFilter('private'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent(industrialTheme)),
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
      final hasQuery = _searchController.text.isNotEmpty;
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
                  : 'Create a new repository to get started',
              style: AppTypography.bodySmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: AppSpacing.xl),
              IndustrialButton(
                onPressed: _createNewRepository,
                label: 'CREATE REPOSITORY',
                variant: IndustrialButtonVariant.primary,
                size: IndustrialButtonSize.medium,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _filteredRepositories.length,
      itemBuilder: (context, index) {
        final repo = _filteredRepositories[index];
        return _RepositoryTile(
          repository: repo,
          onTap: () => _selectRepository(repo),
        );
      },
    );
  }
}

/// Repository tile widget
class _RepositoryTile extends StatelessWidget {
  final GitHubRepository repository;
  final VoidCallback onTap;

  const _RepositoryTile({required this.repository, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: IndustrialCard(
        type: IndustrialCardType.interactive,
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  repository.private
                      ? Icons.lock_outline
                      : Icons.public_outlined,
                  size: 16,
                  color: repository.private
                      ? industrialTheme.statusWarning
                      : industrialTheme.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    repository.fullName,
                    style: AppTypography.labelMedium.copyWith(
                      color: industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (repository.archived) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: industrialTheme.textTertiary.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      'ARCHIVED',
                      style: AppTypography.captionSmall.copyWith(
                        color: industrialTheme.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
            if (repository.description != null &&
                repository.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                repository.description!,
                style: AppTypography.captionSmall.copyWith(
                  color: industrialTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (repository.language != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getLanguageColor(repository.language!),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    repository.language!,
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (repository.openIssuesCount != null) ...[
                  Icon(
                    Icons.bug_report_outlined,
                    size: 14,
                    color: industrialTheme.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${repository.openIssuesCount}',
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (repository.stargazersCount != null) ...[
                  Icon(
                    Icons.star_outline,
                    size: 14,
                    color: industrialTheme.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${repository.stargazersCount}',
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getLanguageColor(String language) {
    // Common GitHub language colors
    final colors = {
      'Dart': const Color(0xFF00B4AB),
      'Flutter': const Color(0xFF42A5F5),
      'JavaScript': const Color(0xFFF1E05A),
      'TypeScript': const Color(0xFF3178C6),
      'Python': const Color(0xFF3572A5),
      'Java': const Color(0xFFB07219),
      'Ruby': const Color(0xFF701516),
      'Go': const Color(0xFF00ADD8),
      'Rust': const Color(0xFFDEA584),
      'Swift': const Color(0xFFFFAC45),
      'Kotlin': const Color(0xFFA97BFF),
      'C#': const Color(0xFF178600),
      'C++': const Color(0xFFF34B7D),
      'C': const Color(0xFF555555),
      'PHP': const Color(0xFF4F5D95),
      'HTML': const Color(0xFFE34C26),
      'CSS': const Color(0xFF563D7C),
      'Shell': const Color(0xFF89E051),
      'Markdown': const Color(0xFF083FA1),
    };

    return colors[language] ?? const Color(0xFF888888);
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.captionSmall.copyWith(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Visibility option widget
class _VisibilityOption extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected
                      ? industrialTheme.accentPrimary
                      : industrialTheme.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: selected
                        ? industrialTheme.accentPrimary
                        : industrialTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description,
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
