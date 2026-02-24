import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';
import '../../utils/logger.dart';

/// Account Settings Screen - GitHub authentication management
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building AccountSettingsScreen', context: 'Settings');

    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: Text(
          'ACCOUNT',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Account status section
          _buildSectionHeader(context, 'STATUS'),
          const SizedBox(height: AppSpacing.md),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return _AccountStatusCard(auth: auth);
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Actions section
          _buildSectionHeader(context, 'ACTIONS'),
          const SizedBox(height: AppSpacing.md),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAuthenticated) {
                return _SettingsTile(
                  icon: Icons.logout_outlined,
                  title: 'Logout',
                  subtitle: 'Remove saved token',
                  isDestructive: true,
                  onTap: () => _showLogoutDialog(context, auth),
                );
              } else {
                return _SettingsTile(
                  icon: Icons.login_outlined,
                  title: 'Login',
                  subtitle: 'Sign in with GitHub',
                  onTap: () => _showLoginDialog(context, auth),
                  enabled: !auth.isLoading,
                );
              }
            },
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Info card
          IndustrialCard(
            type: IndustrialCardType.data,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUTHENTICATION',
                  style: AppTypography.monoAnnotation.copyWith(
                    color: industrialTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildInfoItem(
                  icon: Icons.security_outlined,
                  title: 'SECURE STORAGE',
                  description: 'Tokens stored in encrypted storage',
                  industrialTheme: industrialTheme,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildDivider(industrialTheme),
                const SizedBox(height: AppSpacing.md),
                _buildInfoItem(
                  icon: Icons.cloud_sync_outlined,
                  title: 'OAUTH SUPPORT',
                  description: 'GitHub OAuth or Personal Token',
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

  void _showLoginDialog(BuildContext context, AuthProvider auth) {
    final industrialTheme = context.industrialTheme;
    final tokenController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'GITHUB TOKEN',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IndustrialInput(
              label: 'PERSONAL ACCESS TOKEN',
              hintText: 'ghp_...',
              controller: tokenController,
              inputType: IndustrialInputType.password,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Token starts with ghp_, gho_, ghu_, ghs_, or github_pat_',
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
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
            onPressed: () async {
              final token = tokenController.text.trim();
              
              if (token.isEmpty) {
                Navigator.pop(context);
                return;
              }

              try {
                await auth.validateAndSaveToken(token);
                
                if (!context.mounted) return;
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
                          'Logged in as ${auth.username}',
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
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login failed: $e'),
                    backgroundColor: industrialTheme.statusError,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            label: 'LOGIN',
            variant: IndustrialButtonVariant.primary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
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
              await auth.logout();
              
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen

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

class _AccountStatusCard extends StatelessWidget {
  final AuthProvider auth;

  const _AccountStatusCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return IndustrialCard(
      type: auth.isAuthenticated
          ? IndustrialCardType.data
          : IndustrialCardType.data,
      child: Row(
        children: [
          Icon(
            auth.isAuthenticated
                ? Icons.check_circle
                : Icons.error_outline,
            color: auth.isAuthenticated
                ? industrialTheme.statusSuccess
                : industrialTheme.textTertiary,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isAuthenticated ? 'AUTHENTICATED' : 'NOT LOGGED IN',
                  style: AppTypography.labelMedium.copyWith(
                    color: auth.isAuthenticated
                        ? industrialTheme.statusSuccess
                        : industrialTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isAuthenticated
                      ? (auth.username ?? 'GitHub User')
                      : 'Sign in to access your repositories',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textSecondary,
                  ),
                ),
              ],
            ),
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
          // Icon
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
