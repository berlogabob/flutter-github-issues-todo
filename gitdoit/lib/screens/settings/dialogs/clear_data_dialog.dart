import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../theme/widgets/widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issues_provider.dart';
import '../widgets/clear_data_option.dart';

/// Clear data dialog with multiple options
///
/// Provides options to:
/// - Clear Issues Cache: Remove cached issues only
/// - Clear All Data: Remove everything including login and repo config
class ClearDataDialog extends StatefulWidget {
  const ClearDataDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ClearDataDialog(),
    );
  }

  @override
  State<ClearDataDialog> createState() => _ClearDataDialogState();
}

class _ClearDataDialogState extends State<ClearDataDialog> {
  bool _isClearing = false;
  String? _clearError;

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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: industrialTheme.accentSubtle,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(
              Icons.delete_outline,
              color: industrialTheme.accentPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'CLEAR CACHE',
            style: AppTypography.headlineSmall.copyWith(
              color: industrialTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT CLEAR OPTION',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCacheStats(issuesProvider, industrialTheme),
            const SizedBox(height: AppSpacing.lg),
            ClearDataOption(
              icon: Icons.folder_outlined,
              title: 'Clear Issues Cache',
              description:
                  'Remove cached issues only. Repository config and login will be kept.',
              industrialTheme: industrialTheme,
              onTap: _isClearing ? null : () => _handleClearIssues(issuesProvider),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClearDataOption(
              icon: Icons.warning_outlined,
              title: 'Clear All Data',
              description:
                  'Remove everything: issues, repository config, and login.',
              isDestructive: true,
              industrialTheme: industrialTheme,
              onTap: _isClearing ? null : () => _handleClearAll(issuesProvider),
            ),
            if (_clearError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: industrialTheme.statusError),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _clearError!,
                      style: AppTypography.captionSmall.copyWith(
                        color: industrialTheme.statusError,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        IndustrialButton(
          onPressed: _isClearing ? null : () => Navigator.pop(context),
          label: 'CANCEL',
          variant: IndustrialButtonVariant.text,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildCacheStats(
    IssuesProvider issuesProvider,
    IndustrialThemeData industrialTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: industrialTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: industrialTheme.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_outlined, size: 16, color: industrialTheme.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Cached Issues',
                style: AppTypography.labelSmall.copyWith(
                  color: industrialTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${issuesProvider.issues.length} issues',
            style: AppTypography.monoAnnotation.copyWith(
              color: industrialTheme.textPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClearIssues(IssuesProvider issuesProvider) async {
    setState(() {
      _isClearing = true;
      _clearError = null;
    });

    try {
      await issuesProvider.clearCache();
      if (!mounted) return;
      Navigator.pop(context);
      _showSuccess('Issues cache cleared');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isClearing = false;
        _clearError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleClearAll(IssuesProvider issuesProvider) async {
    final theme = context.industrialTheme;

    setState(() {
      _isClearing = true;
      _clearError = null;
    });

    try {
      await issuesProvider.clearAllData();
      final authProvider = context.read<AuthProvider>();
      await authProvider.clearAllData();

      if (!mounted) return;
      Navigator.pop(context);
      _showSuccess('All data cleared');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isClearing = false;
        _clearError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showSuccess(String message) {
    final industrialTheme = context.industrialTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: industrialTheme.surfacePrimary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              message,
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
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
