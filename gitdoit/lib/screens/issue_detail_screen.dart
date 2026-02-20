import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../models/issue.dart';
import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import 'edit_issue_screen.dart';

class IssueDetailScreen extends StatelessWidget {
  final Issue issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    Logger.d(
      'Building IssueDetailScreen for #${issue.number}',
      context: 'Detail',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Issue #${issue.number}'),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editIssue(context),
            tooltip: 'Edit issue',
          ),
          // Open in browser
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openInBrowser(context),
            tooltip: 'Open on GitHub',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with title and status
            _buildHeader(context),

            // Metadata section
            _buildMetadata(context),

            // Labels section
            if (issue.labels.isNotEmpty) _buildLabelsSection(context),

            // Body with markdown
            _buildBody(context),

            // Action buttons
            _buildActions(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOpen = issue.isOpen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOpen ? Icons.circle_outlined : Icons.check_circle_outline,
                size: 24,
                color: isOpen ? colorScheme.primary : colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  issue.title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Opened ${_formatDate(issue.createdAt)} by ${issue.user?.login ?? 'Unknown'}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metadataRow(
            context,
            icon: Icons.code_rounded,
            label: 'Repository',
            value: issue.repositoryUrl?.split('/').last ?? 'Unknown',
          ),
          const SizedBox(height: 12),
          _metadataRow(
            context,
            icon: Icons.calendar_today_rounded,
            label: 'Created',
            value: DateFormat('MMM d, y • h:mm a').format(issue.createdAt),
          ),
          if (issue.updatedAt != null) ...[
            const SizedBox(height: 12),
            _metadataRow(
              context,
              icon: Icons.update_rounded,
              label: 'Updated',
              value: _formatDate(issue.updatedAt!),
            ),
          ],
          if (issue.closedAt != null) ...[
            const SizedBox(height: 12),
            _metadataRow(
              context,
              icon: Icons.check_circle_rounded,
              label: 'Closed',
              value: _formatDate(issue.closedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metadataRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLabelsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Labels',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: issue.labels.map((label) {
              return _buildLabelChip(context, label);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (issue.body != null && issue.body!.isNotEmpty)
            MarkdownBody(
              data: issue.body!,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyMedium,
                code: TextStyle(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            Text(
              'No description provided.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (issue.assignees.isNotEmpty) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Assignees'),
              subtitle: Text(issue.assignees.map((a) => a.login).join(', ')),
            ),
          ],
          if (issue.milestone != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Milestone'),
              subtitle: Text(issue.milestone!.title),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final isOpen = issue.isOpen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _toggleStatus(context, issuesProvider),
                icon: Icon(
                  isOpen ? Icons.check_circle_outline : Icons.circle_outlined,
                ),
                label: Text(isOpen ? 'Close Issue' : 'Reopen Issue'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
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
      // Refresh the issue list
      Provider.of<IssuesProvider>(context, listen: false).loadIssues();
      Navigator.pop(context, true); // Return to home screen
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
        SnackBar(content: Text(isOpen ? 'Issue closed' : 'Issue reopened')),
      );
      // Update the local issue reference
      // In a real app, this would trigger a rebuild
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

  Widget _buildLabelChip(BuildContext context, dynamic label) {
    final color = _parseColor(label.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
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
