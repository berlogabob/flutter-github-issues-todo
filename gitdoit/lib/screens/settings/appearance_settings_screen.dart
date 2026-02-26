import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/theme_prefs.dart';
import 'widgets/settings_widgets.dart';
import 'widgets/dialog_factory.dart';

/// Appearance Settings Screen
///
/// Manages visual preferences:
/// - Theme selection (Light/Dark/System)
/// - Notifications (placeholder for future feature)
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final dialogFactory = context.dialogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const SettingsSectionHeader(title: 'APPEARANCE'),
        const SizedBox(height: AppSpacing.md),

        // Theme selection tile
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: _getThemeModeLabel(themeProvider.themeMode),
              onTap: () => dialogFactory.showThemeDialog(),
            );
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // Notifications tile (placeholder)
        SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Coming soon',
          enabled: false,
        ),
      ],
    );
  }

  /// Get human-readable label for theme mode
  String _getThemeModeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'System default',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }
}
