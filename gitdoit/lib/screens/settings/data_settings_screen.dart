import 'package:flutter/material.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import 'widgets/settings_widgets.dart';
import 'widgets/dialog_factory.dart';

/// Data Settings Screen
///
/// Manages local data storage:
/// - View storage statistics
/// - Clear cache options
class DataSettingsScreen extends StatelessWidget {
  const DataSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final dialogFactory = context.dialogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const SettingsSectionHeader(title: 'DATA'),
        const SizedBox(height: AppSpacing.md),

        // Offline storage tile
        SettingsTile(
          icon: Icons.storage_outlined,
          title: 'Offline Storage',
          subtitle: 'Manage cached data',
          onTap: () => dialogFactory.showStorageDialog(),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Clear cache tile (destructive)
        SettingsTile(
          icon: Icons.delete_outline,
          title: 'Clear Cache',
          subtitle: 'Remove locally stored issues',
          isDestructive: true,
          onTap: () => dialogFactory.showClearDataDialog(),
        ),
      ],
    );
  }
}
