import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Filter chips widget for main dashboard
class DashboardFilters extends StatelessWidget {
  final String filterStatus;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback? onClearFilters;
  final bool hideUsernameInRepo;
  final ValueChanged<bool>? onHideUsernameToggle;
  final int pendingOperationsCount;

  const DashboardFilters({
    super.key,
    required this.filterStatus,
    required this.onFilterChanged,
    this.onClearFilters,
    required this.hideUsernameInRepo,
    this.onHideUsernameToggle,
    this.pendingOperationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ResponsiveLayout(
            mobile: _buildFiltersMobile(),
            tablet: _buildFiltersTablet(),
            desktop: _buildFiltersTablet(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersMobile() {
    return Row(
      children: [
        _buildFilterChip('Open'),
        const SizedBox(width: 8),
        _buildFilterChip('Closed'),
        const SizedBox(width: 8),
        _buildFilterChip('All'),
        const Spacer(),
        _buildHideUsernameButton(),
        if (pendingOperationsCount > 0) ...[
          const SizedBox(width: 8),
          _buildPendingBadge(),
        ],
      ],
    );
  }

  Widget _buildFiltersTablet() {
    return Row(
      children: [
        _buildFilterChip('Open'),
        const SizedBox(width: 8),
        _buildFilterChip('Closed'),
        const SizedBox(width: 8),
        _buildFilterChip('All'),
        const Spacer(),
        _buildHideUsernameButton(),
        if (pendingOperationsCount > 0) ...[
          const SizedBox(width: 8),
          _buildPendingBadge(),
        ],
      ],
    );
  }

  Widget _buildPendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$pendingOperationsCount',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHideUsernameButton() {
    return IconButton(
      icon: Icon(
        hideUsernameInRepo ? Icons.visibility_off : Icons.visibility,
        color: hideUsernameInRepo ? Colors.white54 : AppColors.primary,
        size: 20,
      ),
      onPressed: () {
        onHideUsernameToggle?.call(!hideUsernameInRepo);
      },
      tooltip: hideUsernameInRepo
          ? 'Show username in repo name'
          : 'Hide username in repo name',
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = filterStatus == label.toLowerCase();
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: isSelected,
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.8),
        fontSize: 13,
      ),
      onSelected: (selected) {
        onFilterChanged(label.toLowerCase());
      },
    );
  }
}
