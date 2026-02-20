import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import 'settings_screen.dart';
import 'issue_detail_screen.dart';
import '../widgets/issue_card.dart';
import '../widgets/offline_indicator.dart';

/// Home Screen - Main dashboard after authentication
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
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: InputDecoration(
                  hintText: 'Search issues...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (query) {
                  setState(() => _searchQuery = query);
                },
              )
            : const Text('GitDoIt'),
        actions: [
          // Search button
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
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
      body: _HomeContent(searchQuery: _searchQuery),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateIssueDialog(context),
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
  final String searchQuery;

  const _HomeContent({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final issuesProvider = Provider.of<IssuesProvider>(context);

    return Column(
      children: [
        // Offline indicator
        const OfflineIndicator(),

        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildFilterBar(context, issuesProvider),
        ),

        // Issue list or empty state
        Expanded(
          child: issuesProvider.isLoading && issuesProvider.issues.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : issuesProvider.error != null
              ? _buildErrorState(context, issuesProvider)
              : _buildIssueList(context, issuesProvider),
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

  Widget _buildIssueList(BuildContext context, IssuesProvider issuesProvider) {
    final issues = issuesProvider.searchIssues(searchQuery);

    return RefreshIndicator(
      onRefresh: () => issuesProvider.refreshIssues(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return IssueCard(
            issue: issue,
            onTap: () => _navigateToDetail(context, issue),
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
    );
  }

  void _navigateToDetail(BuildContext context, dynamic issue) {
    Logger.d('Navigating to issue #${issue.number}', context: 'Home');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)),
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
}
