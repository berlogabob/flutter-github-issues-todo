import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../models/issue.dart';
import '../providers/issues_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/issue_detail_screen.dart';

/// Repository Issues Widget - Collapsible accordion showing repository issues
///
/// **CRITICAL BEHAVIOR:**
/// - ALL repos are collapsible with arrow toggle
/// - Arrow indicates expand/collapse state for ALL widgets
///
/// Collapsed view:
/// ┌─────────────────────────────────────┐
/// │ berlogabob/ToDo >                   │
/// │ o 12  x 43  w 12  p 23              │
/// └─────────────────────────────────────┘
///
/// Expanded view:
/// ┌─────────────────────────────────────┐
/// │ berlogabob/ToDo ^                   │
/// ├─────────────────────────────────────┤
/// │ #187 Fix login crash   ● bug   2h  │
/// │ #186 Update docs       ✓     5d    │
/// │ #185 Add feature       ● high @you │
/// └─────────────────────────────────────┘
class RepositoryIssuesWidget extends StatelessWidget {
  final String repoFullName;

  const RepositoryIssuesWidget({super.key, required this.repoFullName});

  @override
  Widget build(BuildContext context) {
    final issuesProvider = Provider.of<IssuesProvider>(context);
    final industrialTheme = context.industrialTheme;

    // ALL repos are collapsible
    final isCollapsed = issuesProvider.isRepoCollapsed(repoFullName);
    final repoIssues = issuesProvider.getFilteredRepoIssues(repoFullName);

    // Calculate stats
    final openCount = repoIssues.where((i) => i.isOpen).length;
    final closedCount = repoIssues.where((i) => i.isClosed).length;
    final withLabels = repoIssues.where((i) => i.labels.isNotEmpty).length;
    final withAssignees = repoIssues
        .where((i) => i.assignees.isNotEmpty)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: industrialTheme.surfaceElevated,
        border: Border.all(color: industrialTheme.borderPrimary, width: 1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          // Header - always visible
          _RepositoryHeader(
            repoFullName: repoFullName,
            isCollapsed: isCollapsed,
            openCount: openCount,
            closedCount: closedCount,
            withLabels: withLabels,
            withAssignees: withAssignees,
            onToggle: () => issuesProvider.toggleRepoCollapsed(repoFullName),
          ),

          // Issues list - visible when expanded
          if (!isCollapsed)
            _IssueList(issues: repoIssues, repoFullName: repoFullName),
        ],
      ),
    );
  }
}

/// Repository Header Widget
///
/// Shows repo name, expand/collapse arrow for ALL repositories
class _RepositoryHeader extends StatelessWidget {
  final String repoFullName;
  final bool isCollapsed;
  final int openCount;
  final int closedCount;
  final int withLabels;
  final int withAssignees;
  final VoidCallback onToggle;

  const _RepositoryHeader({
    required this.repoFullName,
    required this.isCollapsed,
    required this.openCount,
    required this.closedCount,
    required this.withLabels,
    required this.withAssignees,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusMedium),
        bottom: isCollapsed
            ? Radius.circular(AppSpacing.radiusMedium)
            : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: repo name + arrow (ALL repos have arrow)
            Row(
              children: [
                // Repository icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: industrialTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    size: 14,
                    color: industrialTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Repository name
                Expanded(
                  child: Text(
                    repoFullName,
                    style: AppTypography.monoData.copyWith(
                      color: industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Expand/collapse arrow (ALWAYS shown)
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0,
                  duration: AppAnimations.durationFast,
                  child: Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: industrialTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),

            // Stats row (only in collapsed state or when issues exist)
            if (isCollapsed || openCount + closedCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  // Open issues count
                  _StatBadge(
                    icon: Icons.circle_outlined,
                    count: openCount,
                    color: industrialTheme.statusSuccess,
                    label: 'open',
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Closed issues count
                  _StatBadge(
                    icon: Icons.check_circle_outline,
                    count: closedCount,
                    color: industrialTheme.textTertiary,
                    label: 'closed',
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // With labels count
                  _StatBadge(
                    icon: Icons.label_outline,
                    count: withLabels,
                    color: industrialTheme.accentPrimary,
                    label: 'tagged',
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // With assignees count
                  _StatBadge(
                    icon: Icons.person_outline,
                    count: withAssignees,
                    color: industrialTheme.textSecondary,
                    label: 'assigned',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small stat badge showing icon + count + label
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: AppTypography.monoData.copyWith(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTypography.monoAnnotation.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Issue List Widget
///
/// Displays compact issue rows when repository is expanded
/// **FIXED:** Uses ListView.builder for proper scrolling, no .take(20) limit
class _IssueList extends StatelessWidget {
  final List<Issue> issues;
  final String repoFullName;

  const _IssueList({required this.issues, required this.repoFullName});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    if (issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: industrialTheme.surfaceSecondary,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppSpacing.radiusMedium),
          ),
        ),
        child: Center(
          child: Text(
            'No issues in this repository',
            style: AppTypography.monoAnnotation.copyWith(
              color: industrialTheme.textTertiary,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: industrialTheme.surfaceSecondary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusMedium),
        ),
      ),
      // FIXED: Use ListView.builder for proper scrolling
      // Removed .take(20) limit - shows ALL issues
      child: ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return _CompactIssueRow(issue: issue, repoFullName: repoFullName);
        },
      ),
    );
  }
}

/// Compact Issue Row Widget
///
/// Shows issue in a single compact row:
/// #187 Fix login crash   ● bug   2h
///
/// **FIXED per brief:**
/// - Status: ● #238636 (open) / ✓ #6e7781 (closed) - with text labels
/// - Assignee: @username (highlight if @you)
/// - Relative time (2h, 5d)
class _CompactIssueRow extends StatelessWidget {
  final Issue issue;
  final String repoFullName;

  const _CompactIssueRow({required this.issue, required this.repoFullName});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final isOpen = issue.isOpen;

    // Get current user for @you highlighting
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUsername = authProvider.username;

    return InkWell(
      onTap: () => _navigateToDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: industrialTheme.borderPrimary,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Issue number
            SizedBox(
              width: 35,
              child: Text(
                '#${issue.number}',
                style: AppTypography.monoData.copyWith(
                  color: industrialTheme.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Title (takes remaining space)
            Expanded(
              flex: 2,
              child: Text(
                issue.title,
                style: AppTypography.bodySmall.copyWith(
                  color: industrialTheme.textPrimary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Status icon + text label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOpen ? Icons.circle_outlined : Icons.check_circle,
                  size: 14,
                  color: isOpen
                      ? industrialTheme.statusSuccess
                      : industrialTheme.textTertiary,
                ),
                const SizedBox(width: 2),
                Text(
                  isOpen ? 'open' : 'closed',
                  style: AppTypography.monoAnnotation.copyWith(
                    color: isOpen
                        ? industrialTheme.statusSuccess
                        : industrialTheme.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),

            // Labels (show up to 2)
            if (issue.labels.isNotEmpty) ...[
              Flexible(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: issue.labels
                      .take(2)
                      .map(
                        (label) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _MiniLabel(label: label),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            // Assignee with @ prefix and @you highlighting
            if (issue.assignees.isNotEmpty) ...[
              Flexible(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: issue.assignees.take(2).map((assignee) {
                    final isYou =
                        currentUsername != null &&
                        assignee.login == currentUsername;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '@${assignee.login}',
                        style: AppTypography.monoAnnotation.copyWith(
                          color: isYou
                              ? industrialTheme.accentPrimary
                              : industrialTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: isYou
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            // Time ago
            Text(
              _formatTimeAgo(issue.updatedAt ?? issue.createdAt),
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)),
    );
  }
}

/// Mini Label Chip - Very compact label display
class _MiniLabel extends StatelessWidget {
  final Label label;

  const _MiniLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(label.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label.name,
        style: AppTypography.monoAnnotation.copyWith(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
