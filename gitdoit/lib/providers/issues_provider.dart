import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/issue.dart';
import '../models/repository_config.dart';
import '../services/github_service.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

/// Repository configuration model (legacy - kept for backward compatibility)
class Repository {
  final String owner;
  final String name;

  Repository({required this.owner, required this.name});

  /// Get full repository name in format 'owner/name'
  String get fullName => '$owner/$name';
}

/// Issues Provider - Manages GitHub issues state
///
/// Handles:
/// - Fetching issues from GitHub
/// - Local caching with Hive
/// - Filtering and sorting
/// - Offline/online sync
/// - Auto-sync on startup
class IssuesProvider extends ChangeNotifier {
  final GitHubService _githubService = GitHubService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Hive box for local caching
  late Box<Issue> _issuesBox;

  // State
  List<Issue> _issues = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'open'; // 'open', 'closed', 'all'
  String _sortBy = 'created'; // 'created', 'updated', 'comments'
  bool _isOffline = false;

  // Sync state for auto-sync on startup
  bool _isSyncing = false;
  bool _hasSynced = false;
  DateTime? _lastSyncTime;
  bool _syncError = false;

  // Repository configuration (should come from settings)
  String _owner = '';
  String _repo = '';

  // Multi-repository support
  final MultiRepositoryConfig _multiRepoConfig = MultiRepositoryConfig();

  // Per-repository issues storage
  final Map<String, List<Issue>> _repoIssues = {};

  // Collapsed repositories state (for UI toggle)
  final Set<String> _collapsedRepos = {};

  // Connectivity stream subscription
  StreamSubscription<bool>? _connectivitySubscription;

  // Getters
  List<Issue> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  String get sortBy => _sortBy;
  bool get isOffline => _isOffline;
  bool get isSyncing => _isSyncing;
  bool get hasSynced => _hasSynced;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get hasIssues => _issues.isNotEmpty;
  int get openCount => _issues.where((i) => i.isOpen).length;
  int get closedCount => _issues.where((i) => i.isClosed).length;
  String get owner => _owner;
  String get repo => _repo;
  bool get syncError => _syncError;

  /// Get total issue count in cache
  int get cachedIssueCount => _issuesBox.length;

  /// Get last sync time formatted as string
  String? get lastSyncTimeFormatted {
    if (_lastSyncTime == null) return null;
    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Get cache size in bytes (estimated)
  Future<int> getCacheSizeBytes() async {
    try {
      // Estimate cache size based on number of issues
      // Average issue size is approximately 1-2KB
      final avgIssueSize = 1500; // bytes
      return _issuesBox.length * avgIssueSize;
    } catch (_) {
      return 0;
    }
  }

  /// Get cache size formatted as human-readable string
  Future<String> getCacheSizeFormatted() async {
    try {
      final bytes = await getCacheSizeBytes();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final cacheSize = await getCacheSizeBytes();
      return {
        'issueCount': _issuesBox.length,
        'cacheSizeBytes': cacheSize,
        'cacheSizeFormatted': await getCacheSizeFormatted(),
        'lastSyncTime': _lastSyncTime,
        'lastSyncTimeFormatted': lastSyncTimeFormatted,
        'repositoryCount': _multiRepoConfig.repositories.length,
        'isOffline': _isOffline,
      };
    } catch (_) {
      return {
        'issueCount': 0,
        'cacheSizeBytes': 0,
        'cacheSizeFormatted': 'Unknown',
        'lastSyncTime': null,
        'lastSyncTimeFormatted': 'Never',
        'repositoryCount': 0,
        'isOffline': _isOffline,
      };
    }
  }

  /// Check if repository is configured
  bool get hasRepoConfig => _owner.isNotEmpty && _repo.isNotEmpty;

  Repository? get repository {
    if (_owner.isEmpty || _repo.isEmpty) return null;
    return Repository(owner: _owner, name: _repo);
  }

  // Multi-repository getters
  /// Get multi-repository configuration
  MultiRepositoryConfig get multiRepoConfig => _multiRepoConfig;

  /// Get list of all configured repositories
  List<RepositoryConfig> get repositories => _multiRepoConfig.repositories;

  /// Get enabled repositories only
  List<RepositoryConfig> get enabledRepositories =>
      _multiRepoConfig.enabledRepositories;

  /// Get the default repository (explicitly set via setRepository)
  ///
  /// The default repo is the one set via setRepository() method,
  /// stored in _owner/_repo fields. NOT just the first in the list.
  RepositoryConfig? get defaultRepo {
    if (_owner.isEmpty || _repo.isEmpty) {
      // No explicit default set, return first configured repo if any
      final allRepos = _multiRepoConfig.repositories;
      return allRepos.isNotEmpty ? allRepos.first : null;
    }
    // Find the repo that matches the explicitly set _owner/_repo
    final defaultFullName = '$_owner/$_repo';
    final allRepos = _multiRepoConfig.repositories;
    return allRepos.firstWhere(
      (r) => r.fullName == defaultFullName,
      orElse: () => allRepos.isNotEmpty
          ? allRepos.first
          : RepositoryConfig(owner: _owner, name: _repo),
    );
  }

  /// Get selected repositories (all configured repos excluding default)
  ///
  /// Returns repositories that were explicitly added by the user,
  /// excluding the default repo (which is set via setRepository).
  List<RepositoryConfig> get selectedRepos {
    final allRepos = _multiRepoConfig.repositories;
    final defaultRepo = this.defaultRepo;
    if (allRepos.isEmpty) return [];
    // Return all repos except the default one
    return allRepos.where((r) => r.fullName != defaultRepo?.fullName).toList();
  }

  /// Get issues for a specific repository
  List<Issue> getRepoIssues(String repoFullName) {
    return _repoIssues[repoFullName] ?? [];
  }

  /// Get filtered issues for a specific repository
  ///
  /// Applies the current filter state ('open', 'closed', 'all')
  /// to the issues of the specified repository.
  List<Issue> getFilteredRepoIssues(String repoFullName) {
    var issues = _repoIssues[repoFullName] ?? [];
    
    // Apply filter
    if (_filter == 'open') {
      issues = issues.where((i) => i.isOpen).toList();
    } else if (_filter == 'closed') {
      issues = issues.where((i) => i.isClosed).toList();
    }
    
    return issues;
  }

  /// Get all issues across all repositories
  List<Issue> get allIssues {
    final all = <Issue>[];
    for (final issues in _repoIssues.values) {
      all.addAll(issues);
    }
    return all;
  }

  /// Check if multiple repositories are enabled
  bool get hasMultipleRepos => _multiRepoConfig.hasMultipleRepos;

  /// Check if a repository is collapsed in UI
  bool isRepoCollapsed(String fullName) => _collapsedRepos.contains(fullName);

  /// Toggle repository collapsed state
  void toggleRepoCollapsed(String fullName) {
    if (_collapsedRepos.contains(fullName)) {
      _collapsedRepos.remove(fullName);
    } else {
      _collapsedRepos.add(fullName);
    }
    notifyListeners();
  }

  /// Set repository collapsed state
  void setRepoCollapsed(String fullName, bool collapsed) {
    if (collapsed) {
      _collapsedRepos.add(fullName);
    } else {
      _collapsedRepos.remove(fullName);
    }
    notifyListeners();
  }

  /// Expand all repositories
  void expandAllRepos() {
    _collapsedRepos.clear();
    notifyListeners();
  }

  /// Collapse all repositories
  void collapseAllRepos() {
    _collapsedRepos.addAll(
      _multiRepoConfig.repositories.map((r) => r.fullName),
    );
    notifyListeners();
  }

  /// Initialize - update logger with repository state
  IssuesProvider() {
    Logger.setCurrentRepository(null, null);
  }

  /// Initialize Hive for local caching and auto-sync issues
  ///
  /// Auto-sync flow:
  /// 1. Initialize Hive storage
  /// 2. Load repository configuration
  /// 3. Load multi-repository configuration
  /// 4. Load cached issues (displayed immediately)
  /// 5. Check connectivity
  /// 6. If online + repo configured: fetch from GitHub and merge
  Future<void> initialize() async {
    final metric = Logger.startMetric('initialize', 'Issues');
    Logger.i('Initializing IssuesProvider with auto-sync', context: 'Issues');

    try {
      // Step 1: Initialize Hive
      _issuesBox = await Hive.openBox<Issue>('issues');
      Logger.i('Hive box opened', context: 'Issues');

      // Step 2: Load repository configuration (legacy single-repo)
      await _loadRepositoryConfig();

      // Step 3: Load multi-repository configuration
      await _loadMultiRepositoryConfig();

      // Step 4: Load cached issues immediately (for instant UI display)
      await _loadFromCache();

      // Step 5: Initialize connectivity service
      await _connectivityService.initialize();
      _isOffline = !_connectivityService.isOnline;
      Logger.i(
        'Connectivity initialized: online=${_connectivityService.isOnline}',
        context: 'Issues',
      );

      // Step 5: Listen to connectivity changes for instant offline/online detection
      _connectivitySubscription = _connectivityService.connectivityStream
          .listen(
            (isOnline) async {
              Logger.d(
                'Connectivity stream: isOnline=$isOnline',
                context: 'Issues',
              );
              _isOffline = !isOnline;
              // Force immediate notify for instant cloud icon update
              notifyListeners();
              Logger.d(
                'Cloud icon state updated: offline=$_isOffline',
                context: 'Issues',
              );
            },
            onError: (error, stackTrace) {
              Logger.e(
                'Connectivity stream error',
                error: error,
                stackTrace: stackTrace,
                context: 'Issues',
              );
              // On stream error, force offline state immediately
              _isOffline = true;
              notifyListeners();
            },
          );

      // Step 6: Auto-sync if online and repository configured
      if (_connectivityService.isOnline &&
          _owner.isNotEmpty &&
          _repo.isNotEmpty) {
        Logger.i('Starting auto-sync: $_owner/$_repo', context: 'Issues');
        Logger.trackJourney(
          JourneyEventType.systemAction,
          'Issues',
          'auto_sync_started',
          metadata: {'repository': '$_owner/$_repo'},
        );
        // Don't await - let sync happen in background while UI shows cached data
        _autoSyncIssues();
      } else {
        Logger.d(
          'Skipping auto-sync: offline=${!_connectivityService.isOnline}, repo_configured=${_owner.isNotEmpty}',
          context: 'Issues',
        );
        _hasSynced = true; // Mark as synced (nothing to sync)
      }

      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to initialize IssuesProvider',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _error = 'Failed to initialize local storage';
      _hasSynced = true; // Mark as synced to avoid infinite retry
      notifyListeners();
    }
  }

  /// Auto-sync issues from GitHub
  ///
  /// Fetches remote issues and merges with local cache.
  /// Prefers remote data but keeps local-only issues.
  ///
  /// For multi-repo: syncs all configured repositories.
  Future<void> _autoSyncIssues() async {
    if (_isSyncing) {
      Logger.d('Auto-sync already in progress', context: 'Issues');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    final metric = Logger.startMetric('autoSyncIssues', 'Issues');
    Logger.d('Auto-syncing issues', context: 'Issues');

    try {
      // Sync all configured repositories
      await _syncAllRepositories();

      // Update main issues list with default repo issues (for backward compatibility)
      if (_owner.isNotEmpty && _repo.isNotEmpty) {
        final defaultRepoFullName = '$_owner/$_repo';
        _issues = _repoIssues[defaultRepoFullName] ?? [];
      }

      _error = null;
      _lastSyncTime = DateTime.now();
      _hasSynced = true;

      Logger.i(
        'Auto-sync complete: ${_issues.length} issues',
        context: 'Issues',
      );
      Logger.trackJourney(
        JourneyEventType.systemAction,
        'Issues',
        'auto_sync_completed',
        metadata: {
          'repository': '$_owner/$_repo',
          'total_issues': allIssues.length,
          'sync_time': _lastSyncTime!.toIso8601String(),
        },
      );
      metric.complete(success: true);
      _syncError = false; // Clear any previous sync error

      // Cache merged results
      await _saveToCache();
    } on Exception catch (e, stackTrace) {
      Logger.e(
        'Auto-sync failed',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _syncError = true; // Mark sync error
      _hasSynced = true; // Mark as synced (tried but failed)
      // Keep cached data - don't clear on sync failure
      // Note: _isOffline is managed by connectivity stream, not manually set here
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync issues from all configured repositories
  Future<void> _syncAllRepositories() async {
    final repos = _multiRepoConfig.repositories;
    if (repos.isEmpty) {
      Logger.d('No repositories configured for sync', context: 'Issues');
      return;
    }

    for (final repo in repos) {
      try {
        Logger.d('Syncing repository: ${repo.fullName}', context: 'Issues');

        final remoteIssues = await _githubService.fetchIssues(
          owner: repo.owner,
          repo: repo.name,
          state: 'all',
        );

        // Merge with existing issues for this repo
        final existingIssues = _repoIssues[repo.fullName] ?? [];
        _repoIssues[repo.fullName] = _mergeIssuesForRepo(
          existingIssues,
          remoteIssues,
        );

        // Update repo sync state
        _multiRepoConfig.updateSyncState(
          repo.fullName,
          lastSynced: DateTime.now(),
          issueCount: remoteIssues.length,
        );

        Logger.i(
          'Synced ${remoteIssues.length} issues for ${repo.fullName}',
          context: 'Issues',
        );
      } catch (e, stackTrace) {
        Logger.e(
          'Failed to sync ${repo.fullName}',
          error: e,
          stackTrace: stackTrace,
          context: 'Issues',
        );
      }
    }
  }

  /// Merge issues for a specific repository
  List<Issue> _mergeIssuesForRepo(
    List<Issue> existingIssues,
    List<Issue> remoteIssues,
  ) {
    final remoteMap = {for (var issue in remoteIssues) issue.number: issue};
    final merged = <Issue>[...remoteIssues];

    for (final localIssue in existingIssues) {
      if (!remoteMap.containsKey(localIssue.number)) {
        merged.add(localIssue);
      }
    }

    // Sort by updated date (most recent first)
    merged.sort((a, b) {
      final aUpdated = a.updatedAt ?? a.createdAt;
      final bUpdated = b.updatedAt ?? b.createdAt;
      return bUpdated.compareTo(aUpdated);
    });

    return merged;
  }

  /// Load repository configuration from secure storage
  Future<void> _loadRepositoryConfig() async {
    try {
      final owner = await _storage.read(key: 'github_repository_owner');
      final repo = await _storage.read(key: 'github_repository_name');

      if (owner != null &&
          owner.isNotEmpty &&
          repo != null &&
          repo.isNotEmpty) {
        _owner = owner;
        _repo = repo;
        Logger.setCurrentRepository(_owner, _repo);
        Logger.i('Loaded repository config: $owner/$repo', context: 'Issues');
        Logger.trackJourney(
          JourneyEventType.configChange,
          'Settings',
          'repository_config_loaded',
          metadata: {'repository': '$owner/$repo'},
        );
      } else {
        Logger.d('No repository config found', context: 'Issues');
      }
    } catch (e, stackTrace) {
      Logger.w(
        'Failed to load repository config',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
    }
  }

  /// Save repository configuration to secure storage
  Future<void> _saveRepositoryConfig() async {
    try {
      await _storage.write(key: 'github_repository_owner', value: _owner);
      await _storage.write(key: 'github_repository_name', value: _repo);
      Logger.setCurrentRepository(_owner, _repo);
      Logger.i('Saved repository config: $_owner/$_repo', context: 'Issues');
      Logger.trackJourney(
        JourneyEventType.configChange,
        'Settings',
        'repository_config_saved',
        metadata: {'repository': '$_owner/$_repo'},
      );
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to save repository config',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
    }
  }

  /// Set repository configuration
  ///
  /// [autoRefresh] if true, automatically refreshes issues after saving config
  Future<void> setRepository(
    String owner,
    String repo, {
    bool autoRefresh = false,
  }) async {
    Logger.i('Setting repository: $owner/$repo', context: 'Issues');
    _owner = owner;
    _repo = repo;
    await _saveRepositoryConfig();

    // Also add to multi-repo config
    addRepository(owner, repo);
    await _saveMultiRepositoryConfig();

    Logger.trackJourney(
      JourneyEventType.configChange,
      'Settings',
      'repository_config_changed',
      metadata: {'repository': '$owner/$repo'},
    );

    // Auto-refresh issues after configuration if requested
    if (autoRefresh) {
      Logger.d(
        'Auto-refreshing issues after repository config',
        context: 'Issues',
      );
      Logger.trackJourney(
        JourneyEventType.systemAction,
        'Settings',
        'issues_refresh_after_config',
        metadata: {'repository': '$owner/$repo'},
      );
      await loadIssues();
    }
  }

  // Multi-repository management methods

  /// Add a repository to the multi-repo configuration
  void addRepository(String owner, String name) {
    _multiRepoConfig.addRepository(owner, name);
    Logger.i('Added repository: $owner/$name', context: 'Issues');
    Logger.trackJourney(
      JourneyEventType.configChange,
      'Settings',
      'repository_added',
      metadata: {'repository': '$owner/$name'},
    );
  }

  /// Remove a repository from the multi-repo configuration
  void removeRepository(String fullName) {
    _multiRepoConfig.removeRepository(fullName);
    _collapsedRepos.remove(fullName);
    Logger.i('Removed repository: $fullName', context: 'Issues');
    Logger.trackJourney(
      JourneyEventType.configChange,
      'Settings',
      'repository_removed',
      metadata: {'repository': fullName},
    );
  }

  /// Toggle repository enabled state
  void toggleRepositoryEnabled(String fullName) {
    _multiRepoConfig.toggleRepository(fullName);
    Logger.d('Toggled repository enabled: $fullName', context: 'Issues');
    Logger.trackJourney(
      JourneyEventType.configChange,
      'Settings',
      'repository_toggled',
      metadata: {'repository': fullName},
    );
  }

  /// Set repository enabled state
  void setRepositoryEnabled(String fullName, bool enabled) {
    _multiRepoConfig.setRepositoryEnabled(fullName, enabled);
    Logger.d('Set repository enabled: $fullName = $enabled', context: 'Issues');
  }

  /// Save multi-repository configuration to storage
  ///
  /// Public method for external use (e.g., repo picker)
  Future<void> saveMultiRepositoryConfig() async {
    await _saveMultiRepositoryConfig();
  }

  /// Set active repository
  void setActiveRepository(String? fullName) {
    _multiRepoConfig.setActiveRepository(fullName);
    if (fullName != null) {
      final parts = fullName.split('/');
      if (parts.length == 2) {
        _owner = parts[0];
        _repo = parts[1];
      }
    }
    Logger.d('Set active repository: $fullName', context: 'Issues');
  }

  /// Load multi-repository configuration from storage
  Future<void> _loadMultiRepositoryConfig() async {
    try {
      final reposJson = await _storage.read(key: 'github_repositories');
      if (reposJson != null && reposJson.isNotEmpty) {
        // Parse JSON string to list
        // Format: ["owner1/repo1","owner2/repo2"]
        final repos = reposJson
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        _multiRepoConfig.loadFromList(repos);
        Logger.i(
          'Loaded ${repos.length} repositories from storage',
          context: 'Issues',
        );
      }
    } catch (e, stackTrace) {
      Logger.w(
        'Failed to load multi-repository config',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
    }
  }

  /// Save multi-repository configuration to storage
  Future<void> _saveMultiRepositoryConfig() async {
    try {
      final repos = _multiRepoConfig.exportToList();
      final reposJson = '[${repos.map((r) => '"$r"').join(',')}]';
      await _storage.write(key: 'github_repositories', value: reposJson);
      Logger.i(
        'Saved ${repos.length} repositories to storage',
        context: 'Issues',
      );
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to save multi-repository config',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
    }
  }

  /// Validate repository exists on GitHub
  Future<bool> validateRepository() async {
    if (_owner.isEmpty || _repo.isEmpty) {
      Logger.w('Cannot validate: repository not configured', context: 'Issues');
      return false;
    }

    final validationMetric = Logger.startMetric('validateRepository', 'Issues');
    Logger.trackJourney(
      JourneyEventType.systemAction,
      'Settings',
      'repository_validation_started',
      metadata: {'repository': '$_owner/$_repo'},
    );
    Logger.d('Validating repository: $_owner/$_repo', context: 'Issues');

    try {
      final isValid = await _githubService.validateRepository(
        owner: _owner,
        repo: _repo,
      );

      if (isValid) {
        Logger.trackJourney(
          JourneyEventType.systemAction,
          'Settings',
          'repository_validation_success',
          metadata: {'repository': '$_owner/$_repo'},
        );
        Logger.i(
          'Repository validation successful: $_owner/$_repo',
          context: 'Issues',
        );
        validationMetric.complete(success: true);
      } else {
        Logger.trackJourney(
          JourneyEventType.systemAction,
          'Settings',
          'repository_validation_failed',
          metadata: {
            'repository': '$_owner/$_repo',
            'reason': 'repo_not_found',
          },
        );
        Logger.w(
          'Repository validation failed: $_owner/$_repo does not exist',
          context: 'Issues',
        );
        validationMetric.complete(
          success: false,
          errorMessage: 'Repository not found',
        );
      }
      return isValid;
    } catch (e, stackTrace) {
      Logger.trackJourney(
        JourneyEventType.systemAction,
        'Settings',
        'repository_validation_failed',
        metadata: {
          'repository': '$_owner/$_repo',
          'reason': 'error',
          'error_type': e.runtimeType.toString(),
        },
      );
      Logger.e(
        'Repository validation failed',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      validationMetric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Load issues from GitHub API
  ///
  /// [repoFullName] Optional repository to load issues for.
  /// If not provided, loads issues for the default/active repository.
  Future<void> loadIssues({String? state, String? repoFullName}) async {
    final metric = Logger.startMetric('loadIssues', 'Issues');

    // Determine which repository to load
    final targetRepoFullName = repoFullName ?? '$_owner/$_repo';

    // If repository not configured, just load from cache or show empty state
    if (_owner.isEmpty || _repo.isEmpty) {
      Logger.d(
        'Repository not configured - using local cache',
        context: 'Issues',
      );
      _error = null; // Clear error - this is OK for offline mode
      _isLoading = false;
      notifyListeners();
      metric.complete(success: true);
      return;
    }

    Logger.i(
      'Loading issues for $targetRepoFullName (state: $state ?? $_filter)',
      context: 'Issues',
      metadata: {'repository': targetRepoFullName, 'state': state ?? _filter},
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stateToFetch = state ?? _filter;

      // Parse repo owner and name from full name
      final parts = targetRepoFullName.split('/');
      if (parts.length != 2) {
        throw Exception('Invalid repository format: $targetRepoFullName');
      }
      final owner = parts[0];
      final repo = parts[1];

      final fetchedIssues = await _githubService.fetchIssues(
        owner: owner,
        repo: repo,
        state: stateToFetch,
      );

      // Sort by updated date descending (most recent first)
      fetchedIssues.sort((a, b) {
        final aUpdated = a.updatedAt ?? a.createdAt;
        final bUpdated = b.updatedAt ?? b.createdAt;
        return bUpdated.compareTo(aUpdated);
      });

      // Store issues per repository
      _repoIssues[targetRepoFullName] = fetchedIssues;

      // Update main issues list if loading default repo
      if (targetRepoFullName == '$_owner/$_repo') {
        _issues = fetchedIssues;
      }

      _filter = stateToFetch;
      _error = null;
      _syncError = false; // Clear sync error on successful load
      _lastSyncTime = DateTime.now();

      Logger.i('Loaded ${fetchedIssues.length} issues', context: 'Issues');
      Logger.trackJourney(
        JourneyEventType.userAction,
        'Issues',
        'issues_loaded',
        metadata: {'count': fetchedIssues.length, 'state': stateToFetch},
      );
      metric.complete(success: true);

      // Cache to Hive
      await _saveToCache();
    } on Exception catch (e, stackTrace) {
      Logger.e(
        'Failed to load issues',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _error = e.toString().replaceAll('Exception: ', '');
      _syncError = true; // Mark sync error

      // Try to load from cache
      if (_repoIssues[targetRepoFullName]?.isEmpty ?? true) {
        await _loadFromCache();
        // Note: _isOffline is managed by connectivity stream, not manually set here
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load issues for a specific repository
  Future<void> loadRepoIssues({
    required String repoFullName,
    String? state,
  }) async {
    await loadIssues(repoFullName: repoFullName, state: state);
  }

  /// Refresh issues (pull-to-refresh)
  ///
  /// Syncs all configured repositories when called without repoFullName.
  /// [repoFullName] Optional repository to refresh. If not provided, refreshes all repos.
  Future<void> refreshIssues({String? repoFullName}) async {
    Logger.d('Refreshing issues', context: 'Issues');
    Logger.trackJourney(JourneyEventType.userAction, 'Home', 'refresh_issues');

    if (repoFullName == null) {
      // Refresh all configured repositories
      await _syncAllRepositories();
      // Update main issues list with default repo issues (for backward compatibility)
      if (_owner.isNotEmpty && _repo.isNotEmpty) {
        final defaultRepoFullName = '$_owner/$_repo';
        _issues = _repoIssues[defaultRepoFullName] ?? [];
      }
      _lastSyncTime = DateTime.now();
      notifyListeners();
      await _saveToCache();
    } else {
      // Refresh specific repository
      await loadIssues(repoFullName: repoFullName);
    }
  }

  /// Refresh issues for a specific repository
  Future<void> refreshRepoIssues(String repoFullName) async {
    await refreshIssues(repoFullName: repoFullName);
  }

  /// Create a new issue
  Future<Issue?> createIssue({
    required String title,
    String? body,
    List<String>? labels,
  }) async {
    final metric = Logger.startMetric('createIssue', 'Issues');
    Logger.d(
      'Creating issue: "$title"',
      context: 'Issues',
      metadata: {'has_body': body != null, 'has_labels': labels != null},
    );

    try {
      Issue issue;

      // If repository is configured, create on GitHub
      if (_owner.isNotEmpty && _repo.isNotEmpty) {
        issue = await _githubService.createIssue(
          owner: _owner,
          repo: _repo,
          title: title,
          body: body,
          labels: labels,
        );
      } else {
        // Offline mode: create local issue with dummy number
        final now = DateTime.now();
        issue = Issue(
          number: _issues.length + 1,
          title: title,
          body: body,
          state: 'open',
          createdAt: now,
          updatedAt: now,
          labels: (labels ?? [])
              .map((label) => Label(name: label, color: '#CCCCCC'))
              .toList(),
          assignees: [],
          user: User(login: 'Local User'),
        );
        Logger.i('Created local issue #${issue.number}', context: 'Issues');
      }

      // Add to local list
      _issues.insert(0, issue);
      notifyListeners();

      // Cache to Hive
      await _saveToCache();

      Logger.i('Created issue #${issue.number}', context: 'Issues');
      Logger.trackJourney(
        JourneyEventType.userAction,
        'Home',
        'issue_created',
        metadata: {
          'issue_number': issue.number,
          'repository': '$_owner/$_repo',
        },
      );
      metric.complete(success: true);
      return issue;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to create issue',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Update an existing issue
  Future<Issue?> updateIssue({
    required int issueNumber,
    String? title,
    String? body,
    String? state,
    List<String>? labels,
  }) async {
    final metric = Logger.startMetric('updateIssue', 'Issues');
    Logger.d(
      'Updating issue #$issueNumber',
      context: 'Issues',
      metadata: {
        'title_changed': title != null,
        'state_changed': state != null,
      },
    );

    try {
      Issue issue;

      // If repository is configured, update on GitHub
      if (_owner.isNotEmpty && _repo.isNotEmpty) {
        issue = await _githubService.updateIssue(
          owner: _owner,
          repo: _repo,
          issueNumber: issueNumber,
          title: title,
          body: body,
          state: state,
          labels: labels,
        );
      } else {
        // Offline mode: update local issue
        final index = _issues.indexWhere((i) => i.number == issueNumber);
        if (index == -1) {
          Logger.w(
            'Issue #$issueNumber not found for offline update',
            context: 'Issues',
          );
          metric.complete(success: false, errorMessage: 'Issue not found');
          return null;
        }

        final existingIssue = _issues[index];
        issue = existingIssue.copyWith(
          title: title ?? existingIssue.title,
          body: body ?? existingIssue.body,
          state: state ?? existingIssue.state,
          updatedAt: DateTime.now(),
        );

        _issues[index] = issue;
        Logger.i('Updated local issue #${issue.number}', context: 'Issues');
      }

      // Update in local list (already done for offline case)
      if (_owner.isNotEmpty && _repo.isNotEmpty) {
        final index = _issues.indexWhere((i) => i.number == issueNumber);
        if (index != -1) {
          _issues[index] = issue;
          notifyListeners();
        }
      }

      // Cache to Hive
      await _saveToCache();

      Logger.i('Updated issue #${issue.number}', context: 'Issues');
      Logger.trackJourney(
        JourneyEventType.userAction,
        'Edit',
        'issue_updated',
        metadata: {'issue_number': issueNumber, 'state': state},
      );
      metric.complete(success: true);
      return issue;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to update issue',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Close an issue
  Future<Issue?> closeIssue(int issueNumber) {
    Logger.d('Closing issue #$issueNumber', context: 'Issues');
    Logger.trackJourney(
      JourneyEventType.userAction,
      'Detail',
      'issue_closed',
      metadata: {'issue_number': issueNumber},
    );
    return updateIssue(issueNumber: issueNumber, state: 'closed');
  }

  /// Reopen a closed issue
  Future<Issue?> reopenIssue(int issueNumber) {
    Logger.d('Reopening issue #$issueNumber', context: 'Issues');
    Logger.trackJourney(
      JourneyEventType.userAction,
      'Detail',
      'issue_reopened',
      metadata: {'issue_number': issueNumber},
    );
    return updateIssue(issueNumber: issueNumber, state: 'open');
  }

  /// Set filter
  void setFilter(String filter) {
    Logger.d('Setting filter: $filter', context: 'Issues');
    _filter = filter;
    notifyListeners();
    Logger.trackJourney(
      JourneyEventType.userAction,
      'Home',
      'filter_changed',
      metadata: {'filter': filter},
    );
  }

  /// Set sort order
  void setSortBy(String sortBy) {
    Logger.d('Setting sort: $sortBy', context: 'Issues');
    _sortBy = sortBy;
    notifyListeners();
    Logger.trackJourney(
      JourneyEventType.userAction,
      'Home',
      'sort_changed',
      metadata: {'sort_by': sortBy},
    );
  }

  /// Get filtered issues
  List<Issue> get filteredIssues {
    var filtered = _issues;

    // Apply state filter
    if (_filter == 'open') {
      filtered = filtered.where((i) => i.isOpen).toList();
    } else if (_filter == 'closed') {
      filtered = filtered.where((i) => i.isClosed).toList();
    }

    // Apply sorting
    if (_sortBy == 'created') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'updated') {
      filtered.sort((a, b) {
        final aUpdated = a.updatedAt ?? a.createdAt;
        final bUpdated = b.updatedAt ?? b.createdAt;
        return bUpdated.compareTo(aUpdated);
      });
    } else if (_sortBy == 'comments') {
      // Note: comments count not implemented in model yet
      filtered.sort((a, b) => 0);
    }

    return filtered;
  }

  /// Force refresh connectivity state - for instant cloud icon update
  ///
  /// Call this when you need immediate connectivity verification.
  /// Returns the updated online status.
  Future<bool> refreshConnectivity() async {
    final isOnline = await _connectivityService.forceRefresh();
    _isOffline = !isOnline;
    notifyListeners();
    Logger.d('Connectivity refreshed: offline=$_isOffline', context: 'Issues');
    return isOnline;
  }

  /// Search issues
  List<Issue> searchIssues(String query) {
    if (query.isEmpty) {
      return filteredIssues;
    }

    final lowerQuery = query.toLowerCase();
    final results = filteredIssues.where((issue) {
      return issue.title.toLowerCase().contains(lowerQuery) ||
          (issue.body?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    Logger.d(
      'Search: "$query" found ${results.length} results',
      context: 'Issues',
    );
    Logger.trackJourney(
      JourneyEventType.userAction,
      'Home',
      'search_issues',
      metadata: {'query_length': query.length, 'results_count': results.length},
    );

    return results;
  }

  /// Generate cache key for issue
  ///
  /// Uses string keys to support both remote (positive) and local (negative) issue numbers
  String _getCacheKey(Issue issue) => 'issue_${issue.number}';

  /// Save issues to Hive cache
  ///
  /// Uses issue numbers as keys for reliable persistence and updates
  Future<void> _saveToCache() async {
    final metric = Logger.startMetric('saveToCache', 'Issues');
    try {
      // Clear existing cache
      await _issuesBox.clear();

      // Save each issue using its number as part of the key
      // String keys support both positive (remote) and negative (local) issue numbers
      for (final issue in _issues) {
        await _issuesBox.put(_getCacheKey(issue), issue);
      }

      Logger.d('Cached ${_issues.length} issues', context: 'Issues');
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.w('Failed to cache issues', context: 'Issues');
      Logger.e(
        'Failed to cache issues',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
    }
  }

  /// Load issues from Hive cache
  ///
  /// Returns issues sorted by update time (most recent first)
  Future<void> _loadFromCache() async {
    final metric = Logger.startMetric('loadFromCache', 'Issues');
    try {
      final cachedIssues = _issuesBox.values.toList();

      if (cachedIssues.isNotEmpty) {
        // Sort by updated date (most recent first)
        cachedIssues.sort((a, b) {
          final aUpdated = a.updatedAt ?? a.createdAt;
          final bUpdated = b.updatedAt ?? b.createdAt;
          return bUpdated.compareTo(aUpdated);
        });

        _issues = cachedIssues;
        Logger.i(
          'Loaded ${_issues.length} issues from cache',
          context: 'Issues',
        );
        notifyListeners();
        metric.complete(success: true);
      } else {
        Logger.d('Cache is empty', context: 'Issues');
        metric.complete(success: true);
      }
    } catch (e, stackTrace) {
      Logger.w('Failed to load from cache', context: 'Issues');
      Logger.e(
        'Failed to load from cache',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());

      // Clear corrupted cache to prevent future failures
      try {
        await _issuesBox.clear();
        Logger.i('Cleared corrupted cache', context: 'Issues');
      } catch (clearError) {
        Logger.e(
          'Failed to clear corrupted cache',
          error: clearError,
          context: 'Issues',
        );
      }
    }
  }

  /// Clear all data
  void clear() {
    Logger.d('Clearing issues', context: 'Issues');
    _issues = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear issues cache from Hive
  ///
  /// Removes all cached issues but keeps repository configuration
  Future<void> clearCache() async {
    final metric = Logger.startMetric('clearCache', 'Issues');
    Logger.i('Clearing issues cache', context: 'Issues');

    try {
      await _issuesBox.clear();
      _issues = [];
      Logger.i('Issues cache cleared', context: 'Issues');
      Logger.trackJourney(
        JourneyEventType.userAction,
        'Settings',
        'cache_cleared',
        metadata: {'type': 'issues_only'},
      );
      metric.complete(success: true);
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to clear cache',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Clear repository configuration
  void clearRepository() {
    Logger.d('Clearing repository configuration', context: 'Issues');
    _owner = '';
    _repo = '';
    clear();
  }

  /// Clear repository configuration from secure storage
  ///
  /// Removes saved repository owner and name
  Future<void> clearRepositoryConfig() async {
    final metric = Logger.startMetric('clearRepositoryConfig', 'Issues');
    Logger.i('Clearing repository config from storage', context: 'Issues');

    try {
      await _storage.delete(key: 'github_repository_owner');
      await _storage.delete(key: 'github_repository_name');
      await _storage.delete(key: 'github_repositories');
      _owner = '';
      _repo = '';
      _multiRepoConfig.clear();
      _collapsedRepos.clear();
      Logger.setCurrentRepository(null, null);
      Logger.i('Repository config cleared', context: 'Issues');
      Logger.trackJourney(
        JourneyEventType.configChange,
        'Settings',
        'repository_config_cleared',
      );
      metric.complete(success: true);
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to clear repository config',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Clear all data (cache + repository config)
  ///
  /// Removes issues cache AND repository configuration
  Future<void> clearAllData() async {
    final metric = Logger.startMetric('clearAllData', 'Issues');
    Logger.i('Clearing all data (cache + repo config)', context: 'Issues');

    try {
      await clearCache();
      await clearRepositoryConfig();
      Logger.i('All data cleared', context: 'Issues');
      Logger.trackJourney(
        JourneyEventType.userAction,
        'Settings',
        'all_data_cleared',
      );
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to clear all data',
        error: e,
        stackTrace: stackTrace,
        context: 'Issues',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  @override
  void dispose() {
    _issuesBox.close();
    _githubService.dispose();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    Logger.d('IssuesProvider disposed', context: 'Issues');
    super.dispose();
  }
}
