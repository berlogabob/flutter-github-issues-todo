import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/issue.dart';
import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';

/// Edit Issue Screen - Edit title, body, and status
///
/// REDESIGNED: Industrial Minimalism with hardware-like controls
/// Real-time preview, fader-style controls
class EditIssueScreen extends StatefulWidget {
  final Issue issue;

  const EditIssueScreen({super.key, required this.issue});

  @override
  State<EditIssueScreen> createState() => _EditIssueScreenState();
}

class _EditIssueScreenState extends State<EditIssueScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.issue.title);
    _bodyController = TextEditingController(text: widget.issue.body ?? '');

    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && _hasChanges) {
          _confirmDiscardChanges();
        }
      },
      child: Scaffold(
        backgroundColor: industrialTheme.surfacePrimary,

        // Custom Industrial AppBar
        appBar: AppBar(
          backgroundColor: industrialTheme.surfacePrimary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close_outlined,
              color: industrialTheme.textPrimary,
            ),
            onPressed: () {
              if (_hasChanges) {
                _confirmDiscardChanges();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'EDIT ISSUE',
            style: AppTypography.monoAnnotation.copyWith(
              color: industrialTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            // Save button
            IndustrialButton(
              onPressed: _isLoading ? null : _saveChanges,
              label: 'SAVE',
              variant: IndustrialButtonVariant.primary,
              size: IndustrialButtonSize.small,
              isLoading: _isLoading,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              IndustrialInput(
                label: 'TITLE',
                hintText: 'Issue title',
                controller: _titleController,
                maxLines: null,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Body field
              IndustrialInput(
                label: 'DESCRIPTION (MARKDOWN)',
                hintText: 'Enter issue description',
                controller: _bodyController,
                inputType: IndustrialInputType.multiline,
                maxLines: 10,
                minLines: 5,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Preview section (if changes made)
              if (_hasChanges) ...[
                IndustrialCard(
                  type: IndustrialCardType.data,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: industrialTheme.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'PREVIEW',
                            style: AppTypography.monoAnnotation.copyWith(
                              color: industrialTheme.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPreview(industrialTheme),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Status toggle section
              IndustrialCard(
                type: IndustrialCardType.data,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_outlined,
                          size: 18,
                          color: industrialTheme.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'STATUS CONTROL',
                          style: AppTypography.monoAnnotation.copyWith(
                            color: industrialTheme.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Status indicator
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT STATE',
                                style: AppTypography.monoAnnotation.copyWith(
                                  color: industrialTheme.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              IndustrialStatusBadge(
                                isOpen: widget.issue.isOpen,
                                size: IndustrialBadgeSize.large,
                              ),
                            ],
                          ),
                        ),

                        // Toggle control
                        IndustrialToggle(
                          value: widget.issue.isOpen,
                          onChanged: (value) =>
                              _changeStatus(value ? 'open' : 'closed'),
                          enabled: !_isLoading,
                          size: IndustrialToggleSize.large,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Status action buttons
                    Row(
                      children: [
                        Expanded(
                          child: IndustrialButton(
                            onPressed: widget.issue.isOpen
                                ? null
                                : () => _changeStatus('open'),
                            label: 'SET OPEN',
                            variant: IndustrialButtonVariant.secondary,
                            size: IndustrialButtonSize.small,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: IndustrialButton(
                            onPressed: widget.issue.isOpen
                                ? () => _changeStatus('closed')
                                : null,
                            label: 'SET CLOSED',
                            variant: widget.issue.isOpen
                                ? IndustrialButtonVariant.primary
                                : IndustrialButtonVariant.secondary,
                            size: IndustrialButtonSize.small,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Technical annotation
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _hasChanges
                            ? industrialTheme.accentPrimary
                            : industrialTheme.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _hasChanges ? 'UNSAVED CHANGES' : 'NO CHANGES',
                      style: AppTypography.monoAnnotation.copyWith(
                        color: _hasChanges
                            ? industrialTheme.accentPrimary
                            : industrialTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(IndustrialThemeData industrialTheme) {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    return IndustrialCard(
      type: IndustrialCardType.data,
      backgroundColor: industrialTheme.surfacePrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? '(No title)' : title,
            style: AppTypography.headlineSmall.copyWith(
              color: industrialTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            MarkdownBody(
              data: body,
              styleSheet: MarkdownStyleSheet(
                p: AppTypography.bodyMedium.copyWith(
                  color: industrialTheme.textPrimary,
                ),
                code: AppTypography.monoCode.copyWith(
                  color: industrialTheme.textPrimary,
                  backgroundColor: industrialTheme.surfacePrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => _isLoading = true);

    Logger.i('Saving issue #${widget.issue.number}', context: 'Edit');

    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final result = await issuesProvider.updateIssue(
      issueNumber: widget.issue.number,
      title: title,
      body: body.isEmpty ? null : body,
    );

    if (!context.mounted) return;

    setState(() => _isLoading = false);

    if (result != null) {
      Logger.i('Issue updated successfully', context: 'Edit');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Issue updated successfully'),
          backgroundColor: context.industrialTheme.statusSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      Logger.e('Failed to update issue', context: 'Edit');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update issue')));
    }
  }

  Future<void> _changeStatus(String status) async {
    setState(() => _isLoading = true);

    Logger.i(
      'Changing issue #${widget.issue.number} to $status',
      context: 'Edit',
    );

    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final result = await issuesProvider.updateIssue(
      issueNumber: widget.issue.number,
      state: status,
    );

    if (!context.mounted) return;

    setState(() => _isLoading = false);

    if (result != null) {
      Logger.i('Issue $status successfully', context: 'Edit');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Issue $status successfully'),
          backgroundColor: context.industrialTheme.accentPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      Logger.e('Failed to change status', context: 'Edit');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to change status')));
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) {
      return true;
    }

    final industrialTheme = context.industrialTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'DISCARD CHANGES?',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: AppTypography.bodyMedium.copyWith(
            color: industrialTheme.textSecondary,
          ),
        ),
        actions: [
          IndustrialButton(
            onPressed: () => Navigator.pop(context, false),
            label: 'CANCEL',
            variant: IndustrialButtonVariant.text,
            size: IndustrialButtonSize.small,
          ),
          IndustrialButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'DISCARD',
            variant: IndustrialButtonVariant.destructive,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}
