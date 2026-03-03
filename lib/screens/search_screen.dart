import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../services/search_history_service.dart';
import '../services/local_storage_service.dart';
import '../services/cache_service.dart';
import '../widgets/braille_loader.dart';
import '../widgets/search_filters_panel.dart';
import '../widgets/search_result_item.dart';
import 'issue_detail_screen.dart';

/// Screen for global search across all GitHub issues.
///
/// Features:
/// - Search by title, body, and labels
/// - Debounced search for performance
/// - Filter by content type (title/body/labels)
/// - Filter by status (all/open/closed)
/// - Search across all user repositories
/// - Real-time search results
/// - Error handling and retry
///
/// Implements brief section 7, screen 6.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const SearchScreen()),
/// );
/// ```
class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Search constants
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const int _maxRepos = 100;
  static const String _sortByCreated = 'created';
  static const String _sortByUpdated = 'updated';
  static const String _sortByTitle = 'title';
  static const String _sortOrderDesc = 'desc';

  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<IssueItem> _searchResults = [];
  String _lastQuery = '';
  String _filterStatus = 'all';
  String? _searchError;
  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  final CacheService _cache = CacheService();

  // Cached user login for "My Issues" filter
  String? _cachedUserLogin;

  // Filter states
  bool _filterTitle = true;
  bool _filterBody = true;
  bool _filterLabels = true;

  // Date filter states
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Sort states
  String _sortBy = _sortByCreated; // 'created', 'updated', 'title'
  String _sortOrder = _sortOrderDesc; // 'asc' or 'desc'

  // Author filter state
  String _authorQuery = '';

  // Quick filter states
  bool _filterMyIssues = false;
  bool _filterOpen = false;
  bool _filterClosed = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // Load user login for "My Issues" filter
    _loadUserLogin();
  }

  /// Loads current user login from cache or GitHub API.
  ///
  /// Caches the result for performance. Falls back to cached data in offline mode.
  Future<void> _loadUserLogin() async {
    if (_cachedUserLogin != null) return;

    try {
      // Try cache first
      final cacheKey = 'current_user_login';
      final cachedLogin = _cache.get<String>(cacheKey);
      if (cachedLogin != null) {
        setState(() {
          _cachedUserLogin = cachedLogin;
        });
        return;
      }

      // Try local storage first (faster)
      final localUser = await _localStorage.getUserData();
      if (localUser != null && localUser['login'] != null) {
        final login = localUser['login'] as String;
        setState(() {
          _cachedUserLogin = login;
        });
        // Update cache
        await _cache.set(cacheKey, login, ttl: const Duration(hours: 1));
        return;
      }

      // Fetch from GitHub API
      final userData = await _githubApi.getCurrentUser();
      if (userData != null && userData['login'] != null) {
        final login = userData['login'] as String;
        setState(() {
          _cachedUserLogin = login;
        });
        // Save to local storage and cache
        await _localStorage.saveUserData(userData);
        await _cache.set(cacheKey, login, ttl: const Duration(hours: 1));
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user login: $e');
      AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    return _filterMyIssues ||
        _filterOpen ||
        _filterClosed ||
        _dateFrom != null ||
        _dateTo != null ||
        _authorQuery.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: AppColors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search issues...',
            hintStyle: TextStyle(
              color: AppColors.white.withValues(alpha: 0.54),
            ),
            border: InputBorder.none,
            suffixIcon: const Icon(
              Icons.search,
              color: AppColors.orangePrimary,
            ),
          ),
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search filters
          if (_lastQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchFiltersPanel(
                searchQuery: _searchController.text,
                sortBy: _sortBy,
                sortOrder: _sortOrder,
                dateFrom: _dateFrom,
                dateTo: _dateTo,
                authorQuery: _authorQuery,
                filterMyIssues: _filterMyIssues,
                filterOpen: _filterOpen,
                filterClosed: _filterClosed,
                onSortChanged: (value) {
                  setState(() => _sortBy = value);
                  _performSearch(_lastQuery);
                },
                onSortOrderChanged: (value) {
                  setState(() => _sortOrder = value);
                  _performSearch(_lastQuery);
                },
                onDateFromChanged: (value) {
                  setState(() => _dateFrom = value);
                  _performSearch(_lastQuery);
                },
                onDateToChanged: (value) {
                  setState(() => _dateTo = value);
                  _performSearch(_lastQuery);
                },
                onAuthorChanged: (value) {
                  setState(() => _authorQuery = value);
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(_debounceDuration, () {
                    _performSearch(_lastQuery);
                  });
                },
                onFilterMyIssuesChanged: (value) {
                  setState(() => _filterMyIssues = value);
                  _performSearch(_lastQuery);
                },
                onFilterOpenChanged: (value) {
                  setState(() => _filterOpen = value);
                  if (value) {
                    setState(() => _filterClosed = false);
                  }
                  _performSearch(_lastQuery);
                },
                onFilterClosedChanged: (value) {
                  setState(() => _filterClosed = value);
                  if (value) {
                    setState(() => _filterOpen = false);
                  }
                  _performSearch(_lastQuery);
                },
                onClearAll: () {
                  setState(() {
                    _filterMyIssues = false;
                    _filterOpen = false;
                    _filterClosed = false;
                    _dateFrom = null;
                    _dateTo = null;
                    _authorQuery = '';
                  });
                  _performSearch(_lastQuery);
                },
                hasActiveFilters: _hasActiveFilters,
              ),
            ),
          // Results
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrailleLoader(size: 32),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.54),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Search Error',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.5),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _searchError!,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_lastQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_lastQuery.isEmpty) {
      return Column(
        children: [
          // Show search history when query is empty
          FutureBuilder<List<String>>(
            future: SearchHistoryService().getHistory(),
            builder: (context, snapshot) {
              final history = snapshot.data ?? [];
              if (history.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Searches',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await SearchHistoryService().clearHistory();
                            if (!mounted) return;
                            setState(() {}); // Refresh
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: AppColors.orangePrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: history.map((query) {
                        return InkWell(
                          onTap: () {
                            setState(() => _searchController.text = query);
                            _performSearch(query);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Chip(
                            label: Text(
                              query,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              SearchHistoryService().removeFromHistory(query);
                              setState(() {}); // Refresh
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final issue = _searchResults[index];
        return SearchResultItem(issue: issue, onTap: () => _openIssue(issue));
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Search Issues',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by title, labels, or body',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No results found',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    // Save to history if query is not empty
    if (query.trim().isNotEmpty) {
      SearchHistoryService().addToHistory(query);
    }

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _lastQuery = '';
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _lastQuery = query;
      _searchError = null;
    });

    try {
      // Search issues across all user repositories
      final allIssues = <IssueItem>[];
      final repos = await _githubApi.fetchMyRepositories(perPage: _maxRepos);

      for (final repo in repos) {
        try {
          final parts = repo.fullName.split('/');
          if (parts.length == 2) {
            final issues = await _githubApi.fetchIssues(parts[0], parts[1]);

            // Filter by search query (title, labels, body) based on active filters
            final matchingIssues = issues.where((issue) {
              final queryLower = query.toLowerCase();
              bool matches = false;

              if (_filterTitle &&
                  issue.title.toLowerCase().contains(queryLower)) {
                matches = true;
              }
              if (_filterLabels &&
                  issue.labels.any(
                    (label) => label.toLowerCase().contains(queryLower),
                  )) {
                matches = true;
              }
              if (_filterBody &&
                  (issue.bodyMarkdown?.toLowerCase().contains(queryLower) ??
                      false)) {
                matches = true;
              }

              return matches;
            }).toList();

            allIssues.addAll(matchingIssues);
          }
        } catch (e, stackTrace) {
          debugPrint('Error searching ${repo.fullName}: $e');
          if (mounted) {
            AppErrorHandler.handle(
              e,
              stackTrace: stackTrace,
              context: context,
              showSnackBar: false,
            );
          }
          // Continue with next repo
        }
      }

      // Apply status filter
      final statusFiltered = allIssues.where((issue) {
        if (_filterStatus == 'all') return true;
        if (_filterStatus == 'open') return issue.status == ItemStatus.open;
        if (_filterStatus == 'closed') return issue.status == ItemStatus.closed;
        return true;
      }).toList();

      // Apply date filtering
      final dateFiltered = statusFiltered.where((issue) {
        if (_dateFrom == null && _dateTo == null) return true;

        final createdAt = issue.createdAt ?? issue.updatedAt;
        if (createdAt == null) return true;

        if (_dateFrom != null && createdAt.isBefore(_dateFrom!)) return false;
        if (_dateTo != null && createdAt.isAfter(_dateTo!)) return false;

        return true;
      }).toList();

      // Apply author filtering
      final authorFiltered = dateFiltered.where((issue) {
        if (_authorQuery.isEmpty) return true;
        final assignee = issue.assigneeLogin?.toLowerCase() ?? '';
        return assignee.contains(_authorQuery.toLowerCase());
      }).toList();

      // Apply quick filters
      final quickFiltered = authorFiltered.where((issue) {
        // My Issues filter - filter by current user's assignee
        if (_filterMyIssues) {
          // Use cached user login, skip filter if not loaded yet
          final currentLogin = _cachedUserLogin;
          if (currentLogin == null) {
            // User login not loaded yet, skip this filter
            return true;
          }
          if (issue.assigneeLogin != currentLogin) return false;
        }

        // Open/Closed filter
        if (_filterOpen && issue.status != ItemStatus.open) return false;
        if (_filterClosed && issue.status != ItemStatus.closed) return false;

        return true;
      }).toList();

      // Sort results
      quickFiltered.sort((a, b) {
        int comparison = 0;

        switch (_sortBy) {
          case _sortByCreated:
            final aDate = a.createdAt ?? a.updatedAt;
            final bDate = b.createdAt ?? b.updatedAt;
            if (aDate == null && bDate == null) {
              comparison = 0;
            } else if (aDate == null) {
              comparison = 1;
            } else if (bDate == null) {
              comparison = -1;
            } else {
              comparison = aDate.compareTo(bDate);
            }
            break;

          case _sortByUpdated:
            final aDate = a.updatedAt;
            final bDate = b.updatedAt;
            if (aDate == null && bDate == null) {
              comparison = 0;
            } else if (aDate == null) {
              comparison = 1;
            } else if (bDate == null) {
              comparison = -1;
            } else {
              comparison = aDate.compareTo(bDate);
            }
            break;

          case _sortByTitle:
            comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
        }

        return _sortOrder == _sortOrderDesc ? -comparison : comparison;
      });

      if (mounted) {
        setState(() {
          _searchResults = quickFiltered; // Use the sorted and filtered list
          _isSearching = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Search error: $e');
      if (mounted) {
        AppErrorHandler.handle(
          e,
          stackTrace: stackTrace,
          context: context,
          showSnackBar: true,
        );
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _openIssue(IssueItem issue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IssueDetailScreen(issue: issue)),
    );
  }
}
