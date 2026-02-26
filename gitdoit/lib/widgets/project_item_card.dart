import 'package:flutter/material.dart';

import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';

/// Project Item Card - Compact card for project board items
///
/// Displays issue/PR information in a compact format
/// Used in Project Detail board view
class ProjectItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ProjectItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final content = item['content'] as Map<String, dynamic>?;

    if (content == null) {
      return _buildDraftCard(industrialTheme);
    }

    final issueNumber = content['number'] as int? ?? 0;
    final title = content['title'] as String? ?? 'Untitled';
    final state = content['state'] as String? ?? 'open';
    final labels = content['labels']?['nodes'] as List<dynamic>? ?? [];
    final assignees = content['assignees']?['nodes'] as List<dynamic>? ?? [];
    final updatedAt = content['updatedAt'] as String?;

    return IndustrialCard(
      type: IndustrialCardType.interactive,
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Issue number and title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon
              Icon(
                state == 'open'
                    ? Icons.check_circle_outline
                    : Icons.check_circle,
                size: 16,
                color: state == 'open'
                    ? industrialTheme.statusSuccess
                    : industrialTheme.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              
              // Issue number
              Text(
                '#$issueNumber',
                style: AppTypography.monoAnnotation.copyWith(
                  color: state == 'open'
                      ? industrialTheme.statusSuccess
                      : industrialTheme.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              
              // Title
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Labels
          if (labels.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: labels.take(5).map((label) {
                final colorHex = label['color'] as String? ?? 'CCCCCC';
                Color labelColor;
                try {
                  labelColor = Color(int.parse(colorHex, radix: 16) + 0xFF000000);
                } catch (e) {
                  labelColor = Colors.grey;
                }
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: labelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: labelColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label['name'] as String,
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Footer: Assignees and time
          if (assignees.isNotEmpty || updatedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                // Assignees
                if (assignees.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: assignees.take(3).map((assignee) {
                        final avatarUrl = assignee['avatarUrl'] as String?;
                        return Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: industrialTheme.surfacePrimary,
                              width: 2,
                            ),
                          ),
                          child: avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: 12,
                                      color: industrialTheme.textTertiary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 12,
                                  color: industrialTheme.textTertiary,
                                ),
                        );
                      }).toList(),
                    ),
                  ),
                
                // Updated time
                if (updatedAt != null)
                  Text(
                    _formatUpdateTime(updatedAt),
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textTertiary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDraftCard(IndustrialThemeData industrialTheme) {
    return IndustrialCard(
      type: IndustrialCardType.data,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.article_outlined,
            size: 16,
            color: industrialTheme.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Draft item',
            style: AppTypography.bodyMedium.copyWith(
              color: industrialTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpdateTime(String updatedAt) {
    try {
      final date = DateTime.parse(updatedAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}
