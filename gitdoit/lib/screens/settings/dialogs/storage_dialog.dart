import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../theme/widgets/widgets.dart';
import '../../../providers/issues_provider.dart';
import 'clear_data_dialog.dart';

/// Storage statistics dialog
///
/// Displays information about:
/// - Cache size
/// - Cached issues count
/// - Repository count
/// - Last sync time
/// - Connection status
class StorageDialog extends StatefulWidget {
  const StorageDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const StorageDialog(),
    );
  }

  @override
  State<StorageDialog> createState() => _StorageDialogState();
}

class _StorageDialogState extends State<StorageDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final issuesProvider = context.read<IssuesProvider>();
    final stats = await issuesProvider.getStorageStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

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
              Icons.storage_outlined,
              color: industrialTheme.accentPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'OFFLINE STORAGE',
            style: AppTypography.headlineSmall.copyWith(
              color: industrialTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: _isLoading ? _buildLoading(industrialTheme) : _buildStats(industrialTheme),
      ),
      actions: [
        IndustrialButton(
          onPressed: () => Navigator.pop(context),
          label: 'DONE',
          variant: IndustrialButtonVariant.text,
          size: IndustrialButtonSize.small,
        ),
        IndustrialButton(
          onPressed: () {
            Navigator.pop(context);
            ClearDataDialog.show(context);
          },
          label: 'CLEAR CACHE',
          variant: IndustrialButtonVariant.destructive,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildLoading(IndustrialThemeData industrialTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: industrialTheme.accentPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStats(IndustrialThemeData industrialTheme) {
    final issueCount = _stats?['issueCount'] as int? ?? 0;
    final cacheSize = _stats?['cacheSizeFormatted'] as String? ?? 'Unknown';
    final lastSync = _stats?['lastSyncTimeFormatted'] as String? ?? 'Never';
    final repoCount = _stats?['repositoryCount'] as int? ?? 0;
    final isOffline = _stats?['isOffline'] as bool? ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cache size
        _buildStatRow(
          icon: Icons.storage_outlined,
          label: 'CACHE SIZE',
          value: cacheSize,
          industrialTheme: industrialTheme,
        ),
        const SizedBox(height: AppSpacing.md),

        // Issue count
        _buildStatRow(
          icon: Icons.article_outlined,
          label: 'CACHED ISSUES',
          value: '$issueCount',
          industrialTheme: industrialTheme,
        ),
        const SizedBox(height: AppSpacing.md),

        // Repository count
        _buildStatRow(
          icon: Icons.folder_outlined,
          label: 'REPOSITORIES',
          value: '$repoCount',
          industrialTheme: industrialTheme,
        ),
        const SizedBox(height: AppSpacing.md),

        // Last sync time
        _buildStatRow(
          icon: Icons.access_time_outlined,
          label: 'LAST SYNC',
          value: lastSync,
          industrialTheme: industrialTheme,
        ),
        const SizedBox(height: AppSpacing.md),

        // Connection status
        _buildStatRow(
          icon: isOffline
              ? Icons.cloud_off_outlined
              : Icons.cloud_done_outlined,
          label: 'CONNECTION',
          value: isOffline ? 'OFFLINE' : 'ONLINE',
          valueColor: isOffline
              ? industrialTheme.textTertiary
              : industrialTheme.statusSuccess,
          industrialTheme: industrialTheme,
        ),

        const SizedBox(height: AppSpacing.lg),

        // Info note
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: industrialTheme.accentSubtle,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: industrialTheme.accentPrimary,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: industrialTheme.accentPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Cache size is estimated. Clear cache to free up space.',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required IndustrialThemeData industrialTheme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: industrialTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(icon, size: 16, color: industrialTheme.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.monoAnnotation.copyWith(
              color: industrialTheme.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.monoData.copyWith(
            color: valueColor ?? industrialTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
