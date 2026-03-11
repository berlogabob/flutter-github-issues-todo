import 'package:flutter/material.dart';
import '../models/issue_item.dart';
import '../constants/app_colors.dart';
import 'status_badge.dart';
import 'label_chip.dart';

/// Reusable search result item widget
class SearchResultItem extends StatelessWidget {
  final IssueItem issue;
  final VoidCallback onTap;

  const SearchResultItem({super.key, required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: StatusBadge(status: issue.status),
        title: Text(
          issue.isLocalOnly ? issue.title : '#${issue.number} ${issue.title}',
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (issue.labels.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: issue.labels.take(3).map((label) {
                  return LabelChipWidget(label: label);
                }).toList(),
              ),
            ],
            if (issue.assigneeLogin != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 12, color: AppColors.link),
                  const SizedBox(width: 4),
                  Text(
                    issue.assigneeLogin!,
                    style: const TextStyle(color: AppColors.link, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.error),
        onTap: onTap,
      ),
    );
  }
}
