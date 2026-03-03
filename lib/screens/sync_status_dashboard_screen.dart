import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../services/sync_service.dart';
import '../services/pending_operations_service.dart';
import '../models/sync_history_entry.dart';
import '../widgets/braille_loader.dart';
import '../widgets/pending_operations_list.dart';
import '../widgets/sync_cloud_icon.dart';

/// Sync Status Dashboard - Detailed view of sync status and history
///
/// Features:
/// - Current sync status with visual indicator
/// - Last sync time per repository
/// - Pending operations list with actions
/// - Sync history log (last 10 syncs)
/// - Sync statistics
/// - Manual sync trigger
class SyncStatusDashboardScreen extends ConsumerStatefulWidget {
  const SyncStatusDashboardScreen({super.key});

  @override
  ConsumerState<SyncStatusDashboardScreen> createState() =>
      _SyncStatusDashboardScreenState();
}

class _SyncStatusDashboardScreenState
    extends ConsumerState<SyncStatusDashboardScreen> {
  final SyncService _syncService = SyncService();
  final PendingOperationsService _pendingOps = PendingOperationsService();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Sync Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.orangePrimary,
            onPressed: _isSyncing ? null : _triggerSync,
            tooltip: 'Sync Now',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _triggerSync,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Current Status Card
            _buildCurrentStatusCard(),
            SizedBox(height: 16.h),

            // Statistics Card
            _buildStatisticsCard(),
            SizedBox(height: 16.h),

            // Pending Operations Section
            _buildPendingOperationsSection(),
            SizedBox(height: 16.h),

            // Sync History Section
            _buildSyncHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final syncStatus = _syncService.syncStatus;
    final lastSyncTime = _syncService.lastSyncTime;
    final isNetworkAvailable = _syncService.isNetworkAvailable;

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Sync Icon with Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSyncing)
                  BrailleLoader(size: 32.w)
                else
                  SyncCloudIcon(
                    state: _getSyncCloudState(),
                    size: 48.w,
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // Status Text
            Text(
              _getStatusText(syncStatus),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(syncStatus),
              ),
            ),
            SizedBox(height: 8.h),

            // Last Sync Time
            Text(
              lastSyncTime != null
                  ? 'Last sync: ${_formatLastSyncTime(lastSyncTime)}'
                  : 'Never synced',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 8.h),

            // Network Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNetworkAvailable ? Icons.wifi : Icons.wifi_off,
                  size: 16.w,
                  color: isNetworkAvailable
                      ? Colors.green
                      : Colors.grey.withValues(alpha: 0.5),
                ),
                SizedBox(width: 8.w),
                Text(
                  isNetworkAvailable ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isNetworkAvailable
                        ? Colors.green
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Manual Sync Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _triggerSync,
                icon: const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangePrimary,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final pendingCount = _pendingOps.getPendingCount();
    final stats = _syncService.getSyncStatistics();
    final conflictCount = _syncService.getConflictCount();

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                _buildStatItem(
                  'Pending',
                  pendingCount.toString(),
                  Icons.pending,
                  pendingCount > 0
                      ? AppColors.orangePrimary
                      : Colors.green,
                ),
                _buildStatItem(
                  'Synced',
                  stats.totalIssuesSynced.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Conflicts',
                  conflictCount.toString(),
                  Icons.warning_amber,
                  conflictCount > 0
                      ? AppColors.red
                      : Colors.green,
                ),
                _buildStatItem(
                  'Success Rate',
                  '${stats.successRate.toStringAsFixed(0)}%',
                  Icons.show_chart,
                  stats.successRate >= 80
                      ? Colors.green
                      : stats.successRate >= 50
                          ? AppColors.orangePrimary
                          : AppColors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOperationsSection() {
    final pendingCount = _pendingOps.getPendingCount();

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Operations',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.orangePrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangePrimary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            PendingOperationsList(
              pendingOps: _pendingOps,
              onRefresh: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncHistorySection() {
    final history = _syncService.getSyncHistory();
    final stats = _syncService.getSyncStatistics();

    if (history.isEmpty) {
      return Card(
        color: AppColors.cardBackground,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sync History',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48.w,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No sync history yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sync History',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${stats.successRate.toStringAsFixed(0)}% success',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: stats.successRate >= 80
                        ? Colors.green
                        : stats.successRate >= 50
                            ? AppColors.orangePrimary
                            : AppColors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final entry = history[index];
                return _buildHistoryEntry(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEntry(SyncHistoryEntry entry) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _getResultColor(entry.result).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getResultIcon(entry.result),
            color: _getResultColor(entry.result),
            size: 20.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getResultText(entry.result),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_formatDateTime(entry.timestamp)} • ${entry.duration.inSeconds}s',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${entry.issuesSynced}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orangePrimary,
                ),
              ),
              Text(
                'issues',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getResultIcon(SyncResult result) {
    switch (result) {
      case SyncResult.success:
        return Icons.check_circle;
      case SyncResult.partial:
        return Icons.warning;
      case SyncResult.failed:
        return Icons.error;
    }
  }

  String _getResultText(SyncResult result) {
    switch (result) {
      case SyncResult.success:
        return 'Sync Successful';
      case SyncResult.partial:
        return 'Partial Success';
      case SyncResult.failed:
        return 'Sync Failed';
    }
  }

  Color _getResultColor(SyncResult result) {
    switch (result) {
      case SyncResult.success:
        return Colors.green;
      case SyncResult.partial:
        return AppColors.orangePrimary;
      case SyncResult.failed:
        return AppColors.red;
    }
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  SyncCloudState _getSyncCloudState() {
    if (!_syncService.isNetworkAvailable) {
      return SyncCloudState.offline;
    }
    if (_syncService.isSyncing || _isSyncing) {
      return SyncCloudState.syncing;
    }
    return SyncCloudState.synced;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'idle':
        return 'Ready to Sync';
      case 'syncing':
        return 'Syncing...';
      case 'success':
        return 'Sync Successful';
      case 'error':
        return 'Sync Error';
      default:
        return 'Unknown Status';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'idle':
        return Colors.grey;
      case 'syncing':
        return AppColors.orangePrimary;
      case 'success':
        return Colors.green;
      case 'error':
        return AppColors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatLastSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);

    try {
      await _syncService.syncAll(forceRefresh: true);
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sync completed successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Sync failed: $e'),
                ),
              ],
            ),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}
