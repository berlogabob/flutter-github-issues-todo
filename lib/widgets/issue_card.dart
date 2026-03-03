import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import 'status_badge.dart';
import 'label_chip.dart';

/// IssueCard - Modular, reusable widget for displaying a single issue
/// 
/// PERFORMANCE OPTIMIZATION (Task 16.2):
/// - Uses CachedNetworkImage for assignee avatar caching
/// - Caches images to disk with maxHeightDiskCache: 100
/// - Shows CircularProgressIndicator as placeholder
/// - Shows fallback Icon(Icons.person) on error
class IssueCard extends StatelessWidget {
  final IssueItem issue;
  final ValueChanged<IssueItem>? onTap;
  final bool showRepoName;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.showRepoName = false,
    this.onSwipeRight,
    this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('issue-${issue.id}'), // PERFORMANCE: Use ValueKey instead of Key
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppColors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.red,
        child: const Icon(Icons.close, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Trigger haptic feedback on swipe
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          onSwipeRight?.call();
        } else {
          onSwipeLeft?.call();
        }
        return false; // Don't dismiss, just trigger action
      },
      child: InkWell(
        onTap: () {
          // Trigger haptic feedback on tap
          HapticFeedback.lightImpact();
          onTap?.call(issue);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.cardBackground.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Indicator
              StatusBadge(status: issue.status),
              const SizedBox(width: 12),
              // Issue Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - show issue number for GitHub issues, nothing for local
                    Text(
                      issue.isLocalOnly
                          ? issue.title
                          : '#${issue.number} ${issue.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Metadata
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        // Labels
                        if (issue.labels.isNotEmpty)
                          ...issue.labels
                              .take(3)
                              .map((label) => LabelChipWidget(label: label)),
                        // Assignee with cached image (Task 16.2)
                        if (issue.assigneeLogin != null)
                          _buildAssigneeWithAvatar(),
                        // Local only indicator
                        if (issue.isLocalOnly)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 12,
                                color: AppColors.orangePrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Local',
                                style: const TextStyle(
                                  color: AppColors.orangePrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chevron
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.red, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Build assignee widget with cached avatar image (Task 16.2)
  /// 
  /// PERFORMANCE OPTIMIZATION:
  /// - Uses CachedNetworkImage with disk cache
  /// - maxHeightDiskCache: 100 for memory efficiency
  /// - CircularProgressIndicator as placeholder
  /// - Fallback to Icon(Icons.person) on error
  Widget _buildAssigneeWithAvatar() {
    if (issue.assigneeAvatarUrl != null && issue.assigneeAvatarUrl!.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PERFORMANCE: CachedNetworkImage with optimized settings
          CachedNetworkImage(
            imageUrl: issue.assigneeAvatarUrl!,
            width: 16,
            height: 16,
            maxHeightDiskCache: 100, // PERFORMANCE: Limit cache size
            placeholder: (context, url) => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.person,
              size: 16,
              color: AppColors.blue,
            ),
            imageBuilder: (context, imageProvider) => Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            issue.assigneeLogin!,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 11,
            ),
          ),
        ],
      );
    } else if (issue.assigneeLogin != null) {
      // Fallback to icon only if no avatar URL
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person,
            size: 12,
            color: AppColors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            issue.assigneeLogin!,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 11,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
