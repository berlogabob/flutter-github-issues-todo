import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repo_item.dart';
import 'pinned_repos_provider.dart';

/// Provider for all repositories (state holder)
final repositoriesProvider = NotifierProvider<RepositoriesNotifier, List<RepoItem>>(() {
  return RepositoriesNotifier();
});

class RepositoriesNotifier extends Notifier<List<RepoItem>> {
  RepositoriesNotifier();
  
  @override
  List<RepoItem> build() {
    return [];
  }

  void setRepos(List<RepoItem> repos) {
    state = repos;
  }

  void addRepo(RepoItem repo) {
    state = [...state, repo];
  }

  void updateRepo(RepoItem updatedRepo) {
    state = state.map((r) => r.fullName == updatedRepo.fullName ? updatedRepo : r).toList();
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
