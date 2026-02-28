import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/repo_item.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/braille_loader.dart';
import 'onboarding_screen.dart';
import 'debug_screen.dart';

/// SettingsScreen - App settings and account management
/// Implements brief section 7, screen 7
class SettingsScreen extends ConsumerStatefulWidget {
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

  String _getAppVersion() {
    // Version is read from pubspec.yaml - update here when version changes
    return '0.5.0+40';
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
  List<RepoItem> _userRepos = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDefaultRepo();
  }

  Future<void> _loadDefaultRepo() async {
    final savedRepo = await _localStorage.getDefaultRepo();
    if (savedRepo != null && mounted) {
      setState(() {
        _defaultRepo = savedRepo;
      });
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
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) setState(() => _isLoadingUser = false);
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
    } catch (e) {
      debugPrint('Error loading repos: $e');
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
            icon: const Icon(Icons.bug_report, color: AppColors.orange),
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
                child: Image.network(
                  _user['avatar'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                      child: Text(
                        (_user['login'] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(color: AppColors.orange),
                      ),
                    );
                  },
                ),
              )
            : CircleAvatar(
                backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                child: Text(
                  (_user['login'] as String).substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.orange),
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
        leading: const Icon(Icons.logout, color: AppColors.orange),
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
        leading: const Icon(Icons.folder, color: AppColors.orange),
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
        secondary: const Icon(Icons.wifi, color: AppColors.orange),
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
        activeColor: AppColors.orange,
        onChanged: (value) {
          setState(() {
            _autoSyncWifi = value;
            if (value) _autoSyncAny = false;
          });
        },
      ),
    );
  }

  Widget _buildAutoSyncAnyTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SwitchListTile(
        secondary: const Icon(Icons.network_cell, color: AppColors.orange),
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
        activeColor: AppColors.orange,
        onChanged: (value) {
          setState(() {
            _autoSyncAny = value;
            if (value) _autoSyncWifi = false;
          });
        },
      ),
    );
  }

  Widget _buildSyncNowTile() {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.sync, color: AppColors.orange),
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
        _showTestResult(
          false,
          'No token found. Please login with GitHub token.',
        );
        return;
      }

      // Test 2: Check network
      debugPrint('Testing network...');
      try {
        final result = await InternetAddress.lookup('api.github.com');
        debugPrint('Network check: ${result.isNotEmpty ? "OK" : "FAILED"}');
      } on SocketException catch (e) {
        if (mounted) Navigator.pop(context);
        _showTestResult(
          false,
          'No internet connection.\n\nDetails: ${e.message}',
        );
        return;
      }

      // Test 3: Try to fetch user info
      debugPrint('Testing GitHub API...');
      final user = await _githubApi.getCurrentUser();

      if (mounted) Navigator.pop(context);

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
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showTestResult(false, 'Error: ${e.toString()}');
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
          backgroundColor: AppColors.orange,
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
            color: AppColors.orange.withValues(alpha: 0.5),
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
            'Version ${_getAppVersion()}',
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
          backgroundColor: AppColors.orange,
        ),
      );
    }
  }

  void _changeDefaultRepo() {
    // Show dialog with list of available repos
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Select Default Repository',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _userRepos.length,
            itemBuilder: (context, index) {
              final repo = _userRepos[index];
              final isSelected = _defaultRepo == repo.fullName;
              return ListTile(
                title: Text(
                  repo.fullName,
                  style: const TextStyle(color: Colors.white),
                ),
                selected: isSelected,
                selectedTileColor: AppColors.orange.withValues(alpha: 0.2),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.orange)
                    : null,
                onTap: () {
                  setState(() {
                    _defaultRepo = repo.fullName;
                  });
                  _localStorage.saveDefaultRepo(repo.fullName);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Default repository set to ${repo.fullName}',
                      ),
                      backgroundColor: AppColors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeDefaultProject() {
    // TODO: Show project picker
  }

  void _syncNow() {
    // TODO: Trigger sync
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing...'),
        backgroundColor: AppColors.orange,
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

  void _clearCache() {
    // TODO: Implement clear cache
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared'),
        backgroundColor: AppColors.orange,
      ),
    );
  }
}
