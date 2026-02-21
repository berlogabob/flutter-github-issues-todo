import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/issue.dart';
import '../services/github_service.dart';
import '../utils/logger.dart';

/// Repository configuration model
class Repository {
  final String owner;
  final String name;

  Repository({required this.owner, required this.name});
}

/// Issues Provider - Manages GitHub issues state
///
/// Handles:
/// - Fetching issues from GitHub
/// - Local caching with Hive
/// - Filtering and sorting
/// - Offline/online sync
class IssuesProvider extends ChangeNotifier {
  final GitHubService _githubService = GitHubService();

  // Hive box for local caching
  late Box<Issue> _issuesBox;

  // State
  List<Issue> _issues = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'open'; // 'open', 'closed', 'all'
  String _sortBy = 'created'; // 'created', 'updated', 'comments'
  bool _isOffline = false;

  // Repository configuration (should come from settings)
  String _owner = '';
  String _repo = '';

  // Getters
  List<Issue> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  String get sortBy => _sortBy;
  bool get isOffline => _isOffline;
  bool get hasIssues => _issues.isNotEmpty;
  int get openCount => _issues.where((i) => i.isOpen).length;
  int get closedCount => _issues.where((i) => i.isClosed).length;
  String get owner => _owner;
  String get repo => _repo;
  Repository? get repository {
    if (_owner.isEmpty || _repo.isEmpty) return null;
    return Repository(owner: _owner, name: _repo);
  }

  /// Initialize Hive for local caching
  Future<void> initialize() async {
    Logger.d('Initializing IssuesProvider', context: 'Issues');

    try {
      // Initialize Hive
      _issuesBox = await Hive.openBox<Issue>('issues');
      Logger.i('Hive box opened', context: 'Issues');

      // Load cached issues
      await _loadFromCache();
    } catch (e) {
      Logger.e('Failed to initialize Hive', error: e, context: 'Issues');
      _error = 'Failed to initialize local storage';
      notifyListeners();
    }
  }

  /// Set repository configuration
  void setRepository(String owner, String repo) {
    Logger.i('Setting repository: $owner/$repo', context: 'Issues');
    _owner = owner;
    _repo = repo;
  }

  /// Load issues from GitHub API
  Future<void> loadIssues({String? state}) async {
    if (_owner.isEmpty || _repo.isEmpty) {
      Logger.w('Repository not configured', context: 'Issues');
      _error = 'Repository not configured';
      notifyListeners();
      return;
    }

    Logger.i(
      'Loading issues for $_owner/$_repo (state: $state ?? $_filter)',
      context: 'Issues',
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stateToFetch = state ?? _filter;
      final fetchedIssues = await _githubService.fetchIssues(
        owner: _owner,
        repo: _repo,
        state: stateToFetch,
      );

      _issues = fetchedIssues;
      _filter = stateToFetch;
      _error = null;

      Logger.i('Loaded ${_issues.length} issues', context: 'Issues');

      // Cache to Hive
      await _saveToCache();
    } on Exception catch (e) {
      Logger.e('Failed to load issues', error: e, context: 'Issues');
      _error = e.toString().replaceAll('Exception: ', '');

      // Try to load from cache
      if (_issues.isEmpty) {
        await _loadFromCache();
        _isOffline = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh issues (pull-to-refresh)
  Future<void> refreshIssues() async {
    Logger.d('Refreshing issues', context: 'Issues');
    await loadIssues();
  }

  /// Create a new issue
  Future<Issue?> createIssue({
    required String title,
    String? body,
    List<String>? labels,
  }) async {
    if (_owner.isEmpty || _repo.isEmpty) {
      _error = 'Repository not configured';
      notifyListeners();
      return null;
    }

    Logger.d('Creating issue: "$title"', context: 'Issues');

    try {
      final issue = await _githubService.createIssue(
        owner: _owner,
        repo: _repo,
        title: title,
        body: body,
        labels: labels,
      );

      // Add to local list
      _issues.insert(0, issue);
      notifyListeners();

      // Cache to Hive
      await _saveToCache();

      Logger.i('Created issue #${issue.number}', context: 'Issues');
      return issue;
    } catch (e) {
      Logger.e('Failed to create issue', error: e, context: 'Issues');
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
    Logger.d('Updating issue #$issueNumber', context: 'Issues');

    try {
      final issue = await _githubService.updateIssue(
        owner: _owner,
        repo: _repo,
        issueNumber: issueNumber,
        title: title,
        body: body,
        state: state,
        labels: labels,
      );

      // Update in local list
      final index = _issues.indexWhere((i) => i.number == issueNumber);
      if (index != -1) {
        _issues[index] = issue;
        notifyListeners();
      }

      // Cache to Hive
      await _saveToCache();

      Logger.i('Updated issue #${issue.number}', context: 'Issues');
      return issue;
    } catch (e) {
      Logger.e('Failed to update issue', error: e, context: 'Issues');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Close an issue
  Future<Issue?> closeIssue(int issueNumber) {
    Logger.d('Closing issue #$issueNumber', context: 'Issues');

    return updateIssue(issueNumber: issueNumber, state: 'closed');
  }

  /// Reopen a closed issue
  Future<Issue?> reopenIssue(int issueNumber) {
    Logger.d('Reopening issue #$issueNumber', context: 'Issues');

    return updateIssue(issueNumber: issueNumber, state: 'open');
  }

  /// Set filter
  void setFilter(String filter) {
    Logger.d('Setting filter: $filter', context: 'Issues');
    _filter = filter;
    notifyListeners();
  }

  /// Set sort order
  void setSortBy(String sortBy) {
    Logger.d('Setting sort: $sortBy', context: 'Issues');
    _sortBy = sortBy;
    notifyListeners();
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

  /// Search issues
  List<Issue> searchIssues(String query) {
    if (query.isEmpty) {
      return filteredIssues;
    }

    final lowerQuery = query.toLowerCase();
    return filteredIssues.where((issue) {
      return issue.title.toLowerCase().contains(lowerQuery) ||
          (issue.body?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Save issues to Hive cache
  Future<void> _saveToCache() async {
    try {
      await _issuesBox.clear();
      for (var i = 0; i < _issues.length; i++) {
        await _issuesBox.put(i, _issues[i]);
      }
      Logger.d('Cached ${_issues.length} issues', context: 'Issues');
    } catch (e) {
      Logger.w('Failed to cache issues', context: 'Issues');
      Logger.e('Failed to cache issues', error: e, context: 'Issues');
    }
  }

  /// Load issues from Hive cache
  Future<void> _loadFromCache() async {
    try {
      final cachedIssues = _issuesBox.values.toList();
      if (cachedIssues.isNotEmpty) {
        _issues = cachedIssues;
        Logger.i(
          'Loaded ${_issues.length} issues from cache',
          context: 'Issues',
        );
        notifyListeners();
      }
    } catch (e) {
      Logger.w('Failed to load from cache', context: 'Issues');
      Logger.e('Failed to load from cache', error: e, context: 'Issues');
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

  @override
  void dispose() {
    _issuesBox.close();
    _githubService.dispose();
    Logger.d('IssuesProvider disposed', context: 'Issues');
    super.dispose();
  }
}
