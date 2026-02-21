import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../providers/auth_provider.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';

/// Authentication Screen - Entry point for GitDoIt app
///
/// OFFLINE-FIRST: Users can skip login and use app offline
/// Token can be added later from settings
///
/// REDESIGNED: Industrial Minimalism with spatial depth
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.industrialTheme.surfacePrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const _AuthContent(),
          ),
        ),
      ),
    );
  }
}

class _AuthContent extends StatefulWidget {
  const _AuthContent();

  @override
  State<_AuthContent> createState() => _AuthContentState();
}

class _AuthContentState extends State<_AuthContent> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadSavedToken();
  }

  Future<void> _checkConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivity == ConnectivityResult.none;
    });
    Logger.d(
      'Connectivity: ${_isOffline ? "OFFLINE" : "ONLINE"}',
      context: 'Auth',
    );
  }

  Future<void> _loadSavedToken() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'github_token');
      if (token != null && token.isNotEmpty) {
        _tokenController.text = token;
        Logger.i('Loaded saved token', context: 'Auth');
      }
    } catch (e) {
      Logger.w('Failed to load saved token', context: 'Auth');
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _validateAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _tokenController.text.trim();

    // Basic validation only (no network)
    if (token.isNotEmpty &&
        !token.startsWith('ghp_') &&
        !token.startsWith('gho_') &&
        !token.startsWith('ghu_') &&
        !token.startsWith('ghs_') &&
        !token.startsWith('github_pat_')) {
      _showError(
        'Invalid token format. GitHub tokens start with ghp_, gho_, ghu_, ghs_, or github_pat_',
      );
      return;
    }

    if (token.isNotEmpty && token.length < 10) {
      _showError('Token too short. Please check your token.');
      return;
    }

    setState(() => _isLoading = true);

    // If token is empty, continue without auth
    if (token.isEmpty) {
      Logger.i(
        'Continuing without authentication (offline mode)',
        context: 'Auth',
      );
      setState(() => _isLoading = false);
      _navigateToHome();
      return;
    }

    // Validate with GitHub only if online
    await _checkConnectivity();

    if (_isOffline) {
      Logger.w('Offline - saving token for later validation', context: 'Auth');
      final storage = FlutterSecureStorage();
      await storage.write(key: 'github_token', value: token);
      setState(() => _isLoading = false);
      _showInfo('Token saved. Will validate when online.');
      _navigateToHome();
      return;
    }

    // Online - validate token
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.validateAndSaveToken(token);

    setState(() => _isLoading = false);

    if (authProvider.isAuthenticated) {
      Logger.i('Authentication successful', context: 'Auth');
      _navigateToHome();
    } else {
      _showError(
        authProvider.errorMessage ??
            'Failed to authenticate. Please check your token.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.industrialTheme.statusError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.industrialTheme.accentPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }

  void _navigateToHome() {
    Logger.i('Navigating to HomeScreen', context: 'Auth');
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),

        // Logo - Industrial style
        _buildLogo(industrialTheme),

        const SizedBox(height: AppSpacing.xl),

        // Title - Display typography
        Text(
          'GitDoIt',
          style: AppTypography.displayMedium.copyWith(
            color: industrialTheme.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Subtitle - Monospace annotation
        Text(
          'GitHub Issues TODO Tool',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xxxl),

        // Offline indicator
        if (_isOffline) ...[
          IndustrialCard(
            type: IndustrialCardType.data,
            backgroundColor: industrialTheme.statusWarning.withOpacity(0.1),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off_outlined,
                  color: industrialTheme.statusWarning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OFFLINE MODE',
                        style: AppTypography.labelSmall.copyWith(
                          color: industrialTheme.statusWarning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add token later to sync',
                        style: AppTypography.captionSmall.copyWith(
                          color: industrialTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Token Input Form
        Form(
          key: _formKey,
          child: IndustrialInput(
            label: 'PERSONAL ACCESS TOKEN',
            hintText: 'ghp_...',
            controller: _tokenController,
            inputType: IndustrialInputType.password,
            helperText: 'Leave empty for offline mode',
            prefixIcon: Icon(
              Icons.key_outlined,
              size: 20,
              color: industrialTheme.textSecondary,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 10) {
                return 'Token must be at least 10 characters';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Continue Button - Primary action
        IndustrialButton(
          onPressed: _isLoading ? null : _validateAndContinue,
          label: _tokenController.text.isEmpty
              ? 'CONTINUE OFFLINE'
              : 'CONTINUE',
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.large,
          isFullWidth: true,
          isLoading: _isLoading,
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Info card - How it works
        IndustrialCard(
          type: IndustrialCardType.data,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW IT WORKS',
                style: AppTypography.monoAnnotation.copyWith(
                  color: industrialTheme.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildInfoItem(
                icon: Icons.cloud_off_outlined,
                title: 'OFFLINE FIRST',
                description: 'Use app without authentication',
                industrialTheme: industrialTheme,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDivider(industrialTheme),
              const SizedBox(height: AppSpacing.md),
              _buildInfoItem(
                icon: Icons.cloud_sync_outlined,
                title: 'SYNC LATER',
                description: 'Add token to sync with GitHub',
                industrialTheme: industrialTheme,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDivider(industrialTheme),
              const SizedBox(height: AppSpacing.md),
              _buildInfoItem(
                icon: Icons.folder_outlined,
                title: 'LOCAL CACHE',
                description: 'Data stored securely on device',
                industrialTheme: industrialTheme,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Technical annotation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'v0.2.0-industrial',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildLogo(IndustrialThemeData industrialTheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: industrialTheme.accentSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: industrialTheme.accentPrimary, width: 1),
      ),
      child: Icon(
        Icons.rocket_launch_outlined,
        size: 40,
        color: industrialTheme.accentPrimary,
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
