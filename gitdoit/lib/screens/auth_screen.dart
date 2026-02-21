import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../providers/auth_provider.dart';
import '../utils/logger.dart';

/// Authentication Screen - Entry point for GitDoIt app
///
/// OFFLINE-FIRST: Users can skip login and use app offline
/// Token can be added later from settings
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
        // Don't auto-validate - let user choose to login
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
      // Save token but don't validate yet
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
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToHome() {
    Logger.i('Navigating to HomeScreen', context: 'Auth');
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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

        // Offline error
        if (_isOffline) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.error),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Working offline - Add token later',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Token Input Form
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _tokenController,
            obscureText: _obscureText,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: 'GitHub Personal Access Token (Optional)',
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
              helperText: 'Leave empty to use offline mode',
              helperStyle: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 10) {
                return 'Token must be at least 10 characters';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 24),

        // Continue Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _validateAndContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _tokenController.text.isEmpty
                        ? 'CONTINUE OFFLINE'
                        : 'CONTINUE',
                    style: textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Info card
        Card(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  icon: Icons.cloud_off_outlined,
                  text: 'Use app offline without token',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                  icon: Icons.cloud_sync_outlined,
                  text: 'Add token later to sync with GitHub',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                  icon: Icons.key,
                  text: 'Get token from github.com/settings/tokens',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ),

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

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
