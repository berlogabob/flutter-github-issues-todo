import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../widgets/braille_loader.dart';
import '../widgets/status_badge.dart';
import '../widgets/label_chip.dart';
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
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates the search screen.
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<IssueItem> _searchResults = [];
  String _lastQuery = '';
  String _filterStatus = 'all';
  String? _searchError;
  final GitHubApiService _githubApi = GitHubApiService();

  // Filter states
  bool _filterTitle = true;
  bool _filterBody = true;
  bool _filterLabels = true;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
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
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search issues...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: AppColors.orangePrimary),
          ),
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search filters
          if (_lastQuery.isNotEmpty) _buildSearchFilters(),
          // Results
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Filters:',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Title', true),
          const SizedBox(width: 4),
          _buildFilterChip('Body', true),
          const SizedBox(width: 4),
          _buildFilterChip('Labels', true),
          const SizedBox(width: 12),
          // Status filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.orangePrimary.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: _filterStatus,
              underline: const SizedBox(),
              dropdownColor: AppColors.cardBackground,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filterStatus = value;
                  });
                  if (_lastQuery.isNotEmpty) {
                    _performSearch(_lastQuery);
                  }
                }
              },
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.orangePrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    bool isSelected;
    String filterType;

    switch (label) {
      case 'Title':
        isSelected = _filterTitle;
        filterType = 'title';
        break;
      case 'Body':
        isSelected = _filterBody;
        filterType = 'body';
        break;
      case 'Labels':
        isSelected = _filterLabels;
        filterType = 'labels';
        break;
      default:
        isSelected = isActive;
        filterType = label.toLowerCase();
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: AppColors.background,
      selectedColor: AppColors.orangePrimary.withValues(alpha: 0.3),
      checkmarkColor: AppColors.orangePrimary,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.orangePrimary
            : Colors.white.withValues(alpha: 0.7),
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (selected) {
        setState(() {
          switch (filterType) {
            case 'title':
              _filterTitle = selected;
              break;
            case 'body':
              _filterBody = selected;
              break;
            case 'labels':
              _filterLabels = selected;
              break;
          }
        });
        if (_lastQuery.isNotEmpty) {
          _performSearch(_lastQuery);
        }
      },
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrailleLoader(size: 32),
            SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
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
                color: Colors.white.withValues(alpha: 0.5),
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
                  color: Colors.white.withValues(alpha: 0.3),
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
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final issue = _searchResults[index];
        return _buildSearchResult(issue);
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
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Search Issues',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search by title, labels, or body',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
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
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No results found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResult(IssueItem issue) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: StatusBadge(status: issue.status),
        title: Text(
          '#${issue.number} ${issue.title}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (issue.bodyMarkdown != null &&
                issue.bodyMarkdown!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                issue.bodyMarkdown!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (issue.labels.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: issue.labels
                    .take(3)
                    .map((label) => LabelChipWidget(label: label))
                    .toList(),
              ),
            ],
            if (issue.assigneeLogin != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 12, color: AppColors.blue),
                  const SizedBox(width: 4),
                  Text(
                    issue.assigneeLogin!,
                    style: const TextStyle(color: AppColors.blue, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: () => _openIssue(issue),
      ),
    );
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
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
      final repos = await _githubApi.fetchMyRepositories(perPage: 100);

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
        } catch (e) {
          debugPrint('Error searching ${repo.fullName}: $e');
          // Continue with next repo
        }
      }

      // Apply status filter
      final filteredIssues = allIssues.where((issue) {
        if (_filterStatus == 'all') return true;
        if (_filterStatus == 'open') return issue.status == ItemStatus.open;
        if (_filterStatus == 'closed') return issue.status == ItemStatus.closed;
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredIssues;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _filterTitle = true;
      _filterBody = true;
      _filterLabels = true;
      _filterStatus = 'all';
    });
    if (_lastQuery.isNotEmpty) {
      _performSearch(_lastQuery);
    }
  }

  void _openIssue(IssueItem issue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IssueDetailScreen(issue: issue)),
    );
  }
}
