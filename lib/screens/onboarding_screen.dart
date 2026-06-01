import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_router.dart';
import '../constants/app_colors.dart';
import '../models/repo_item.dart';
import '../services/secure_storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/github_api_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/braille_loader.dart';
import '../widgets/error_boundary.dart';
import '../widgets/loading_skeleton.dart';

/// OnboardingScreen - First screen with authentication choice
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _patController = TextEditingController();
  final LocalStorageService _localStorage = LocalStorageService();
  bool _isLoading = false;
  String? _errorMessage;

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
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedContent(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                      // Authentication Options
                      _buildButton(
                        'Use Personal Access Token',
                        icon: Icons.key,
                        onPressed: _isLoading ? null : _showPatInput,
                      ),
                      const SizedBox(height: 16),
                      _buildButton(
                        'Continue Offline',
                        icon: Icons.offline_pin,
                        onPressed: _isLoading ? null : _continueOffline,
                        isSecondary: true,
                      ),
                      const SizedBox(height: 24),
                      // Help text
                      Text(
                        'PAT is recommended for full functionality',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading) ...[BrailleLoader(size: 24)],
                      if (_errorMessage != null) ...[
                        InlineError(message: _errorMessage!),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
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

  void _showPatInput() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Row(
          children: [
            Icon(Icons.key, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Personal Access Token',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your GitHub Personal Access Token:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _patController,
              obscureText: true,
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Token',
                hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                labelStyle: TextStyle(color: Color(0x4DFFFFFF), fontSize: 14),
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
              onSubmitted: (_) => _patController.text.isNotEmpty
                  ? _loginWithPAT(_patController.text)
                  : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Required scopes:\n• repo (Full control of private repositories)\n• read:user (Read user profile data)\n• user:email (Access user email addresses)\n• project (Read and write projects)',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _patController.clear();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _patController.text.isEmpty
                ? null
                : () => _loginWithPAT(_patController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
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

    debugPrint('PAT login started');

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
      await SecureStorageService.saveToken(trimmedToken);
      await SecureStorageService.write(key: 'auth_type', value: 'pat');

      // Verify token was saved immediately
      final verifyToken = await SecureStorageService.getToken();
      await SecureStorageService.read(key: 'auth_type');
      debugPrint('PAT login token verification completed');

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

        // Close dialog
        Navigator.pop(context);
        _patController.clear();

        // Show repo picker
        await _showDefaultRepoPicker();
      }
    } catch (e) {
      debugPrint('PAT login failed (${e.runtimeType})');
      if (mounted) {
        setState(() {
          _errorMessage = _safeAuthErrorMessage(e);
        });
      }
      // Close dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
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
        // User cancels
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Save offline mode flag
      await SecureStorageService.write(key: 'auth_type', value: 'offline');

      // PERSIST PERMISSION (use LocalStorageService for vault_folder)
      await _localStorage.saveVaultFolderPermission(folderPath);

      debugPrint('Offline mode saved with vault folder: $folderPath');

      // Simulate short delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        debugPrint('Navigating to dashboard in offline mode...');
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      debugPrint('Offline mode failed (${e.runtimeType})');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to start offline mode. Check permissions and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _safeAuthErrorMessage(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('save authentication token') ||
        value.contains('save token securely')) {
      return 'Unable to securely store your token. Please try again.';
    }
    if (value.contains('invalid token format') ||
        value.contains('invalid token length') ||
        value.contains('invalid characters')) {
      return error.toString();
    }
    return 'Authentication failed. Please verify your token and try again.';
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
        backgroundColor: AppColors.card,
        title: const Row(
          children: [
            Icon(Icons.folder_off, color: AppColors.primary),
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showFolderSelectionDialog() async {
    final result = await FilePicker.getDirectoryPath(
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
      await _localStorage.saveDefaultRepo(selectedRepo.fullName);

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

        context.go(AppRoutes.dashboard);
      }
    } else if (mounted) {
      // User cancelled - show error
      setState(() {
        _errorMessage = 'Please select a default repository to continue';
      });
    }
  }
}

/// Dialog to select default repository
class _RepoPickerDialog extends StatefulWidget {
  const _RepoPickerDialog({required this.githubApi});

  final GitHubApiService githubApi;

  @override
  State<_RepoPickerDialog> createState() => _RepoPickerDialogState();
}

class _RepoPickerDialogState extends State<_RepoPickerDialog> {
  List<RepoItem> _repos = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRepos();
  }

  Future<void> _fetchRepos() async {
    try {
      final repos = await widget.githubApi.fetchMyRepositories();
      setState(() {
        _repos = repos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<RepoItem> get _filteredRepos {
    if (_searchQuery.isEmpty) return _repos;
    return _repos
        .where(
          (repo) =>
              repo.fullName.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Row(
        children: [
          Icon(Icons.folder, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Select Default Repo', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: LoadingSkeleton(height: 56, itemCount: 5, spacing: 12),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InlineError(message: _error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchRepos,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search repositories...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 16),
                  // Repo list
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: _filteredRepos.length,
                      itemBuilder: (context, index) {
                        final repo = _filteredRepos[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            repo.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            repo.fullName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, repo),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
