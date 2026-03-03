import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../models/pending_operation.dart';
import '../services/pending_operations_service.dart';

/// Widget displaying list of pending operations
class PendingOperationsList extends StatefulWidget {
  final PendingOperationsService pendingOps;
  final VoidCallback? onRefresh;

  const PendingOperationsList({
    super.key,
    required this.pendingOps,
    this.onRefresh,
  });

  @override
  State<PendingOperationsList> createState() => _PendingOperationsListState();
}

class _PendingOperationsListState extends State<PendingOperationsList> {
  @override
  Widget build(BuildContext context) {
    final operations = widget.pendingOps.getAllOperations();

    if (operations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: operations.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final operation = operations[index];
        return _buildOperationTile(operation);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64.w,
            color: AppColors.orangePrimary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'All operations synced',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'No pending operations',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTile(PendingOperation operation) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getStatusColor(operation).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          _buildStatusIcon(operation),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getOperationTitle(operation),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _getOperationSubtitle(operation),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                if (operation.errorMessage != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Error: ${operation.errorMessage}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.red.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildRetryButton(operation),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(PendingOperation operation) {
    IconData icon;
    Color color;

    switch (operation.status) {
      case OperationStatus.pending:
        icon = Icons.pending;
        color = Colors.grey;
        break;
      case OperationStatus.syncing:
        icon = Icons.sync;
        color = AppColors.orangePrimary;
        break;
      case OperationStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case OperationStatus.failed:
        icon = Icons.error;
        color = AppColors.red;
        break;
    }

    return Icon(icon, color: color, size: 24.w);
  }

  String _getOperationTitle(PendingOperation operation) {
    switch (operation.type) {
      case OperationType.createIssue:
        return 'Create Issue';
      case OperationType.updateIssue:
        return 'Update Issue';
      case OperationType.closeIssue:
        return 'Close Issue';
      case OperationType.reopenIssue:
        return 'Reopen Issue';
      case OperationType.updateLabels:
        return 'Update Labels';
      case OperationType.updateAssignee:
        return 'Update Assignee';
      case OperationType.addComment:
        return 'Add Comment';
      case OperationType.deleteComment:
        return 'Delete Comment';
    }
  }

  String _getOperationSubtitle(PendingOperation operation) {
    final repo = operation.owner != null && operation.repo != null
        ? '${operation.owner}/${operation.repo}'
        : 'Unknown repo';
    final issueNum = operation.issueNumber != null
        ? '#${operation.issueNumber}'
        : 'New issue';
    return '$repo • $issueNum';
  }

  Widget _buildRetryButton(PendingOperation operation) {
    if (operation.status != OperationStatus.failed) {
      return SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.refresh, size: 20),
      color: AppColors.orangePrimary,
      onPressed: () async {
        // Reset status to pending for retry
        operation.status = OperationStatus.pending;
        operation.isSyncing = false;
        operation.errorMessage = null;
        await widget.pendingOps.init();
        // Update in storage
        await widget.pendingOps.addOperation(operation);
        widget.onRefresh?.call();
      },
      tooltip: 'Retry',
    );
  }

  Color _getStatusColor(PendingOperation operation) {
    switch (operation.status) {
      case OperationStatus.pending:
        return Colors.grey;
      case OperationStatus.syncing:
        return AppColors.orangePrimary;
      case OperationStatus.completed:
        return Colors.green;
      case OperationStatus.failed:
        return AppColors.red;
    }
  }
}
