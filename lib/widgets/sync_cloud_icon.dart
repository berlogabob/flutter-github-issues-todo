import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Cloud icon with 4 states for sync status
/// Cloud stays static, only the rotation indicator circle rotates
class SyncCloudIcon extends StatefulWidget {
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
  State<SyncCloudIcon> createState() => _SyncCloudIconState();
}

class _SyncCloudIconState extends State<SyncCloudIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isRotating && widget.state == SyncCloudState.syncing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncCloudIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRotating && widget.state == SyncCloudState.syncing) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the static cloud icon
    Widget cloudIcon;

    switch (widget.state) {
      case SyncCloudState.offline:
        cloudIcon = _buildCloudIcon(
          cloudColor: Colors.grey,
          badge: Icons.cloud_off,
          badgeColor: Colors.grey,
        );
        break;
      case SyncCloudState.syncing:
        cloudIcon = _buildCloudIcon(
          cloudColor: AppColors.orange,
          badge: null, // No badge when syncing, show rotating circle instead
          badgeColor: AppColors.orange,
        );
        break;
      case SyncCloudState.synced:
        cloudIcon = _buildCloudIcon(
          cloudColor: Colors.green,
          badge: Icons.check_circle,
          badgeColor: Colors.green,
        );
        break;
      case SyncCloudState.error:
        cloudIcon = _buildCloudIcon(
          cloudColor: AppColors.red,
          badge: Icons.error,
          badgeColor: AppColors.red,
        );
        break;
    }

    // For syncing state, add rotating circle indicator
    if (widget.isRotating && widget.state == SyncCloudState.syncing) {
      return _buildCloudWithRotatingIndicator(cloudIcon);
    }

    return cloudIcon;
  }

  /// Builds cloud icon with rotating circle indicator at bottom right
  Widget _buildCloudWithRotatingIndicator(Widget cloudIcon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Static cloud icon
        cloudIcon,
        // Rotating circle indicator at bottom right
        Positioned(
          right: 0,
          bottom: 0,
          child: SizedBox(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            child: RotationTransition(
              turns: _controller,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            ),
          ),
        ),
      ],
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
