import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/issue.dart';

/// Issue Card Widget - Displays a GitHub issue summary
///
/// Shows:
/// - Issue title and number
/// - Status (open/closed)
/// - Labels
/// - Creation date
/// - Quick actions (toggle status)
class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOpen = issue.isOpen;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon
                  Icon(
                    isOpen ? Icons.circle_outlined : Icons.check_circle_outline,
                    size: 20,
                    color: isOpen ? colorScheme.primary : colorScheme.tertiary,
                  ),
                  const SizedBox(width: 12),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Issue number and date
                        Text(
                          '#${issue.number} • ${_formatDate(issue.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  // Toggle button
                  if (onToggleStatus != null)
                    IconButton(
                      icon: Icon(
                        isOpen
                            ? Icons.check_circle_outline
                            : Icons.circle_outlined,
                      ),
                      onPressed: onToggleStatus,
                      tooltip: isOpen ? 'Close issue' : 'Reopen issue',
                      color: isOpen
                          ? colorScheme.primary
                          : colorScheme.tertiary,
                    ),
                ],
              ),

              // Labels
              if (issue.labels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: issue.labels.take(5).map((label) {
                    return _LabelChip(label: label);
                  }).toList(),
                ),
              ],

              // Body preview (if available)
              if (issue.body != null && issue.body!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  issue.body!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return DateFormat('MMM y').format(date);
    } else if (difference.inDays > 30) {
      return DateFormat('MMM d').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Label Chip Widget - Displays a GitHub label
class _LabelChip extends StatelessWidget {
  final Label label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    // Parse hex color
    final color = _parseColor(label.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(51), // 0.2 opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.grey;
  }
}
