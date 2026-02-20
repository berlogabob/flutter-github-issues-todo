import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import 'settings_screen.dart';
import '../widgets/issue_card.dart';

/// Home Screen - Main dashboard after authentication
///
/// Shows list of GitHub issues as TODO items
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.username ?? 'User';

    Logger.d('Building HomeScreen for user: $username', context: 'Home');

    return Scaffold(
      appBar: AppBar(
        title: const Text('GitDoIt'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              Logger.d('Settings pressed', context: 'Home');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: const _HomeContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Logger.d('Create issue pressed', context: 'Home');
          _showCreateIssueDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateIssueDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Issue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter issue title',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter issue description',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                  SnackBar(content: Text('Created issue #${issue.number}')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to create issue')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final issuesProvider = Provider.of<IssuesProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${context.watch<AuthProvider>().username ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your GitHub Issues as TODOs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              // Filter chips
              _buildFilterBar(context, issuesProvider),
            ],
          ),
        ),

        // Issue list or empty state
        Expanded(
          child: issuesProvider.isLoading && issuesProvider.issues.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : issuesProvider.error != null
              ? _buildErrorState(context, issuesProvider)
              : issuesProvider.issues.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => issuesProvider.refreshIssues(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: issuesProvider.filteredIssues.length,
                    itemBuilder: (context, index) {
                      final issue = issuesProvider.filteredIssues[index];
                      return IssueCard(
                        issue: issue,
                        onTap: () => Logger.d(
                          'Issue tapped: #${issue.number}',
                          context: 'Home',
                        ),
                        onToggleStatus: () {
                          if (issue.isOpen) {
                            issuesProvider.closeIssue(issue.number);
                          } else {
                            issuesProvider.reopenIssue(issue.number);
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, IssuesProvider issuesProvider) {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Open'),
          selected: issuesProvider.filter == 'open',
          onSelected: (selected) {
            if (selected) {
              issuesProvider.setFilter('open');
              issuesProvider.loadIssues(state: 'open');
            }
          },
        ),
        FilterChip(
          label: const Text('Closed'),
          selected: issuesProvider.filter == 'closed',
          onSelected: (selected) {
            if (selected) {
              issuesProvider.setFilter('closed');
              issuesProvider.loadIssues(state: 'closed');
            }
          },
        ),
        FilterChip(
          label: const Text('All'),
          selected: issuesProvider.filter == 'all',
          onSelected: (selected) {
            if (selected) {
              issuesProvider.setFilter('all');
              issuesProvider.loadIssues(state: 'all');
            }
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, IssuesProvider issuesProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load issues',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              issuesProvider.error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => issuesProvider.loadIssues(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No issues found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first issue to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
