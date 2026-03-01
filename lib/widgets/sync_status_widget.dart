import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'braille_loader.dart';

/// Sync status widget that shows either:
/// - BrailleLoader animation when syncing
/// - Last sync time when not syncing
///
/// Square widget (1:1 ratio) with consistent size
class SyncStatusWidget extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final double size;

  const SyncStatusWidget({
    super.key,
    required this.isSyncing,
    this.lastSyncTime,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: _buildContent());
  }

  Widget _buildContent() {
    // Show BrailleLoader when syncing
    if (isSyncing) {
      return BrailleLoader(size: size * 0.7, color: AppColors.orange);
    }

    // Show last sync time when not syncing
    final syncText = _getSyncText();
    if (syncText.isNotEmpty) {
      return Center(
        child: Text(
          syncText,
          style: TextStyle(
            color: Colors.white54,
            fontSize: size * 0.22,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Show nothing if no sync time available
    return const SizedBox.shrink();
  }

  String _getSyncText() {
    final lastSync = lastSyncTime;
    if (lastSync == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inSeconds < 10) {
      return 'now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }
}
