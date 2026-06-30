import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Loading Skeleton widget with shimmer effect (Task 16.5)
///
/// Matches list item dimensions while [Shimmer] provides loading feedback.
class LoadingSkeleton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.3,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: _buildSkeletonItem(index),
          );
        },
      ),
    );
  }

  /// Build a single skeleton item matching issue card dimensions
  Widget _buildSkeletonItem(int index) {
    final isCompact = height < 64;
    final contentPadding = isCompact ? 8.0 : 12.0;
    final indicatorSize = isCompact ? 10.0 : 12.0;
    final titleHeight = isCompact ? 10.0 : 14.0;
    final chevronSize = isCompact ? 16.0 : 20.0;

    return Container(
      key: ValueKey('loading_skeleton_item_$index'),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Shimmer.fromColors(
          baseColor: AppColors.card,
          highlightColor: AppColors.background.withValues(alpha: 0.5),
          child: Container(
            padding: EdgeInsets.all(contentPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator skeleton (circle)
                Container(
                  width: indicatorSize,
                  height: indicatorSize,
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
                    mainAxisAlignment: isCompact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      // Title skeleton (wider rectangle)
                      Container(
                        height: titleHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      if (!isCompact) ...[
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
                    ],
                  ),
                ),
                // Chevron skeleton
                Container(
                  width: chevronSize,
                  height: chevronSize,
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Shimmer.fromColors(
          baseColor: AppColors.card,
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
