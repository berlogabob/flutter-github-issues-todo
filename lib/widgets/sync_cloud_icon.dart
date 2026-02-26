import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Cloud icon with 4 states for sync status
class SyncCloudIcon extends StatelessWidget {
  final SyncCloudState state;
  final double size;
  final bool isRotating;

  const SyncCloudIcon({
    super.key,
    required this.state,
    this.size = 24,
    this.isRotating = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon;

    switch (state) {
      case SyncCloudState.offline:
        icon = _buildCloudIcon(
          cloudColor: Colors.grey,
          badge: Icons.cloud_off,
          badgeColor: Colors.grey,
        );
        break;
      case SyncCloudState.syncing:
        icon = _buildCloudIcon(
          cloudColor: AppColors.orange,
          badge: Icons.refresh,
          badgeColor: AppColors.orange,
        );
        break;
      case SyncCloudState.synced:
        icon = _buildCloudIcon(
          cloudColor: Colors.green,
          badge: Icons.check_circle,
          badgeColor: Colors.green,
        );
        break;
      case SyncCloudState.error:
        icon = _buildCloudIcon(
          cloudColor: AppColors.red,
          badge: Icons.error,
          badgeColor: AppColors.red,
        );
        break;
    }

    if (isRotating && state == SyncCloudState.syncing) {
      return RotationTransition(
        turns: AlwaysStoppedAnimation(0.5), // 180 degrees
        child: icon,
      );
    }

    return icon;
  }

  Widget _buildCloudIcon({
    required Color cloudColor,
    required IconData badge,
    required Color badgeColor,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cloud SVG
        SvgPicture.asset(
          'assets/cloud.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(cloudColor, BlendMode.srcIn),
        ),
        // Badge icon
        Positioned(
          right: 0,
          bottom: 0,
          child: Icon(
            badge,
            size: size * 0.5,
            color: badgeColor,
          ),
        ),
      ],
    );
  }
}

/// Sync cloud states
enum SyncCloudState {
  offline,
  syncing,
  synced,
  error,
}
