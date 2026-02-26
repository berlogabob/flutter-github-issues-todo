import 'package:flutter/material.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import 'widgets/settings_widgets.dart';

/// Developer Settings Screen
///
/// Provides access to developer tools:
/// - Debug console for logs and metrics
class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const SettingsSectionHeader(title: 'DEVELOPER'),
        const SizedBox(height: AppSpacing.md),

        // Debug console tile
        SettingsTile(
          icon: Icons.bug_report_outlined,
          title: 'Debug Console',
          subtitle: 'View logs and metrics',
          onTap: () {
            debugPrint('[INFO::Settings] Opening debug console');
            Navigator.pushNamed(context, '/debug');
          },
        ),
      ],
    );
  }
}
