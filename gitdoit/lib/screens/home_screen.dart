import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';
import 'settings_screen.dart';
import 'issue_detail_screen.dart';
import '../widgets/issue_card.dart';
import '../widgets/offline_indicator.dart';

/// Home Screen - Main dashboard after authentication
///
/// REDESIGNED: Industrial Minimalism with modular card grid
/// Z-axis interactions, spring physics animations
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GitDoIt',
                    style: AppTypography.headlineMedium.copyWith(
                      color: industrialTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Issues Dashboard',
                    style: AppTypography.monoAnnotation.copyWith(
                      color: industrialTheme.textTertiary,
                    ),
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
            onPressed: () {
              Logger.d('Refresh pressed', context: 'Home');
              Provider.of<IssuesProvider>(
                context,
                listen: false,
              ).refreshIssues();
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

    return Column(
      children: [
        // Offline indicator
        const OfflineIndicator(),

        // Filter bar - Industrial style
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: _buildFilterBar(context, issuesProvider, industrialTheme),
        ),

        // Issue list or empty state
        Expanded(
          child: issuesProvider.isLoading && issuesProvider.issues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            industrialTheme.accentPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Loading issues...',
                        style: AppTypography.monoAnnotation.copyWith(
                          color: industrialTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              : issuesProvider.error != null
              ? _buildErrorState(context, issuesProvider, industrialTheme)
              : _buildIssueList(context, issuesProvider, industrialTheme),
        ),
      ],
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
                    issuesProvider.loadIssues(state: 'open');
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'CLOSED',
                  selected: issuesProvider.filter == 'closed',
                  onTap: () {
                    issuesProvider.setFilter('closed');
                    issuesProvider.loadIssues(state: 'closed');
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'ALL',
                  selected: issuesProvider.filter == 'all',
                  onTap: () {
                    issuesProvider.setFilter('all');
                    issuesProvider.loadIssues(state: 'all');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssueList(
    BuildContext context,
    IssuesProvider issuesProvider,
    IndustrialThemeData industrialTheme,
  ) {
    final issues = issuesProvider.searchIssues(searchQuery);

    return RefreshIndicator(
      onRefresh: () => issuesProvider.refreshIssues(),
      color: industrialTheme.accentPrimary,
      backgroundColor: industrialTheme.surfaceElevated,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: IssueCard(
              issue: issue,
              onTap: () => _navigateToDetail(context, issue),
              onToggleStatus: () {
                if (issue.isOpen) {
                  issuesProvider.closeIssue(issue.number);
                } else {
                  issuesProvider.reopenIssue(issue.number);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, dynamic issue) {
    Logger.d('Navigating to issue #${issue.number}', context: 'Home');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    IssuesProvider issuesProvider,
    IndustrialThemeData industrialTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: industrialTheme.statusError,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Failed to load issues',
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              issuesProvider.error ?? 'Unknown error',
              style: AppTypography.bodyMedium.copyWith(
                color: industrialTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            IndustrialButton(
              onPressed: () => issuesProvider.loadIssues(),
              label: 'TRY AGAIN',
              variant: IndustrialButtonVariant.secondary,
              icon: const Icon(Icons.refresh_outlined, size: 18),
            ),
          ],
        ),
      ),
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
