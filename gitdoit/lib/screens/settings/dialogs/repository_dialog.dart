import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../theme/widgets/widgets.dart';
import '../../../providers/issues_provider.dart';
import '../../../utils/logging.dart';
import '../../../utils/repo_config_parser.dart';

/// Dialog status for repository configuration
enum RepositoryDialogStatus { idle, validating, loading, success, error }

/// Repository configuration dialog
///
/// Allows users to set and validate a GitHub repository
/// Supports both owner/repo format and full GitHub URLs
class RepositoryDialog extends StatefulWidget {
  const RepositoryDialog({super.key});

  static Future<void> show(
    BuildContext context,
    IssuesProvider issuesProvider,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => RepositoryDialog(),
    );
  }

  @override
  State<RepositoryDialog> createState() => _RepositoryDialogState();
}

class _RepositoryDialogState extends State<RepositoryDialog> {
  late final TextEditingController _ownerController;
  late final TextEditingController _repoController;
  RepositoryDialogStatus _status = RepositoryDialogStatus.idle;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final issuesProvider = context.read<IssuesProvider>();

    _ownerController = TextEditingController();
    _repoController = TextEditingController();

    // Pre-fill with existing repository if configured
    if (issuesProvider.repository != null) {
      _ownerController.text = issuesProvider.owner;
      _repoController.text = issuesProvider.repo;
    }
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issuesProvider = context.watch<IssuesProvider>();

    return AlertDialog(
      backgroundColor: industrialTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
      ),
      title: Text(
        'SET REPOSITORY',
        style: AppTypography.headlineSmall.copyWith(
          color: industrialTheme.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IndustrialInput(
              label: 'OWNER',
              hintText: 'e.g., berlogabob',
              controller: _ownerController,
              enabled: _canEdit,
            ),
            const SizedBox(height: AppSpacing.lg),
            IndustrialInput(
              label: 'REPOSITORY',
              hintText: 'e.g., flutter-github-issues-todo',
              controller: _repoController,
              enabled: _canEdit,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildStatusWidget(industrialTheme, issuesProvider),
          ],
        ),
      ),
      actions: [
        IndustrialButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          label: 'CANCEL',
          variant: IndustrialButtonVariant.text,
          size: IndustrialButtonSize.small,
        ),
        IndustrialButton(
          onPressed: _isLoading ? null : () => _handleSave(issuesProvider),
          label: 'SAVE',
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }

  bool get _canEdit =>
      _status == RepositoryDialogStatus.idle ||
      _status == RepositoryDialogStatus.success ||
      _status == RepositoryDialogStatus.error;

  bool get _isLoading =>
      _status == RepositoryDialogStatus.validating ||
      _status == RepositoryDialogStatus.loading;

  Widget _buildStatusWidget(
    IndustrialThemeData industrialTheme,
    IssuesProvider issuesProvider,
  ) {
    switch (_status) {
      case RepositoryDialogStatus.validating:
        return _buildStatusRow(
          industrialTheme,
          icon: CircularProgressIndicator(
            strokeWidth: 2,
            color: industrialTheme.accentPrimary,
          ),
          label: 'Validating repository...',
        );

      case RepositoryDialogStatus.loading:
        return _buildStatusRow(
          industrialTheme,
          icon: CircularProgressIndicator(
            strokeWidth: 2,
            color: industrialTheme.accentPrimary,
          ),
          label: 'Loading issues...',
        );

      case RepositoryDialogStatus.success:
        return _buildStatusRow(
          industrialTheme,
          icon: Icon(
            Icons.check_circle_outline,
            size: 16,
            color: industrialTheme.statusSuccess,
          ),
          label: 'Repository validated successfully',
          labelColor: industrialTheme.statusSuccess,
        );

      case RepositoryDialogStatus.error:
        return _buildErrorSection(industrialTheme, issuesProvider);

      case RepositoryDialogStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusRow(
    IndustrialThemeData industrialTheme, {
    required Widget icon,
    required String label,
    Color? labelColor,
  }) {
    return Row(
      children: [
        SizedBox(width: 16, height: 16, child: icon),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: labelColor ?? industrialTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(
    IndustrialThemeData industrialTheme,
    IssuesProvider issuesProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: industrialTheme.statusError,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                _validationError ?? 'Unknown error',
                style: AppTypography.captionSmall.copyWith(
                  color: industrialTheme.statusError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        IndustrialButton(
          onPressed: () => _handleRetry(issuesProvider),
          label: 'RETRY',
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }

  void _handleRetry(IssuesProvider issuesProvider) {
    final parsed = _parseRepositoryInput();
    if (parsed == null) {
      setState(() {
        _status = RepositoryDialogStatus.error;
        _validationError =
            'Invalid repository format. Use owner/repo or GitHub URL';
      });
      return;
    }

    setState(() {
      _status = RepositoryDialogStatus.validating;
      _validationError = null;
    });

    issuesProvider.setRepository(parsed.owner, parsed.repo);
    issuesProvider.validateRepository(parsed.owner, parsed.repo).then((isValid) {
      if (!mounted) return;
      setState(() {
        _status = isValid
            ? RepositoryDialogStatus.success
            : RepositoryDialogStatus.error;
        _validationError = isValid ? null : 'Repository not found';
      });
    });
  }

  void _handleSave(IssuesProvider issuesProvider) async {
    final parsed = _parseRepositoryInput();
    if (parsed == null) {
      setState(() {
        _status = RepositoryDialogStatus.error;
        _validationError =
            'Invalid repository format. Use owner/repo or GitHub URL';
      });
      return;
    }

    setState(() {
      _status = RepositoryDialogStatus.validating;
      _validationError = null;
    });

    Logger.i(
      'Setting repository: ${parsed.owner}/${parsed.repo}',
      context: 'Settings',
    );
    issuesProvider.setRepository(parsed.owner, parsed.repo);

    try {
      final isValid = await issuesProvider.validateRepository(
        parsed.owner,
        parsed.repo,
      );

      if (!mounted) return;

      setState(() {
        _status = isValid
            ? RepositoryDialogStatus.success
            : RepositoryDialogStatus.error;
        _validationError = isValid
            ? null
            : 'Repository not found on GitHub';
      });

      if (!isValid) return;

      // Load issues after successful validation
      setState(() {
        _status = RepositoryDialogStatus.loading;
      });

      await issuesProvider.loadIssues();

      if (!mounted) return;

      setState(() {
        _status = RepositoryDialogStatus.success;
      });

      // Show success and close dialog
      if (!mounted) return;
      Navigator.pop(context);

      _showSuccessSnackBar(context, parsed);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = RepositoryDialogStatus.error;
        _validationError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  RepoOwnerRepo? _parseRepositoryInput() {
    final ownerTrimmed = _ownerController.text.trim();
    final repoTrimmed = _repoController.text.trim();

    // Check if owner field contains a full URL
    if (ownerTrimmed.contains('github.com') ||
        ownerTrimmed.startsWith('git@')) {
      return parseRepositoryInput(ownerTrimmed);
    }

    // Standard owner/repo format
    if (ownerTrimmed.isNotEmpty && repoTrimmed.isNotEmpty) {
      return RepoOwnerRepo(owner: ownerTrimmed, repo: repoTrimmed);
    }

    return null;
  }

  void _showSuccessSnackBar(
    BuildContext context,
    RepoOwnerRepo parsed,
  ) {
    final industrialTheme = context.industrialTheme;
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
              'Repository set to ${parsed.owner}/${parsed.repo}',
              style: AppTypography.labelSmall.copyWith(
                color: industrialTheme.surfacePrimary,
              ),
            ),
          ],
        ),
        backgroundColor: industrialTheme.statusSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
