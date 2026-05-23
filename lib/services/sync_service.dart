import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ce/hive_ce.dart';
import 'local_storage_service.dart';
import 'github_api_service.dart';
import 'pending_operations_service.dart';
import 'conflict_detection_service.dart';
import 'secure_storage_service.dart';
import '../utils/app_error_handler.dart';
import '../utils/retry_helper.dart';
import '../models/issue_item.dart';
import '../models/pending_operation.dart';
import '../models/sync_history_entry.dart';
import '../models/cached_dashboard_data.dart';

enum SyncPhase {
  idle,
  queued,
  syncingPendingOperations,
  syncingIssues,
  syncingProjects,
  success,
  partial,
  error,
}

class PendingReplayResult {
  final int totalOperations;
  final int attemptedOperations;
  final int succeededOperations;
  final int failedOperations;
  final int skippedOperations;

  const PendingReplayResult({
    this.totalOperations = 0,
    this.attemptedOperations = 0,
    this.succeededOperations = 0,
    this.failedOperations = 0,
    this.skippedOperations = 0,
  });
}

class IssuesSyncResult {
  final int syncedIssuesCount;
  final int repositoriesSucceeded;
  final int repositoriesFailed;
  final int conflictsDetected;
  final int localIssuesSynced;
  final int localIssuesFailed;

  const IssuesSyncResult({
    this.syncedIssuesCount = 0,
    this.repositoriesSucceeded = 0,
    this.repositoriesFailed = 0,
    this.conflictsDetected = 0,
    this.localIssuesSynced = 0,
    this.localIssuesFailed = 0,
  });
}

class LocalIssuesSyncResult {
  final List<String> syncedIssueIds;
  final int failedCount;

  const LocalIssuesSyncResult({
    this.syncedIssueIds = const [],
    this.failedCount = 0,
  });
}

/// Sync Service - Handles synchronization between local storage and GitHub
///
/// Features:
/// - Manual sync via syncAll()
/// - Auto-sync on network availability
/// - Conflict resolution (remote wins for existing, local wins for new)
/// - Sync status tracking
/// - Background sync support
class SyncService {
  SyncService();

  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  final PendingOperationsService _pendingOps = PendingOperationsService();
  final ConflictDetectionService _conflictDetector = ConflictDetectionService();

  // Sync status
  bool _isSyncing = false;
  bool _isNetworkAvailable = false;
  bool _isOfflineAuthMode = false;
  DateTime? _lastSyncTime;
  DateTime? _lastProjectsSyncTime;
  SyncPhase _syncPhase = SyncPhase.idle;
  String _syncStatus = 'idle'; // idle, syncing, success, error
  String? _syncErrorMessage;
  int _syncedIssuesCount = 0;
  int _syncedProjectsCount = 0;

  // OFFLINE-FIRST (Critical Fix): Cached data for instant startup
  CachedDashboardData? _cachedData;
  bool _cachedDataLoaded = false;

  // Getters for cached data
  CachedDashboardData? get cachedData => _cachedData;
  bool get hasCachedData => _cachedData != null && _cachedData!.hasData;

  // Callback for when sync is needed (has local issues + internet)
  Function()? onSyncNeeded;

  // Callback for when local issues have been synced (UI should refresh vault)
  Function()? onLocalIssuesSynced;
  void Function(List<IssueConflict> conflicts)? onConflictsDetected;
  void Function(String event, Map<String, Object?> details)? onSyncEvent;

  // Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Auto-sync debounce
  Timer? _autoSyncTimer;

  // Listener support for UI updates
  final _listeners = <VoidCallback>{};

  // Sync history
  late Box<dynamic> _historyBox;
  final List<SyncHistoryEntry> _syncHistory = [];
  static const String _historyBoxName = 'sync_history';

  // Getters
  bool get isSyncing => _isSyncing;
  bool get isNetworkAvailable => _isNetworkAvailable;
  DateTime? get lastSyncTime => _lastSyncTime;
  DateTime? get lastProjectsSyncTime => _lastProjectsSyncTime;
  SyncPhase get syncPhase => _syncPhase;
  String get syncStatus => _syncStatus;
  String? get syncErrorMessage => _syncErrorMessage;
  int get syncedIssuesCount => _syncedIssuesCount;
  int get syncedProjectsCount => _syncedProjectsCount;

  /// Add a listener for sync state changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Initialize sync service
  Future<void> init() async {
    debugPrint('SyncService: Initializing...');
    await _loadCachedData(); // OFFLINE-FIRST: Load cached data immediately
    await _loadAuthSyncMode();
    _setupConnectivityListener();
    await _checkNetworkStatus();
    await _loadLastSyncTimes();
    await _initHistory();
    _transitionTo(SyncPhase.idle);
  }

  Future<void> _loadAuthSyncMode() async {
    try {
      final authType = await SecureStorageService.read(key: 'auth_type');
      final hasToken = await SecureStorageService.hasToken();
      _isOfflineAuthMode = authType == 'offline' || !hasToken;
      debugPrint('SyncService: Auth sync mode offline=$_isOfflineAuthMode');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, showSnackBar: false);
      _isOfflineAuthMode = true;
      debugPrint(
        'SyncService: Failed to read auth mode, defaulting offline: $e',
      );
    }
  }

  /// Load cached data from local storage (OFFLINE-FIRST)
  Future<void> _loadCachedData() async {
    if (_cachedDataLoaded && _cachedData != null) {
      debugPrint('SyncService: Cached data already loaded');
      return;
    }

    try {
      debugPrint('SyncService: Loading cached dashboard data...');
      _cachedData = await _localStorage.getCachedDashboardData();
      _cachedDataLoaded = true;

      if (_cachedData != null && _cachedData!.hasData) {
        debugPrint(
          'SyncService: ✓ Loaded cached data: '
          '${_cachedData!.repositories.length} repos, '
          '${_cachedData!.localIssues.length} local issues',
        );
      } else {
        debugPrint('SyncService: No cached data found');
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Failed to load cached data: $e');
      // Don't fail initialization, just continue without cache
    }
  }

  /// Initialize sync history
  Future<void> _initHistory() async {
    try {
      _historyBox = await Hive.openBox(_historyBoxName);
      _loadSyncHistory();
      debugPrint(
        'SyncService: History initialized with ${_syncHistory.length} entries',
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: History init failed: $e');
    }
  }

  /// Load sync history from storage
  void _loadSyncHistory() {
    try {
      _syncHistory.clear();
      for (final entry in _historyBox.values) {
        if (entry is String) {
          final json = jsonDecode(entry) as Map<String, dynamic>;
          _syncHistory.add(SyncHistoryEntry.fromJson(json));
        }
      }
      // Keep only last 10 entries
      if (_syncHistory.length > 10) {
        _syncHistory.removeRange(10, _syncHistory.length);
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  /// Record sync history entry
  Future<void> _recordSyncHistory({
    required SyncResult result,
    required int issuesSynced,
    required int projectsSynced,
    required int operationsProcessed,
    required Duration duration,
    String? errorMessage,
  }) async {
    try {
      final safeErrorMessage = errorMessage == null
          ? null
          : _safeError(errorMessage);
      final entry = SyncHistoryEntry(
        id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        result: result,
        issuesSynced: issuesSynced,
        projectsSynced: projectsSynced,
        operationsProcessed: operationsProcessed,
        duration: duration,
        errorMessage: safeErrorMessage,
      );

      // Add to beginning of list
      _syncHistory.insert(0, entry);

      // Keep only last 10 entries
      if (_syncHistory.length > 10) {
        _syncHistory.removeRange(10, _syncHistory.length);
      }

      // Save to storage
      await _historyBox.put(entry.id, jsonEncode(entry.toJson()));

      debugPrint('SyncService: Recorded sync history entry: ${entry.result}');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  /// Get sync history
  List<SyncHistoryEntry> getSyncHistory() {
    return List.unmodifiable(_syncHistory);
  }

  /// Get sync statistics
  SyncStatistics getSyncStatistics() {
    final totalSyncs = _syncHistory.length;
    final successfulSyncs = _syncHistory
        .where((e) => e.result == SyncResult.success)
        .length;
    final failedSyncs = _syncHistory
        .where((e) => e.result == SyncResult.failed)
        .length;
    final totalIssuesSynced = _syncHistory.fold<int>(
      0,
      (sum, e) => sum + e.issuesSynced,
    );
    final totalOperationsProcessed = _syncHistory.fold<int>(
      0,
      (sum, e) => sum + e.operationsProcessed,
    );

    return SyncStatistics(
      totalSyncs: totalSyncs,
      successfulSyncs: successfulSyncs,
      failedSyncs: failedSyncs,
      totalIssuesSynced: totalIssuesSynced,
      totalOperationsProcessed: totalOperationsProcessed,
      lastSyncTime: _lastSyncTime,
      lastSuccessfulSync: _syncHistory
          .where((e) => e.result == SyncResult.success)
          .firstOrNull
          ?.timestamp,
    );
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
  }

  /// Load last sync times from local storage
  Future<void> _loadLastSyncTimes() async {
    _lastSyncTime = await _localStorage.getReposSyncTime();
    _lastProjectsSyncTime = await _localStorage.getProjectsSyncTime();
    debugPrint('SyncService: Last sync time: $_lastSyncTime');
  }

  /// Setup network connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateNetworkStatus(results);
    });
  }

  /// Update network status from connectivity results
  void _updateNetworkStatus(List<ConnectivityResult> results) {
    final wasAvailable = _isNetworkAvailable;

    _isNetworkAvailable = results.any(
      (result) => result != ConnectivityResult.none,
    );

    debugPrint('SyncService: Network status changed: $_isNetworkAvailable');
    _emitSyncEvent('network_status_changed', {
      'isNetworkAvailable': _isNetworkAvailable,
      'wasAvailable': wasAvailable,
    });

    if (_isOfflineAuthMode) {
      _transitionTo(SyncPhase.idle);
      return;
    }

    // Auto-sync when network becomes available
    if (_isNetworkAvailable && !wasAvailable) {
      debugPrint('SyncService: Network restored, triggering auto-sync');
      _transitionTo(SyncPhase.queued);
      _triggerAutoSync();

      // Check if there are local issues to sync
      _checkAndNotifyLocalIssues();
    }
  }

  /// Check if there are local-only issues and notify via callback
  Future<void> _checkAndNotifyLocalIssues() async {
    if (_isOfflineAuthMode) return;
    try {
      final localIssues = await _localStorage.getLocalIssues();
      final localOnlyCount = localIssues.where((i) => i.isLocalOnly).length;

      if (localOnlyCount > 0 && onSyncNeeded != null) {
        debugPrint('SyncService: Found $localOnlyCount local issues to sync');
        onSyncNeeded!();
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Error checking local issues: $e');
    }
  }

  /// Public method to check if there are local issues
  Future<int> getLocalIssuesCount() async {
    final localIssues = await _localStorage.getLocalIssues();
    return localIssues.where((i) => i.isLocalOnly).length;
  }

  /// Public method to sync local issues to a specific repo
  Future<bool> syncLocalIssuesToRepo(String owner, String repo) async {
    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress');
      return false;
    }

    _isSyncing = true;
    _transitionTo(SyncPhase.syncingIssues);

    try {
      final localIssues = await _localStorage.getLocalIssues();
      final result = await _syncLocalIssuesToGitHub(owner, repo, localIssues);

      // FIX (#34): Cancel any pending auto-sync to prevent duplicate processing
      _autoSyncTimer?.cancel();

      // FIX (#34): Wait a bit to ensure files are deleted before any other sync
      await Future.delayed(const Duration(milliseconds: 500));

      final hasPartialFailure = result.failedCount > 0;
      _transitionTo(hasPartialFailure ? SyncPhase.partial : SyncPhase.success);
      _emitSyncEvent('sync_local_issues_to_repo_completed', {
        'owner': owner,
        'repo': repo,
        'synced': result.syncedIssueIds.length,
        'failed': result.failedCount,
      });
      return !hasPartialFailure;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Failed to sync local issues: ${_safeError(e)}');
      _transitionTo(SyncPhase.error, errorMessage: e.toString());
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Check current network status
  Future<void> _checkNetworkStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateNetworkStatus(results);
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Failed to check network status: $e');
      _isNetworkAvailable = false;
    }
  }

  /// Trigger auto-sync when network becomes available (with debounce)
  Future<void> _triggerAutoSync() async {
    if (_isOfflineAuthMode) return;
    // Cancel any pending auto-sync
    _autoSyncTimer?.cancel();

    // Debounce: wait 2 seconds before syncing
    _autoSyncTimer = Timer(const Duration(seconds: 2), () async {
      if (!_isSyncing && _isNetworkAvailable) {
        debugPrint('SyncService: Starting auto-sync');
        await syncAll(forceRefresh: false);
      }
    });
  }

  /// Manual sync all data (repositories, issues, projects)
  /// Returns true if successful
  Future<bool> syncAll({bool forceRefresh = false}) async {
    if (_isOfflineAuthMode) {
      _transitionTo(SyncPhase.idle);
      _emitSyncEvent('sync_skipped_offline_mode', {
        'reason': 'offline auth mode',
      });
      return true;
    }

    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress');
      return false;
    }

    if (!_isNetworkAvailable) {
      debugPrint('SyncService: No network available');
      _transitionTo(SyncPhase.error, errorMessage: 'No internet connection');
      return false;
    }

    final canSyncWithGitHub = await _canSyncWithGitHub();
    if (!canSyncWithGitHub) {
      debugPrint(
        'SyncService: Skipping GitHub sync (offline auth mode or missing token)',
      );
      _transitionTo(SyncPhase.idle);
      _emitSyncEvent('sync_skipped_no_auth', {
        'isNetworkAvailable': _isNetworkAvailable,
      });
      return true;
    }

    debugPrint('SyncService: Starting full sync...');
    final startedAt = DateTime.now();
    _isSyncing = true;
    _syncedIssuesCount = 0;
    _syncedProjectsCount = 0;
    _transitionTo(SyncPhase.syncingPendingOperations);

    try {
      // PROCESS PENDING OPERATIONS FIRST
      final pendingReplayResult = await _processPendingOperations();

      // Sync repositories and issues
      _transitionTo(SyncPhase.syncingIssues);
      final issuesSyncResult = await syncIssues(forceRefresh: forceRefresh);

      // Sync projects
      _transitionTo(SyncPhase.syncingProjects);
      await syncProjects(forceRefresh: forceRefresh);

      _lastSyncTime = DateTime.now();
      final hasPartialFailures =
          pendingReplayResult.failedOperations > 0 ||
          issuesSyncResult.repositoriesFailed > 0 ||
          issuesSyncResult.localIssuesFailed > 0;
      _transitionTo(hasPartialFailures ? SyncPhase.partial : SyncPhase.success);

      debugPrint('SyncService: Full sync completed successfully');
      debugPrint('  - Synced $_syncedIssuesCount issues');
      debugPrint('  - Synced $_syncedProjectsCount projects');

      // OFFLINE-FIRST: Refresh cached data after successful sync
      await _loadCachedData();

      // Record sync history
      await _recordSyncHistory(
        result: hasPartialFailures ? SyncResult.partial : SyncResult.success,
        issuesSynced: _syncedIssuesCount,
        projectsSynced: _syncedProjectsCount,
        operationsProcessed: pendingReplayResult.attemptedOperations,
        duration: DateTime.now().difference(startedAt),
        errorMessage: hasPartialFailures
            ? 'Partial sync: pending_failed=${pendingReplayResult.failedOperations}, '
                  'repo_failed=${issuesSyncResult.repositoriesFailed}, '
                  'local_failed=${issuesSyncResult.localIssuesFailed}'
            : null,
      );

      _emitSyncEvent('sync_all_completed', {
        'result': hasPartialFailures ? 'partial' : 'success',
        'pendingAttempted': pendingReplayResult.attemptedOperations,
        'pendingFailed': pendingReplayResult.failedOperations,
        'issuesSynced': _syncedIssuesCount,
        'projectsSynced': _syncedProjectsCount,
        'repositoriesFailed': issuesSyncResult.repositoriesFailed,
        'conflictsDetected': issuesSyncResult.conflictsDetected,
      });
      return true;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Sync failed: ${_safeError(e)}');
      _transitionTo(SyncPhase.error, errorMessage: e.toString());

      // Record failed sync
      await _recordSyncHistory(
        result: SyncResult.failed,
        issuesSynced: 0,
        projectsSynced: 0,
        operationsProcessed: 0,
        duration: DateTime.now().difference(startedAt),
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _canSyncWithGitHub() async {
    try {
      await _loadAuthSyncMode();
      if (_isOfflineAuthMode) {
        return false;
      }
      final authType = await SecureStorageService.read(key: 'auth_type');
      if (authType == 'offline') {
        return false;
      }
      return await SecureStorageService.hasToken();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, showSnackBar: false);
      debugPrint('SyncService: Failed to evaluate GitHub auth state: $e');
      return false;
    }
  }

  /// Sync issues from GitHub with local storage
  /// Uses "remote wins" strategy for conflicts
  Future<IssuesSyncResult> syncIssues({bool forceRefresh = false}) async {
    debugPrint('SyncService: Syncing issues...');

    try {
      // Get local-only issues (created offline)
      final localIssues = await _localStorage.getLocalIssues();
      debugPrint('SyncService: Found ${localIssues.length} local issues');

      // FIX (#34): Track synced local issues to prevent duplicate sync attempts
      final syncedLocalIssueIds = <String>{};

      // Fetch repositories
      final repos = await _githubApi.fetchMyRepositories(perPage: 30);
      debugPrint('SyncService: Fetched ${repos.length} repositories');

      int totalSynced = 0;
      int reposSucceeded = 0;
      int reposFailed = 0;
      int conflictsDetected = 0;
      int localIssuesSynced = 0;
      int localIssuesFailed = 0;

      // Fetch and sync issues for each repository
      for (final repo in repos) {
        final parts = repo.fullName.split('/');
        if (parts.length != 2) continue;

        final owner = parts[0];
        final repoName = parts[1];

        try {
          // Check if we need to sync this repo (unless force refresh)
          if (!forceRefresh) {
            final lastSync = await _localStorage.getSyncTime(repo.fullName);
            if (lastSync != null) {
              final diff = DateTime.now().difference(lastSync);
              // Skip if synced within last 5 minutes
              if (diff.inMinutes < 5) {
                debugPrint(
                  'SyncService: Skipping ${repo.fullName} (recently synced)',
                );
                continue;
              }
            }
          }

          // Fetch all issues (open + closed)
          final remoteIssues = await _githubApi.fetchIssues(
            owner,
            repoName,
            state: 'all',
          );
          debugPrint(
            'SyncService: Fetched ${remoteIssues.length} issues for ${repo.fullName}',
          );

          // FIX (#34): Filter out already-synced local issues before conflict resolution
          final unsyncedLocalIssues = localIssues.where((issue) {
            return issue.repoFullName == repo.fullName &&
                !syncedLocalIssueIds.contains(issue.id);
          }).toList();

          // Resolve conflicts and merge data
          final mergedIssues = await _resolveIssuesConflict(
            repo.fullName,
            remoteIssues,
            unsyncedLocalIssues,
          );
          conflictsDetected += _conflictDetector.getConflictCount();

          // Save synced issues to local storage
          await _localStorage.saveSyncedIssues(repo.fullName, mergedIssues);

          totalSynced += mergedIssues.length;
          reposSucceeded++;

          // FIX (#34): Sync local issues and track which ones were successfully synced
          final localSyncResult = await _syncLocalIssuesToGitHub(
            owner,
            repoName,
            unsyncedLocalIssues,
          );
          syncedLocalIssueIds.addAll(localSyncResult.syncedIssueIds);
          localIssuesSynced += localSyncResult.syncedIssueIds.length;
          localIssuesFailed += localSyncResult.failedCount;
        } catch (e, stackTrace) {
          AppErrorHandler.handle(e, stackTrace: stackTrace);
          debugPrint(
            'SyncService: Failed to sync ${repo.fullName}: ${_safeError(e)}',
          );
          reposFailed++;
          // Continue with next repo
        }
      }

      _syncedIssuesCount = totalSynced;
      debugPrint('SyncService: Issues sync completed ($totalSynced issues)');

      // FIX (#34): Notify UI to refresh vault repo after local issues are synced
      if (syncedLocalIssueIds.isNotEmpty && onLocalIssuesSynced != null) {
        debugPrint(
          'SyncService: Notifying UI to refresh vault (${syncedLocalIssueIds.length} issues synced)',
        );
        onLocalIssuesSynced!();
      }

      return IssuesSyncResult(
        syncedIssuesCount: totalSynced,
        repositoriesSucceeded: reposSucceeded,
        repositoriesFailed: reposFailed,
        conflictsDetected: conflictsDetected,
        localIssuesSynced: localIssuesSynced,
        localIssuesFailed: localIssuesFailed,
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Issues sync failed: ${_safeError(e)}');
      rethrow;
    }
  }

  /// Sync projects from GitHub
  Future<void> syncProjects({bool forceRefresh = false}) async {
    debugPrint('SyncService: Syncing projects...');

    try {
      // Check if we need to sync (unless force refresh)
      if (!forceRefresh) {
        final lastSync = await _localStorage.getProjectsSyncTime();
        if (lastSync != null) {
          final diff = DateTime.now().difference(lastSync);
          if (diff.inMinutes < 5) {
            debugPrint('SyncService: Skipping projects (recently synced)');
            return;
          }
        }
      }

      final projects = await _githubApi.fetchProjects(first: 30);
      debugPrint('SyncService: Fetched ${projects.length} projects');

      // Save projects to local storage
      await _localStorage.saveSyncedProjects(projects);
      _lastProjectsSyncTime = DateTime.now();

      _syncedProjectsCount = projects.length;
      debugPrint('SyncService: Projects sync completed');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Projects sync failed: $e');
      rethrow;
    }
  }

  /// Resolve conflicts between local and remote issues
  /// Strategy:
  /// - Remote issues always win for existing issues (by issue number)
  /// - Local-only issues (isLocalOnly=true) are kept for sync to GitHub
  /// - Merged list includes all remote issues + local-only issues
  /// - FIX (#34): Prevent duplication by detecting already-synced issues
  Future<List<IssueItem>> _resolveIssuesConflict(
    String repoFullName,
    List<IssueItem> remoteIssues,
    List<IssueItem> localIssues,
  ) async {
    debugPrint('SyncService: Resolving conflicts for $repoFullName');
    debugPrint(
      'SyncService: Remote issues: ${remoteIssues.length}, Local issues: ${localIssues.length}',
    );

    // Detect conflicts between local and remote issues
    final conflicts = _conflictDetector.detectConflicts(
      localIssues: localIssues,
      remoteIssues: remoteIssues,
    );

    if (conflicts.isNotEmpty) {
      debugPrint(
        'SyncService: Found ${conflicts.length} conflicts - using remote-wins strategy',
      );
      _emitSyncEvent('conflicts_detected', {
        'repo': repoFullName,
        'count': conflicts.length,
      });
      if (onConflictsDetected != null) {
        onConflictsDetected!(List<IssueConflict>.unmodifiable(conflicts));
      }
    }

    // Create a map of remote issues by number for quick lookup
    final remoteIssuesByNumber = <int, IssueItem>{};
    for (final issue in remoteIssues) {
      if (issue.number != null) {
        remoteIssuesByNumber[issue.number!] = issue;
      }
    }

    // FIX (#34): Create a map of remote issues by title for duplicate detection
    // This prevents offline-created issues from appearing twice after sync
    final remoteIssuesByTitle = <String, IssueItem>{};
    for (final issue in remoteIssues) {
      final titleKey = issue.title.toLowerCase().trim();
      remoteIssuesByTitle[titleKey] = issue;
    }

    // Find local-only issues that don't exist on GitHub yet
    final localOnlyIssues = <IssueItem>[];
    for (final issue in localIssues) {
      // Must be marked as local-only
      if (!issue.isLocalOnly) {
        continue;
      }

      bool duplicateDetected = false;

      // FIX (#34): Check if this local issue already exists on GitHub by number
      if (issue.number != null &&
          remoteIssuesByNumber.containsKey(issue.number)) {
        duplicateDetected = true;
        debugPrint(
          'SyncService: SKIP local issue with number ${issue.number} - already on GitHub',
        );
      }

      // FIX (#34): Check if this local issue matches a remote issue by title/body
      if (!duplicateDetected) {
        final titleKey = issue.title.toLowerCase().trim();
        if (remoteIssuesByTitle.containsKey(titleKey)) {
          final matchingRemote = remoteIssuesByTitle[titleKey];
          final bodyMatches =
              issue.bodyMarkdown == null ||
              matchingRemote?.bodyMarkdown == null ||
              issue.bodyMarkdown!.trim() ==
                  matchingRemote!.bodyMarkdown!.trim();

          if (bodyMatches) {
            duplicateDetected = true;
            debugPrint(
              'SyncService: SKIP local issue by title/body match - already on GitHub',
            );
          }
        }
      }

      if (duplicateDetected) {
        await _localStorage.removeLocalIssue(issue.id);
        continue;
      }

      localOnlyIssues.add(issue);
    }

    debugPrint(
      'SyncService: Found ${localOnlyIssues.length} local-only issues to sync',
    );

    // Merge: remote issues + local-only issues
    final merged = <IssueItem>[...remoteIssues, ...localOnlyIssues];

    // Remove duplicates (by id)
    final seen = <String>{};
    final unique = <IssueItem>[];
    for (final issue in merged) {
      if (!seen.contains(issue.id)) {
        seen.add(issue.id);
        unique.add(issue);
      }
    }

    debugPrint(
      'SyncService: Merged ${unique.length} total issues (remote: ${remoteIssues.length}, local-only: ${localOnlyIssues.length})',
    );
    return unique;
  }

  /// Get detected conflicts
  List<IssueConflict> getDetectedConflicts() {
    return _conflictDetector.getConflicts();
  }

  /// Get conflict count
  int getConflictCount() {
    return _conflictDetector.getConflictCount();
  }

  /// Sync local-only issues to GitHub
  /// After successful sync, removes them from local storage
  /// Returns list of successfully synced issue IDs
  Future<LocalIssuesSyncResult> _syncLocalIssuesToGitHub(
    String owner,
    String repo,
    List<IssueItem> localIssues,
  ) async {
    final localOnlyIssues = localIssues.where((i) => i.isLocalOnly).toList();
    final syncedIds = <String>[];
    int failedCount = 0;

    if (localOnlyIssues.isEmpty) {
      return const LocalIssuesSyncResult();
    }

    debugPrint(
      'SyncService: Syncing ${localOnlyIssues.length} local issues to GitHub',
    );

    for (final issue in localOnlyIssues) {
      try {
        // Create the issue on GitHub
        final createdIssue = await _githubApi.createIssue(
          owner,
          repo,
          title: issue.title,
          body: issue.bodyMarkdown,
          labels: issue.labels.isNotEmpty ? issue.labels : null,
          assignee: issue.assigneeLogin,
        );

        debugPrint(
          'SyncService: ✓ Created issue #${createdIssue.number} on GitHub',
        );

        await _localStorage.upsertSyncedIssue(
          '$owner/$repo',
          createdIssue.copyWith(repoFullName: '$owner/$repo'),
        );

        // Remove from local storage after successful sync
        await _localStorage.removeLocalIssue(issue.id);

        debugPrint('SyncService: Removed local issue ${issue.id}');

        // Track successfully synced issue
        syncedIds.add(issue.id);
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace);
        failedCount++;
        debugPrint('SyncService: Failed to sync local issue: ${_safeError(e)}');
        // Keep the local issue for next sync attempt - don't add to syncedIds
      }
    }

    return LocalIssuesSyncResult(
      syncedIssueIds: syncedIds,
      failedCount: failedCount,
    );
  }

  /// Get comprehensive sync status for UI
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'isNetworkAvailable': _isNetworkAvailable,
      'lastSyncTime': _lastSyncTime,
      'lastProjectsSyncTime': _lastProjectsSyncTime,
      'syncPhase': _syncPhase.name,
      'syncStatus': _syncStatus,
      'syncErrorMessage': _syncErrorMessage,
      'syncedIssuesCount': _syncedIssuesCount,
      'syncedProjectsCount': _syncedProjectsCount,
    };
  }

  /// Reset sync status
  void resetStatus() {
    _transitionTo(SyncPhase.idle);
  }

  /// Notify listeners of status changes
  void _notifyListeners() {
    debugPrint('SyncService: Status updated - $_syncStatus');
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Process pending operations queue
  Future<PendingReplayResult> _processPendingOperations() async {
    debugPrint('SyncService: Processing pending operations...');

    await _pendingOps.init();
    final operations = _pendingOps.getAllOperations()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (operations.isEmpty) {
      debugPrint('SyncService: No pending operations');
      return const PendingReplayResult();
    }

    debugPrint('SyncService: Found ${operations.length} pending operations');

    final retryHelper = RetryHelper(
      maxRetries: 5,
      initialDelay: const Duration(seconds: 1),
      maxDelay: const Duration(seconds: 16),
      backoffMultiplier: 2.0,
    );

    int attempted = 0;
    int succeeded = 0;
    int failed = 0;
    int skipped = 0;

    for (final operation in operations) {
      if (operation.isSyncing && operation.retryCount > 5) {
        debugPrint(
          'SyncService: Skipping operation ${operation.id} (max retries exceeded)',
        );
        skipped++;
        await _pendingOps.markAsFailed(
          operation.id,
          'Max retry threshold exceeded',
        );
        continue;
      }

      try {
        attempted++;
        await _pendingOps.markAsSyncing(operation.id);

        // Execute with exponential backoff retry
        await retryHelper.execute(
          () => _executeOperation(operation),
          operationName: 'Sync operation ${operation.type}',
        );

        await _pendingOps.markAsCompleted(operation.id);
        await _pendingOps.removeOperation(operation.id);
        debugPrint('SyncService: Completed operation ${operation.id}');
        succeeded++;
      } catch (e) {
        await _pendingOps.markAsFailed(operation.id, e.toString());
        debugPrint(
          'SyncService: Failed operation ${operation.id} after retries: ${_safeError(e)}',
        );
        failed++;
        // Keep in queue for next sync
      }
    }

    _emitSyncEvent('pending_replay_completed', {
      'total': operations.length,
      'attempted': attempted,
      'succeeded': succeeded,
      'failed': failed,
      'skipped': skipped,
    });

    return PendingReplayResult(
      totalOperations: operations.length,
      attemptedOperations: attempted,
      succeededOperations: succeeded,
      failedOperations: failed,
      skippedOperations: skipped,
    );
  }

  /// Execute a single pending operation
  Future<void> _executeOperation(PendingOperation operation) async {
    switch (operation.type) {
      case OperationType.createIssue:
        await _executeCreateIssue(operation);
        break;
      case OperationType.updateIssue:
        await _executeUpdateIssue(operation);
        break;
      case OperationType.closeIssue:
        await _executeCloseIssue(operation);
        break;
      case OperationType.reopenIssue:
        await _executeReopenIssue(operation);
        break;
      case OperationType.updateLabels:
        await _executeUpdateLabels(operation);
        break;
      case OperationType.updateAssignee:
        await _executeUpdateAssignee(operation);
        break;
      case OperationType.addComment:
        await _executeAddComment(operation);
        break;
      case OperationType.deleteComment:
        await _executeDeleteComment(operation);
        break;
    }
  }

  Future<void> _executeCreateIssue(PendingOperation operation) async {
    _ensureOperationHasRepoContext(operation);

    final createdIssue = await _githubApi.createIssue(
      operation.owner!,
      operation.repo!,
      title: operation.data['title'] as String,
      body: operation.data['body'] as String?,
      labels: _stringListFromData(operation.data['labels']),
      assignee: operation.data['assignee'] as String?,
    );

    if (operation.issueId != null && operation.issueId!.isNotEmpty) {
      await _localStorage.removeLocalIssue(operation.issueId!);
    }

    debugPrint(
      'SyncService: Created issue #${createdIssue.number} from queued operation',
    );
  }

  Future<void> _executeUpdateIssue(PendingOperation operation) async {
    _ensureOperationHasRepoAndIssueNumber(operation);

    await _githubApi.updateIssue(
      operation.owner!,
      operation.repo!,
      operation.issueNumber!,
      title: operation.data['title'] as String?,
      body: operation.data['body'] as String?,
      labels: _stringListFromData(operation.data['labels']),
      assignees: _stringListFromData(operation.data['assignees']),
    );

    debugPrint(
      'SyncService: Updated issue #${operation.issueNumber} from queued operation',
    );
  }

  Future<void> _executeCloseIssue(PendingOperation operation) async {
    _ensureOperationHasRepoAndIssueNumber(operation);

    await _githubApi.updateIssue(
      operation.owner!,
      operation.repo!,
      operation.issueNumber!,
      state: 'closed',
    );

    debugPrint(
      'SyncService: Closed issue #${operation.issueNumber} from queued operation',
    );
  }

  Future<void> _executeReopenIssue(PendingOperation operation) async {
    _ensureOperationHasRepoAndIssueNumber(operation);

    await _githubApi.updateIssue(
      operation.owner!,
      operation.repo!,
      operation.issueNumber!,
      state: 'open',
    );

    debugPrint(
      'SyncService: Reopened issue #${operation.issueNumber} from queued operation',
    );
  }

  Future<void> _executeUpdateLabels(PendingOperation operation) async {
    _ensureOperationHasRepoAndIssueNumber(operation);

    final labels = _stringListFromData(operation.data['labels']);

    await _githubApi.updateIssue(
      operation.owner!,
      operation.repo!,
      operation.issueNumber!,
      labels: labels,
    );

    debugPrint(
      'SyncService: Updated labels for issue #${operation.issueNumber} from queued operation',
    );
  }

  Future<void> _executeUpdateAssignee(PendingOperation operation) async {
    _ensureOperationHasRepoAndIssueNumber(operation);

    final assignee = operation.data['assignee'] as String?;
    final List<String> assignees = assignee != null ? [assignee] : [];

    await _githubApi.updateIssue(
      operation.owner!,
      operation.repo!,
      operation.issueNumber!,
      assignees: assignees,
    );

    debugPrint(
      'SyncService: Updated assignee for issue #${operation.issueNumber} from queued operation',
    );
  }

  Future<void> _executeAddComment(PendingOperation operation) async {
    _ensureOperationHasRepoAndIssueNumber(operation);

    final body = operation.data['body'] as String?;
    if (body == null || body.isEmpty) {
      throw StateError('Missing comment body for addComment operation');
    }

    await _githubApi.addIssueComment(
      operation.owner!,
      operation.repo!,
      operation.issueNumber!,
      body,
    );

    debugPrint(
      'SyncService: Added comment to issue #${operation.issueNumber} from queued operation',
    );
  }

  Future<void> _executeDeleteComment(PendingOperation operation) async {
    _ensureOperationHasRepoContext(operation);
    final commentId = operation.data['commentId'] as int?;
    if (commentId == null) {
      throw StateError('Missing commentId for deleteComment operation');
    }

    await _githubApi.deleteIssueComment(
      operation.owner!,
      operation.repo!,
      commentId,
    );

    debugPrint(
      'SyncService: Deleted comment #$commentId from queued operation',
    );
  }

  void _ensureOperationHasRepoContext(PendingOperation operation) {
    if (operation.owner == null || operation.repo == null) {
      throw StateError(
        'Missing owner/repo in operation ${operation.id} (${operation.type.name})',
      );
    }
  }

  void _ensureOperationHasRepoAndIssueNumber(PendingOperation operation) {
    _ensureOperationHasRepoContext(operation);
    if (operation.issueNumber == null) {
      throw StateError(
        'Missing issueNumber in operation ${operation.id} (${operation.type.name})',
      );
    }
  }

  void _transitionTo(SyncPhase phase, {String? errorMessage}) {
    _syncPhase = phase;
    _syncStatus = _statusFromPhase(phase);
    _syncErrorMessage = errorMessage == null ? null : _safeError(errorMessage);
    _notifyListeners();
  }

  String _statusFromPhase(SyncPhase phase) {
    switch (phase) {
      case SyncPhase.idle:
      case SyncPhase.queued:
        return 'idle';
      case SyncPhase.syncingPendingOperations:
      case SyncPhase.syncingIssues:
      case SyncPhase.syncingProjects:
        return 'syncing';
      case SyncPhase.success:
        return 'success';
      case SyncPhase.partial:
        return 'partial';
      case SyncPhase.error:
        return 'error';
    }
  }

  String _safeError(Object error) {
    final raw = error.toString();
    return raw
        .replaceAll(
          RegExp(r'token\s+[A-Za-z0-9_.-]+', caseSensitive: false),
          'token [REDACTED]',
        )
        .replaceAll(
          RegExp(r'authorization:\s*[^\s,]+', caseSensitive: false),
          'authorization: [REDACTED]',
        );
  }

  List<String>? _stringListFromData(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is List<String>) {
      return value;
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return null;
  }

  void _emitSyncEvent(String event, Map<String, Object?> details) {
    final safeDetails = Map<String, Object?>.from(details)
      ..removeWhere((key, _) {
        final normalized = key.toLowerCase();
        return normalized.contains('token') ||
            normalized.contains('secret') ||
            normalized.contains('authorization') ||
            normalized.contains('body');
      });
    debugPrint('SyncService[event=$event]: $safeDetails');
    onSyncEvent?.call(event, safeDetails);
  }
}
