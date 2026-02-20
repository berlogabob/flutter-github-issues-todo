import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../providers/auth_provider.dart';
import '../utils/logger.dart';

/// Authentication Screen - Entry point for GitDoIt app
///
/// Allows users to enter their GitHub Personal Access Token (PAT)
/// for authentication with the GitHub API.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
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
      Logger.e('Failed to load saved token', error: e, context: 'Auth');
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

    // Basic validation
    if (!token.startsWith('ghp_') &&
        !token.startsWith('gho_') &&
        !token.startsWith('ghu_') &&
        !token.startsWith('ghs_') &&
        !token.startsWith('github_pat_')) {
      _showError(
        'Invalid token format. GitHub tokens start with ghp_, gho_, ghu_, ghs_, or github_pat_',
      );
      return;
    }

    if (token.length < 10) {
      _showError('Token too short. Please check your token.');
      return;
    }

    // Save token and validate with GitHub
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.validateAndSaveToken(token);

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
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToHome() {
    // TODO: Navigate to home screen
    Logger.d('Navigation to home - not implemented yet', context: 'Auth');
  }

  void _openGitHubTokenPage() async {
    // TODO: Open GitHub token page in browser
    Logger.d(
      'Opening GitHub token page - not implemented yet',
      context: 'Auth',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),

        // Logo
        _buildLogo(colorScheme),

        const SizedBox(height: 24),

        // Title
        Text(
          'Welcome to GitDoIt',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Your GitHub Issues TODO Tool',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        // Token Input Form
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _tokenController,
            obscureText: _obscureText,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: 'GitHub Personal Access Token',
              hintText: 'ghp_...',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              helperText: 'Starts with ghp_, gho_, ghu_, ghs_, or github_pat_',
              helperStyle: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your GitHub token';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 24),

        // Get Started Button
        SizedBox(
          height: 56,
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return ElevatedButton(
                onPressed: authProvider.isLoading ? null : _validateAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'GET STARTED',
                        style: textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                        ),
                      ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Divider with "or"
        Row(
          children: [
            Expanded(child: Divider(color: colorScheme.outline.withAlpha(128))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: colorScheme.outline.withAlpha(128))),
          ],
        ),

        const SizedBox(height: 24),

        // Create token link
        TextButton.icon(
          onPressed: _openGitHubTokenPage,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Create one on GitHub'),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),

        const SizedBox(height: 32),

        // Token Requirements Card
        _buildRequirementsCard(colorScheme, textTheme),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.rocket_launch_rounded,
        size: 48,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildRequirementsCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Token Requirements',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRequirementItem(
              icon: Icons.check_circle_outline,
              text: 'repo:read & repo:write',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 8),
            _buildRequirementItem(
              icon: Icons.check_circle_outline,
              text: 'issues:read & issues:write',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 8),
            _buildRequirementItem(
              icon: Icons.check_circle_outline,
              text: 'Fine-grained or Classic token',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
