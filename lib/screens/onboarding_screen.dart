import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../models/repo_item.dart';
import '../services/secure_storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/oauth_service.dart';
import '../services/github_api_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/braille_loader.dart';
import 'main_dashboard_screen.dart';

/// OnboardingScreen - First screen with authentication choice
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _patController = TextEditingController();
  final OAuthService _oauthService = OAuthService();
  bool _usePat = false;
  bool _isLoading = false;
  String? _errorMessage;
  DeviceCodeResponse? _deviceCode;

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: ConstrainedContent(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo and Title
              Icon(
                Icons.checklist_rounded,
                size: 80.w,
                color: const Color(0xFFFF6200),
              ),
              SizedBox(height: 24.h),
              Text(
                'GitDoIt',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Minimalist GitHub Issues & Projects TODO Manager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              // Login Options
              if (!_usePat) ...[
                _buildButton(
                  'Login with GitHub',
                  icon: Icons.login,
                  onPressed: _isLoading ? null : _loginWithOAuth,
                ),
                const SizedBox(height: 16),
                _buildButton(
                  'Use Personal Access Token',
                  icon: Icons.key,
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _usePat = true),
                ),
                const SizedBox(height: 16),
                _buildButton(
                  'Continue Offline',
                  icon: Icons.offline_pin,
                  onPressed: _isLoading ? null : _continueOffline,
                  isSecondary: true,
                ),
              ] else ...[
                TextField(
                  controller: _patController,
                  obscureText: true,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Personal Access Token',
                    hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                    labelStyle: TextStyle(
                      color: Color(0x4DFFFFFF),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0x4DFFFFFF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF6200)),
                    ),
                    prefixIcon: Icon(Icons.key, color: Color(0xFFFF6200)),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    // Rebuild to enable/disable Continue button
                    setState(() {});
                  },
                  onSubmitted: (_) => _patController.text.isNotEmpty
                      ? _loginWithPAT(_patController.text)
                      : null,
                ),
                const SizedBox(height: 16),
                _buildButton(
                  'Continue',
                  icon: Icons.arrow_forward,
                  onPressed: _patController.text.isEmpty
                      ? null
                      : () => _loginWithPAT(_patController.text),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _usePat = false),
                  child: const Text('Back to options'),
                ),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 16),
                BrailleLoader(size: 24),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF3B30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF3B30),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFFF3B30),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String label, {
    required IconData icon,
    required VoidCallback? onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24.w),
        label: Text(
          label,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? Colors.transparent
              : const Color(0xFFFF6200),
          foregroundColor: isSecondary ? Colors.white : Colors.black,
          side: isSecondary ? const BorderSide(color: Color(0xFFFF6200)) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _loginWithOAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Request device code
      debugPrint('OAuth: Requesting device code...');
      _deviceCode = await _oauthService.requestDeviceCode();

      if (_deviceCode == null) {
        throw Exception('Failed to get device code from GitHub');
      }

      debugPrint('OAuth: Device code received: ${_deviceCode!.userCode}');

      if (!mounted) return;

      // Step 2: Show dialog with user code
      await _showOAuthDeviceCodeDialog();
    } catch (e, stackTrace) {
      debugPrint('OAuth error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'OAuth failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Show dialog with device code and verification URL
  Future<void> _showOAuthDeviceCodeDialog() async {
    if (_deviceCode == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.qr_code_2, color: AppColors.orangePrimary, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Authorize GitDoIt',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To authorize GitDoIt, follow these steps:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Step 1
                _buildStep('1', 'Visit:', value: _deviceCode!.verificationUri),
                const SizedBox(height: 4),

                // Step 2
                _buildStep(
                  '2',
                  'Enter code:',
                  value: _deviceCode!.userCode,
                  isCode: true,
                ),
                const SizedBox(height: 4),

                // Step 3
                _buildStep('3', 'Authorize GitDoIt when prompted'),

                const SizedBox(height: 16),

                // Copy code button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangePrimary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _deviceCode!.userCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                          backgroundColor: AppColors.orangePrimary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Opening browser button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open in Browser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await _oauthService.openVerificationUrl();
                      // Start polling for token
                      _startPollingForToken(setDialogState);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _oauthService.stopPolling();
                Navigator.pop(context);
                setState(() => _isLoading = false);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    String number,
    String text, {
    String? value,
    bool isCode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.orangePrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.orangePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (value != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.orangePrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: isCode ? AppColors.orangePrimary : Colors.white,
                        fontWeight: isCode
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: isCode ? 18 : 13,
                        fontFamily: isCode ? 'monospace' : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startPollingForToken(StateSetter setDialogState) async {
    setDialogState(() => _isLoading = true);

    try {
      final token = await _oauthService.startPolling();

      if (token != null && mounted) {
        // Success! Navigate to dashboard
        Navigator.pop(context); // Close dialog
        await _handleOAuthSuccess();
      } else if (mounted) {
        // Failed or cancelled
        setDialogState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      debugPrint('Polling error: $e');
      setDialogState(() => _isLoading = false);
    }
  }

  Future<void> _handleOAuthSuccess() async {
    debugPrint('OAuth: Token received successfully');

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Authorization successful!'),
            ],
          ),
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          duration: const Duration(seconds: 1),
        ),
      );

      // Save token and show repo picker
      await _showDefaultRepoPicker();
    }
  }

  Future<void> _loginWithPAT(String token) async {
    // Validate token format
    final trimmedToken = token.trim();

    if (trimmedToken.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid token';
      });
      return;
    }

    debugPrint('=== PAT Login Started ===');
    debugPrint('Token length: ${trimmedToken.length}');
    debugPrint('Token prefix: ${trimmedToken.substring(0, 6)}...');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Basic token format validation
      if (!trimmedToken.startsWith('ghp_') &&
          !trimmedToken.startsWith('github_pat_')) {
        throw Exception(
          'Invalid token format. GitHub tokens start with "ghp_" or "github_pat_"',
        );
      }

      // Validate token length (GitHub tokens are typically 40 chars)
      if (trimmedToken.length < 20 || trimmedToken.length > 100) {
        throw Exception(
          'Invalid token length. Token should be 20-100 characters (yours is ${trimmedToken.length})',
        );
      }

      // Validate token contains only valid characters
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmedToken)) {
        throw Exception(
          'Token contains invalid characters. Tokens should only contain letters, numbers, and underscores',
        );
      }

      // Save token securely
      debugPrint('Saving token to secure storage...');
      await SecureStorageService.saveToken(trimmedToken);
      await SecureStorageService.instance.write(key: 'auth_type', value: 'pat');

      // Verify token was saved immediately
      final verifyToken = await SecureStorageService.getToken();
      final verifyAuthType = await SecureStorageService.instance.read(
        key: 'auth_type',
      );
      debugPrint(
        'Token verification - saved: ${verifyToken != null}, length: ${verifyToken?.length ?? 0}, authType: $verifyAuthType',
      );

      if (verifyToken == null || verifyToken != trimmedToken) {
        throw Exception('Failed to save token securely. Please try again.');
      }

      if (mounted) {
        debugPrint('Token saved successfully, showing repo picker...');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Token accepted!'),
              ],
            ),
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            duration: const Duration(seconds: 1),
          ),
        );

        // Show repo picker
        await _showDefaultRepoPicker();
      }
    } catch (e, stackTrace) {
      debugPrint('PAT login ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueOffline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Starting offline mode...');

      // Request storage permission first
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        // Show explanation dialog
        await _showPermissionExplanationDialog();
      }

      // Show dialog to select vault folder
      final folderPath = await _showFolderSelectionDialog();

      if (folderPath == null) {
        // User cancelled
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Save offline mode flag and vault folder path
      await SecureStorageService.instance.write(
        key: 'auth_type',
        value: 'offline',
      );
      await SecureStorageService.instance.write(
        key: 'vault_folder',
        value: folderPath,
      );

      debugPrint('Offline mode saved with vault folder: $folderPath');

      // Simulate short delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        debugPrint('Navigating to dashboard in offline mode...');
        // Navigate to main dashboard in offline mode
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Offline mode error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to start offline mode: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _requestStoragePermission() async {
    // Check if storage permission is already granted
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Request the permission
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> _showPermissionExplanationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.folder_off, color: AppColors.orangePrimary),
            SizedBox(width: 8),
            Text(
              'Storage Permission Required',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To save your offline issues as markdown files that can be synced with apps like Syncthing or Nextcloud,',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 12),
            Text(
              'Please enable "Files and media" permission in Settings:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Open Settings → Apps → GitDoIt\n'
              '2. Tap "Permissions"\n'
              '3. Enable "Files and media" or "All files access"',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangePrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showFolderSelectionDialog() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder for your offline vault',
      initialDirectory: '/storage/emulated/0',
    );
    return result;
  }

  /// Show dialog to select default repository
  Future<void> _showDefaultRepoPicker() async {
    final githubApi = GitHubApiService();

    // Show dialog immediately with loading state
    final selectedRepo = await showDialog<RepoItem>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RepoPickerDialog(githubApi: githubApi),
    );

    if (!mounted) return;

    // Save selected repository
    if (selectedRepo != null && mounted) {
      await LocalStorageService().saveDefaultRepo(selectedRepo.fullName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('Default repository set: ${selectedRepo.fullName}'),
              ],
            ),
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Navigate to dashboard
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
      );
    }
  }
}

/// Dialog widget for selecting default repository
class _RepoPickerDialog extends StatefulWidget {
  final GitHubApiService githubApi;

  const _RepoPickerDialog({required this.githubApi});

  @override
  State<_RepoPickerDialog> createState() => _RepoPickerDialogState();
}

class _RepoPickerDialogState extends State<_RepoPickerDialog> {
  List<RepoItem> repos = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    try {
      debugPrint('Fetching repositories for repo picker...');
      repos = await widget.githubApi.fetchMyRepositories(perPage: 50);
      debugPrint('Fetched ${repos.length} repositories');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      debugPrint('Error fetching repositories: $e');
      error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AlertDialog(
        backgroundColor: AppColors.cardBackground,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrailleLoader(size: 24),
            const SizedBox(height: 16),
            const Text(
              'Loading your repositories...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Error Loading Repositories',
          style: TextStyle(color: AppColors.red),
        ),
        content: Text(error!, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to dashboard anyway
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainDashboardScreen(),
                ),
              );
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Row(
        children: [
          const Icon(Icons.folder, color: AppColors.orangePrimary),
          const SizedBox(width: 8),
          const Text(
            'Select Default Repository',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a repository to use as default for creating issues:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (repos.isEmpty)
              const Text(
                'No repositories found. You can create one on GitHub.',
                style: TextStyle(color: Colors.white70),
              )
            else
              Flexible(
                child: SizedBox(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: repos.length,
                    itemBuilder: (context, index) {
                      final repo = repos[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.folder,
                          color: AppColors.orangePrimary,
                        ),
                        title: Text(
                          repo.fullName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: repo.description != null
                            ? Text(
                                repo.description!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, repo),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Create new repository button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, color: AppColors.orangePrimary),
                label: const Text(
                  'Create New Repository on GitHub',
                  style: TextStyle(color: AppColors.orangePrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.orangePrimary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  // Open GitHub in browser
                  final uri = Uri.parse('https://github.com/new');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (repos.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to dashboard without selecting
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainDashboardScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            child: const Text('Skip'),
          ),
      ],
    );
  }
}
