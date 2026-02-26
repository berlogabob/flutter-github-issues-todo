import 'dart:async';

import 'package:flutter/foundation.dart';

import 'issues_cache.dart';
import 'issues_repository.dart';
import '../models/issue.dart';
import '../models/repository_config.dart';
import '../services/connectivity_service.dart';
import '../utils/logging.dart';

/// Issues Provider - Manages GitHub issues state
///
/// Handles:
/// - State management for issues
/// - Filtering and sorting
/// - Offline/online sync
/// - Auto-sync on startup
/// - Multi-repository support
class IssuesProvider extends ChangeNotifier {
  final IssuesCache _cache = IssuesCache();
  final IssuesRepository _repository = IssuesRepository();
  final ConnectivityService _connectivityService = ConnectivityService();

  // State
  List<Issue> _issues = [];
  String? _error;
  bool _isLoading = false;
  String _filter = 'open'; // 'open', 'closed', 'all'
  String _sortBy = 'created'; // 'created', 'updated', 'comments'
  bool _isOffline = false;

  // Sync state for auto-sync on startup
  bool _isSyncing = false;
  bool _hasSynced = false;
  DateTime? _lastSyncTime;
  bool _syncError = false;

  // Repository configuration
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
  bool get isLoading => _repository.isLoading;
  String? get error => _repository.error ?? (_syncError ? 'Sync error' : null);
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
  int get cachedIssueCount => _cache.cachedIssueCount;

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

  /// Get repository configuration
  Repository? get repository {
    if (_owner.isEmpty || _repo.isEmpty) return null;
    return Repository(owner: _owner, name: _repo);
  }

  /// Get all configured repositories
  List<RepositoryConfig> get repositories => _multiRepoConfig.repositories;

  /// Get enabled repositories
  List<RepositoryConfig> get enabledRepositories =>
      _multiRepoConfig.enabledRepositories;

  /// Check if user has multiple repositories
  bool get hasMultipleRepos => _multiRepoConfig.repositories.length > 1;

  /// Get multi-repository configuration
  MultiRepositoryConfig get multiRepoConfig => _multiRepoConfig;

  /// Check if repository is configured (legacy getter for backward compatibility)
  bool get hasRepoConfig => _owner.isNotEmpty && _repo.isNotEmpty;

  /// Check if repository is collapsed
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

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return {
      'issueCount': cachedIssueCount,
      'cacheSize': await getCacheSizeFormatted(),
      'lastSyncTime': lastSyncTimeFormatted,
      'isOffline': isOffline,
      'syncError': syncError,
    };
  }

  /// Initialize provider
  Future<void> initialize() async {
    Logger.d('Initializing IssuesProvider', context: 'IssuesProvider');

    try {
      // Initialize cache
      await _cache.initialize();
      Logger.i('Cache initialized', context: 'IssuesProvider');

      // Load repository configuration
      await _loadRepositoryConfig();

      // Load cached issues
      await _loadFromCache();

      // Initialize connectivity monitoring
      _initializeConnectivityMonitoring();

      // Auto-sync if repository configured and online
      if (_owner.isNotEmpty && _repo.isNotEmpty && !_isOffline) {
        await _autoSyncIssues();
      }
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to initialize IssuesProvider',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesProvider',
      );
      _error = 'Failed to initialize';
      _syncError = true;
      notifyListeners();
    }
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((isOnline) {
      _isOffline = !isOnline;
      Logger.d(
        'Connectivity changed: ${_isOffline ? "OFFLINE" : "ONLINE"}',
        context: 'IssuesProvider',
      );

      // Auto-sync when coming back online
      if (!_isOffline && _owner.isNotEmpty && _repo.isNotEmpty) {
        _autoSyncIssues();
      }

      notifyListeners();
    });
  }

  /// Load repository configuration from secure storage
  Future<void> _loadRepositoryConfig() async {
    try {
      final owner = await _cache.storage.read(key: 'github_repository_owner');
      final repo = await _cache.storage.read(key: 'github_repository_name');

      if (owner != null && owner.isNotEmpty &&
          repo != null && repo.isNotEmpty) {
        _owner = owner;
        _repo = repo;
        Logger.i(
          'Loaded repository config: $owner/$repo',
          context: 'IssuesProvider',
        );
      } else {
        Logger.d('No repository config found', context: 'IssuesProvider');
      }
    } catch (e) {
      Logger.w(
        'Failed to load repository config',
        error: e,
        context: 'IssuesProvider',
      );
    }
  }

  /// Auto-sync issues on startup
  Future<void> _autoSyncIssues() async {
    if (_isSyncing || _hasSynced) return;

    _isSyncing = true;
    _syncError = false;
    notifyListeners();

    try {
      await loadIssues();
      _hasSynced = true;
      _lastSyncTime = DateTime.now();
      Logger.i('Auto-sync completed', context: 'IssuesProvider');
    } catch (e) {
      _syncError = true;
      Logger.e('Auto-sync failed', error: e, context: 'IssuesProvider');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Load issues from GitHub API
  Future<void> loadIssues({String? state}) async {
    if (_owner.isEmpty || _repo.isEmpty) {
      Logger.w('Repository not configured', context: 'IssuesProvider');
      _error = 'Repository not configured';
      notifyListeners();
      return;
    }

    Logger.i(
      'Loading issues for $_owner/$_repo (state: ${state ?? _filter})',
      context: 'IssuesProvider',
    );

    try {
      final stateToFetch = state ?? _filter;
      final fetchedIssues = await _repository.fetchIssues(
        owner: _owner,
        repo: _repo,
        state: stateToFetch,
      );

      _issues = fetchedIssues;
      _filter = stateToFetch;
      _error = null;

      Logger.i('Loaded ${_issues.length} issues', context: 'IssuesProvider');

      // Cache to Hive
      await _cache.saveToCache(_issues);
    } catch (e) {
      Logger.e('Failed to load issues', error: e, context: 'IssuesProvider');
      _error = e.toString().replaceAll('Exception: ', '');

      // Try to load from cache
      if (_issues.isEmpty) {
        await _loadFromCache();
        _isOffline = true;
      }
    }
  }

  /// Refresh issues (pull-to-refresh)
  Future<void> refreshIssues() async {
    Logger.d('Refreshing issues', context: 'IssuesProvider');
    await loadIssues();
  }

  /// Create a new issue
  Future<Issue?> createIssue({
    required String title,
    String? body,
    List<String>? labels,
  }) async {
    Logger.d('Creating issue: "$title"', context: 'IssuesProvider');

    try {
      Issue issue;

      // If repository is configured, create on GitHub
      if (_owner.isNotEmpty && _repo.isNotEmpty) {
        issue = await _repository.createIssue(
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
        Logger.i('Created local issue #${issue.number}', context: 'IssuesProvider');
      }

      // Add to local list
      _issues.insert(0, issue);
      notifyListeners();

      // Cache to Hive
      await _cache.saveToCache(_issues);

      Logger.i('Created issue #${issue.number}', context: 'IssuesProvider');
      return issue;
    } catch (e) {
      Logger.e('Failed to create issue', error: e, context: 'IssuesProvider');
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
    Logger.d('Updating issue #$issueNumber', context: 'IssuesProvider');

    try {
      Issue issue;

      // If repository is configured, update on GitHub
      if (_owner.isNotEmpty && _repo.isNotEmpty) {
        issue = await _repository.updateIssue(
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
            context: 'IssuesProvider',
          );
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
        Logger.i('Updated local issue #${issue.number}', context: 'IssuesProvider');
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
      await _cache.saveToCache(_issues);

      Logger.i('Updated issue #${issue.number}', context: 'IssuesProvider');
      return issue;
    } catch (e) {
      Logger.e('Failed to update issue', error: e, context: 'IssuesProvider');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Close an issue
  Future<Issue?> closeIssue(int issueNumber) {
    Logger.d('Closing issue #$issueNumber', context: 'IssuesProvider');
    return updateIssue(issueNumber: issueNumber, state: 'closed');
  }

  /// Reopen a closed issue
  Future<Issue?> reopenIssue(int issueNumber) {
    Logger.d('Reopening issue #$issueNumber', context: 'IssuesProvider');
    return updateIssue(issueNumber: issueNumber, state: 'open');
  }

  /// Load issues from Hive cache
  Future<void> _loadFromCache() async {
    final cachedIssues = await _cache.loadFromCache();
    if (cachedIssues.isNotEmpty) {
      _issues = cachedIssues;
      Logger.i(
        'Loaded ${_issues.length} issues from cache',
        context: 'IssuesProvider',
      );
      notifyListeners();
    }
  }

  /// Set filter
  void setFilter(String filter) {
    Logger.d('Setting filter: $filter', context: 'IssuesProvider');
    _filter = filter;
    notifyListeners();
  }

  /// Set sort order
  void setSortBy(String sortBy) {
    Logger.d('Setting sort: $sortBy', context: 'IssuesProvider');
    _sortBy = sortBy;
    notifyListeners();
  }

  /// Set repository configuration
  void setRepository(String owner, String repo) {
    Logger.i('Setting repository: $owner/$repo', context: 'IssuesProvider');
    _owner = owner;
    _repo = repo;
    _saveRepositoryConfig();
  }

  /// Save repository configuration to secure storage
  Future<void> _saveRepositoryConfig() async {
    try {
      await _cache.storage.write(key: 'github_repository_owner', value: _owner);
      await _cache.storage.write(key: 'github_repository_name', value: _repo);
      Logger.i(
        'Saved repository config: $_owner/$_repo',
        context: 'IssuesProvider',
      );
    } catch (e) {
      Logger.e(
        'Failed to save repository config',
        error: e,
        context: 'IssuesProvider',
      );
    }
  }

  /// Clear all data
  void clear() {
    Logger.d('Clearing issues', context: 'IssuesProvider');
    _issues = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear cache only
  Future<void> clearCache() async {
    await _cache.clearCache();
    Logger.i('Cache cleared', context: 'IssuesProvider');
    notifyListeners();
  }

  /// Clear all data including auth
  Future<void> clearAllData() async {
    await _cache.clearCache();
    await _cache.storage.deleteAll();
    _issues = [];
    _owner = '';
    _repo = '';
    _multiRepoConfig.repositories.clear();
    _collapsedRepos.clear();
    Logger.i('All data cleared', context: 'IssuesProvider');
    notifyListeners();
  }

  /// Clear repository configuration
  void clearRepository() {
    Logger.d('Clearing repository configuration', context: 'IssuesProvider');
    _owner = '';
    _repo = '';
    notifyListeners();
  }

  /// Add repository to multi-repo config
  void addRepository(String owner, String name) {
    _multiRepoConfig.addRepository(owner, name);
    Logger.i('Added repository: $owner/$name', context: 'IssuesProvider');
    notifyListeners();
  }

  /// Remove repository from multi-repo config
  void removeRepository(String fullName) {
    _multiRepoConfig.removeRepository(fullName);
    _collapsedRepos.remove(fullName);
    Logger.i('Removed repository: $fullName', context: 'IssuesProvider');
    notifyListeners();
  }

  /// Toggle repository enabled state
  void toggleRepositoryEnabled(String fullName) {
    _multiRepoConfig.toggleRepository(fullName);
    Logger.d('Toggled repository enabled: $fullName', context: 'IssuesProvider');
    notifyListeners();
  }

  /// Set repository enabled state
  void setRepositoryEnabled(String fullName, bool enabled) {
    _multiRepoConfig.setRepositoryEnabled(fullName, enabled);
    Logger.d('Set repository enabled: $fullName = $enabled', context: 'IssuesProvider');
    notifyListeners();
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
    Logger.d('Set active repository: $fullName', context: 'IssuesProvider');
    notifyListeners();
  }

  /// Save multi-repository configuration
  Future<void> saveMultiRepositoryConfig() async {
    await _multiRepoConfig.saveToStorage(_cache.storage);
    Logger.i('Multi-repository config saved', context: 'IssuesProvider');
  }

  /// Load multi-repository configuration
  Future<void> _loadMultiRepositoryConfig() async {
    await _multiRepoConfig.loadFromStorage(_cache.storage);
    Logger.d('Multi-repository config loaded', context: 'IssuesProvider');
  }

  /// Validate repository exists on GitHub
  Future<bool> validateRepository(String owner, String repo) async {
    try {
      return await _repository.validateRepository(owner: owner, repo: repo);
    } catch (e) {
      Logger.e('Repository validation failed', error: e, context: 'IssuesProvider');
      return false;
    }
  }

  /// Get filtered issues for a specific repo
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

  /// Refresh connectivity state
  Future<void> refreshConnectivity() async {
    await _connectivityService.forceRefresh();
    _isOffline = !_connectivityService.isOnline;
    Logger.d('Connectivity refreshed: offline=$_isOffline', context: 'IssuesProvider');
    notifyListeners();
  }

  /// Get cache size in bytes
  Future<int> getCacheSizeBytes() async {
    return cachedIssueCount * 1500; // Approximate bytes per issue
  }

  /// Get cache size formatted as string
  Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSizeBytes();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _cache.close();
    _repository.dispose();
    Logger.d('IssuesProvider disposed', context: 'IssuesProvider');
    super.dispose();
  }
}
