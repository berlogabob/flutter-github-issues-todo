import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/issues_provider.dart';
import '../utils/logging.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import 'settings/settings.dart';

/// Settings Screen - App configuration
///
/// REDESIGNED: Modular architecture with Industrial Minimalism
/// Main menu screen that orchestrates modular settings components
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    Logger.d('Building SettingsScreen', context: 'Settings');

    final industrialTheme = context.industrialTheme;
    final dialogFactory = context.dialogs;

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
          const AccountSettingsScreen(),

          const SizedBox(height: AppSpacing.xl),

          // Repository section
          const RepositorySettingsScreen(),

          const SizedBox(height: AppSpacing.xl),

          // Appearance section
          const AppearanceSettingsScreen(),

          const SizedBox(height: AppSpacing.xl),

          // Data section
          const DataSettingsScreen(),

          const SizedBox(height: AppSpacing.xl),

          // Developer section
          const DeveloperSettingsScreen(),

          const SizedBox(height: AppSpacing.xl),

          // Danger zone
          const SettingsSectionHeader(
            title: 'DANGER ZONE',
            isDestructive: true,
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsTile(
            icon: Icons.logout_outlined,
            title: 'Logout',
            subtitle: 'Remove saved token',
            isDestructive: true,
            onTap: () => dialogFactory.showLogoutDialog(),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // App version - Technical annotation
          const SettingsAppVersion(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
