import 'package:flutter/material.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import 'github_api_service.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';
import '../widgets/sync_cloud_icon.dart';

/// Service for dashboard data loading and state management
class DashboardDataService {
  final GitHubApiService _githubApi;
  final LocalStorageService _localStorage;
  final SyncService _syncService;

  DashboardDataService({
    GitHubApiService? githubApi,
    LocalStorageService? localStorage,
    SyncService? syncService,
  }) : _githubApi = githubApi ?? GitHubApiService(),
       _localStorage = localStorage ?? LocalStorageService(),
       _syncService = syncService ?? SyncService();

  /// Load all dashboard data
  Future<DashboardData> loadData({
    required String filterStatus,
    required bool isOfflineMode,
    required Set<String> pinnedRepos,
    String? vaultFolderName,
  }) async {
    final data = DashboardData();

    // Load local issues
    data.localIssues = await _loadLocalIssues(vaultFolderName);

    // Fetch repositories
    try {
      data.repositories = await _githubApi.fetchMyRepositories(perPage: 30);
      data.repositoriesLoaded = true;
    } catch (e) {
      data.errorMessage = e.toString();
      data.repositoriesLoaded = false;
    }

    // Fetch projects
    try {
      data.projects = await _githubApi.fetchProjects();
    } catch (e) {
      debugPrint('Error fetching projects: $e');
    }

    // Fetch issues for all repos
    if (data.repositoriesLoaded) {
      await _fetchIssuesForAllRepos(data.repositories);
    }

    // Auto-pin default repo if no pinned repos
    if (pinnedRepos.isEmpty && data.repositories.isNotEmpty) {
      await _autoPinDefaultRepo(
        pinnedRepos: pinnedRepos,
        filterStatus: filterStatus,
      );
    }

    return data;
  }

  /// Load local issues from storage
  Future<List<IssueItem>> _loadLocalIssues(String? vaultFolderName) async {
    try {
      return await _localStorage.getLocalIssues();
    } catch (e) {
      debugPrint('Error loading local issues: $e');
      return [];
    }
  }

  /// Fetch issues for all repositories
  Future<void> _fetchIssuesForAllRepos(List<RepoItem> repos) async {
    final futures = repos.map((repo) async {
      try {
        final parts = repo.fullName.split('/');
        if (parts.length == 2) {
          final issues = await _githubApi.fetchIssues(parts[0], parts[1]);
          repo.children.addAll(issues);
        }
      } catch (e) {
        debugPrint('Failed to fetch issues for ${repo.fullName}: $e');
      }
    });
    await Future.wait(futures);
  }

  /// Auto-pin default repo
  Future<void> _autoPinDefaultRepo({
    required Set<String> pinnedRepos,
    required String filterStatus,
  }) async {
    final defaultRepoName = await _localStorage.getDefaultRepo();
    if (defaultRepoName != null) {
      pinnedRepos.add(defaultRepoName);
      await _localStorage.saveFilters(
        filterStatus: filterStatus,
        pinnedRepos: pinnedRepos.toList(),
      );
    }
  }

  /// Get sync cloud state
  SyncCloudState getSyncCloudState({required bool isOfflineMode}) {
    if (isOfflineMode || !_syncService.isNetworkAvailable) {
      return SyncCloudState.offline;
    }
    if (_syncService.isSyncing) {
      return SyncCloudState.syncing;
    }
    if (_syncService.syncStatus == 'error') {
      return SyncCloudState.error;
    }
    return SyncCloudState.synced;
  }

  /// Get displayed repos based on mode
  List<RepoItem> getDisplayedRepos({
    required List<RepoItem> repositories,
    required bool isOfflineMode,
    required Set<String> pinnedRepos,
  }) {
    if (repositories.isEmpty) return [];

    if (isOfflineMode) {
      return repositories.where((r) => r.id == 'vault').toList();
    }

    if (pinnedRepos.isNotEmpty) {
      final pinned = repositories
          .where((r) => pinnedRepos.contains(r.fullName) && r.id != 'vault')
          .toList();
      if (pinned.isNotEmpty) return pinned;
    }

    try {
      return [
        repositories.firstWhere(
          (r) => r.id != 'vault',
          orElse: () => repositories.first,
        ),
      ];
    } catch (e) {
      return repositories;
    }
  }
}

/// Dashboard data container
class DashboardData {
  List<RepoItem> repositories = [];
  List<IssueItem> localIssues = [];
  List<Map<String, dynamic>> projects = [];
  bool repositoriesLoaded = false;
  String? errorMessage;
}
