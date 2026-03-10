import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Loading Skeleton widget with shimmer effect (Task 16.5)
///
/// PERFORMANCE OPTIMIZATION:
/// - Uses AnimatedOpacity for smooth fade animation
/// - Matches list item dimensions for consistent layout
/// - Uses AppColors.cardBackground and AppColors.background
/// - Replaces BrailleLoader in list loading states
/// - Provides visual feedback during data loading
class LoadingSkeleton extends StatefulWidget {
  /// Height of the skeleton item
  final double height;

  /// Width of the skeleton item (defaults to full width)
  final double? width;

  /// Border radius for rounded corners
  final double borderRadius;

  /// Number of skeleton items to display
  final int itemCount;

  /// Spacing between skeleton items
  final double spacing;

  const LoadingSkeleton({
    super.key,
    this.height = 80.0,
    this.width,
    this.borderRadius = 8.0,
    this.itemCount = 5,
    this.spacing = 12.0,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // PERFORMANCE: AnimatedOpacity for smooth fade animation (Task 16.5)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacityAnimation.value,
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: widget.spacing),
            child: _buildSkeletonItem(),
          );
        },
      ),
    );
  }

  /// Build a single skeleton item matching issue card dimensions
  Widget _buildSkeletonItem() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Shimmer.fromColors(
          baseColor: AppColors.cardBackground,
          highlightColor: AppColors.background.withValues(alpha: 0.5),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator skeleton (circle)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Content skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title skeleton (wider rectangle)
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Metadata skeleton (shorter rectangles)
                      Row(
                        children: [
                          // Label chip skeleton
                          Container(
                            height: 16,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Assignee skeleton
                          Container(
                            height: 16,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chevron skeleton
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Repo header skeleton for repository loading state
class RepoHeaderSkeleton extends StatelessWidget {
  const RepoHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Shimmer.fromColors(
          baseColor: AppColors.cardBackground,
          highlightColor: AppColors.background.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Expand icon skeleton
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                // Repo icon skeleton
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                // Repo info skeleton
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      // Title
                      SizedBox(
                        height: 16,
                        width: 150,
                        child: Placeholder(
                          color: Colors.white,
                          fallbackHeight: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Description
                      SizedBox(
                        height: 12,
                        width: 100,
                        child: Placeholder(
                          color: Colors.white,
                          fallbackHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge skeleton
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
