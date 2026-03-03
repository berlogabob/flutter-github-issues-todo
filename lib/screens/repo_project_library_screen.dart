import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../models/repo_item.dart';
import '../widgets/braille_loader.dart';
import 'repo_detail_screen.dart';

/// RepoProjectLibraryScreen - Manage repositories and projects
/// Implements brief section 7, screen 5
class RepoProjectLibraryScreen extends ConsumerStatefulWidget {
  const RepoProjectLibraryScreen({super.key});

  @override
  ConsumerState<RepoProjectLibraryScreen> createState() =>
      _RepoProjectLibraryScreenState();
}

class _RepoProjectLibraryScreenState
    extends ConsumerState<RepoProjectLibraryScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  bool _isLoading = false;
  String _filter = 'all'; // all, repos, projects
  List<String> _pinnedRepos = []; // Repos shown on main page
  bool _isOfflineMode = false;

  // Real data from GitHub
  List<RepoItem> _repositories = [];
  List<Map<String, dynamic>> _projects = []; // Projects v2

  @override
  void initState() {
    super.initState();
    _checkOfflineMode();
    _loadPinnedRepos();
    debugPrint('[RepoLibrary] initState - calling _fetchRepositories');
    _fetchRepositories();
  }

  /// Check if app is in offline mode.
  ///
  /// FIX (Task 20.7): Detect offline mode for proper UI behavior.
  Future<void> _checkOfflineMode() async {
    final authType = await SecureStorageService.instance.read(key: 'auth_type');
    if (mounted) {
      setState(() {
        _isOfflineMode = authType == 'offline';
        debugPrint('[RepoLibrary] Offline mode: $_isOfflineMode');
      });
    }
  }

  Future<void> _loadPinnedRepos() async {
    final filters = await _localStorage.getFilters();
    if (mounted) {
      setState(() {
        _pinnedRepos = List<String>.from(filters['pinnedRepos'] ?? []);
        debugPrint(
          '[RepoLibrary] Loaded ${_pinnedRepos.length} pinned repos',
        );
      });
    }
  }

  /// Fetch repositories with improved error handling and offline mode support.
  ///
  /// FIX (Task 20.7): Better offline mode handling and debug logging.
  Future<void> _fetchRepositories() async {
    // In offline mode, just load from cache/local storage
    if (_isOfflineMode) {
      debugPrint('[RepoLibrary] Offline mode - skipping network fetch');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _repositories = []; // Clear old data
    });

    try {
      debugPrint('[RepoLibrary] Fetching repositories...');

      // Check token first
      final hasToken = await _githubApi.getToken();
      if (hasToken == null || hasToken.isEmpty) {
        throw Exception('Not authenticated. Please login with a GitHub token.');
      }

      final repos = await _githubApi.fetchMyRepositories(perPage: 30);
      debugPrint('[RepoLibrary] ✓ Fetched ${repos.length} repositories');

      if (mounted) {
        setState(() {
          _repositories = repos;
          _isLoading = false;
        });

        if (repos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No repositories found. Create a repo on GitHub first.',
              ),
              backgroundColor: AppColors.orangePrimary,
            ),
          );
        }
      }
    } on SocketException catch (e) {
      debugPrint('[RepoLibrary] ✗ Network error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No internet connection',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Showing cached repositories if available',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppColors.orangePrimary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('[RepoLibrary] ✗ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed to fetch repos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_fetchRepositories(), _fetchProjects()]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repositories and projects refreshed'),
            backgroundColor: AppColors.orangePrimary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Refresh failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            icon: const Icon(Icons.refresh, color: AppColors.orangePrimary),
            onPressed: _isLoading ? null : _refreshAll,
            tooltip: 'Refresh All',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.orangePrimary),
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
                        BrailleLoader(size: 32),
                        SizedBox(height: 16),
                        Text(
                          'Loading repositories...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: AppColors.orangePrimary,
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
          Expanded(child: _buildFilterTab('All', 'all')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterTab('Repositories', 'repos')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterTab('Projects', 'projects')),
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
          color: isSelected ? AppColors.orangePrimary : Colors.transparent,
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
    // Removed redundant buttons - auto-refresh, AppBar refresh button, and pull-to-refresh are sufficient
    return const SizedBox.shrink();
  }

  Widget _buildList() {
    debugPrint(
      '_buildList called - repos: ${_repositories.length}, filter: $_filter, isLoading: $_isLoading',
    );

    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrailleLoader(size: 32),
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
    final showProjects =
        (_filter == 'all' || _filter == 'projects') && _projects.isNotEmpty;

    // Show empty state if nothing to display
    if (!showRepos && !showProjects) {
      return _buildEmptyState(
        _filter == 'projects' ? 'projects' : 'repositories',
      );
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
            'No $type',
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
    final isPinned = _pinnedRepos.contains(repo.fullName);

    return Dismissible(
      key: Key(repo.fullName),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.orangePrimary,
        child: const Row(
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text('Show on main', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.red,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Hide from main', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.remove, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (direction) async {
        // Swipe right - pin
        if (direction == DismissDirection.startToEnd) {
          await _pinRepo(repo.fullName);
        } 
        // Swipe left - unpin
        else {
          await _unpinRepo(repo.fullName);
        }
      },
      child: Card(
        color: AppColors.cardBackground,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orangePrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder,
              color: AppColors.orangePrimary,
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
              if (isPinned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.orangePrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Main',
                    style: TextStyle(
                      color: AppColors.orangePrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Icon(Icons.chevron_right, color: AppColors.red, size: 20),
            ],
          ),
          onTap: () async {
            final parts = repo.fullName.split('/');
            if (parts.length == 2) {
              await _navigateToRepoDetail(parts[0], parts[1]);
            }
          },
        ),
      ),
    );
  }

  /// Pin a repository to show on main dashboard.
  ///
  /// FIX (Task 20.7): Improved pin functionality with debug logging.
  Future<void> _pinRepo(String fullName) async {
    debugPrint('[RepoLibrary] Pinning repo: $fullName');
    
    // Add to pinned list
    if (!_pinnedRepos.contains(fullName)) {
      setState(() {
        _pinnedRepos.add(fullName);
      });
    }

    // Save to local storage with error handling
    try {
      final filters = await _localStorage.getFilters();
      final filterStatus = filters['filterStatus'] ?? 'open';
      await _localStorage.saveFilters(
        filterStatus: filterStatus,
        pinnedRepos: _pinnedRepos.toList(),
      );
      debugPrint('[RepoLibrary] ✓ Pinned repo saved: $fullName');
    } catch (e) {
      debugPrint('[RepoLibrary] ✗ Failed to save pinned repo: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$fullName will appear on main page'),
            ],
          ),
          backgroundColor: AppColors.orangePrimary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Unpin a repository from main dashboard.
  ///
  /// FIX (Task 20.7): Improved unpin functionality with debug logging.
  Future<void> _unpinRepo(String fullName) async {
    debugPrint('[RepoLibrary] Unpinning repo: $fullName');
    
    // Remove from pinned list
    if (_pinnedRepos.contains(fullName)) {
      setState(() {
        _pinnedRepos.remove(fullName);
      });
    }

    // Save to local storage with error handling
    try {
      final filters = await _localStorage.getFilters();
      final filterStatus = filters['filterStatus'] ?? 'open';
      await _localStorage.saveFilters(
        filterStatus: filterStatus,
        pinnedRepos: _pinnedRepos.toList(),
      );
      debugPrint('[RepoLibrary] ✓ Unpinned repo saved: $fullName');
    } catch (e) {
      debugPrint('[RepoLibrary] ✗ Failed to save unpinned repo: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$fullName removed from main page'),
            ],
          ),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.view_kanban, color: AppColors.blue, size: 24),
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
                  style: TextStyle(color: Colors.grey, fontSize: 10),
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
            const Icon(Icons.open_in_new, color: AppColors.blue, size: 18),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.red, size: 20),
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
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Add Repository',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter repository URL or full name (owner/repo):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'berlogabob/gitdoit',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.orangePrimary),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              controller.dispose();
              Navigator.pop(context);
              if (value.isNotEmpty) {
                _handleRepoInput(value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangePrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRepoInput(String value) async {
    try {
      String owner, repo;

      // Try to parse as URL first
      final uri = Uri.tryParse(value);
      if (uri != null && uri.host.contains('github.com')) {
        final parts = uri.pathSegments;
        if (parts.length >= 2) {
          owner = parts[0];
          repo = parts[1];
        } else {
          throw Exception('Invalid GitHub URL');
        }
      } else if (value.contains('/')) {
        // Parse as owner/repo
        final parts = value.split('/');
        if (parts.length != 2) {
          throw Exception('Invalid format. Use owner/repo');
        }
        owner = parts[0].trim();
        repo = parts[1].trim();
      } else {
        throw Exception('Invalid format. Use owner/repo or GitHub URL');
      }

      // Navigate to repo detail (or open in browser for now)
      await _navigateToRepoDetail(owner, repo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToRepoDetail(String owner, String repo) async {
    // Navigate to in-app repo detail screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepoDetailScreen(owner: owner, repo: repo),
      ),
    );
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
              content: Text(
                'No projects found. Create a project on GitHub first.',
              ),
              backgroundColor: AppColors.orangePrimary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${projectsList.length} projects'),
              backgroundColor: AppColors.orangePrimary,
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
}
