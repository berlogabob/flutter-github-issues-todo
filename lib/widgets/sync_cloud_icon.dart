import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Cloud icon with 4 states for sync status
/// Cloud stays static, only color/badge changes
class SyncCloudIcon extends StatefulWidget {
  final SyncCloudState state;
  final double size;

  const SyncCloudIcon({super.key, required this.state, this.size = 24});

  @override
  State<SyncCloudIcon> createState() => _SyncCloudIconState();
}

class _SyncCloudIconState extends State<SyncCloudIcon> {
  @override
  Widget build(BuildContext context) {
    Widget cloudIcon = _buildCloudIcon(
      cloudColor: _getCloudColor(),
      badge: _getBadgeIcon(),
      badgeColor: _getCloudColor(),
    );

    // Build stack with appropriate badge
    return Stack(
      alignment: Alignment.center,
      children: [
        cloudIcon,
        // Status badges - static, no rotation
        if (widget.state == SyncCloudState.offline)
          _buildStatusBadge(Icons.cloud_off, AppColors.secondaryText),
        if (widget.state == SyncCloudState.synced)
          _buildStatusBadge(Icons.check_circle, Colors.green),
        if (widget.state == SyncCloudState.error)
          _buildStatusBadge(Icons.error, AppColors.red),
        // For syncing state, just show orange dot (no rotation)
        if (widget.state == SyncCloudState.syncing) _buildSyncingIndicator(),
      ],
    );
  }

  /// Get cloud color based on state
  Color _getCloudColor() {
    switch (widget.state) {
      case SyncCloudState.offline:
        return Colors.grey;
      case SyncCloudState.syncing:
        return AppColors.orangePrimary;
      case SyncCloudState.synced:
        return Colors.green;
      case SyncCloudState.error:
        return AppColors.red;
    }
  }

  /// Get badge icon based on state (null for syncing)
  IconData? _getBadgeIcon() {
    switch (widget.state) {
      case SyncCloudState.offline:
        return Icons.cloud_off;
      case SyncCloudState.syncing:
        return null; // No icon badge when syncing, use orange dot instead
      case SyncCloudState.synced:
        return Icons.check_circle;
      case SyncCloudState.error:
        return Icons.error;
    }
  }

  /// Static indicator for syncing state (orange dot)
  Widget _buildSyncingIndicator() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: widget.size * 0.3,
        height: widget.size * 0.3,
        decoration: BoxDecoration(
          color: AppColors.orangePrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(IconData icon, Color color) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: widget.size * 0.5,
        height: widget.size * 0.5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: widget.size * 0.3, color: Colors.white),
      ),
    );
  }

  Widget _buildCloudIcon({
    required Color cloudColor,
    IconData? badge,
    required Color badgeColor,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cloud SVG
        SvgPicture.asset(
          'assets/cloud.svg',
          width: widget.size,
          height: widget.size,
          colorFilter: ColorFilter.mode(cloudColor, BlendMode.srcIn),
        ),
        // Badge icon (if provided)
        if (badge != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(badge, size: widget.size * 0.5, color: badgeColor),
          ),
      ],
    );
  }
}

/// Sync cloud states
enum SyncCloudState { offline, syncing, synced, error }
