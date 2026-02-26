import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_storage_service.dart';
import 'github_api_service.dart';
import '../models/issue_item.dart';

/// Sync Service - Handles synchronization between local storage and GitHub
///
/// Features:
/// - Manual sync via syncAll()
/// - Auto-sync on network availability
/// - Conflict resolution (remote wins for existing, local wins for new)
/// - Sync status tracking
/// - Background sync support
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();

  // Sync status
  bool _isSyncing = false;
  bool _isNetworkAvailable = false;
  DateTime? _lastSyncTime;
  DateTime? _lastProjectsSyncTime;
  String _syncStatus = 'idle'; // idle, syncing, success, error
  String? _syncErrorMessage;
  int _syncedIssuesCount = 0;
  int _syncedProjectsCount = 0;

  // Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Auto-sync debounce
  Timer? _autoSyncTimer;

  // Getters
  bool get isSyncing => _isSyncing;
  bool get isNetworkAvailable => _isNetworkAvailable;
  DateTime? get lastSyncTime => _lastSyncTime;
  DateTime? get lastProjectsSyncTime => _lastProjectsSyncTime;
  String get syncStatus => _syncStatus;
  String? get syncErrorMessage => _syncErrorMessage;
  int get syncedIssuesCount => _syncedIssuesCount;
  int get syncedProjectsCount => _syncedProjectsCount;

  /// Initialize sync service
  void init() {
    debugPrint('SyncService: Initializing...');
    _setupConnectivityListener();
    _checkNetworkStatus();
    _loadLastSyncTimes();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
  }

  /// Load last sync times from local storage
  Future<void> _loadLastSyncTimes() async {
    _lastSyncTime = await _localStorage.getProjectsSyncTime();
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

    // Auto-sync when network becomes available
    if (_isNetworkAvailable && !wasAvailable) {
      debugPrint('SyncService: Network restored, triggering auto-sync');
      _triggerAutoSync();
    }
  }

  /// Check current network status
  Future<void> _checkNetworkStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateNetworkStatus(results);
    } catch (e) {
      debugPrint('SyncService: Failed to check network status: $e');
      _isNetworkAvailable = false;
    }
  }

  /// Trigger auto-sync when network becomes available (with debounce)
  Future<void> _triggerAutoSync() async {
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
    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress');
      return false;
    }

    if (!_isNetworkAvailable) {
      debugPrint('SyncService: No network available');
      _syncStatus = 'error';
      _syncErrorMessage = 'No internet connection';
      _notifyListeners();
      return false;
    }

    debugPrint('SyncService: Starting full sync...');
    _isSyncing = true;
    _syncStatus = 'syncing';
    _syncErrorMessage = null;
    _syncedIssuesCount = 0;
    _syncedProjectsCount = 0;
    _notifyListeners();

    try {
      // Sync repositories and issues
      await syncIssues(forceRefresh: forceRefresh);

      // Sync projects
      await syncProjects(forceRefresh: forceRefresh);

      _lastSyncTime = DateTime.now();
      _syncStatus = 'success';

      debugPrint('SyncService: Full sync completed successfully');
      debugPrint('  - Synced $_syncedIssuesCount issues');
      debugPrint('  - Synced $_syncedProjectsCount projects');

      _notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SyncService: Sync failed: $e');
      _syncStatus = 'error';
      _syncErrorMessage = e.toString();
      _notifyListeners();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync issues from GitHub with local storage
  /// Uses "remote wins" strategy for conflicts
  Future<void> syncIssues({bool forceRefresh = false}) async {
    debugPrint('SyncService: Syncing issues...');

    try {
      // Get local-only issues (created offline)
      final localIssues = await _localStorage.getLocalIssues();
      debugPrint('SyncService: Found ${localIssues.length} local issues');

      // Fetch repositories
      final repos = await _githubApi.fetchMyRepositories(perPage: 30);
      debugPrint('SyncService: Fetched ${repos.length} repositories');

      int totalSynced = 0;

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

          // Resolve conflicts and merge data
          final mergedIssues = await _resolveIssuesConflict(
            repo.fullName,
            remoteIssues,
            localIssues,
          );

          // Save synced issues to local storage
          await _localStorage.saveSyncedIssues(repo.fullName, mergedIssues);

          totalSynced += mergedIssues.length;

          // Remove synced local-only issues
          await _syncLocalIssuesToGitHub(owner, repoName, localIssues);
        } catch (e) {
          debugPrint('SyncService: Failed to sync ${repo.fullName}: $e');
          // Continue with next repo
        }
      }

      _syncedIssuesCount = totalSynced;
      debugPrint('SyncService: Issues sync completed ($totalSynced issues)');
    } catch (e) {
      debugPrint('SyncService: Issues sync failed: $e');
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
    } catch (e) {
      debugPrint('SyncService: Projects sync failed: $e');
      rethrow;
    }
  }

  /// Resolve conflicts between local and remote issues
  /// Strategy:
  /// - Remote issues always win for existing issues (by issue number)
  /// - Local-only issues (isLocalOnly=true) are kept for sync to GitHub
  /// - Merged list includes all remote issues + local-only issues
  Future<List<IssueItem>> _resolveIssuesConflict(
    String repoFullName,
    List<IssueItem> remoteIssues,
    List<IssueItem> localIssues,
  ) async {
    debugPrint('SyncService: Resolving conflicts for $repoFullName');

    // Create a map of remote issues by number for quick lookup
    final remoteIssuesByNumber = <int, IssueItem>{};
    for (final issue in remoteIssues) {
      if (issue.number != null) {
        remoteIssuesByNumber[issue.number!] = issue;
      }
    }

    // Find local-only issues that don't exist on GitHub yet
    final localOnlyIssues = localIssues.where((issue) {
      // Keep if it's marked as local-only
      if (issue.isLocalOnly) return true;

      // Keep if it doesn't have a GitHub number yet
      if (issue.number == null) return true;

      return false;
    }).toList();

    debugPrint(
      'SyncService: Found ${localOnlyIssues.length} local-only issues',
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

    debugPrint('SyncService: Merged ${unique.length} total issues');
    return unique;
  }

  /// Sync local-only issues to GitHub
  /// After successful sync, removes them from local storage
  Future<void> _syncLocalIssuesToGitHub(
    String owner,
    String repo,
    List<IssueItem> localIssues,
  ) async {
    final localOnlyIssues = localIssues.where((i) => i.isLocalOnly).toList();

    if (localOnlyIssues.isEmpty) {
      return;
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
        );

        debugPrint(
          'SyncService: ✓ Created issue #${createdIssue.number} on GitHub',
        );

        // Remove from local storage after successful sync
        await _localStorage.removeLocalIssue(issue.id);

        debugPrint('SyncService: Removed local issue ${issue.id}');
      } catch (e) {
        debugPrint(
          'SyncService: Failed to sync local issue "${issue.title}": $e',
        );
        // Keep the local issue for next sync attempt
      }
    }
  }

  /// Get comprehensive sync status for UI
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'isNetworkAvailable': _isNetworkAvailable,
      'lastSyncTime': _lastSyncTime,
      'lastProjectsSyncTime': _lastProjectsSyncTime,
      'syncStatus': _syncStatus,
      'syncErrorMessage': _syncErrorMessage,
      'syncedIssuesCount': _syncedIssuesCount,
      'syncedProjectsCount': _syncedProjectsCount,
    };
  }

  /// Reset sync status
  void resetStatus() {
    _syncStatus = 'idle';
    _syncErrorMessage = null;
    _notifyListeners();
  }

  /// Notify listeners of status changes
  void _notifyListeners() {
    debugPrint('SyncService: Status updated - $_syncStatus');
    // In production, use Riverpod or other state management
  }
}
