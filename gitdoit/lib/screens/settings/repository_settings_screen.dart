import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../providers/issues_provider.dart';
import 'widgets/settings_widgets.dart';
import 'widgets/dialog_factory.dart';

/// Repository Settings Screen
///
/// Manages default repository configuration:
/// - Display current repository
/// - Allow repository change via dialog
class RepositorySettingsScreen extends StatelessWidget {
  const RepositorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final dialogFactory = context.dialogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const SettingsSectionHeader(title: 'REPOSITORY'),
        const SizedBox(height: AppSpacing.md),

        // Default repository tile
        Consumer<IssuesProvider>(
          builder: (context, issues, _) {
            return SettingsTile(
              icon: Icons.folder_outlined,
              title: 'Default Repository',
              subtitle: issues.repository != null
                  ? '${issues.repository!.owner}/${issues.repository!.name}'
                  : 'Not configured',
              onTap: () => dialogFactory.showRepositoryDialog(issues),
            );
          },
        ),
      ],
    );
  }
}
