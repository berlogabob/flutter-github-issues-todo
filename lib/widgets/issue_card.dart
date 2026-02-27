import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../models/item.dart';

/// IssueCard - Modular, reusable widget for displaying a single issue
class IssueCard extends StatelessWidget {
  final IssueItem issue;
  final ValueChanged<IssueItem>? onTap;
  final bool showRepoName;

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.showRepoName = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = issue.status == ItemStatus.open;

    return InkWell(
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
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isOpen ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Issue Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title - show issue number for GitHub issues, nothing for local
                  Text(
                    issue.isLocalOnly
                        ? '${issue.title}'
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
                            .map(
                              (label) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.orange,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
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
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Local',
                              style: const TextStyle(
                                color: AppColors.orange,
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
    );
  }
}
