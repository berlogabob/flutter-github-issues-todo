import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../theme/widgets/widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/logging.dart';
import '../widgets/login_method_tile.dart';

/// Login dialog with OAuth and Token options
///
/// Provides two authentication methods:
/// - OAuth: Redirect to GitHub for authorization
/// - Token: Manual personal access token entry
class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  static Future<void> show(BuildContext context, AuthProvider auth) async {
    await showDialog(
      context: context,
      builder: (context) => const LoginDialog(),
    );
  }

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  LoginMethod _selectedMethod = LoginMethod.oauth;
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final auth = context.watch<AuthProvider>();

    return AlertDialog(
      backgroundColor: industrialTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: industrialTheme.accentSubtle,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(Icons.login_outlined, color: industrialTheme.accentPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'LOGIN TO GITHUB',
            style: AppTypography.headlineSmall.copyWith(
              color: industrialTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMethodSelection(industrialTheme),
            const SizedBox(height: AppSpacing.xl),
            if (_selectedMethod == LoginMethod.oauth)
              _buildOAuthSection(industrialTheme),
            if (_selectedMethod == LoginMethod.token)
              _buildTokenSection(industrialTheme, auth),
          ],
        ),
      ),
      actions: [
        IndustrialButton(
          onPressed: () => Navigator.pop(context),
          label: 'CANCEL',
          variant: IndustrialButtonVariant.text,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }

  Widget _buildMethodSelection(IndustrialThemeData industrialTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT LOGIN METHOD',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: LoginMethodTile(
                icon: Icons.cloud_sync_outlined,
                title: 'OAuth',
                description: 'Quick & secure',
                selected: _selectedMethod == LoginMethod.oauth,
                onTap: () => setState(() => _selectedMethod = LoginMethod.oauth),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: LoginMethodTile(
                icon: Icons.key_outlined,
                title: 'Token',
                description: 'Manual entry',
                selected: _selectedMethod == LoginMethod.token,
                onTap: () => setState(() => _selectedMethod = LoginMethod.token),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOAuthSection(IndustrialThemeData industrialTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OAUTH AUTHENTICATION',
          style: AppTypography.labelMedium.copyWith(
            color: industrialTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'You will be redirected to GitHub to authorize this app.',
          style: AppTypography.bodySmall.copyWith(
            color: industrialTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndustrialCard(
          type: IndustrialCardType.data,
          padding: const EdgeInsets.all(AppSpacing.md),
          backgroundColor: industrialTheme.accentSubtle,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: industrialTheme.accentPrimary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Note: OAuth requires configuring a GitHub OAuth App.',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndustrialButton(
          onPressed: _handleOAuthLogin,
          label: 'START OAUTH LOGIN',
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.medium,
          isFullWidth: true,
          icon: Icon(Icons.open_in_new_outlined, size: 18, color: AppColors.textOnAccent),
        ),
      ],
    );
  }

  Widget _buildTokenSection(IndustrialThemeData industrialTheme, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERSONAL ACCESS TOKEN',
          style: AppTypography.labelMedium.copyWith(
            color: industrialTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enter your GitHub Personal Access Token (PAT).',
          style: AppTypography.bodySmall.copyWith(
            color: industrialTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndustrialInput(
          label: 'TOKEN',
          hintText: 'ghp_...',
          controller: _tokenController,
          inputType: IndustrialInputType.password,
          prefixIcon: Icon(Icons.key_outlined, size: 20, color: industrialTheme.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse('https://github.com/settings/tokens');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            'Create a token in GitHub →',
            style: AppTypography.captionSmall.copyWith(
              color: industrialTheme.accentPrimary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndustrialButton(
          onPressed: auth.isLoading ? null : _handleTokenLogin,
          label: auth.isLoading ? 'VALIDATING...' : 'LOGIN',
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.medium,
          isFullWidth: true,
          isLoading: auth.isLoading,
        ),
      ],
    );
  }

  void _handleOAuthLogin() async {
    final industrialTheme = context.industrialTheme;
    try {
      final auth = context.read<AuthProvider>();
      final oauthUrl = await auth.loginWithOAuth();
      final uri = Uri.parse(oauthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!context.mounted) return;
        _showOAuthInstructions(industrialTheme);
      } else {
        throw Exception('Cannot open browser');
      }
    } catch (e, stackTrace) {
      Logger.e('OAuth login failed', error: e, stackTrace: stackTrace, context: 'Settings');
      if (!context.mounted) return;
      _showError('Failed to start OAuth: ${e.toString().replaceAll("Exception: ", "")}', industrialTheme);
    }
  }

  void _handleTokenLogin() async {
    final industrialTheme = context.industrialTheme;
    final auth = context.read<AuthProvider>();
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      _showError('Please enter a token', industrialTheme);
      return;
    }

    try {
      await auth.validateAndSaveToken(token);
      if (!context.mounted) return;

      if (auth.isAuthenticated) {
        Navigator.pop(context);
        _showSuccess('Logged in as ${auth.username}', industrialTheme);
      } else {
        _showError(auth.errorMessage ?? 'Authentication failed', industrialTheme);
      }
    } catch (e, stackTrace) {
      Logger.e('Token login failed', error: e, stackTrace: stackTrace, context: 'Settings');
      if (!context.mounted) return;
      _showError('Failed to login: ${e.toString().replaceAll("Exception: ", "")}', industrialTheme);
    }
  }

  void _showOAuthInstructions(IndustrialThemeData industrialTheme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'OAUTH INSTRUCTIONS',
          style: AppTypography.headlineSmall.copyWith(color: industrialTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionStep('1. Authorize the app in GitHub', industrialTheme),
            const SizedBox(height: AppSpacing.sm),
            _buildInstructionStep(
              '2. After authorization, you will be redirected back to this app',
              industrialTheme,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInstructionStep(
              '3. If not redirected automatically, copy the code from the URL',
              industrialTheme,
            ),
          ],
        ),
        actions: [
          IndustrialButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'GOT IT',
            variant: IndustrialButtonVariant.primary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String text, IndustrialThemeData industrialTheme) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(color: industrialTheme.textSecondary),
    );
  }

  void _showError(String message, IndustrialThemeData industrialTheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: industrialTheme.statusError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }

  void _showSuccess(String message, IndustrialThemeData industrialTheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: industrialTheme.statusSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }
}
