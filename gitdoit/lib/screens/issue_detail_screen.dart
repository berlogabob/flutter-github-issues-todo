import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../providers/issues_provider.dart';
import '../../models/issue.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';
import '../utils/logging.dart';
import '../widgets/label_chip.dart';

/// Issue Detail Screen - Full issue view with Markdown, comments, timeline
///
/// Displays:
/// - Full issue details with Markdown rendering
/// - Labels and assignees
/// - Comments section
/// - Timeline events
/// - Actions (Edit, Close, Assign, etc.)
class IssueDetailScreen extends StatefulWidget {
  final Issue issue;

  const IssueDetailScreen({
    super.key,
    required this.issue,
  });

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  bool _isEditing = false;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.issue.title;
    _bodyController.text = widget.issue.body ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issue = widget.issue;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      
      // Custom AppBar
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: industrialTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '#${issue.number}',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Edit button
          if (!_isEditing)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: industrialTheme.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          // Save button
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.check,
                color: industrialTheme.statusSuccess,
              ),
              onPressed: () => _saveChanges(),
            ),
          // More actions
          PopupMenuButton<String>(
            color: industrialTheme.surfaceElevated,
            onSelected: (value) => _handleAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'assign',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 18,
                      color: industrialTheme.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Assign',
                      style: AppTypography.bodyMedium.copyWith(
                        color: industrialTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: issue.isOpen ? 'close' : 'reopen',
                child: Row(
                  children: [
                    Icon(
                      issue.isOpen
                          ? Icons.check_circle_outline
                          : Icons.refresh,
                      size: 18,
                      color: issue.isOpen
                          ? industrialTheme.statusSuccess
                          : industrialTheme.accentPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      issue.isOpen ? 'Close' : 'Reopen',
                      style: AppTypography.bodyMedium.copyWith(
                        color: issue.isOpen
                            ? industrialTheme.statusSuccess
                            : industrialTheme.accentPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header: Status, Title, Author
          _buildHeader(issue, industrialTheme),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Labels
          if (issue.labels.isNotEmpty) ...[
            _buildSectionLabel(industrialTheme, 'LABELS'),
            const SizedBox(height: AppSpacing.sm),
            _buildLabels(issue.labels, industrialTheme),
            const SizedBox(height: AppSpacing.xl),
          ],
          
          // Assignees
          if (issue.assignees.isNotEmpty) ...[
            _buildSectionLabel(industrialTheme, 'ASSIGNEES'),
            const SizedBox(height: AppSpacing.sm),
            _buildAssignees(issue.assignees, industrialTheme),
            const SizedBox(height: AppSpacing.xl),
          ],
          
          // Description
          _buildSectionLabel(industrialTheme, 'DESCRIPTION'),
          const SizedBox(height: AppSpacing.sm),
          _buildDescription(issue, industrialTheme),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Timeline/Comments placeholder
          _buildSectionLabel(industrialTheme, 'ACTIVITY'),
          const SizedBox(height: AppSpacing.sm),
          _buildActivityPlaceholder(industrialTheme),
          
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),

      // FAB for quick actions
      floatingActionButton: _isEditing
          ? FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _titleController.text = widget.issue.title;
                  _bodyController.text = widget.issue.body ?? '';
                });
              },
              backgroundColor: industrialTheme.statusError,
              child: Icon(
                Icons.close,
                color: industrialTheme.surfacePrimary,
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(Issue issue, IndustrialThemeData industrialTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: industrialTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: issue.isOpen
              ? industrialTheme.statusSuccess.withOpacity(0.3)
              : industrialTheme.textTertiary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              Icon(
                issue.isOpen
                    ? Icons.check_circle_outline
                    : Icons.check_circle,
                size: 18,
                color: issue.isOpen
                    ? industrialTheme.statusSuccess
                    : industrialTheme.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                issue.isOpen ? 'OPEN' : 'CLOSED',
                style: AppTypography.labelMedium.copyWith(
                  color: issue.isOpen
                      ? industrialTheme.statusSuccess
                      : industrialTheme.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Issue number
              Text(
                '#${issue.number}',
                style: AppTypography.monoAnnotation.copyWith(
                  color: industrialTheme.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Title or Edit
          if (_isEditing)
            IndustrialInput(
              label: 'TITLE',
              controller: _titleController,
              inputType: IndustrialInputType.text,
            )
          else
            Text(
              issue.title,
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Author and time
          Row(
            children: [
              if (issue.user != null) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: industrialTheme.surfacePrimary,
                  child: Text(
                    issue.user!.login.substring(0, 1).toUpperCase(),
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  issue.user!.login,
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                'opened ${_formatRelativeTime(issue.createdAt)}',
                style: AppTypography.captionSmall.copyWith(
                  color: industrialTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(IndustrialThemeData industrialTheme, String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          color: industrialTheme.accentPrimary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLabels(List<Label> labels, IndustrialThemeData industrialTheme) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: labels.map((label) {
        return LabelChip(label: label);
      }).toList(),
    );
  }

  Widget _buildAssignees(
    List<User> assignees,
    IndustrialThemeData industrialTheme,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: assignees.map((assignee) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: industrialTheme.surfacePrimary,
              child: Text(
                assignee.login.substring(0, 1).toUpperCase(),
                style: AppTypography.captionSmall.copyWith(
                  color: industrialTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              assignee.login,
              style: AppTypography.bodySmall.copyWith(
                color: industrialTheme.textPrimary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDescription(Issue issue, IndustrialThemeData industrialTheme) {
    if (_isEditing) {
      return IndustrialInput(
        label: 'DESCRIPTION',
        controller: _bodyController,
        inputType: IndustrialInputType.text,
        maxLines: 10,
      );
    }

    if (issue.body == null || issue.body!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Text(
          'No description provided.',
          style: AppTypography.bodyMedium.copyWith(
            color: industrialTheme.textTertiary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: industrialTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: industrialTheme.borderPrimary,
          width: 1,
        ),
      ),
      child: MarkdownBody(
        data: issue.body!,
        styleSheet: MarkdownStyleSheet(
          p: AppTypography.bodyMedium.copyWith(
            color: industrialTheme.textPrimary,
          ),
          h1: AppTypography.headlineMedium.copyWith(
            color: industrialTheme.textPrimary,
          ),
          h2: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
          h3: AppTypography.bodyMedium.copyWith(
            color: industrialTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          code: AppTypography.monoData.copyWith(
            color: industrialTheme.accentPrimary,
            backgroundColor: industrialTheme.surfacePrimary,
          ),
          codeblockDecoration: BoxDecoration(
            color: industrialTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: industrialTheme.borderPrimary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityPlaceholder(IndustrialThemeData industrialTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: industrialTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: industrialTheme.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: industrialTheme.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Activity Timeline',
            style: AppTypography.bodyMedium.copyWith(
              color: industrialTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Comments and events will appear here',
            style: AppTypography.captionSmall.copyWith(
              color: industrialTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          IndustrialButton(
            onPressed: () {
              Logger.d('Add comment clicked', context: 'IssueDetail');
            },
            label: 'ADD COMMENT',
            variant: IndustrialButtonVariant.secondary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else {
      return '${(diff.inDays / 365).floor()}y ago';
    }
  }

  Future<void> _saveChanges() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    
    try {
      await issuesProvider.updateIssue(
        issueNumber: widget.issue.number,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim().isEmpty
            ? null
            : _bodyController.text.trim(),
      );

      if (!mounted) return;
      
      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: context.industrialTheme.surfacePrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Issue updated successfully',
                style: AppTypography.labelSmall.copyWith(
                  color: context.industrialTheme.surfacePrimary,
                ),
              ),
            ],
          ),
          backgroundColor: context.industrialTheme.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update issue: $e'),
          backgroundColor: context.industrialTheme.statusError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleAction(String action) async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    
    try {
      switch (action) {
        case 'assign':
          Logger.d('Assign action', context: 'IssueDetail');
          // TODO: Show assignee picker
          break;
        case 'close':
          await issuesProvider.closeIssue(widget.issue.number);
          if (!mounted) return;
          Navigator.pop(context, true); // Return to refresh list
          break;
        case 'reopen':
          await issuesProvider.reopenIssue(widget.issue.number);
          if (!mounted) return;
          Navigator.pop(context, true); // Return to refresh list
          break;
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
          backgroundColor: context.industrialTheme.statusError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
