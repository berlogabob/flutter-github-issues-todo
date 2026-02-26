import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../theme/widgets/widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issues_provider.dart';
import '../../../utils/logging.dart';

/// Logout confirmation dialog
///
/// Confirms user intent before logging out and clearing authentication
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
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
          onPressed: () async {
            Logger.i('User logged out', context: 'Settings');
            final authProvider = context.read<AuthProvider>();
            final issuesProvider = context.read<IssuesProvider>();

            await authProvider.logout();
            issuesProvider.clearRepository();

            if (!context.mounted) return;
            // Navigate back to root and show AuthScreen
            Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
          },
          label: 'LOGOUT',
          variant: IndustrialButtonVariant.destructive,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }
}
