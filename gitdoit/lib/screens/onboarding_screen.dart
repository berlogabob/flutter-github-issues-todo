import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';
import '../utils/logging.dart';
import 'home_screen.dart';

/// Onboarding Screen - First-time user experience
///
/// Features:
/// - Welcome screen with app branding
/// - "How It Works" cards
/// - Authentication choice (PAT/OAuth/Offline)
/// - Quick start guide
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(industrialTheme),
            
            // Main content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(industrialTheme),
                  _buildHowItWorksPage(industrialTheme),
                  _buildAuthChoicePage(industrialTheme),
                ],
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(industrialTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(IndustrialThemeData industrialTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            width: _currentPage == index ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? industrialTheme.accentPrimary
                  : industrialTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: industrialTheme.borderPrimary,
                width: 1,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage(IndustrialThemeData industrialTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: industrialTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(
                color: industrialTheme.accentPrimary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: industrialTheme.accentPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: industrialTheme.accentPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // App Name
          Text(
            'GitDoIt',
            style: AppTypography.headlineLarge.copyWith(
              color: industrialTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Subtitle
          Text(
            'GitHub Issues & Projects\nTODO Manager',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: industrialTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Feature highlights
          _buildFeatureItem(
            industrialTheme,
            Icons.cloud_off_outlined,
            'Offline First',
            'Work without internet, sync later',
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildFeatureItem(
            industrialTheme,
            Icons.check_circle_outline,
            'Simple TODO',
            'Minimalist interface, maximum productivity',
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildFeatureItem(
            industrialTheme,
            Icons.folder_outlined,
            'Projects Support',
            'Manage GitHub Projects v2 boards',
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage(IndustrialThemeData industrialTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'HOW IT WORKS',
            style: AppTypography.monoAnnotation.copyWith(
              color: industrialTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Step cards
          _buildStepCard(
            industrialTheme,
            '01',
            'Connect to GitHub',
            'Login with your GitHub account using OAuth or Personal Access Token',
            Icons.login_outlined,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildStepCard(
            industrialTheme,
            '02',
            'Select Repository',
            'Choose from your repositories or add any public repo',
            Icons.folder_outlined,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildStepCard(
            industrialTheme,
            '03',
            'Manage Issues',
            'Create, edit, and organize issues as your TODO tasks',
            Icons.check_circle_outline,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildStepCard(
            industrialTheme,
            '04',
            'Sync Anytime',
            'Work offline and sync when you\'re back online',
            Icons.cloud_sync_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthChoicePage(IndustrialThemeData industrialTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'GET STARTED',
            style: AppTypography.monoAnnotation.copyWith(
              color: industrialTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Text(
            'Choose your login method',
            style: AppTypography.headlineSmall.copyWith(
              color: industrialTheme.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // OAuth Option
          _buildAuthOption(
            context,
            industrialTheme,
            'OAuth Login',
            'Recommended - Secure and easy',
            Icons.login,
            () => _startOAuthLogin(context),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // PAT Option
          _buildAuthOption(
            context,
            industrialTheme,
            'Personal Access Token',
            'For advanced users',
            Icons.key_outlined,
            () => _showPATDialog(context),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Offline Option
          _buildAuthOption(
            context,
            industrialTheme,
            'Continue Offline',
            'Try without login',
            Icons.cloud_off_outlined,
            () => _startOffline(context),
            isDestructive: false,
            isSecondary: true,
          ),
          
          const Spacer(),
          
          // Info note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: industrialTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: industrialTheme.borderPrimary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: industrialTheme.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'You can change authentication method anytime in Settings',
                    style: AppTypography.captionSmall.copyWith(
                      color: industrialTheme.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IndustrialThemeData industrialTheme,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: industrialTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: industrialTheme.borderPrimary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: industrialTheme.accentPrimary,
            size: 24,
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
      ),
    );
  }

  Widget _buildStepCard(
    IndustrialThemeData industrialTheme,
    String step,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: industrialTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: industrialTheme.borderPrimary,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: industrialTheme.accentPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: industrialTheme.accentPrimary,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                step,
                style: AppTypography.monoAnnotation.copyWith(
                  color: industrialTheme.accentPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: industrialTheme.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.labelMedium.copyWith(
                          color: industrialTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
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
      ),
    );
  }

  Widget _buildAuthOption(
    BuildContext context,
    IndustrialThemeData industrialTheme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
    bool isSecondary = false,
  }) {
    return IndustrialCard(
      type: IndustrialCardType.interactive,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSecondary
                  ? industrialTheme.surfacePrimary
                  : (isDestructive
                      ? industrialTheme.statusError.withOpacity(0.1)
                      : industrialTheme.accentPrimary.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isSecondary
                    ? industrialTheme.borderPrimary
                    : (isDestructive
                        ? industrialTheme.statusError
                        : industrialTheme.accentPrimary),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSecondary
                  ? industrialTheme.textSecondary
                  : (isDestructive
                      ? industrialTheme.statusError
                      : industrialTheme.accentPrimary),
            ),
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
                Text(
                  subtitle,
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          Icon(
            Icons.chevron_right_outlined,
            color: industrialTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(IndustrialThemeData industrialTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentPage > 0)
            IndustrialButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              label: 'BACK',
              variant: IndustrialButtonVariant.text,
            )
          else
            const SizedBox.shrink(),
          
          // Next/Skip button
          IndustrialButton(
            onPressed: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            label: _currentPage == 2 ? 'GET STARTED' : 'NEXT',
            variant: IndustrialButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _startOAuthLogin(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      Logger.i('Starting OAuth from onboarding', context: 'Onboarding');
      
      final result = await authProvider.startOAuthLogin();
      
      if (!context.mounted) return;
      
      // Show user code dialog
      _showOAuthCodeDialog(context, result['user_code'] ?? '', result['verification_uri'] ?? '');
      
      // Complete OAuth flow in background
      authProvider.completeOAuthFlow();
      
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OAuth failed: $e'),
          backgroundColor: context.industrialTheme.statusError,
        ),
      );
    }
  }

  void _showOAuthCodeDialog(
    BuildContext context,
    String userCode,
    String verificationUri,
  ) {
    final industrialTheme = context.industrialTheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'AUTHORIZE ON GITHUB',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter this code on GitHub:',
              style: AppTypography.bodyMedium.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: industrialTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: industrialTheme.accentPrimary,
                  width: 2,
                ),
              ),
              child: Text(
                userCode,
                style: AppTypography.headlineMedium.copyWith(
                  color: industrialTheme.accentPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Or visit: $verificationUri',
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  industrialTheme.accentPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Waiting for authorization...',
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPATDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final tokenController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Text(
          'PERSONAL ACCESS TOKEN',
          style: AppTypography.headlineSmall.copyWith(
            color: industrialTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IndustrialInput(
              label: 'TOKEN',
              hintText: 'ghp_...',
              controller: tokenController,
              inputType: IndustrialInputType.password,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Create token at: github.com/settings/tokens',
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textSecondary,
              ),
            ),
          ],
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
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = tokenController.text.trim();
              
              if (token.isEmpty) {
                Navigator.pop(context);
                return;
              }
              
              try {
                await authProvider.validateAndSaveToken(token);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _navigateToMain(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged in as ${authProvider.username}'),
                    backgroundColor: context.industrialTheme.statusSuccess,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login failed: $e'),
                    backgroundColor: context.industrialTheme.statusError,
                  ),
                );
              }
            },
            label: 'LOGIN',
            variant: IndustrialButtonVariant.primary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _startOffline(BuildContext context) {
    Logger.i('Starting offline mode', context: 'Onboarding');
    _navigateToMain(context);
  }

  void _navigateToMain(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }
}
