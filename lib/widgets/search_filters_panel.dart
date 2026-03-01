import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable search filters panel widget
class SearchFiltersPanel extends StatelessWidget {
  final String searchQuery;
  final String sortBy;
  final String sortOrder;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String authorQuery;
  final bool filterMyIssues;
  final bool filterOpen;
  final bool filterClosed;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSortOrderChanged;
  final ValueChanged<DateTime?> onDateFromChanged;
  final ValueChanged<DateTime?> onDateToChanged;
  final ValueChanged<String> onAuthorChanged;
  final ValueChanged<bool> onFilterMyIssuesChanged;
  final ValueChanged<bool> onFilterOpenChanged;
  final ValueChanged<bool> onFilterClosedChanged;
  final VoidCallback onClearAll;
  final bool hasActiveFilters;

  const SearchFiltersPanel({
    super.key,
    required this.searchQuery,
    required this.sortBy,
    required this.sortOrder,
    this.dateFrom,
    this.dateTo,
    this.authorQuery = '',
    this.filterMyIssues = false,
    this.filterOpen = false,
    this.filterClosed = false,
    required this.onSortChanged,
    required this.onSortOrderChanged,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.onAuthorChanged,
    required this.onFilterMyIssuesChanged,
    required this.onFilterOpenChanged,
    required this.onFilterClosedChanged,
    required this.onClearAll,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSortControls(context),
        const SizedBox(height: 12),
        _buildDateFilters(context),
        const SizedBox(height: 12),
        _buildAuthorFilter(),
        const SizedBox(height: 12),
        _buildQuickFilters(context),
        if (hasActiveFilters) ...[
          const SizedBox(height: 8),
          _buildClearAllButton(),
        ],
      ],
    );
  }

  Widget _buildSortControls(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Sort:',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            value: sortBy,
            isExpanded: true,
            dropdownColor: AppColors.cardBackground,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'created', child: Text('Date Created')),
              DropdownMenuItem(value: 'updated', child: Text('Last Updated')),
              DropdownMenuItem(value: 'title', child: Text('Title')),
            ],
            onChanged: (value) {
              if (value != null) {
                onSortChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            sortOrder == 'desc' ? Icons.arrow_downward : Icons.arrow_upward,
            color: AppColors.orangePrimary,
          ),
          onPressed: () {
            onSortOrderChanged(sortOrder == 'asc' ? 'desc' : 'asc');
          },
          tooltip: sortOrder == 'desc' ? 'Descending' : 'Ascending',
        ),
      ],
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            dateFrom != null ? 'From: ${_formatDate(dateFrom!)}' : 'From: Any',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: dateFrom ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onDateFromChanged(date);
            }
          },
          child: const Text(
            'Select',
            style: TextStyle(color: AppColors.orangePrimary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            dateTo != null ? 'To: ${_formatDate(dateTo!)}' : 'To: Any',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: dateTo ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onDateToChanged(date);
            }
          },
          child: const Text(
            'Select',
            style: TextStyle(color: AppColors.orangePrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorFilter() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Filter by author...',
        prefixIcon: const Icon(Icons.person, color: AppColors.orangePrimary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: AppColors.cardBackground,
      ),
      onChanged: onAuthorChanged,
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('My Issues'),
          selected: filterMyIssues,
          onSelected: onFilterMyIssuesChanged,
        ),
        FilterChip(
          label: const Text('Open'),
          selected: filterOpen,
          onSelected: (value) {
            onFilterOpenChanged(value);
            if (value) {
              onFilterClosedChanged(false);
            }
          },
        ),
        FilterChip(
          label: const Text('Closed'),
          selected: filterClosed,
          onSelected: (value) {
            onFilterClosedChanged(value);
            if (value) {
              onFilterOpenChanged(false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildClearAllButton() {
    return TextButton.icon(
      onPressed: onClearAll,
      icon: const Icon(Icons.clear_all, size: 16),
      label: const Text('Clear All Filters', style: TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.orangePrimary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
