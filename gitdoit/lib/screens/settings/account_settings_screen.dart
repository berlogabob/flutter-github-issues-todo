import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issues_provider.dart';
import '../../../utils/logging.dart';
import 'widgets/settings_widgets.dart';
import 'widgets/dialog_factory.dart';
import '../repository_picker_screen.dart';

/// Account Settings Screen
///
/// Manages GitHub authentication and repository selection:
/// - Login/Logout status
/// - Repository selection
/// - Account information display
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building AccountSettingsScreen', context: 'Settings');

    final industrialTheme = context.industrialTheme;
    final dialogFactory = context.dialogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const SettingsSectionHeader(title: 'ACCOUNT'),
        const SizedBox(height: AppSpacing.md),

        // Account status tile
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SettingsTile(
              icon: auth.isAuthenticated
                  ? Icons.check_circle_outline
                  : Icons.person_outline,
              title: 'GitHub Account',
              subtitle: auth.isAuthenticated
                  ? (auth.username ?? 'Logged in')
                  : 'Not logged in',
              monospaceSubtitle: true,
              onTap: auth.isAuthenticated
                  ? null
                  : () => dialogFactory.showLoginDialog(auth),
              enabled: !auth.isLoading,
            );
          },
        ),

        // Repository picker (only when authenticated)
        if (Provider.of<AuthProvider>(context).isAuthenticated) ...[
          const SizedBox(height: AppSpacing.sm),
          SettingsTile(
            icon: Icons.folder_outlined,
            title: 'Select Repository',
            subtitle: 'Choose from your repositories',
            onTap: () => _navigateToRepositoryPicker(context),
          ),
        ],
      ],
    );
  }

  /// Navigate to repository picker screen
  Future<void> _navigateToRepositoryPicker(BuildContext context) async {
    Logger.d('Opening repository picker', context: 'Settings');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RepositoryPickerScreen(),
      ),
    );

    if (result != null && context.mounted) {
      // Refresh UI - repository was selected
    }
  }
}
