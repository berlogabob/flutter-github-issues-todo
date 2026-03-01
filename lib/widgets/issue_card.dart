import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import 'status_badge.dart';
import 'label_chip.dart';

/// IssueCard - Modular, reusable widget for displaying a single issue
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
      key: Key('issue-${issue.id}'),
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
        if (direction == DismissDirection.startToEnd) {
          onSwipeRight?.call();
        } else {
          onSwipeLeft?.call();
        }
        return false; // Don't dismiss, just trigger action
      },
      child: InkWell(
        onTap: onTap != null ? () => onTap!(issue) : null,
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
                        // Assignee
                        if (issue.assigneeLogin != null)
                          Row(
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
                          ),
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
}
