import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../widgets/braille_loader.dart';

/// SearchScreen - Global search across issues
/// Implements brief section 7, screen 6
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;
  List<IssueItem> _searchResults = [];
  String _lastQuery = '';

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
            suffixIcon: Icon(Icons.search, color: AppColors.orange),
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
          const Spacer(),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      backgroundColor: AppColors.background,
      selectedColor: AppColors.orange.withValues(alpha: 0.3),
      checkmarkColor: AppColors.orange,
      labelStyle: TextStyle(
        color: isActive
            ? AppColors.orange
            : Colors.white.withValues(alpha: 0.7),
        fontSize: 11,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (selected) {
        // TODO: Toggle filter
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
    final isOpen = issue.status == ItemStatus.open;

    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOpen ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
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
                children: issue.labels.take(3).map((label) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
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
    // Debounce search
    // TODO: Implement proper debouncing
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _lastQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _lastQuery = query;
    });

    // TODO: Perform actual search
    // Simulating search for demo
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          // Sample results
          _searchResults = [
            IssueItem(
              id: 'search1',
              title: 'Search result for: $query',
              number: 100,
              bodyMarkdown:
                  'This is a sample search result matching your query.',
              status: ItemStatus.open,
              labels: ['search', 'result'],
              assigneeLogin: 'user',
            ),
          ];
        });
      }
    });
  }

  void _clearFilters() {
    // TODO: Clear search filters
  }

  void _openIssue(IssueItem issue) {
    // TODO: Navigate to issue detail
  }
}
