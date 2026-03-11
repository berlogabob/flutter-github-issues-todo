import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/github_api_service.dart';
import '../services/secure_storage_service.dart';
import '../models/repo_item.dart';
import '../widgets/braille_loader.dart';
import '../providers/pinned_repos_provider.dart';
import '../providers/repositories_provider.dart';
import 'repo_detail_screen.dart';

/// RepoProjectLibraryScreen - Manage repositories and projects
/// RIVERPOD MIGRATION: Fully migrated to Riverpod 3
class RepoProjectLibraryScreen extends ConsumerStatefulWidget {
  const RepoProjectLibraryScreen({super.key});

  @override
  ConsumerState<RepoProjectLibraryScreen> createState() =>
      _RepoProjectLibraryScreenState();
}

class _RepoProjectLibraryScreenState
    extends ConsumerState<RepoProjectLibraryScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  bool _isLoading = false;
  String _filter = 'all'; // all, repos, projects
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _checkOfflineMode();
    _loadMainRepo();
    _fetchRepositories();
  }

  Future<void> _checkOfflineMode() async {
    final authType = await SecureStorageService.instance.read(key: 'auth_type');
    if (mounted) {
      setState(() {
        _isOfflineMode = authType == 'offline';
      });
    }
  }

  Future<void> _loadMainRepo() async {
    ref.read(mainRepoProvider.notifier).load();
  }

  Future<void> _fetchRepositories() async {
    if (_isOfflineMode) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hasToken = await _githubApi.getToken();
      if (hasToken == null || hasToken.isEmpty) {
        throw Exception('Not authenticated');
      }

      final repos = await _githubApi.fetchMyRepositories(perPage: 30);

      // Update Riverpod state
      ref.read(repositoriesProvider.notifier).setRepos(repos);

      if (mounted) {
        setState(() => _isLoading = false);
        if (repos.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No repositories found'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } on SocketException {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pinRepo(String fullName) async {
    await ref.read(pinnedReposProvider.notifier).pin(fullName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fullName will appear on main page'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _unpinRepo(String fullName) async {
    final mainRepo = ref.read(mainRepoProvider);
    if (fullName == mainRepo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot unpin main repository'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await ref.read(pinnedReposProvider.notifier).unpin(fullName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fullName removed from main page'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddRepoDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Repository'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'owner/repository',
            labelText: 'Repository (e.g., flutter/flutter)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    if (!result.contains('/')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use format: owner/repository'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parts = result.split('/');
      final repo = await _githubApi.fetchRepoByUrl(parts[0], parts[1]);

      if (repo != null) {
        // Add to repositories list
        ref.read(repositoriesProvider.notifier).addRepo(repo);
        // Pin to main screen
        await ref.read(pinnedReposProvider.notifier).pin(repo.fullName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${repo.fullName} added to main page'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Repository not found'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repos = ref.watch(repositoriesProvider);
    final pinned = ref.watch(pinnedReposProvider);
    final mainRepo = ref.watch(mainRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Add repo by URL',
            onPressed: () => _showAddRepoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchRepositories,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == 'all',
                  onSelected: (v) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Repos'),
                  selected: _filter == 'repos',
                  onSelected: (v) => setState(() => _filter = 'repos'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Projects'),
                  selected: _filter == 'projects',
                  onSelected: (v) => setState(() => _filter = 'projects'),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: BrailleLoader(size: 32))
                : repos.isEmpty
                ? const Center(child: Text('No repositories'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: repos.length,
                    itemBuilder: (context, index) {
                      final repo = repos[index];
                      final isPinned = pinned.contains(repo.fullName);
                      final isMain = repo.fullName == mainRepo;

                      return _buildRepoItem(repo, isPinned, isMain);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepoItem(RepoItem repo, bool isPinned, bool isMain) {
    return Dismissible(
      key: ValueKey(repo.fullName),
      direction: DismissDirection.horizontal,
      resizeDuration: null, // Don't dismiss, just trigger action
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.primary,
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
        color: AppColors.error,
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
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          await _pinRepo(repo.fullName);
        } else {
          await _unpinRepo(repo.fullName);
        }
      },
      child: Card(
        color: AppColors.card,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder,
              color: AppColors.primary,
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
              ? Text(
                  repo.description!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMain)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'main',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.error, size: 20),
            ],
          ),
          onTap: () async {
            final parts = repo.fullName.split('/');
            if (parts.length == 2) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RepoDetailScreen(owner: parts[0], repo: parts[1]),
                ),
              );
            }
          },
          onLongPress: () async {
            final currentMainRepo = ref.read(mainRepoProvider);
            if (repo.fullName != currentMainRepo) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Set as Main Repository?'),
                  content: Text(
                    '${repo.fullName} will become your default repo.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Set as Main'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref
                    .read(mainRepoProvider.notifier)
                    .setMain(repo.fullName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${repo.fullName} set as main repository'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            }
          },
        ),
      ),
    );
  }
}
