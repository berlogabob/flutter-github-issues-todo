import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../models/issue.dart';
import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';
import 'edit_issue_screen.dart';

/// Issue Detail Screen - Full issue view with spatial depth
///
/// REDESIGNED: Industrial Minimalism with technical annotations
/// Hardware-like controls, monospace metadata
class IssueDetailScreen extends StatelessWidget {
  final Issue issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    Logger.d(
      'Building IssueDetailScreen for #${issue.number}',
      context: 'Detail',
    );

    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,

      // Custom Industrial AppBar
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_outlined,
            color: industrialTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue #${issue.number}',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          // Edit button
          IconButton(
            icon: Icon(Icons.edit_outlined, color: industrialTheme.textPrimary),
            onPressed: () => _editIssue(context),
            tooltip: 'Edit issue',
          ),
          // Open in browser
          IconButton(
            icon: Icon(
              Icons.open_in_new_outlined,
              color: industrialTheme.textPrimary,
            ),
            onPressed: () => _openInBrowser(context),
            tooltip: 'Open on GitHub',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Header with title and status
            _buildHeader(context),

            const SizedBox(height: AppSpacing.lg),

            // Metadata section
            _buildMetadata(context),

            const SizedBox(height: AppSpacing.lg),

            // Labels section
            if (issue.labels.isNotEmpty) ...[
              _buildLabelsSection(context),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Body with markdown
            _buildBody(context),

            const SizedBox(height: AppSpacing.xxl),

            // Action buttons
            _buildActions(context),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final isOpen = issue.isOpen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: IndustrialCard(
        type: IndustrialCardType.data,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge and title
            Row(
              children: [
                IndustrialStatusBadge(isOpen: isOpen),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    issue.title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: industrialTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Author and date - monospace
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: industrialTheme.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  issue.user?.login ?? 'Unknown',
                  style: AppTypography.monoData.copyWith(
                    color: industrialTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: industrialTheme.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  _formatDate(issue.createdAt),
                  style: AppTypography.monoTimestamp.copyWith(
                    color: industrialTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: IndustrialCard(
        type: IndustrialCardType.data,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Text(
              'METADATA',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _metadataRow(
              context,
              icon: Icons.folder_outlined,
              label: 'Repository',
              value: issue.repositoryUrl?.split('/').last ?? 'Unknown',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDivider(industrialTheme),
            const SizedBox(height: AppSpacing.md),
            _metadataRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Created',
              value: DateFormat('MMM d, y • h:mm a').format(issue.createdAt),
            ),
            if (issue.updatedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDivider(industrialTheme),
              const SizedBox(height: AppSpacing.md),
              _metadataRow(
                context,
                icon: Icons.update_outlined,
                label: 'Updated',
                value: _formatDate(issue.updatedAt!),
              ),
            ],
            if (issue.closedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDivider(industrialTheme),
              const SizedBox(height: AppSpacing.md),
              _metadataRow(
                context,
                icon: Icons.check_circle_outlined,
                label: 'Closed',
                value: _formatDate(issue.closedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metadataRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final industrialTheme = context.industrialTheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: industrialTheme.textTertiary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.monoAnnotation.copyWith(
                  color: industrialTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.monoData.copyWith(
                  color: industrialTheme.textPrimary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabelsSection(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: IndustrialCard(
        type: IndustrialCardType.data,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LABELS',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: issue.labels.map((label) {
                return IndustrialLabelBadge(
                  label: label.name,
                  colorHex: label.color,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: IndustrialCard(
        type: IndustrialCardType.data,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DESCRIPTION',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (issue.body != null && issue.body!.isNotEmpty)
              MarkdownBody(
                data: issue.body!,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.bodyMedium.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                  h1: AppTypography.headlineSmall.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                  h2: AppTypography.headlineSmall.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                  h3: AppTypography.headlineSmall.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                  code: AppTypography.monoCode.copyWith(
                    color: industrialTheme.textPrimary,
                    backgroundColor: industrialTheme.surfacePrimary,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: industrialTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(
                      color: industrialTheme.borderPrimary,
                      width: 1,
                    ),
                  ),
                  blockquote: AppTypography.bodyMedium.copyWith(
                    color: industrialTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: industrialTheme.accentPrimary,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                'No description provided.',
                style: AppTypography.bodyMedium.copyWith(
                  color: industrialTheme.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: IndustrialCard(
        type: IndustrialCardType.data,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DETAILS',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (issue.assignees.isNotEmpty) ...[
              _actionRow(
                context,
                icon: Icons.people_outline,
                label: 'Assignees',
                value: issue.assignees.map((a) => a.login).join(', '),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDivider(industrialTheme),
              const SizedBox(height: AppSpacing.md),
            ],

            if (issue.milestone != null) ...[
              _actionRow(
                context,
                icon: Icons.flag_outlined,
                label: 'Milestone',
                value: issue.milestone!.title,
              ),
            ],

            if (issue.assignees.isEmpty && issue.milestone == null)
              Text(
                'No additional details',
                style: AppTypography.bodySmall.copyWith(
                  color: industrialTheme.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final industrialTheme = context.industrialTheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: industrialTheme.textTertiary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.monoAnnotation.copyWith(
                  color: industrialTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: industrialTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(IndustrialThemeData industrialTheme) {
    return Container(height: 1, color: industrialTheme.borderPrimary);
  }

  Widget _buildBottomBar(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final isOpen = issue.isOpen;

    return Container(
      decoration: BoxDecoration(
        color: industrialTheme.surfaceElevated,
        border: Border(
          top: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: IndustrialButton(
          onPressed: () => _toggleStatus(context, issuesProvider),
          label: isOpen ? 'CLOSE ISSUE' : 'REOPEN ISSUE',
          variant: isOpen
              ? IndustrialButtonVariant.secondary
              : IndustrialButtonVariant.primary,
          icon: Icon(
            isOpen ? Icons.check_circle_outlined : Icons.circle_outlined,
            size: 18,
          ),
          isFullWidth: true,
          size: IndustrialButtonSize.large,
        ),
      ),
    );
  }

  void _editIssue(BuildContext context) async {
    Logger.d('Edit issue #${issue.number}', context: 'Detail');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditIssueScreen(issue: issue)),
    );

    if (result == true && context.mounted) {
      Provider.of<IssuesProvider>(context, listen: false).loadIssues();
      Navigator.pop(context, true);
    }
  }

  Future<void> _openInBrowser(BuildContext context) async {
    if (issue.htmlUrl != null) {
      final uri = Uri.parse(issue.htmlUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Logger.e('Cannot open URL: ${issue.htmlUrl}', context: 'Detail');
      }
    }
  }

  Future<void> _toggleStatus(
    BuildContext context,
    IssuesProvider issuesProvider,
  ) async {
    final isOpen = issue.isOpen;
    final result = await issuesProvider.updateIssue(
      issueNumber: issue.number,
      state: isOpen ? 'closed' : 'open',
    );

    if (!context.mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isOpen ? 'Issue closed' : 'Issue reopened'),
          backgroundColor: context.industrialTheme.accentPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update issue')));
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return DateFormat('MMM d, y').format(date);
    } else if (diff.inDays > 30) {
      return DateFormat('MMM d').format(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
