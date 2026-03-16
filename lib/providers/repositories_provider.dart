import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repo_item.dart';
import '../services/local_storage_service.dart';
import 'pinned_repos_provider.dart';

/// Provider for all repositories (state holder)
final repositoriesProvider = NotifierProvider<RepositoriesNotifier, List<RepoItem>>(() {
  return RepositoriesNotifier();
});

class RepositoriesNotifier extends Notifier<List<RepoItem>> {
  RepositoriesNotifier();

  @override
  List<RepoItem> build() {
    // Load cached repos on provider initialization (OFFLINE-FIRST)
    _loadCachedRepos();
    return [];
  }

  /// Load cached repositories from local storage
  Future<void> _loadCachedRepos() async {
    try {
      final localStorage = LocalStorageService();
      final cachedRepos = await localStorage.getRepos();
      
      if (cachedRepos.isNotEmpty) {
        state = cachedRepos.map((r) => RepoItem.fromJson(r)).toList();
        debugPrint('RepositoriesNotifier: Loaded ${state.length} cached repos');
      }
    } catch (e) {
      debugPrint('RepositoriesNotifier: Failed to load cached repos: $e');
    }
  }

  void setRepos(List<RepoItem> repos) {
    state = repos;
    // Also cache to local storage
    _cacheToLocalStorage(repos);
  }

  void addRepo(RepoItem repo) {
    state = [...state, repo];
    _cacheToLocalStorage(state);
  }

  void updateRepo(RepoItem updatedRepo) {
    state = state.map((r) => r.fullName == updatedRepo.fullName ? updatedRepo : r).toList();
    _cacheToLocalStorage(state);
  }

  /// Cache repositories to local storage
  Future<void> _cacheToLocalStorage(List<RepoItem> repos) async {
    try {
      final localStorage = LocalStorageService();
      await localStorage.saveRepos(repos.map((r) => r.toJson()).toList());
      debugPrint('RepositoriesNotifier: Cached ${repos.length} repos');
    } catch (e) {
      debugPrint('RepositoriesNotifier: Failed to cache repos: $e');
    }
  }

  /// Load repositories (alias for setRepos for compatibility)
  Future<void> load() async {
    await _loadCachedRepos();
  }
}

/// Provider for displayed repositories (pinned + main)
final displayedReposProvider = Provider<List<RepoItem>>((ref) {
  final allRepos = ref.watch(repositoriesProvider);
  final pinned = ref.watch(pinnedReposProvider);
  final mainRepo = ref.watch(mainRepoProvider);

  // Always show main repo first, then pinned repos
  final main = allRepos.where((r) => r.fullName == mainRepo).toList();
  final pinnedRepos = allRepos.where((r) => pinned.contains(r.fullName) && r.fullName != mainRepo).toList();
  
  return [...main, ...pinnedRepos];
});
