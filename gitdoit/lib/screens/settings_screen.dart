import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/issues_provider.dart';
import '../providers/theme_provider.dart';
import '../services/theme_prefs.dart';
import '../utils/logger.dart';
import '../utils/repo_config_parser.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';
import 'repository_picker_screen.dart';

/// Dialog status for repository configuration
enum _RepositoryDialogStatus { idle, validating, loading, success, error }

/// Login method selection
enum _LoginMethod { oauth, token }

/// Settings Screen - App configuration
///
/// REDESIGNED: Industrial Minimalism with technical layout
/// Monospace labels, modular sections, dot-matrix icons
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
          _buildSectionHeader(context, 'ACCOUNT'),
          const SizedBox(height: AppSpacing.md),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return _SettingsTile(
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
                    : () => _showLoginDialog(context, auth),
                enabled: !auth.isLoading,
              );
            },
          ),
          if (Provider.of<AuthProvider>(context).isAuthenticated) ...[
            const SizedBox(height: AppSpacing.sm),
            _SettingsTile(
              icon: Icons.folder_outlined,
              title: 'Select Repository',
              subtitle: 'Choose from your repositories',
              onTap: () => _navigateToRepositoryPicker(context),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Repository section
          _buildSectionHeader(context, 'REPOSITORY'),
          const SizedBox(height: AppSpacing.md),
          Consumer<IssuesProvider>(
            builder: (context, issues, _) {
              return _SettingsTile(
                icon: Icons.folder_outlined,
                title: 'Default Repository',
                subtitle: issues.repository != null
                    ? '${issues.repository!.owner}/${issues.repository!.name}'
                    : 'Not configured',
                onTap: () => _showRepositoryDialog(context, issues),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // App section
          _buildSectionHeader(context, 'APPEARANCE'),
          const SizedBox(height: AppSpacing.md),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: _getThemeModeLabel(themeProvider.themeMode),
                onTap: () => _showThemeDialog(context, themeProvider),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Coming soon',
            enabled: false,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Data section
          _buildSectionHeader(context, 'DATA'),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Offline Storage',
            subtitle: 'Manage cached data',
            onTap: () => _showStorageDialog(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove locally stored issues',
            isDestructive: true,
            onTap: () => _showClearCacheDialog(context),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Developer section
          _buildSectionHeader(context, 'DEVELOPER'),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Debug Console',
            subtitle: 'View logs and metrics',
            onTap: () {
              Logger.i('Opening debug console', context: 'Settings');
              Navigator.pushNamed(context, '/debug');
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Danger zone
          _buildSectionHeader(context, 'DANGER ZONE', isDestructive: true),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.logout_outlined,
            title: 'Logout',
            subtitle: 'Remove saved token',
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // App version - Technical annotation
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                      'GitDoIt v1.0.0+2',
                      style: AppTypography.monoAnnotation.copyWith(
                        color: industrialTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Built with Flutter',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                RichText(
                  text: TextSpan(
                    text: 'by ',
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textTertiary.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    children: [
                      TextSpan(
                        text: 'BerlogaBob',
                        style: AppTypography.captionSmall.copyWith(
                          color: industrialTheme.textTertiary.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' with ❤️ from Portugal',
                        style: AppTypography.captionSmall.copyWith(
                          color: industrialTheme.textTertiary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    bool isDestructive = false,
  }) {
    final industrialTheme = context.industrialTheme;

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: isDestructive
              ? industrialTheme.statusError
              : industrialTheme.accentPrimary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.monoAnnotation.copyWith(
            color: isDestructive
                ? industrialTheme.statusError
                : industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Future<void> _showRepositoryDialog(
    BuildContext context,
    IssuesProvider issuesProvider,
  ) async {
    final ownerController = TextEditingController();
    final repoController = TextEditingController();
    final industrialTheme = context.industrialTheme;

    // Pre-fill with existing repository if configured
    if (issuesProvider.repository != null) {
      ownerController.text = issuesProvider.owner;
      repoController.text = issuesProvider.repo;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          var status = _RepositoryDialogStatus.idle;
          String? validationError;

          Widget buildStatusWidget() {
            switch (status) {
              case _RepositoryDialogStatus.validating:
                return Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: industrialTheme.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Validating repository...',
                      style: AppTypography.captionSmall.copyWith(
                        color: industrialTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              case _RepositoryDialogStatus.loading:
                return Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: industrialTheme.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Loading issues...',
                      style: AppTypography.captionSmall.copyWith(
                        color: industrialTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              case _RepositoryDialogStatus.success:
                return Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: industrialTheme.statusSuccess,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Repository validated successfully',
                      style: AppTypography.captionSmall.copyWith(
                        color: industrialTheme.statusSuccess,
                      ),
                    ),
                  ],
                );
              case _RepositoryDialogStatus.error:
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: industrialTheme.statusError,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            validationError ?? 'Unknown error',
                            style: AppTypography.captionSmall.copyWith(
                              color: industrialTheme.statusError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    IndustrialButton(
                      onPressed: () async {
                        // Parse repository input (supports URLs and owner/repo format)
                        final parsed = _parseRepositoryInput(
                          ownerController.text,
                          repoController.text,
                        );

                        if (parsed == null) {
                          setDialogState(() {
                            status = _RepositoryDialogStatus.error;
                            validationError =
                                'Invalid repository format. Use owner/repo or GitHub URL';
                          });
                          return;
                        }

                        // Retry validation
                        setDialogState(() {
                          status = _RepositoryDialogStatus.validating;
                          validationError = null;
                        });

                        issuesProvider.setRepository(parsed.owner, parsed.repo);
                        final isValid = await issuesProvider
                            .validateRepository(parsed.owner, parsed.repo);

                        if (!context.mounted) return;

                        setDialogState(() {
                          status = isValid
                              ? _RepositoryDialogStatus.success
                              : _RepositoryDialogStatus.error;
                          validationError = isValid
                              ? null
                              : 'Repository not found';
                        });
                      },
                      label: 'RETRY',
                      variant: IndustrialButtonVariant.primary,
                      size: IndustrialButtonSize.small,
                    ),
                  ],
                );
              case _RepositoryDialogStatus.idle:
                return const SizedBox.shrink();
            }
          }

          return AlertDialog(
            backgroundColor: industrialTheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
            ),
            title: Text(
              'SET REPOSITORY',
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IndustrialInput(
                    label: 'OWNER',
                    hintText: 'e.g., berlogabob',
                    controller: ownerController,
                    enabled:
                        status == _RepositoryDialogStatus.idle ||
                        status == _RepositoryDialogStatus.success ||
                        status == _RepositoryDialogStatus.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  IndustrialInput(
                    label: 'REPOSITORY',
                    hintText: 'e.g., flutter-github-issues-todo',
                    controller: repoController,
                    enabled:
                        status == _RepositoryDialogStatus.idle ||
                        status == _RepositoryDialogStatus.success ||
                        status == _RepositoryDialogStatus.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  buildStatusWidget(),
                ],
              ),
            ),
            actions: [
              IndustrialButton(
                onPressed:
                    status == _RepositoryDialogStatus.validating ||
                        status == _RepositoryDialogStatus.loading
                    ? null
                    : () => Navigator.pop(context),
                label: 'CANCEL',
                variant: IndustrialButtonVariant.text,
                size: IndustrialButtonSize.small,
              ),
              IndustrialButton(
                onPressed:
                    status == _RepositoryDialogStatus.validating ||
                        status == _RepositoryDialogStatus.loading
                    ? null
                    : () async {
                        // Parse repository input (supports URLs and owner/repo format)
                        final parsed = _parseRepositoryInput(
                          ownerController.text,
                          repoController.text,
                        );

                        if (parsed == null) {
                          setDialogState(() {
                            status = _RepositoryDialogStatus.error;
                            validationError =
                                'Invalid repository format. Use owner/repo or GitHub URL';
                          });
                          return;
                        }

                        // Start validation
                        setDialogState(() {
                          status = _RepositoryDialogStatus.validating;
                          validationError = null;
                        });

                        Logger.i(
                          'Setting repository: ${parsed.owner}/${parsed.repo}',
                          context: 'Settings',
                        );
                        issuesProvider.setRepository(parsed.owner, parsed.repo);

                        // Validate repository
                        try {
                          final isValid = await issuesProvider
                              .validateRepository(parsed.owner, parsed.repo);

                          if (!context.mounted) return;

                          setDialogState(() {
                            status = isValid
                                ? _RepositoryDialogStatus.success
                                : _RepositoryDialogStatus.error;
                            validationError = isValid
                                ? null
                                : 'Repository not found on GitHub';
                          });

                          if (!isValid) return;

                          // Load issues after successful validation
                          setDialogState(() {
                            status = _RepositoryDialogStatus.loading;
                          });

                          await issuesProvider.loadIssues();

                          if (!context.mounted) return;

                          setDialogState(() {
                            status = _RepositoryDialogStatus.success;
                          });

                          // Show success and close dialog
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
                                    'Repository set to ${parsed.owner}/${parsed.repo}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: industrialTheme.surfacePrimary,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: industrialTheme.statusSuccess,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium,
                                ),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;

                          setDialogState(() {
                            status = _RepositoryDialogStatus.error;
                            validationError = e.toString().replaceAll(
                              'Exception: ',
                              '',
                            );
                          });
                        }
                      },
                label: 'SAVE',
                variant: IndustrialButtonVariant.primary,
                size: IndustrialButtonSize.small,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Parse repository input from user (supports URLs and owner/repo format)
  ///
  /// Combines owner and repo fields and parses as:
  /// - Plain text: "owner/repo"
  /// - Full URL: "https://github.com/owner/repo"
  /// - SSH URL: "git@github.com:owner/repo.git"
  RepoOwnerRepo? _parseRepositoryInput(String ownerInput, String repoInput) {
    // If repo field is empty but owner looks like a URL, try parsing owner as full URL
    final ownerTrimmed = ownerInput.trim();
    final repoTrimmed = repoInput.trim();

    // Check if owner field contains a full URL
    if (ownerTrimmed.contains('github.com') ||
        ownerTrimmed.startsWith('git@')) {
      return parseRepositoryInput(ownerTrimmed);
    }

    // Standard owner/repo format
    if (ownerTrimmed.isNotEmpty && repoTrimmed.isNotEmpty) {
      return RepoOwnerRepo(owner: ownerTrimmed, repo: repoTrimmed);
    }

    return null;
  }

  /// Navigate to repository picker screen
  Future<void> _navigateToRepositoryPicker(BuildContext context) async {
    Logger.d('Opening repository picker', context: 'Settings');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RepositoryPickerScreen()),
    );

    if (result != null && mounted) {
      setState(() {}); // Refresh UI
    }
  }

  /// Show login dialog with OAuth and Token options
  Future<void> _showLoginDialog(BuildContext context, AuthProvider auth) async {
    final industrialTheme = context.industrialTheme;
    _LoginMethod selectedMethod = _LoginMethod.oauth;
    final tokenController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                  child: Icon(
                    Icons.login_outlined,
                    color: industrialTheme.accentPrimary,
                    size: 20,
                  ),
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
                  // Method selection
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
                        child: _LoginMethodTile(
                          icon: Icons.cloud_sync_outlined,
                          title: 'OAuth',
                          description: 'Quick & secure',
                          selected: selectedMethod == _LoginMethod.oauth,
                          onTap: () => setDialogState(
                            () => selectedMethod = _LoginMethod.oauth,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _LoginMethodTile(
                          icon: Icons.key_outlined,
                          title: 'Token',
                          description: 'Manual entry',
                          selected: selectedMethod == _LoginMethod.token,
                          onTap: () => setDialogState(
                            () => selectedMethod = _LoginMethod.token,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // OAuth method
                  if (selectedMethod == _LoginMethod.oauth) ...[
                    _buildOAuthSection(
                      context,
                      setDialogState,
                      industrialTheme,
                    ),
                  ],

                  // Token method
                  if (selectedMethod == _LoginMethod.token) ...[
                    _buildTokenSection(
                      context,
                      setDialogState,
                      tokenController,
                      industrialTheme,
                      auth,
                    ),
                  ],
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
        },
      ),
    );

    tokenController.dispose();
  }

  Widget _buildOAuthSection(
    BuildContext context,
    void Function(void Function()) setDialogState,
    IndustrialThemeData industrialTheme,
  ) {
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
          'You will be redirected to GitHub to authorize this app. This is the recommended method for most users.',
          style: AppTypography.bodySmall.copyWith(
            color: industrialTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndustrialCard(
          type: IndustrialCardType.data,
          padding: const EdgeInsets.all(AppSpacing.md),
          backgroundColor: industrialTheme.accentSubtle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: industrialTheme.accentPrimary,
                  ),
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndustrialButton(
          onPressed: () async {
            try {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final oauthUrl = await auth.loginWithOAuth();

              // Launch OAuth URL
              final uri = Uri.parse(oauthUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);

                if (!context.mounted) return;

                // Show instructions
                _showOAuthInstructions(context, industrialTheme);
              } else {
                throw Exception('Cannot open browser');
              }
            } catch (e, stackTrace) {
              Logger.e(
                'OAuth login failed',
                error: e,
                stackTrace: stackTrace,
                context: 'Settings',
              );
              if (!context.mounted) return;
              _showError(
                context,
                'Failed to start OAuth: ${e.toString().replaceAll("Exception: ", "")}',
                industrialTheme,
              );
            }
          },
          label: 'START OAUTH LOGIN',
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.medium,
          isFullWidth: true,
          icon: Icon(
            Icons.open_in_new_outlined,
            size: 18,
            color: AppColors.textOnAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildTokenSection(
    BuildContext context,
    void Function(void Function()) setDialogState,
    TextEditingController tokenController,
    IndustrialThemeData industrialTheme,
    AuthProvider auth,
  ) {
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
          'Enter your GitHub Personal Access Token (PAT). You can create one in GitHub Developer Settings.',
          style: AppTypography.bodySmall.copyWith(
            color: industrialTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IndustrialInput(
          label: 'TOKEN',
          hintText: 'ghp_...',
          controller: tokenController,
          inputType: IndustrialInputType.password,
          prefixIcon: Icon(
            Icons.key_outlined,
            size: 20,
            color: industrialTheme.textSecondary,
          ),
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
          onPressed: auth.isLoading
              ? null
              : () async {
                  final token = tokenController.text.trim();

                  if (token.isEmpty) {
                    _showError(
                      context,
                      'Please enter a token',
                      industrialTheme,
                    );
                    return;
                  }

                  try {
                    await auth.validateAndSaveToken(token);

                    if (!context.mounted) return;

                    if (auth.isAuthenticated) {
                      Navigator.pop(context);
                      _showSuccess(
                        context,
                        'Logged in as ${auth.username}',
                        industrialTheme,
                      );
                    } else {
                      _showError(
                        context,
                        auth.errorMessage ?? 'Authentication failed',
                        industrialTheme,
                      );
                    }
                  } catch (e, stackTrace) {
                    Logger.e(
                      'Token login failed',
                      error: e,
                      stackTrace: stackTrace,
                      context: 'Settings',
                    );
                    if (!context.mounted) return;
                    _showError(
                      context,
                      'Failed to login: ${e.toString().replaceAll("Exception: ", "")}',
                      industrialTheme,
                    );
                  }
                },
          label: auth.isLoading ? 'VALIDATING...' : 'LOGIN',
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.medium,
          isFullWidth: true,
          isLoading: auth.isLoading,
        ),
      ],
    );
  }

  void _showOAuthInstructions(
    BuildContext context,
    IndustrialThemeData industrialTheme,
  ) {
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
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Authorize the app in GitHub',
              style: AppTypography.labelMedium.copyWith(
                color: industrialTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '2. After authorization, you will be redirected back to this app',
              style: AppTypography.bodySmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '3. If not redirected automatically, copy the code from the URL and paste it below',
              style: AppTypography.bodySmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
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

  void _showError(
    BuildContext context,
    String message,
    IndustrialThemeData industrialTheme,
  ) {
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

  void _showSuccess(
    BuildContext context,
    String message,
    IndustrialThemeData industrialTheme,
  ) {
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

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
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
          'THEME',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: 'System Default',
              subtitle: 'Follow device settings',
              selected: themeProvider.isSystemMode,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.system);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ThemeOption(
              title: 'Light',
              subtitle: 'Always use light theme',
              selected: themeProvider.isLightMode,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.light);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ThemeOption(
              title: 'Dark',
              subtitle: 'Always use dark theme',
              selected: themeProvider.isDarkMode,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.dark);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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

  void _showStorageDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isLoading = true;
          Map<String, dynamic>? stats;

          // Load stats on dialog open
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final loadedStats = await issuesProvider.getStorageStats();
            if (context.mounted) {
              setDialogState(() {
                stats = loadedStats;
                isLoading = false;
              });
            }
          });

          Widget buildStatsContent() {
            if (isLoading) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: industrialTheme.accentPrimary,
                    ),
                  ),
                ),
              );
            }

            final issueCount = stats?['issueCount'] as int? ?? 0;
            final cacheSize =
                stats?['cacheSizeFormatted'] as String? ?? 'Unknown';
            final lastSync =
                stats?['lastSyncTimeFormatted'] as String? ?? 'Never';
            final repoCount = stats?['repositoryCount'] as int? ?? 0;
            final isOffline = stats?['isOffline'] as bool? ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cache size
                _buildStatRow(
                  context,
                  icon: Icons.storage_outlined,
                  label: 'CACHE SIZE',
                  value: cacheSize,
                  industrialTheme: industrialTheme,
                ),
                const SizedBox(height: AppSpacing.md),

                // Issue count
                _buildStatRow(
                  context,
                  icon: Icons.article_outlined,
                  label: 'CACHED ISSUES',
                  value: '$issueCount',
                  industrialTheme: industrialTheme,
                ),
                const SizedBox(height: AppSpacing.md),

                // Repository count
                _buildStatRow(
                  context,
                  icon: Icons.folder_outlined,
                  label: 'REPOSITORIES',
                  value: '$repoCount',
                  industrialTheme: industrialTheme,
                ),
                const SizedBox(height: AppSpacing.md),

                // Last sync time
                _buildStatRow(
                  context,
                  icon: Icons.access_time_outlined,
                  label: 'LAST SYNC',
                  value: lastSync,
                  industrialTheme: industrialTheme,
                ),
                const SizedBox(height: AppSpacing.md),

                // Connection status
                _buildStatRow(
                  context,
                  icon: isOffline
                      ? Icons.cloud_off_outlined
                      : Icons.cloud_done_outlined,
                  label: 'CONNECTION',
                  value: isOffline ? 'OFFLINE' : 'ONLINE',
                  valueColor: isOffline
                      ? industrialTheme.textTertiary
                      : industrialTheme.statusSuccess,
                  industrialTheme: industrialTheme,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Info note
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: industrialTheme.accentSubtle,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(
                      color: industrialTheme.accentPrimary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: industrialTheme.accentPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Cache size is estimated. Clear cache to free up space.',
                          style: AppTypography.captionSmall.copyWith(
                            color: industrialTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

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
                  child: Icon(
                    Icons.storage_outlined,
                    color: industrialTheme.accentPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'OFFLINE STORAGE',
                  style: AppTypography.headlineSmall.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(child: buildStatsContent()),
            actions: [
              IndustrialButton(
                onPressed: () => Navigator.pop(context),
                label: 'DONE',
                variant: IndustrialButtonVariant.text,
                size: IndustrialButtonSize.small,
              ),
              IndustrialButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showClearCacheDialog(context);
                },
                label: 'CLEAR CACHE',
                variant: IndustrialButtonVariant.destructive,
                size: IndustrialButtonSize.small,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build a stat row for the storage dialog
  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required IndustrialThemeData industrialTheme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: industrialTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Icon(icon, size: 16, color: industrialTheme.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.monoAnnotation.copyWith(
              color: industrialTheme.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.monoData.copyWith(
            color: valueColor ?? industrialTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isClearing = false;
          String? clearError;

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
                  child: Icon(
                    Icons.delete_outline,
                    color: industrialTheme.accentPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'CLEAR CACHE',
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
                  // Cache info
                  Text(
                    'SELECT CLEAR OPTION',
                    style: AppTypography.monoAnnotation.copyWith(
                      color: industrialTheme.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Cache stats
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: industrialTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                      border: Border.all(
                        color: industrialTheme.borderPrimary,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage_outlined,
                              size: 16,
                              color: industrialTheme.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Cached Issues',
                              style: AppTypography.labelSmall.copyWith(
                                color: industrialTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${issuesProvider.issues.length} issues',
                          style: AppTypography.monoAnnotation.copyWith(
                            color: industrialTheme.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Option 1: Clear Issues Cache
                  // ignore: dead_code
                  _ClearCacheOption(
                    icon: Icons.folder_outlined,
                    title: 'Clear Issues Cache',
                    description:
                        'Remove cached issues only. Repository config and login will be kept.',
                    industrialTheme: industrialTheme,
                    onTap: isClearing
                        ? null // ignore: dead_code
                        : () async {
                            setDialogState(() {
                              isClearing = true;
                              clearError = null;
                            });

                            try {
                              await issuesProvider.clearCache();
                              if (!mounted) return;
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
                                        'Issues cache cleared',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: industrialTheme
                                                  .surfacePrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      industrialTheme.statusSuccess,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMedium,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              setDialogState(() {
                                isClearing = false;
                                clearError = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              });
                            }
                          },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Option 2: Clear All Data
                  _ClearCacheOption(
                    icon: Icons.warning_outlined,
                    title: 'Clear All Data',
                    description:
                        'Remove everything: issues, repository config, and login. You will need to set up again.',
                    isDestructive: true,
                    industrialTheme: industrialTheme,
                    onTap: isClearing
                        ? null
                        : () async {
                            final theme = industrialTheme;
                            setDialogState(() {
                              isClearing = true;
                              clearError = null;
                            });

                            try {
                              // Clear issues + repo config
                              await issuesProvider.clearAllData();

                              // Clear auth data
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              await authProvider.clearAllData();

                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: theme.surfacePrimary,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'All data cleared',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: theme.surfacePrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: theme.statusSuccess,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMedium,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              setDialogState(() {
                                isClearing = false;
                                clearError = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              });
                            }
                          },
                  ),

                  if (clearError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: industrialTheme.statusError,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            clearError!,
                            style: AppTypography.captionSmall.copyWith(
                              color: industrialTheme.statusError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              IndustrialButton(
                onPressed: isClearing ? null : () => Navigator.pop(context),
                label: 'CANCEL',
                variant: IndustrialButtonVariant.text,
                size: IndustrialButtonSize.small,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final issuesProvider = Provider.of<IssuesProvider>(
                context,
                listen: false,
              );

              await authProvider.logout();
              issuesProvider.clearRepository();

              if (!context.mounted) return;
              // Navigate back to root and show AuthScreen
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/auth', (route) => false);
            },
            label: 'LOGOUT',
            variant: IndustrialButtonVariant.destructive,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }
}

/// Clear cache option tile
class _ClearCacheOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isDestructive;
  final IndustrialThemeData industrialTheme;

  const _ClearCacheOption({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.isDestructive = false,
    required this.industrialTheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDestructive
              ? industrialTheme.statusError.withValues(alpha: 0.1)
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isDestructive
                ? industrialTheme.statusError.withValues(alpha: 0.3)
                : industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDestructive
                    ? industrialTheme.statusError.withValues(alpha: 0.2)
                    : industrialTheme.accentSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? industrialTheme.statusError
                    : industrialTheme.accentPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDestructive
                          ? industrialTheme.statusError
                          : industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description,
                    style: AppTypography.captionSmall.copyWith(
                      color: isDestructive
                          ? industrialTheme.statusError.withValues(alpha: 0.8)
                          : industrialTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: isDestructive
                    ? industrialTheme.statusError
                    : industrialTheme.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable settings tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;
  final bool monospaceSubtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
    this.monospaceSubtitle = false,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDestructive
                  ? industrialTheme.statusError.withValues(alpha: 0.1)
                  : industrialTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isDestructive
                    ? industrialTheme.statusError
                    : industrialTheme.borderPrimary,
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        (monospaceSubtitle
                                ? AppTypography.monoAnnotation
                                : AppTypography.captionSmall)
                            .copyWith(
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

/// Theme option tile
class _ThemeOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? industrialTheme.accentPrimary
                      : industrialTheme.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected
                        ? industrialTheme.accentPrimary
                        : industrialTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  subtitle!,
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Login method tile widget
class _LoginMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _LoginMethodTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected
                      ? industrialTheme.accentPrimary
                      : industrialTheme.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelSmall.copyWith(
                      color: selected
                          ? industrialTheme.accentPrimary
                          : industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description,
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
