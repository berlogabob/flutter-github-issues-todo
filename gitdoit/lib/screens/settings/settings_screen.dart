import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/issues_provider.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';
import '../../utils/logger.dart';
import 'account_settings_screen.dart';
import 'repository_settings_screen.dart';

/// Settings Screen - Main menu for app configuration
///
/// REDESIGNED: Industrial Minimalism with navigation to sub-screens
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building SettingsScreen', context: 'Settings');

    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Account section
          _buildSectionHeader(context, 'ACCOUNT'),
          const SizedBox(height: AppSpacing.md),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return _SettingsTile(
                icon: auth.isAuthenticated
                    ? Icons.check_circle_outline
                    : Icons.person_outline,
                title: 'GitHub Account',
                subtitle: auth.isAuthenticated
                    ? (auth.username ?? 'Logged in')
                    : 'Not logged in',
                monospaceSubtitle: true,
                onTap: () => _navigateToAccountSettings(context),
                enabled: !auth.isLoading,
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Repository section
          _buildSectionHeader(context, 'REPOSITORY'),
          const SizedBox(height: AppSpacing.md),
          Consumer<IssuesProvider>(
            builder: (context, issues, _) {
              return _SettingsTile(
                icon: Icons.folder_outlined,
                title: 'Default Repository',
                subtitle: issues.repository != null
                    ? '${issues.repository!.owner}/${issues.repository!.name}'
                    : 'Not configured',
                onTap: () => _navigateToRepositorySettings(context),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Appearance section (placeholder)
          _buildSectionHeader(context, 'APPEARANCE'),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Coming soon',
            enabled: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Coming soon',
            enabled: false,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Data section
          _buildSectionHeader(context, 'DATA'),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Offline Storage',
            subtitle: 'Manage cached data',
            onTap: () => _showStorageInfoDialog(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove cached issues',
            isDestructive: true,
            onTap: () => _showClearCacheDialog(context),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Danger zone
          _buildSectionHeader(context, 'DANGER ZONE', isDestructive: true),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.logout_outlined,
            title: 'Logout',
            subtitle: 'Remove saved token',
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // App version
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: industrialTheme.accentPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'v1.0.0',
                      style: AppTypography.monoAnnotation.copyWith(
                        color: industrialTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Built with Flutter',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    bool isDestructive = false,
  }) {
    final industrialTheme = context.industrialTheme;

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: isDestructive
              ? industrialTheme.statusError
              : industrialTheme.accentPrimary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.monoAnnotation.copyWith(
            color: isDestructive
                ? industrialTheme.statusError
                : industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _navigateToAccountSettings(BuildContext context) {
    Logger.d('Navigating to AccountSettingsScreen', context: 'Settings');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
    );
  }

  void _navigateToRepositorySettings(BuildContext context) {
    Logger.d('Navigating to RepositorySettingsScreen', context: 'Settings');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RepositorySettingsScreen()),
    );
  }

  void _showStorageInfoDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issuesProvider =
        Provider.of<IssuesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'OFFLINE STORAGE',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: FutureBuilder<Map<String, dynamic>>(
          future: issuesProvider.getStorageStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              final stats = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(
                    'Cached Issues',
                    '${stats['issueCount']}',
                    industrialTheme,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatRow(
                    'Cache Size',
                    stats['cacheSize'] ?? 'Unknown',
                    industrialTheme,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatRow(
                    'Last Sync',
                    stats['lastSyncTime'] ?? 'Never',
                    industrialTheme,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatRow(
                    'Status',
                    stats['isOffline'] == true ? 'Offline' : 'Online',
                    industrialTheme,
                  ),
                ],
              );
            }

            return Text(
              'Unable to load storage stats',
              style: AppTypography.bodyMedium.copyWith(
                color: industrialTheme.textSecondary,
              ),
            );
          },
        ),
        actions: [
          IndustrialButton(
            onPressed: () => Navigator.pop(context),
            label: 'DONE',
            variant: IndustrialButtonVariant.primary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IndustrialThemeData industrialTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: industrialTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.monoData.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issuesProvider =
        Provider.of<IssuesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'CLEAR CACHE',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will remove all cached issues. They will be re-downloaded next time you refresh.',
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
            onPressed: () async {
              Logger.i('Clearing cache', context: 'Settings');
              await issuesProvider.clearCache();
              
              if (!context.mounted) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cache cleared successfully'),
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

  void _showLogoutDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'LOGOUT',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to logout? You will need to sign in again.',
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
            onPressed: () async {
              Logger.i('User logged out', context: 'Settings');
              await authProvider.logout();
              
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: industrialTheme.accentPrimary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: 'LOGOUT',
            variant: IndustrialButtonVariant.destructive,
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
  final bool monospaceSubtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
    this.monospaceSubtitle = false,
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
                    style: (monospaceSubtitle
                            ? AppTypography.monoAnnotation
                            : AppTypography.captionSmall)
                        .copyWith(
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
