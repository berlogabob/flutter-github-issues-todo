import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../models/repo_item.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../services/cache_service.dart';
import '../services/pending_operations_service.dart';
import '../services/error_logging_service.dart';
import '../widgets/braille_loader.dart';
import '../widgets/pending_operations_list.dart';
import 'onboarding_screen.dart';
import 'debug_screen.dart';
import 'sync_status_dashboard_screen.dart';
import 'error_log_screen.dart';

/// Settings screen for app configuration and account management.
///
/// Provides access to:
/// - User account settings and logout
/// - Repository and project defaults
/// - Sync configuration (WiFi/mobile data)
/// - Connection testing
/// - Cache management and token reset
/// - App version information
///
/// Implements brief section 7, screen 7.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const SettingsScreen()),
/// );
/// ```
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  bool _autoSyncWifi = true;
  bool _autoSyncAny = false;
  bool _isLoadingUser = true;
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDefaultRepo();
    _loadDefaultProject();
    _loadAutoSyncSettings();
    _loadAppVersion();
  }

  /// Load app version from package info
  Future<void> _loadAppVersion() async {
    final version = await _getAppVersion();
    if (mounted) {
      setState(() {
        _appVersion = version;
      });
    }
  }

  /// Load auto-sync settings from local storage (Task 16.3)
  Future<void> _loadAutoSyncSettings() async {
    final autoSyncWifi = await _localStorage.getAutoSyncWifi();
    final autoSyncAny = await _localStorage.getAutoSyncAny();
    if (mounted) {
      setState(() {
        _autoSyncWifi = autoSyncWifi;
        _autoSyncAny = autoSyncAny;
      });
    }
  }

  /// Returns the current app version from pubspec.yaml.
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('Failed to get app version: $e');
      return 'Unknown';
    }
  }

  // User data - will be fetched from GitHub
  Map<String, dynamic> _user = {
    'login': 'user',
    'name': 'GitHub User',
    'avatar': null,
    'email': null,
  };

  String _defaultRepo = 'user/gitdoit';
  String _defaultProject = 'Mobile Development';
  List<Map<String, dynamic>> _projects = [];
  bool _isLoadingProjects = false;
  List<RepoItem> _userRepos = [];

  Future<void> _loadDefaultRepo() async {
    final savedRepo = await _localStorage.getDefaultRepo();
    if (savedRepo != null && mounted) {
      setState(() {
        _defaultRepo = savedRepo;
      });
    }
  }

  Future<void> _loadDefaultProject() async {
    final savedProject = await _localStorage.getDefaultProject();
    if (savedProject != null && mounted) {
      setState(() {
        _defaultProject = savedProject;
      });
    }
  }

  Future<void> _loadProjects() async {
    if (_isLoadingProjects) return;
    
    setState(() => _isLoadingProjects = true);
    
    try {
      final projects = await _githubApi.fetchProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          _isLoadingProjects = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading projects: $e');
      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isLoadingProjects = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);

    // First try to load from local storage
    final localUser = await _localStorage.getUserData();
    if (localUser != null && mounted) {
      setState(() {
        _user = localUser;
        _isLoadingUser = false;
      });
    }

    // Then try to fetch fresh data from GitHub
    await _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;

    setState(() => _isLoadingUser = true);

    try {
      final userData = await _githubApi.getCurrentUser();
      if (userData != null && mounted) {
        final userMap = {
          'login': userData['login'] ?? 'user',
          'name': userData['name'] ?? userData['login'] ?? 'GitHub User',
          'avatar': userData['avatar_url'],
          'email': userData['email'],
        };

        setState(() {
          _user = userMap;
          _defaultRepo = userData['public_repos'] != null
              ? '${_user['login']}/gitdoit'
              : _defaultRepo;
          _isLoadingUser = false;
        });

        // Save to local storage
        await _localStorage.saveUserData(userMap);

        // Load user repositories
        await _loadUserRepos();
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _loadUserRepos() async {
    try {
      final repos = await _githubApi.fetchMyRepositories(perPage: 50);
      if (mounted) {
        setState(() {
          _userRepos = repos;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading repos: $e');
      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: AppColors.orangePrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugScreen()),
              );
            },
            tooltip: 'Debug Diagnostics',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildUserTile(),
          _buildLogoutTile(),

          const SizedBox(height: 8),

          // Defaults Section
          _buildSectionHeader('Defaults'),
          _buildDefaultRepoTile(),
          _buildDefaultProjectTile(),

          const SizedBox(height: 8),

          // Sync Section
          _buildSectionHeader('Sync'),
          _buildAutoSyncWifiTile(),
          _buildAutoSyncAnyTile(),
          _buildSyncNowTile(),
          _buildTestConnectionTile(),

          // Pending Operations Section
          const SizedBox(height: 8),
          _buildSectionHeader('Pending Operations'),
          _buildPendingOperationsSection(),

          const SizedBox(height: 8),

          // Developer Section
          _buildSectionHeader('Developer'),
          _buildErrorLogTile(),

          const SizedBox(height: 8),

          // Danger Zone
          _buildSectionHeader('Danger Zone', isDanger: true),
          _buildClearCacheTile(),
          _buildResetTokenTile(),

          const SizedBox(height: 16),

          // App Info
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppColors.red : Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: _isLoadingUser
            ? BrailleLoader(size: 40)
            : _user['avatar'] != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _user['avatar'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration(milliseconds: 200),
                  fadeOutDuration: Duration(milliseconds: 200),
                  placeholder: (context, url) => CircleAvatar(
                    backgroundColor: AppColors.orangePrimary.withValues(
                      alpha: 0.2,
                    ),
                    child: const BrailleLoader(size: 20),
                  ),
                  errorWidget: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: AppColors.orangePrimary.withValues(
                        alpha: 0.2,
                      ),
                      child: Text(
                        (_user['login'] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(color: AppColors.orangePrimary),
                      ),
                    );
                  },
                ),
              )
            : CircleAvatar(
                backgroundColor: AppColors.orangePrimary.withValues(alpha: 0.2),
                child: Text(
                  (_user['login'] as String).substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.orangePrimary),
                ),
              ),
        title: Text(
          _user['name'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: _isLoadingUser
            ? const Text(
                'Loading...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              )
            : Text(
                '@${_user['login']}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
        trailing: _isLoadingUser
            ? null
            : const Icon(Icons.verified_user, color: AppColors.blue, size: 24),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.orangePrimary),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: _confirmLogout,
      ),
    );
  }

  Widget _buildDefaultRepoTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.folder, color: AppColors.orangePrimary),
        title: const Text(
          'Default Repository',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _defaultRepo,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: _changeDefaultRepo,
      ),
    );
  }

  Widget _buildDefaultProjectTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.view_kanban, color: AppColors.blue),
        title: const Text(
          'Default Project',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _defaultProject,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: _changeDefaultProject,
      ),
    );
  }

  Widget _buildAutoSyncWifiTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SwitchListTile(
        secondary: const Icon(Icons.wifi, color: AppColors.orangePrimary),
        title: const Text(
          'Auto-sync on WiFi',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Automatically sync when on WiFi',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        value: _autoSyncWifi,
        activeThumbColor: AppColors.orangePrimary,
        onChanged: (value) async {
          setState(() {
            _autoSyncWifi = value;
            if (value) _autoSyncAny = false;
          });
          // PERFORMANCE: Persist auto-sync settings (Task 16.3)
          await _localStorage.saveAutoSyncWifi(value);
        },
      ),
    );
  }

  Widget _buildAutoSyncAnyTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SwitchListTile(
        secondary: const Icon(
          Icons.network_cell,
          color: AppColors.orangePrimary,
        ),
        title: const Text(
          'Auto-sync on any network',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Use mobile data for sync (may incur charges)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        value: _autoSyncAny,
        activeThumbColor: AppColors.orangePrimary,
        onChanged: (value) async {
          setState(() {
            _autoSyncAny = value;
            if (value) _autoSyncWifi = false;
          });
          // PERFORMANCE: Persist auto-sync settings (Task 16.3)
          await _localStorage.saveAutoSyncAny(value);
        },
      ),
    );
  }

  Widget _buildSyncNowTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.sync, color: AppColors.orangePrimary),
        title: const Text('Sync Now', style: TextStyle(color: Colors.white)),
        subtitle: Text(
          'Manually trigger sync',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: _syncNow,
      ),
    );
  }

  Widget _buildTestConnectionTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.wifi, color: AppColors.blue),
        title: const Text(
          'Test Connection',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Verify token and network',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: _testConnection,
      ),
    );
  }

  Widget _buildErrorLogTile() {
    return FutureBuilder<int>(
      future: ErrorLoggingService.instance.getErrorCount(),
      builder: (context, snapshot) {
        final errorCount = snapshot.data ?? 0;
        return Card(
          color: AppColors.cardBackground,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListTile(
            leading: Icon(
              Icons.bug_report,
              color: errorCount > 0 ? AppColors.red : AppColors.orangePrimary,
            ),
            title: const Text(
              'View Error Log',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              errorCount > 0
                  ? '$errorCount error${errorCount != 1 ? 's' : ''} logged'
                  : 'No errors logged',
              style: TextStyle(
                color: errorCount > 0
                    ? AppColors.red.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$errorCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                if (errorCount > 0) const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.red),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ErrorLogScreen()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingOperationsSection() {
    final pendingOps = PendingOperationsService();
    final pendingCount = pendingOps.getPendingCount();
    
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Operations',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.orangePrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangePrimary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            PendingOperationsList(
              pendingOps: pendingOps,
              onRefresh: () {
                setState(() {});
              },
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SyncStatusDashboardScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orangePrimary,
                  side: BorderSide(color: AppColors.orangePrimary),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text('View Full Sync Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrailleLoader(size: 24),
            const SizedBox(height: 16),
            const Text(
              'Testing connection...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      // Test 1: Check token
      debugPrint('=== Connection Test ===');
      final hasToken = await _githubApi.testTokenSaved();
      debugPrint('Token check: ${hasToken ? "FOUND" : "NOT FOUND"}');

      if (!hasToken) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          _showTestResult(
            false,
            'No token found. Please login with GitHub token.',
          );
        }
        return;
      }

      // Test 2: Check network
      debugPrint('Testing network...');
      try {
        final result = await InternetAddress.lookup('api.github.com');
        debugPrint('Network check: ${result.isNotEmpty ? "OK" : "FAILED"}');
      } on SocketException catch (e) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          _showTestResult(
            false,
            'No internet connection.\n\nDetails: ${e.message}',
          );
        }
        return;
      }

      // Test 3: Try to fetch user info
      debugPrint('Testing GitHub API...');
      final user = await _githubApi.getCurrentUser();

      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (user != null) {
          _showTestResult(
            true,
            '✓ Connected to GitHub!\n\nUser: ${user['login']}\nToken is valid and working.',
          );
        } else {
          _showTestResult(
            false,
            'Failed to connect to GitHub.\n\nToken may be invalid or expired.',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Connection test error: $e');
      if (mounted) Navigator.pop(context);
      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        _showTestResult(false, 'Error: ${e.toString()}');
      }
    }
  }

  void _showTestResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : AppColors.red,
            ),
            const SizedBox(width: 8),
            Text(
              success ? 'Success' : 'Failed',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildClearCacheTile() {
    return Card(
      color: AppColors.cardBackground.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: AppColors.red),
        title: const Text(
          'Clear Local Cache',
          style: TextStyle(color: AppColors.red),
        ),
        subtitle: Text(
          'Delete all locally stored data',
          style: TextStyle(
            color: AppColors.red.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: _confirmClearCache,
      ),
    );
  }

  Widget _buildResetTokenTile() {
    return Card(
      color: AppColors.cardBackground.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.key_off, color: AppColors.red),
        title: const Text(
          'Reset Token',
          style: TextStyle(color: AppColors.red),
        ),
        subtitle: Text(
          'Clear saved GitHub token (use if token is corrupted)',
          style: TextStyle(
            color: AppColors.red.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.red),
        onTap: _confirmResetToken,
      ),
    );
  }

  void _confirmResetToken() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Reset Token', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will delete your saved GitHub token and return you to the login screen.\n\nUse this if your token is corrupted or not working.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToken();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToken() async {
    // Delete token using singleton
    await SecureStorageService.deleteToken();
    await SecureStorageService.instance.delete(key: 'auth_type');

    // Clear GitHub API cache
    _githubApi.clearCachedToken();

    if (mounted) {
      // Navigate back to onboarding
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token reset. Please login again.'),
          backgroundColor: AppColors.orangePrimary,
        ),
      );
    }
  }

  Widget _buildAppInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 48,
            color: AppColors.orangePrimary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'GitDoIt',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version $_appVersion',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Minimalist GitHub Issues & Projects TODO Manager',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to logout? You will need to authenticate again.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // Clear secure storage (token) using singleton
    await SecureStorageService.deleteToken();
    await SecureStorageService.instance.delete(key: 'auth_type');

    // Clear GitHub API cache
    _githubApi.clearCachedToken();

    // Clear all local data
    await _localStorage.clearAllData();

    if (mounted) {
      // Navigate back to onboarding and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false, // Remove all previous routes
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppColors.orangePrimary,
        ),
      );
    }
  }

  /// Shows repository picker dialog with search functionality.
  ///
  /// FIX (Task 20.6): Improved default repo selection dialog.
  /// - Adds search functionality for large repo lists
  /// - Shows current selection highlighted
  /// - Includes debug logging for troubleshooting
  /// - Persists selection to LocalStorageService
  void _changeDefaultRepo() {
    final searchController = TextEditingController();
    String searchQuery = '';

    // FIX (Task 20.7): Ensure repos are loaded before showing dialog
    if (_userRepos.isEmpty) {
      _loadUserRepos().then((_) {
        if (mounted) {
          _showRepoPickerDialog(searchController, searchQuery);
        }
      });
    } else {
      _showRepoPickerDialog(searchController, searchQuery);
    }
  }

  /// Shows the repository picker dialog with search.
  void _showRepoPickerDialog(TextEditingController searchController, String searchQuery) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Select Default Repository',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field for large datasets
              TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search repositories...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.orangePrimary,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() => searchQuery = value.toLowerCase());
                },
              ),
              const SizedBox(height: 16),
              // Repo list with filtering
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SizedBox(
                  width: double.maxFinite,
                  child: _userRepos.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No repositories available',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _userRepos
                            .where(
                              (repo) =>
                                  searchQuery.isEmpty ||
                                  repo.fullName.toLowerCase().contains(
                                    searchQuery,
                                  ),
                            )
                            .length,
                        itemBuilder: (context, index) {
                          final filteredRepos = _userRepos
                              .where(
                                (repo) =>
                                    searchQuery.isEmpty ||
                                    repo.fullName.toLowerCase().contains(
                                      searchQuery,
                                    ),
                              )
                              .toList();
                          final repo = filteredRepos[index];
                          final isSelected = _defaultRepo == repo.fullName;
                          return ListTile(
                            leading: const Icon(
                              Icons.folder,
                              color: AppColors.orangePrimary,
                            ),
                            title: Text(
                              repo.fullName,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.orangePrimary
                                    : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: AppColors.orangePrimary.withValues(
                              alpha: 0.2,
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.orangePrimary,
                                  )
                                : null,
                            onTap: () {
                              debugPrint(
                                '[Settings] Default repo selected: ${repo.fullName}',
                              );
                              setState(() {
                                _defaultRepo = repo.fullName;
                              });
                              _localStorage.saveDefaultRepo(repo.fullName);
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Default: ${repo.fullName}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.orangePrimary,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                searchController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows project picker dialog with user's GitHub projects.
  ///
  /// FIX (Task 20.6): Improved default project selection dialog.
  /// - Adds search functionality for large project lists
  /// - Shows current selection highlighted
  /// - Filters out closed projects by default
  /// - Includes debug logging for troubleshooting
  /// - Persists selection to LocalStorageService
  Future<void> _changeDefaultProject() async {
    // Load projects first
    await _loadProjects();

    if (!mounted) return;

    final searchController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Select Default Project',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field for large datasets
              TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.blue,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() => searchQuery = value.toLowerCase());
                },
              ),
              const SizedBox(height: 16),
              // Project list with filtering
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SizedBox(
                  width: double.maxFinite,
                  child: _isLoadingProjects
                    ? const Center(child: BrailleLoader(size: 24))
                    : _projects.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No projects available',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _projects
                                .where(
                                  (project) =>
                                      // Filter: show open projects or matching search
                                      !(project['closed'] as bool? ?? false) &&
                                      (searchQuery.isEmpty ||
                                          (project['title'] as String? ?? '')
                                              .toLowerCase()
                                              .contains(searchQuery)),
                                )
                                .length,
                            itemBuilder: (context, index) {
                              final filteredProjects = _projects
                                  .where(
                                    (project) =>
                                        !(project['closed'] as bool? ?? false) &&
                                        (searchQuery.isEmpty ||
                                            (project['title'] as String? ?? '')
                                                .toLowerCase()
                                                .contains(searchQuery)),
                                  )
                                  .toList();
                              final project = filteredProjects[index];
                              final title = project['title'] as String? ?? '';
                              final isSelected = _defaultProject == title;

                              return ListTile(
                                leading: const Icon(
                                  Icons.view_kanban,
                                  color: AppColors.blue,
                                ),
                                title: Text(
                                  title,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.blue
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                selectedTileColor: AppColors.blue.withValues(
                                  alpha: 0.2,
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  debugPrint(
                                    '[Settings] Default project selected: $title',
                                  );
                                  setState(() {
                                    _defaultProject = title;
                                  });
                                  _localStorage.saveDefaultProject(title);
                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Default: $title',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.blue,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                searchController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _syncNow() {
    // TODO: Trigger sync
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing...'),
        backgroundColor: AppColors.orangePrimary,
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will delete all locally stored data. This action cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearCache() async {
    await CacheService().clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared'),
          backgroundColor: AppColors.orangePrimary,
        ),
      );
    }
  }
}
