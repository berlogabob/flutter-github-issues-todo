import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';

/// Settings Screen - App configuration
///
/// REDESIGNED: Industrial Minimalism with technical layout
/// Monospace labels, modular sections, dot-matrix icons
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building SettingsScreen', context: 'Settings');

    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,

      // Custom Industrial AppBar
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
                icon: Icons.person_outline,
                title: 'GitHub Account',
                subtitle: auth.username ?? 'Not logged in',
                monospaceSubtitle: true,
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
                onTap: () => _showRepositoryDialog(context, issues),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // App section
          _buildSectionHeader(context, 'APPEARANCE'),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'System default',
            onTap: () => _showThemeDialog(context),
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
            onTap: () => _showStorageDialog(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove locally stored issues',
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

          // App version - Technical annotation
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
                      'GitDoIt v0.2.0-industrial',
                      style: AppTypography.monoAnnotation.copyWith(
                        color: industrialTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Industrial Minimalism Edition',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary,
                  ),
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
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  void _showRepositoryDialog(
    BuildContext context,
    IssuesProvider issuesProvider,
  ) {
    final ownerController = TextEditingController();
    final repoController = TextEditingController();
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
          'SET REPOSITORY',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IndustrialInput(
              label: 'OWNER',
              hintText: 'e.g., berlogabob',
              controller: ownerController,
            ),
            const SizedBox(height: AppSpacing.lg),
            IndustrialInput(
              label: 'REPOSITORY',
              hintText: 'e.g., flutter-github-issues-todo',
              controller: repoController,
            ),
          ],
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
              final owner = ownerController.text.trim();
              final repo = repoController.text.trim();

              if (owner.isEmpty || repo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in both fields')),
                );
                return;
              }

              Logger.i('Setting repository: $owner/$repo', context: 'Settings');
              issuesProvider.setRepository(owner, repo);
              Navigator.pop(context);

              issuesProvider.loadIssues();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Repository set to $owner/$repo'),
                  backgroundColor: industrialTheme.accentPrimary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              );
            },
            label: 'SAVE',
            variant: IndustrialButtonVariant.primary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
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
          'THEME',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: 'System Default',
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ThemeOption(
              title: 'Light',
              selected: false,
              onTap: () {
                // TODO: Implement theme switching
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ThemeOption(
              title: 'Dark',
              selected: false,
              onTap: () {
                // TODO: Implement theme switching
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageDialog(BuildContext context) {
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
          'OFFLINE STORAGE',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Text(
          'Manage how much data is stored locally for offline use.',
          style: AppTypography.bodyMedium.copyWith(
            color: industrialTheme.textSecondary,
          ),
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

  void _showClearCacheDialog(BuildContext context) {
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
          'CLEAR CACHE',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will remove all locally cached issues. They will be re-downloaded next time you refresh.',
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
              Logger.i('Clearing cache', context: 'Settings');
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
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
          'Are you sure you want to logout? You will need to enter your token again.',
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
              Logger.i('User logged out', context: 'Settings');
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context);
              Navigator.pop(context);
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

/// Reusable settings tile
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
          // Icon
          Container(
            width: 40,
            height: 40,
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
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        (monospaceSubtitle
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

          // Chevron
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

/// Theme option tile
class _ThemeOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? industrialTheme.accentPrimary
                  : industrialTheme.textTertiary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: selected
                    ? industrialTheme.accentPrimary
                    : industrialTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
