import 'package:flutter/material.dart';
import '../models/repo_item.dart';
import 'github_api_service.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';
import '../widgets/sync_cloud_icon.dart';

/// Service for dashboard business logic
class DashboardService extends GitHubApiService {
  final LocalStorageService _localStorage;
  final SyncService _syncService;

  DashboardService({
    GitHubApiService? githubApi,
    LocalStorageService? localStorage,
    SyncService? syncService,
  }) : _localStorage = localStorage ?? LocalStorageService(),
       _syncService = syncService ?? SyncService(),
       super(githubApi: githubApi);

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

  /// Get list of repos to display on main screen
  List<RepoItem> getDisplayedRepos({
    required List<RepoItem> repositories,
    required bool isOfflineMode,
    required Set<String> pinnedRepos,
  }) {
    if (repositories.isEmpty) return [];

    // Offline mode: show only vault repo
    if (isOfflineMode) {
      return repositories.where((r) => r.id == 'vault').toList();
    }

    // Online mode: show pinned repos
    if (pinnedRepos.isNotEmpty) {
      final pinned = repositories
          .where((r) => pinnedRepos.contains(r.fullName) && r.id != 'vault')
          .toList();
      if (pinned.isNotEmpty) {
        return pinned;
      }
    }

    // Fallback: if no pinned repos, show first non-vault repo
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

  /// Toggle pin repo
  Future<void> togglePinRepo({
    required String repoFullName,
    required Set<String> pinnedRepos,
    required String filterStatus,
  }) async {
    if (pinnedRepos.contains(repoFullName)) {
      pinnedRepos.remove(repoFullName);
    } else {
      pinnedRepos.add(repoFullName);
    }
    await _localStorage.saveFilters(
      filterStatus: filterStatus,
      pinnedRepos: pinnedRepos.toList(),
    );
  }

  /// Load saved filters
  Future<Map<String, dynamic>> loadSavedFilters() async {
    try {
      final filters = await _localStorage.getFilters();
      return {
        'filterStatus': filters['filterStatus'] ?? 'open',
        'pinnedRepos': ((filters['pinnedRepos'] as List?) ?? [])
            .map((e) => e.toString())
            .toSet(),
      };
    } catch (e) {
      debugPrint('Error loading filters: $e');
      return {'filterStatus': 'open', 'pinnedRepos': <String>{}};
    }
  }

  /// Save hide username setting
  Future<void> saveHideUsernameSetting(bool hide) async {
    await _localStorage.saveHideUsernameSetting(hide);
  }
}
