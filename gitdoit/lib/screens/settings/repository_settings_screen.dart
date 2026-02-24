import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/issues_provider.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';
import '../../utils/logger.dart';

/// Repository Settings Screen - Default repository configuration
class RepositorySettingsScreen extends StatefulWidget {
  const RepositorySettingsScreen({super.key});

  @override
  State<RepositorySettingsScreen> createState() =>
      _RepositorySettingsScreenState();
}

class _RepositorySettingsScreenState extends State<RepositorySettingsScreen> {
  _RepositoryDialogStatus _status = _RepositoryDialogStatus.idle;
  String? _validationError;

  @override
  Widget build(BuildContext context) {
    Logger.d('Building RepositorySettingsScreen', context: 'Settings');

    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: Text(
          'REPOSITORY',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Current repository section
          _buildSectionHeader(context, 'CURRENT'),
          const SizedBox(height: AppSpacing.md),
          Consumer<IssuesProvider>(
            builder: (context, issues, _) {
              return _CurrentRepositoryCard(
                owner: issues.owner,
                repo: issues.repo,
                onEdit: () => _showRepositoryDialog(context, issues),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Actions section
          _buildSectionHeader(context, 'ACTIONS'),
          const SizedBox(height: AppSpacing.md),
          Consumer<IssuesProvider>(
            builder: (context, issues, _) {
              return _SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Change Repository',
                subtitle: 'Update default repository',
                onTap: () => _showRepositoryDialog(context, issues),
                enabled: !issues.isLoading,
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Repository',
            subtitle: 'Remove repository configuration',
            isDestructive: true,
            onTap: () => _showClearDialog(context),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Info card
          IndustrialCard(
            type: IndustrialCardType.data,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPOSITORY',
                  style: AppTypography.monoAnnotation.copyWith(
                    color: industrialTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildInfoItem(
                  icon: Icons.folder_outlined,
                  title: 'DEFAULT REPOSITORY',
                  description: 'Used for issue operations',
                  industrialTheme: industrialTheme,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildDivider(industrialTheme),
                const SizedBox(height: AppSpacing.md),
                _buildInfoItem(
                  icon: Icons.cloud_sync_outlined,
                  title: 'AUTO-SYNC',
                  description: 'Issues sync automatically',
                  industrialTheme: industrialTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final industrialTheme = context.industrialTheme;

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: industrialTheme.accentPrimary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showRepositoryDialog(BuildContext context, IssuesProvider issues) {
    final ownerController = TextEditingController();
    final repoController = TextEditingController();
    final industrialTheme = context.industrialTheme;

    // Pre-fill with existing repository if configured
    if (issues.repository != null) {
      ownerController.text = issues.owner;
      repoController.text = issues.repo;
    }

    showDialog(
      context: context,
      barrierDismissible: _status == _RepositoryDialogStatus.idle,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: industrialTheme.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
          ),
          title: Row(
            children: [
              Icon(
                _status == _RepositoryDialogStatus.validating
                    ? Icons.hourglass_empty
                    : _status == _RepositoryDialogStatus.success
                        ? Icons.check_circle
                        : _status == _RepositoryDialogStatus.error
                            ? Icons.error_outline
                            : Icons.folder_outlined,
                color: _status == _RepositoryDialogStatus.validating
                    ? industrialTheme.accentPrimary
                    : _status == _RepositoryDialogStatus.success
                        ? industrialTheme.statusSuccess
                        : _status == _RepositoryDialogStatus.error
                            ? industrialTheme.statusError
                            : industrialTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'SET REPOSITORY',
                  style: AppTypography.headlineSmall.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IndustrialInput(
                label: 'OWNER',
                hintText: 'e.g., berlogabob',
                controller: ownerController,
                enabled: _status == _RepositoryDialogStatus.idle,
              ),
              const SizedBox(height: AppSpacing.lg),
              IndustrialInput(
                label: 'REPOSITORY',
                hintText: 'e.g., flutter-github-issues-todo',
                controller: repoController,
                enabled: _status == _RepositoryDialogStatus.idle,
              ),
              if (_validationError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _validationError!,
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.statusError,
                  ),
                ),
              ],
              if (_status == _RepositoryDialogStatus.validating) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      industrialTheme.accentPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IndustrialButton(
              onPressed: _status == _RepositoryDialogStatus.validating
                  ? null
                  : () => Navigator.pop(context),
              label: 'CANCEL',
              variant: IndustrialButtonVariant.text,
              size: IndustrialButtonSize.small,
            ),
            IndustrialButton(
              onPressed: _status == _RepositoryDialogStatus.validating
                  ? null
                  : () async {
                      setDialogState(() {
                        _status = _RepositoryDialogStatus.validating;
                        _validationError = null;
                      });

                      final owner = ownerController.text.trim();
                      final repo = repoController.text.trim();

                      if (owner.isEmpty || repo.isEmpty) {
                        setDialogState(() {
                          _status = _RepositoryDialogStatus.error;
                          _validationError =
                              'Please fill in both owner and repository';
                        });
                        return;
                      }

                      Logger.i(
                        'Setting repository: $owner/$repo',
                        context: 'Settings',
                      );
                      issues.setRepository(owner, repo);

                      // Validate repository
                      try {
                        final isValid = await issues.validateRepository(
                            owner, repo);

                        if (!context.mounted) return;

                        setDialogState(() {
                          _status = isValid
                              ? _RepositoryDialogStatus.success
                              : _RepositoryDialogStatus.error;
                          _validationError = isValid
                              ? null
                              : 'Repository not found on GitHub';
                        });

                        if (isValid) {
                          // Auto-refresh issues
                          await issues.loadIssues();

                          Future.delayed(const Duration(seconds: 1), () {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: industrialTheme.surfacePrimary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Repository set to $owner/$repo',
                                        style: AppTypography.labelSmall.copyWith(
                                          color:
                                              industrialTheme.surfacePrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      industrialTheme.statusSuccess,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMedium,
                                    ),
                                  ),
                                ),
                              );
                            }
                          });
                        }
                      } catch (e) {
                        if (!context.mounted) return;

                        setDialogState(() {
                          _status = _RepositoryDialogStatus.error;
                          _validationError = 'Validation failed: $e';
                        });
                      }
                    },
              label: _status == _RepositoryDialogStatus.validating
                  ? 'VALIDATING...'
                  : _status == _RepositoryDialogStatus.success
                      ? 'SUCCESS'
                      : _status == _RepositoryDialogStatus.error
                          ? 'RETRY'
                          : 'SAVE',
              variant: _status == _RepositoryDialogStatus.success
                  ? IndustrialButtonVariant.primary
                  : IndustrialButtonVariant.primary,
              size: IndustrialButtonSize.small,
              isLoading: _status == _RepositoryDialogStatus.validating,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'CLEAR REPOSITORY',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will remove the repository configuration. You will need to set it again to sync issues.',
          style: AppTypography.bodyMedium.copyWith(
            color: industrialTheme.textSecondary,
          ),
        ),
        actions: [
          IndustrialButton(
            onPressed: () => Navigator.pop(context),
            label: 'CANCEL',
            variant: IndustrialButtonVariant.text,
            size: IndustrialButtonSize.small,
          ),
          IndustrialButton(
            onPressed: () {
              Logger.i('Clearing repository configuration', context: 'Settings');
              final issuesProvider =
                  Provider.of<IssuesProvider>(context, listen: false);
              issuesProvider.clearRepository();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Repository configuration cleared'),
                  backgroundColor: industrialTheme.accentPrimary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: 'CLEAR',
            variant: IndustrialButtonVariant.destructive,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    required IndustrialThemeData industrialTheme,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: industrialTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: industrialTheme.borderPrimary, width: 1),
          ),
          child: Icon(icon, size: 20, color: industrialTheme.accentPrimary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: industrialTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.captionSmall.copyWith(
                  color: industrialTheme.textSecondary,
                ),
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
}

enum _RepositoryDialogStatus { idle, validating, loading, success, error }

class _CurrentRepositoryCard extends StatelessWidget {
  final String owner;
  final String repo;
  final VoidCallback onEdit;

  const _CurrentRepositoryCard({
    required this.owner,
    required this.repo,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    if (owner.isEmpty || repo.isEmpty) {
      return IndustrialCard(
        type: IndustrialCardType.data,
        child: Row(
          children: [
            Icon(
              Icons.folder_off_outlined,
              color: industrialTheme.textTertiary,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NO REPOSITORY',
                    style: AppTypography.labelMedium.copyWith(
                      color: industrialTheme.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Change Repository" to set one',
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            IndustrialButton(
              onPressed: onEdit,
              label: 'SET',
              variant: IndustrialButtonVariant.secondary,
              size: IndustrialButtonSize.small,
            ),
          ],
        ),
      );
    }

    return IndustrialCard(
      type: IndustrialCardType.interactive,
      onTap: onEdit,
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            color: industrialTheme.accentPrimary,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEFAULT REPOSITORY',
                  style: AppTypography.labelMedium.copyWith(
                    color: industrialTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$owner/$repo',
                  style: AppTypography.monoData.copyWith(
                    color: industrialTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IndustrialButton(
            onPressed: onEdit,
            label: 'EDIT',
            variant: IndustrialButtonVariant.secondary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final textColor = enabled
        ? industrialTheme.textPrimary
        : industrialTheme.textTertiary;
    final iconColor = isDestructive
        ? industrialTheme.statusError
        : (enabled
              ? industrialTheme.textSecondary
              : industrialTheme.textTertiary);

    return IndustrialCard(
      type: onTap != null && enabled
          ? IndustrialCardType.interactive
          : IndustrialCardType.data,
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDestructive
                  ? industrialTheme.statusError.withOpacity(0.1)
                  : industrialTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isDestructive
                    ? industrialTheme.statusError
                    : industrialTheme.borderPrimary,
                width: 1,
              ),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTypography.captionSmall.copyWith(
                      color: isDestructive
                          ? industrialTheme.statusError
                          : industrialTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null && enabled)
            Icon(
              Icons.chevron_right_outlined,
              color: industrialTheme.textTertiary,
            ),
        ],
      ),
    );
  }
}
