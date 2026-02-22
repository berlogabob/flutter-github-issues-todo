import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';
import '../widgets/cloud_sync_icon.dart';
import '../widgets/repo_header_widget.dart';
import '../widgets/repository_issues_widget.dart';
import 'settings_screen.dart';
import 'repo_add_menu.dart';

/// Home Screen - Main dashboard after authentication
///
/// REDESIGNED: Industrial Minimalism with modular card grid
/// Z-axis interactions, spring physics animations
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial connectivity refresh for instant cloud icon state
    _refreshConnectivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh connectivity when app resumes (instant cloud icon update)
    if (state == AppLifecycleState.resumed) {
      Logger.d('App resumed - refreshing connectivity', context: 'Home');
      _refreshConnectivity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  /// Refresh connectivity state for instant cloud icon update
  void _refreshConnectivity() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    await issuesProvider.refreshConnectivity();
  }

  /// Determine sync state for cloud icon
  SyncState _getSyncState(IssuesProvider issuesProvider) {
    if (issuesProvider.isSyncing) {
      return SyncState.syncing;
    }
    if (issuesProvider.syncError) {
      return SyncState.error;
    }
    if (issuesProvider.isOffline) {
      return SyncState.offline;
    }
    return SyncState.synced;
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,

      // Custom Industrial Header
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: _showSearch
            ? IndustrialInput(
                hintText: 'Search issues...',
                controller: _searchController,
                onChanged: (query) {
                  setState(() => _searchQuery = query);
                },
                autofocus: true,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GitDoIt',
                          style: AppTypography.headlineMedium.copyWith(
                            color: industrialTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Issues Dashboard',
                          style: AppTypography.monoAnnotation.copyWith(
                            color: industrialTheme.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Cloud sync icon
                  Consumer<IssuesProvider>(
                    builder: (context, issuesProvider, _) {
                      final syncState = _getSyncState(issuesProvider);
                      return CloudSyncIcon(state: syncState);
                    },
                  ),
                  // Add repository button
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: industrialTheme.accentPrimary,
                    ),
                    onPressed: () async {
                      Logger.d('Add repository pressed', context: 'Home');
                      // Get button position for menu
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        await RepoAddMenu.show(
                          context: context,
                          position: RelativeRect.fromRect(
                            Rect.fromPoints(
                              box.localToGlobal(Offset.zero),
                              box.localToGlobal(Offset.zero),
                            ),
                            Offset.zero & box.size,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
        actions: [
          // Search button
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_outlined : Icons.search_outlined,
              color: industrialTheme.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          // Refresh button
          IconButton(
            icon: Icon(
              Icons.refresh_outlined,
              color: industrialTheme.textPrimary,
            ),
            onPressed: () async {
              Logger.d('Refresh pressed', context: 'Home');
              final issuesProvider = Provider.of<IssuesProvider>(
                context,
                listen: false,
              );
              // Refresh connectivity first for instant cloud icon update
              await issuesProvider.refreshConnectivity();
              // Then refresh issues
              await issuesProvider.refreshIssues();
            },
          ),
          // Settings button
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: industrialTheme.textPrimary,
            ),
            onPressed: () {
              Logger.d('Settings pressed', context: 'Home');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),

      body: _HomeContent(searchQuery: _searchQuery),

      // Custom FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateIssueDialog(context),
        backgroundColor: industrialTheme.accentPrimary,
        foregroundColor: AppColors.textOnAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        icon: const Icon(Icons.add_outlined),
        label: Text(
          'NEW ISSUE',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textOnAccent,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showCreateIssueDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final industrialTheme = context.industrialTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'Create Issue',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IndustrialInput(
                label: 'TITLE',
                hintText: 'Enter issue title',
                controller: titleController,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              IndustrialInput(
                label: 'DESCRIPTION',
                hintText: 'Enter issue description (optional)',
                controller: bodyController,
                inputType: IndustrialInputType.multiline,
                maxLines: 5,
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
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required')),
                );
                return;
              }

              Logger.i('Creating issue: "$title"', context: 'Home');

              final issuesProvider = Provider.of<IssuesProvider>(
                context,
                listen: false,
              );
              final issue = await issuesProvider.createIssue(
                title: title,
                body: bodyController.text.trim(),
              );

              if (!context.mounted) return;
              Navigator.pop(context);

              if (issue != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created issue #${issue.number}'),
                    backgroundColor: industrialTheme.statusSuccess,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to create issue')),
                );
              }
            },
            label: 'CREATE',
            variant: IndustrialButtonVariant.primary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String searchQuery;

  const _HomeContent({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final issuesProvider = Provider.of<IssuesProvider>(context);
    final industrialTheme = context.industrialTheme;

    return RefreshIndicator(
      onRefresh: () => issuesProvider.refreshIssues(),
      color: industrialTheme.accentPrimary,
      backgroundColor: industrialTheme.surfaceElevated,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Filter bar - Industrial style
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: _buildFilterBar(context, issuesProvider, industrialTheme),
            ),

            // Repository headers: default repo on top, selected repos below
            _buildAllRepoHeaders(context, issuesProvider, industrialTheme),
          ],
        ),
      ),
    );
  }

  /// Build all repository headers (default + selected repos)
  Widget _buildAllRepoHeaders(
    BuildContext context,
    IssuesProvider issuesProvider,
    IndustrialThemeData industrialTheme,
  ) {
    final allRepos = issuesProvider.repositories;

    // If no repositories configured, show placeholder
    if (allRepos.isEmpty) {
      return const RepoHeaderPlaceholder();
    }

    // Show ALL repositories uniformly (all collapsible with arrow)
    return Column(
      children: allRepos.map((repo) {
        return RepositoryIssuesWidget(repoFullName: repo.fullName);
      }).toList(),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    IssuesProvider issuesProvider,
    IndustrialThemeData industrialTheme,
  ) {
    return Row(
      children: [
        // Filter label
        Text(
          'FILTER:',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Filter chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'OPEN',
                  selected: issuesProvider.filter == 'open',
                  onTap: () {
                    issuesProvider.setFilter('open');
                    // Reload issues for ALL repos
                    for (final repo in issuesProvider.repositories) {
                      issuesProvider.loadIssues(repoFullName: repo.fullName, state: 'open');
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'CLOSED',
                  selected: issuesProvider.filter == 'closed',
                  onTap: () {
                    issuesProvider.setFilter('closed');
                    // Reload issues for ALL repos
                    for (final repo in issuesProvider.repositories) {
                      issuesProvider.loadIssues(repoFullName: repo.fullName, state: 'closed');
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'ALL',
                  selected: issuesProvider.filter == 'all',
                  onTap: () {
                    issuesProvider.setFilter('all');
                    // Reload issues for ALL repos
                    for (final repo in issuesProvider.repositories) {
                      issuesProvider.loadIssues(repoFullName: repo.fullName, state: 'all');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Industrial Filter Chip
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
      child: AnimatedContainer(
        duration: AppAnimations.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoData.copyWith(
            fontSize: 12,
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
