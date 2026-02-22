import 'package:flutter/material.dart';

import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';

/// Cloud Sync Icon - Visual indicator for sync status in AppBar
///
/// Displays 4 states:
/// 1. [SyncState.synced] - Green cloud_done icon
/// 2. [SyncState.syncing] - Orange cloud_sync icon with rotation animation
/// 3. [SyncState.offline] - Grey cloud_off icon
/// 4. [SyncState.error] - Red cloud_off icon
///
/// Uses fast animations (100ms) for instant connectivity state changes,
/// matching the responsiveness of the notification system.
class CloudSyncIcon extends StatefulWidget {
  /// Current sync state
  final SyncState state;

  /// Size of the icon (default: 20)
  final double size;

  const CloudSyncIcon({super.key, required this.state, this.size = 20});

  @override
  State<CloudSyncIcon> createState() => _CloudSyncIconState();
}

class _CloudSyncIconState extends State<CloudSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupRotationAnimation();
  }

  @override
  void didUpdateWidget(CloudSyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation if state changed to syncing
    if (widget.state == SyncState.syncing &&
        oldWidget.state != SyncState.syncing) {
      _rotationController.repeat(reverse: false);
    } else if (widget.state != SyncState.syncing) {
      _rotationController.stop();
      _rotationController.value = 0;
    }
  }

  void _setupRotationAnimation() {
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    if (widget.state == SyncState.syncing) {
      _rotationController.repeat(reverse: false);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    // Use fast animation (100ms) for instant connectivity state changes
    return AnimatedSwitcher(
      duration: AppAnimations.durationFast,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _buildIcon(industrialTheme),
    );
  }

  Widget _buildIcon(IndustrialThemeData industrialTheme) {
    switch (widget.state) {
      case SyncState.synced:
        return Icon(
          Icons.cloud_done_outlined,
          size: widget.size,
          color: industrialTheme.statusSuccess,
          key: const ValueKey('synced'),
        );

      case SyncState.syncing:
        return RotationTransition(
          turns: _rotationAnimation,
          child: Icon(
            Icons.cloud_sync_outlined,
            size: widget.size,
            color: industrialTheme.statusWarning,
            key: const ValueKey('syncing'),
          ),
        );

      case SyncState.offline:
        return Icon(
          Icons.cloud_off_outlined,
          size: widget.size,
          color: industrialTheme.textTertiary,
          key: const ValueKey('offline'),
        );

      case SyncState.error:
        return Icon(
          Icons.cloud_off_outlined,
          size: widget.size,
          color: industrialTheme.statusError,
          key: const ValueKey('error'),
        );
    }
  }
}

/// Sync state enumeration
enum SyncState {
  /// Successfully synced - green cloud_done
  synced,

  /// Currently syncing - orange cloud_sync with rotation
  syncing,

  /// Offline/no connectivity - grey cloud_off
  offline,

  /// Sync error occurred - red cloud_off
  error,
}
