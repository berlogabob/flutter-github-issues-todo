import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/github_api_service.dart';
import '../models/repo_item.dart';

/// RepoProjectLibraryScreen - Manage repositories and projects
/// Implements brief section 7, screen 5
class RepoProjectLibraryScreen extends ConsumerStatefulWidget {
  const RepoProjectLibraryScreen({super.key});

  @override
  ConsumerState<RepoProjectLibraryScreen> createState() => _RepoProjectLibraryScreenState();
}

class _RepoProjectLibraryScreenState extends ConsumerState<RepoProjectLibraryScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  bool _isLoading = false;
  String _filter = 'all'; // all, repos, projects

  // Real data from GitHub
  List<RepoItem> _repositories = [];
  List<Map<String, dynamic>> _projects = []; // Projects v2

  @override
  void initState() {
    super.initState();
    debugPrint('RepoLibrary: initState - calling _fetchRepositories');
    _fetchRepositories();
  }

  Future<void> _fetchRepositories() async {
    setState(() {
      _isLoading = true;
      _repositories = []; // Clear old data
    });
    
    try {
      debugPrint('Repo Library: Fetching repositories...');
      
      // Check token first
      final hasToken = await _githubApi.getToken();
      if (hasToken == null || hasToken.isEmpty) {
        throw Exception('Not authenticated. Please login with a GitHub token.');
      }
      
      final repos = await _githubApi.fetchMyRepositories(perPage: 30);
      debugPrint('Repo Library: Fetched ${repos.length} repositories');
      
      if (mounted) {
        setState(() {
          _repositories = repos;
          _isLoading = false;
        });
        
        if (repos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No repositories found. Create a repo on GitHub first.'),
              backgroundColor: AppColors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Repo Library Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Failed to fetch repos:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(e.toString(), style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchRepositories,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('RepoLibrary: build - repos: ${_repositories.length}');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Repositories & Projects',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _isLoading ? null : _fetchRepositories,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.orange),
            onPressed: _addByUri,
            tooltip: 'Add by URL',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),
          // Action buttons
          _buildActionButtons(),
          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading repositories...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchRepositories,
                    color: AppColors.orange,
                    child: _buildList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab('All', 'all'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab('Repositories', 'repos'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab('Projects', 'projects'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.folder, size: 18),
              label: const Text('Fetch Repos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoading ? null : _fetchRepositories,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.view_kanban, size: 18),
              label: const Text('Fetch Projects'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isLoading ? null : _fetchProjects,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    debugPrint('_buildList called - repos: ${_repositories.length}, filter: $_filter, isLoading: $_isLoading');

    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
            SizedBox(height: 16),
            Text(
              'Loading repositories...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Check if there are any repos to show
    final hasRepos = _repositories.isNotEmpty;
    final showRepos = (_filter == 'all' || _filter == 'repos') && hasRepos;
    final showProjects = (_filter == 'all' || _filter == 'projects') && _projects.isNotEmpty;
    
    // Show empty state if nothing to display
    if (!showRepos && !showProjects) {
      return _buildEmptyState(_filter == 'projects' ? 'projects' : 'repositories');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showRepos) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Repositories',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._repositories.map((repo) => _buildRepoItem(repo)),
          if (showProjects) const SizedBox(height: 24),
        ],
        if (showProjects) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Projects',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._projects.map((project) => _buildProjectItem(project)),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'repositories' ? Icons.folder_open : Icons.view_kanban,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${type}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Fetch ${type == 'repositories' ? 'Repos' : 'Projects'}" to load',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepoItem(RepoItem repo) {
    debugPrint('_buildRepoItem: ${repo.fullName}');
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.folder,
            color: AppColors.orange,
            size: 24,
          ),
        ),
        title: Text(
          repo.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: repo.description != null && repo.description!.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    repo.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.open_in_new,
              color: AppColors.blue,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.red,
              size: 20,
            ),
          ],
        ),
        onTap: () async {
          final uri = Uri.parse('https://github.com/${repo.fullName}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  Widget _buildProjectItem(Map<String, dynamic> project) {
    final title = project['title'] as String? ?? 'Untitled';
    final description = project['shortDescription'] as String?;
    final isClosed = project['closed'] as bool? ?? false;
    final url = project['url'] as String?;
    
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.view_kanban,
            color: AppColors.blue,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isClosed) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Closed',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: description != null && description.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.open_in_new,
              color: AppColors.blue,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.red,
              size: 20,
            ),
          ],
        ),
        onTap: () async {
          if (url != null && url.isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cannot open project URL'),
                  backgroundColor: AppColors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _addByUri() {
    // TODO: Add repository/project by URL
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('Fetching Projects v2...');
      final projectsList = await _githubApi.fetchProjects(first: 30);
      debugPrint('Fetched ${projectsList.length} projects');
      
      if (mounted) {
        setState(() {
          _projects = projectsList;
          _isLoading = false;
        });
        
        if (projectsList.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No projects found. Create a project on GitHub first.'),
              backgroundColor: AppColors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${projectsList.length} projects'),
              backgroundColor: AppColors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch projects: $e'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _handleRepoAction(String action, RepoItem repo) {
    switch (action) {
      case 'default':
        // TODO: Set as default
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set ${repo.fullName} as default'),
            backgroundColor: AppColors.orange,
          ),
        );
        break;
      case 'issues':
        // TODO: Navigate to repo issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing issues for ${repo.fullName}'),
            backgroundColor: AppColors.orange,
          ),
        );
        break;
    }
  }

  void _handleProjectAction(String action, Map<String, dynamic> project) {
    switch (action) {
      case 'default':
        // TODO: Set as default
        break;
      case 'remove':
        // TODO: Remove project
        break;
    }
  }
}
