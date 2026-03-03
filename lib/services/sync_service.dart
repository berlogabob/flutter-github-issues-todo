import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive/hive.dart';
import 'local_storage_service.dart';
import 'github_api_service.dart';
import 'pending_operations_service.dart';
import 'conflict_detection_service.dart';
import '../utils/app_error_handler.dart';
import '../utils/retry_helper.dart';
import '../models/issue_item.dart';
import '../models/pending_operation.dart';
import '../models/sync_history_entry.dart';

part 'sync_service.g.dart';

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
  DateTime? _lastSyncTime;
  DateTime? _lastProjectsSyncTime;
  String _syncStatus = 'idle'; // idle, syncing, success, error
  String? _syncErrorMessage;
  int _syncedIssuesCount = 0;
  int _syncedProjectsCount = 0;

  // Callback for when sync is needed (has local issues + internet)
  Function()? onSyncNeeded;

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
  void init() {
    debugPrint('SyncService: Initializing...');
    _setupConnectivityListener();
    _checkNetworkStatus();
    _loadLastSyncTimes();
    _initHistory();
  }

  /// Initialize sync history
  Future<void> _initHistory() async {
    try {
      _historyBox = await Hive.openBox(_historyBoxName);
      _loadSyncHistory();
      debugPrint('SyncService: History initialized with ${_syncHistory.length} entries');
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
      final entry = SyncHistoryEntry(
        id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        result: result,
        issuesSynced: issuesSynced,
        projectsSynced: projectsSynced,
        operationsProcessed: operationsProcessed,
        duration: duration,
        errorMessage: errorMessage,
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

      // Check if there are local issues to sync
      _checkAndNotifyLocalIssues();
    }
  }

  /// Check if there are local-only issues and notify via callback
  Future<void> _checkAndNotifyLocalIssues() async {
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
    _syncStatus = 'syncing';
    _notifyListeners();

    try {
      final localIssues = await _localStorage.getLocalIssues();
      await _syncLocalIssuesToGitHub(owner, repo, localIssues);

      _syncStatus = 'success';
      _notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Failed to sync local issues: $e');
      _syncStatus = 'error';
      _syncErrorMessage = e.toString();
      _notifyListeners();
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
      // PROCESS PENDING OPERATIONS FIRST
      await _processPendingOperations();

      // Sync repositories and issues
      await syncIssues(forceRefresh: forceRefresh);

      // Sync projects
      await syncProjects(forceRefresh: forceRefresh);

      _lastSyncTime = DateTime.now();
      _syncStatus = 'success';

      debugPrint('SyncService: Full sync completed successfully');
      debugPrint('  - Synced $_syncedIssuesCount issues');
      debugPrint('  - Synced $_syncedProjectsCount projects');

      // Record sync history
      await _recordSyncHistory(
        result: SyncResult.success,
        issuesSynced: _syncedIssuesCount,
        projectsSynced: _syncedProjectsCount,
        operationsProcessed: _pendingOps.getAllOperations().length,
        duration: DateTime.now().difference(_lastSyncTime ?? DateTime.now()),
      );

      _notifyListeners();
      return true;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('SyncService: Sync failed: $e');
      _syncStatus = 'error';
      _syncErrorMessage = e.toString();

      // Record failed sync
      await _recordSyncHistory(
        result: SyncResult.failed,
        issuesSynced: 0,
        projectsSynced: 0,
        operationsProcessed: 0,
        duration: Duration.zero,
        errorMessage: e.toString(),
      );

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
        } catch (e, stackTrace) {
          AppErrorHandler.handle(e, stackTrace: stackTrace);
          debugPrint('SyncService: Failed to sync ${repo.fullName}: $e');
          // Continue with next repo
        }
      }

      _syncedIssuesCount = totalSynced;
      debugPrint('SyncService: Issues sync completed ($totalSynced issues)');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
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
  Future<List<IssueItem>> _resolveIssuesConflict(
    String repoFullName,
    List<IssueItem> remoteIssues,
    List<IssueItem> localIssues,
  ) async {
    debugPrint('SyncService: Resolving conflicts for $repoFullName');

    // Detect conflicts between local and remote issues
    final conflicts = _conflictDetector.detectConflicts(
      localIssues: localIssues,
      remoteIssues: remoteIssues,
    );

    if (conflicts.isNotEmpty) {
      debugPrint(
        'SyncService: Found ${conflicts.length} conflicts - using remote-wins strategy',
      );
      // For MVP, we use "remote wins" strategy silently
      // Future enhancement: Show conflict resolution dialog to user
    }

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
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace);
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
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Process pending operations queue
  Future<void> _processPendingOperations() async {
    debugPrint('SyncService: Processing pending operations...');

    await _pendingOps.init();
    final operations = _pendingOps.getAllOperations();

    if (operations.isEmpty) {
      debugPrint('SyncService: No pending operations');
      return;
    }

    debugPrint('SyncService: Found ${operations.length} pending operations');

    final retryHelper = RetryHelper(
      maxRetries: 5,
      initialDelay: const Duration(seconds: 1),
      maxDelay: const Duration(seconds: 16),
      backoffMultiplier: 2.0,
    );

    for (final operation in operations) {
      if (operation.isSyncing && operation.retryCount > 5) {
        debugPrint(
          'SyncService: Skipping operation ${operation.id} (max retries exceeded)',
        );
        continue;
      }

      try {
        await _pendingOps.markAsSyncing(operation.id);
        
        // Execute with exponential backoff retry
        await retryHelper.execute(
          () => _executeOperation(operation),
          operationName: 'Sync operation ${operation.type}',
        );
        
        await _pendingOps.markAsCompleted(operation.id);
        await _pendingOps.removeOperation(operation.id);
        debugPrint('SyncService: Completed operation ${operation.id}');
      } catch (e) {
        await _pendingOps.markAsFailed(operation.id, e.toString());
        debugPrint('SyncService: Failed operation ${operation.id} after retries: $e');
        // Keep in queue for next sync
      }
    }
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
      default:
        debugPrint('SyncService: Unknown operation type: ${operation.type}');
    }
  }

  Future<void> _executeCreateIssue(PendingOperation operation) async {
    if (operation.owner == null || operation.repo == null) return;

    final createdIssue = await _githubApi.createIssue(
      operation.owner!,
      operation.repo!,
      title: operation.data['title'] as String,
      body: operation.data['body'] as String?,
      labels: operation.data['labels'] as List<String>?,
      assignee: operation.data['assignee'] as String?,
    );

    debugPrint(
      'SyncService: Created issue #${createdIssue.number} from queued operation',
    );
  }

  Future<void> _executeUpdateIssue(PendingOperation operation) async {
    if (operation.owner == null ||
        operation.repo == null ||
        operation.issueNumber == null)
      return;

    await _githubApi.updateIssue(
      operation.owner!,
      operation.repo!,
      operation.issueNumber!,
      title: operation.data['title'] as String?,
      body: operation.data['body'] as String?,
      labels: operation.data['labels'] as List<String>?,
    );

    debugPrint(
      'SyncService: Updated issue #${operation.issueNumber} from queued operation',
    );
  }

  Future<void> _executeCloseIssue(PendingOperation operation) async {
    if (operation.owner == null ||
        operation.repo == null ||
        operation.issueNumber == null)
      return;

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
    if (operation.owner == null ||
        operation.repo == null ||
        operation.issueNumber == null)
      return;

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
    if (operation.owner == null ||
        operation.repo == null ||
        operation.issueNumber == null)
      return;

    final labels = operation.data['labels'] as List<String>?;

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
    if (operation.owner == null ||
        operation.repo == null ||
        operation.issueNumber == null)
      return;

    final assignee = operation.data['assignee'] as String?;
    final List<String>? assignees = assignee != null ? [assignee] : null;

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
    if (operation.owner == null ||
        operation.repo == null ||
        operation.issueNumber == null)
      return;

    final body = operation.data['body'] as String?;
    if (body == null || body.isEmpty) return;

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
}

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final service = SyncService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
}
