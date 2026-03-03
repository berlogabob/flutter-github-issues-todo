import 'package:flutter/material.dart';
import '../models/repo_item.dart';
import 'github_api_service.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';
import '../widgets/sync_cloud_icon.dart';

/// Service for dashboard business logic.
///
/// Provides core functionality for the main dashboard including:
/// - Repository display logic with caching
/// - Filter management and persistence
/// - Sync state management
///
/// TESTING SUPPORT (Task 20.8):
/// - Extensive debug logging for troubleshooting
/// - Dependency injection for testability
/// - Clear separation of business logic
class DashboardService extends GitHubApiService {
  final LocalStorageService _localStorage;
  final SyncService _syncService;

  // Cache for getDisplayedRepos
  List<RepoItem>? _cachedRepos;
  String? _cacheKey;

  /// Creates a dashboard service with optional dependencies for testing.
  ///
  /// Parameters:
  /// - [githubApi]: GitHub API service (optional, uses default if null)
  /// - [localStorage]: Local storage service (optional, uses default if null)
  /// - [syncService]: Sync service (optional, uses default if null)
  DashboardService({
    super.githubApi,
    LocalStorageService? localStorage,
    SyncService? syncService,
  }) : _localStorage = localStorage ?? LocalStorageService(),
       _syncService = syncService ?? SyncService();

  /// Get sync cloud state based on current sync status.
  ///
  /// Returns the appropriate [SyncCloudState] based on:
  /// - Offline mode status
  /// - Network availability
  /// - Current sync operation
  SyncCloudState getSyncCloudState({required bool isOfflineMode}) {
    if (isOfflineMode || !_syncService.isNetworkAvailable) {
      debugPrint('[DashboardService] Cloud state: offline');
      return SyncCloudState.offline;
    }
    if (_syncService.isSyncing) {
      debugPrint('[DashboardService] Cloud state: syncing');
      return SyncCloudState.syncing;
    }
    if (_syncService.syncStatus == 'error') {
      debugPrint('[DashboardService] Cloud state: error');
      return SyncCloudState.error;
    }
    debugPrint('[DashboardService] Cloud state: synced');
    return SyncCloudState.synced;
  }

  /// Get list of repos to display on main screen with caching.
  ///
  /// PERFORMANCE OPTIMIZATION: Caches results to avoid recalculating
  /// when parameters haven't changed.
  ///
  /// Parameters:
  /// - [repositories]: All available repositories
  /// - [isOfflineMode]: Whether app is in offline mode
  /// - [pinnedRepos]: Set of pinned repository full names
  ///
  /// Returns filtered list based on mode and pin status.
  List<RepoItem> getDisplayedRepos({
    required List<RepoItem> repositories,
    required bool isOfflineMode,
    required Set<String> pinnedRepos,
  }) {
    // Create cache key from parameters
    final cacheKey =
        '${repositories.length}_${isOfflineMode}_${pinnedRepos.length}';

    // Return cached result if available
    if (_cachedRepos != null && _cacheKey == cacheKey) {
      debugPrint('[DashboardService] Cache hit for displayed repos');
      return _cachedRepos!;
    }

    debugPrint(
      '[DashboardService] Calculating displayed repos: '
      'total=${repositories.length}, offline=$isOfflineMode, '
      'pinned=${pinnedRepos.length}',
    );

    // Calculate result
    final repos = _calculateDisplayedRepos(
      repositories: repositories,
      isOfflineMode: isOfflineMode,
      pinnedRepos: pinnedRepos,
    );

    // Cache it
    _cachedRepos = repos;
    _cacheKey = cacheKey;

    debugPrint(
      '[DashboardService] Displaying ${repos.length} repos (cached)',
    );

    return repos;
  }

  /// Internal method to calculate displayed repos (business logic).
  ///
  /// Logic:
  /// 1. Offline mode: show only vault repo
  /// 2. Online with pinned: show pinned repos
  /// 3. Online without pinned: show first non-vault repo
  List<RepoItem> _calculateDisplayedRepos({
    required List<RepoItem> repositories,
    required bool isOfflineMode,
    required Set<String> pinnedRepos,
  }) {
    if (repositories.isEmpty) {
      debugPrint('[DashboardService] No repositories to display');
      return [];
    }

    // Offline mode: show only vault repo
    if (isOfflineMode) {
      final vaultRepos =
          repositories.where((r) => r.id == 'vault').toList();
      debugPrint(
        '[DashboardService] Offline mode: showing ${vaultRepos.length} vault repos',
      );
      return vaultRepos;
    }

    // Online mode: show pinned repos
    if (pinnedRepos.isNotEmpty) {
      final pinned = repositories
          .where((r) => pinnedRepos.contains(r.fullName) && r.id != 'vault')
          .toList();
      if (pinned.isNotEmpty) {
        debugPrint(
          '[DashboardService] Showing ${pinned.length} pinned repos',
        );
        return pinned;
      }
      debugPrint('[DashboardService] No valid pinned repos found');
    }

    // Fallback: if no pinned repos, show first non-vault repo
    try {
      final fallback = repositories.firstWhere(
        (r) => r.id != 'vault',
        orElse: () => repositories.first,
      );
      debugPrint('[DashboardService] Fallback: showing ${fallback.fullName}');
      return [fallback];
    } catch (e) {
      debugPrint('[DashboardService] Fallback failed, showing all repos');
      return repositories;
    }
  }

  /// Toggle pin status for a repository.
  ///
  /// TESTING SUPPORT (Task 20.8): Added debug logging for testability.
  Future<void> togglePinRepo({
    required String repoFullName,
    required Set<String> pinnedRepos,
    required String filterStatus,
  }) async {
    final isPinning = !pinnedRepos.contains(repoFullName);
    debugPrint(
      '[DashboardService] Toggle pin: $repoFullName (pinning: $isPinning)',
    );

    if (pinnedRepos.contains(repoFullName)) {
      pinnedRepos.remove(repoFullName);
    } else {
      pinnedRepos.add(repoFullName);
    }

    try {
      await _localStorage.saveFilters(
        filterStatus: filterStatus,
        pinnedRepos: pinnedRepos.toList(),
      );
      debugPrint('[DashboardService] ✓ Pin state saved');
    } catch (e) {
      debugPrint('[DashboardService] ✗ Failed to save pin state: $e');
      rethrow;
    }
  }

  /// Load saved filters from local storage.
  ///
  /// TESTING SUPPORT (Task 20.8): Added debug logging for testability.
  Future<Map<String, dynamic>> loadSavedFilters() async {
    try {
      debugPrint('[DashboardService] Loading saved filters...');
      final filters = await _localStorage.getFilters();
      final result = {
        'filterStatus': filters['filterStatus'] ?? 'open',
        'pinnedRepos': ((filters['pinnedRepos'] as List?) ?? [])
            .map((e) => e.toString())
            .toSet(),
      };
      debugPrint(
        '[DashboardService] ✓ Loaded filters: status=${result['filterStatus']}, '
        'pinned=${(result['pinnedRepos'] as Set).length} repos',
      );
      return result;
    } catch (e) {
      debugPrint('[DashboardService] ✗ Error loading filters: $e');
      return {'filterStatus': 'open', 'pinnedRepos': <String>{}};
    }
  }

  /// Save hide username setting.
  Future<void> saveHideUsernameSetting(bool hide) async {
    debugPrint('[DashboardService] Save hide username: $hide');
    await _localStorage.saveHideUsernameSetting(hide);
  }
}
