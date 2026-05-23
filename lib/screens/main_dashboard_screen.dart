import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../utils/auth_error_handler.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/dashboard_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/conflict_detection_service.dart';
import '../services/pending_operations_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/braille_loader.dart';
import '../widgets/dashboard_filters.dart';
import '../widgets/dashboard_empty_state.dart';
import '../widgets/repo_list.dart';
import '../widgets/sync_cloud_icon.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/conflict_resolution_dialog.dart';
import '../widgets/error_boundary.dart';
import 'create_issue_screen.dart';
import '../utils/responsive_utils.dart';
import 'issue_detail_screen.dart';
import 'project_board_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'repo_project_library_screen.dart';
import '../providers/pinned_repos_provider.dart';
import '../providers/repositories_provider.dart';
import '../providers/app_providers.dart';

/// MainDashboardScreen - Main screen with task hierarchy
/// Implements brief section 7, screen 2
class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();
  final PendingOperationsService _pendingOps = PendingOperationsService();

  // Dashboard state
  String _filterStatus = 'open';
  bool _hideUsernameInRepo = true;
  bool _isOfflineMode = false;
  bool _isFetchingRepos = true; // Start as true to show loading on first build
  bool _isFetchingProjects = false;
  String? _errorMessage;
  String? _vaultFolderName;

  // OFFLINE-FIRST (Critical Fix): Cached data loading state
  bool _isLoadingCachedData = false;
  bool _isLoadingComplete = false;
  DateTime? _cachedDataTimestamp;

  // Large dataset optimization: Track issue loading per repo
  final Map<String, bool> _repoIssueLoadingState = {};
  final Map<String, String?> _repoErrorState = {};
  static const int _maxConcurrentIssueFetches = 5;

  List<RepoItem> _repositories = [];
  String? _expandedRepoId;
  List<Map<String, dynamic>> _projects = [];
  // Cloud icon now updates via SyncService listener only (no timer)
  VoidCallback? _syncListener;
  bool _isConflictDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _syncService.init();
    await _checkOfflineMode();
    _loadHideUsernameSetting();
    _loadDefaultRepoSetting();

    // Set up callback for when internet becomes available with local issues
    _syncService.onSyncNeeded = _isOfflineMode
        ? null
        : _showSyncLocalIssuesDialog;

    // FIX (#34): Set up callback for when local issues are synced - refresh vault
    _syncService.onLocalIssuesSynced = _onLocalIssuesSynced;
    _syncService.onConflictsDetected = _onConflictsDetected;

    // Listen to sync service changes to update cloud icon
    _syncListener = () {
      if (mounted) {
        setState(() {
          // This will trigger rebuild and update cloud icon
        });
      }
    };
    _syncService.addListener(_syncListener!);

    // Check immediately if there are local issues to sync
    if (!_isOfflineMode) {
      _checkLocalIssuesToSync();
    }

    _loadData();
  }

  /// Reload pinned repos from storage (called when returning to screen)
  Future<void> _reloadPinnedRepos() async {
    ref.read(pinnedReposProvider.notifier).load();
    ref.read(mainRepoProvider.notifier).load();
  }

  Future<void> _loadHideUsernameSetting() async {
    await ref.read(dashboardProvider.notifier).loadHideUsernameSetting();
  }

  Future<void> _loadDefaultRepoSetting() async {
    final defaultRepo = await _localStorage.getDefaultRepo();
    if (mounted) {
      if (defaultRepo != null) {
        debugPrint('Default repo setting: $defaultRepo');
      }
    }
  }

  Future<void> _checkLocalIssuesToSync() async {
    // Wait for repos to load first
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && !_isOfflineMode) {
      final count = await _syncService.getLocalIssuesCount();
      if (count > 0 && _repositories.isNotEmpty) {
        _showSyncLocalIssuesDialog();
      }
    }
  }

  void _showSyncLocalIssuesDialog() {
    if (!mounted || _repositories.isEmpty || _isOfflineMode) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Row(
          children: [
            Icon(Icons.sync, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Sync Local Issues', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have offline issues that can be synced to GitHub.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a repository to sync to:',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _repositories.length,
                itemBuilder: (context, index) {
                  final repo = _repositories[index];
                  return ListTile(
                    leading: const Icon(Icons.folder, color: AppColors.primary),
                    title: Text(
                      repo.fullName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _syncLocalIssuesToRepo(repo.fullName);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncLocalIssuesToRepo(String repoFullName) async {
    final parts = repoFullName.split('/');
    if (parts.length != 2) return;

    final owner = parts[0];
    final repo = parts[1];

    final success = await _syncService.syncLocalIssuesToRepo(owner, repo);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Issues synced to $repoFullName'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Reload data to reflect changes
        await _loadLocalIssues();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Failed to sync issues'),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// FIX (#34): Callback invoked when local issues are synced to GitHub
  /// This refreshes the vault repo to remove synced issues and prevent duplication
  void _onLocalIssuesSynced() {
    debugPrint('[Dashboard] Local issues synced - refreshing vault repo');
    // Schedule the refresh for after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _loadLocalIssues();
        debugPrint('[Dashboard] Vault repo refreshed');
      }
    });
  }

  void _onConflictsDetected(List<IssueConflict> conflicts) {
    if (!mounted || conflicts.isEmpty || _isConflictDialogVisible) {
      return;
    }

    _isConflictDialogVisible = true;

    final firstConflict = conflicts.first;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ConflictResolutionDialog(
        conflict: firstConflict,
        onResolve: (choice) {
          if (Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
          if (mounted) {
            _isConflictDialogVisible = false;
          }
          late final String message;
          switch (choice) {
            case ResolutionChoice.useRemote:
              message =
                  'Using GitHub version for issue #${firstConflict.issueNumber}.';
              break;
            case ResolutionChoice.useLocal:
              message =
                  'Local preference noted. Change will sync on next retry.';
              break;
            case ResolutionChoice.merge:
              message = 'Merge preference noted. Manual review recommended.';
              break;
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
      ),
    ).then((_) {
      if (mounted) {
        _isConflictDialogVisible = false;
      }
    });
  }

  Future<void> _checkOfflineMode() async {
    try {
      final authType = await SecureStorageService.read(key: 'auth_type');
      // Use LocalStorageService for vault_folder (not SecureStorageService)
      final vaultFolder = await _localStorage.getVaultFolder();

      if (mounted) {
        setState(() {
          _isOfflineMode = authType == 'offline';
          // Extract folder name from path for display (e.g., "/storage/emulated/0/Notes" -> "Notes")
          if (vaultFolder != null) {
            final parts = vaultFolder.split('/');
            _vaultFolderName = parts.isNotEmpty ? parts.last : 'Vault';
          } else {
            _vaultFolderName = 'Vault';
          }
        });
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error checking offline mode: $e');
      if (mounted) {
        setState(() {
          _isOfflineMode = false;
          _vaultFolderName = 'Vault';
        });
      }
    }
  }

  @override
  void dispose() {
    final syncListener = _syncListener;
    if (syncListener != null) {
      _syncService.removeListener(syncListener);
    }
    _syncService.onSyncNeeded = null;
    // FIX (#34): Clean up callback
    _syncService.onLocalIssuesSynced = null;
    _syncService.onConflictsDetected = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload filters when screen becomes visible (e.g., after returning from library)
    _reloadFiltersIfNeeded();

    // Force rebuild when dependencies change (fixes UI not updating after data load)
    if (_isLoadingComplete && _repositories.isNotEmpty) {
      setState(() {
        // Trigger rebuild with loaded data
      });
    }
  }

  bool _isInitialLoad = true;

  /// Handle authentication errors (401/403)
  /// Triggers logout flow and navigates to onboarding
  Future<void> _handleAuthError(Object error) async {
    if (!AuthErrorHandler.isAuthError(error)) {
      return; // Not an auth error
    }

    debugPrint('MainDashboardScreen: Auth error detected - $error');

    if (!mounted) return;

    final message = AuthErrorHandler.getAuthErrorMessage(error);

    // Show auth error dialog and trigger logout
    await AuthErrorHandler.handle(context, message, forceLogout: false);
  }

  Future<void> _reloadFiltersIfNeeded() async {
    // Only reload after initial load is complete
    if (!_isInitialLoad) {
      await _loadSavedFilters();
      await _reloadPinnedRepos(); // ✅ Reload pinned repos when returning from library
    }
  }

  Future<void> _loadData() async {
    // STEP 1: Load cached data IMMEDIATELY (OFFLINE-FIRST)
    await _loadCachedData();

    // STEP 2: Mark loading complete, show UI with cached data
    if (mounted) {
      setState(() {
        _isLoadingComplete = true;
      });
    }

    // STEP 3: Refresh in background (non-blocking)
    _refreshDataInBackground();

    // Load saved filters
    await _loadSavedFilters();
    _isInitialLoad = false;

    // Load pinned repos AFTER cached data is loaded
    await _reloadPinnedRepos();

    // Show pending operations count
    final pendingCount = _pendingOps.getPendingCount();
    if (pendingCount > 0 && mounted && !_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$pendingCount changes pending sync'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Load cached data from local storage (OFFLINE-FIRST - Critical Fix)
  Future<void> _loadCachedData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCachedData = true;
    });

    try {
      debugPrint('[Dashboard] Loading cached data...');

      // Load cached repos with issues
      final cachedRepos = await _localStorage.getRepos();
      if (cachedRepos.isNotEmpty) {
        final repos = cachedRepos.map((r) => RepoItem.fromJson(r)).toList();

        // Load cached issues for each repo
        for (final repo in repos) {
          try {
            final issues = await _localStorage.getSyncedIssues(repo.fullName);
            repo.children = issues;
          } catch (e) {
            debugPrint('Error loading issues for ${repo.fullName}: $e');
          }
        }

        // Load cached projects
        final cachedProjects = await _localStorage.getSyncedProjects();

        if (mounted) {
          setState(() {
            _repositories = repos;
            _projects = cachedProjects;
            _isFetchingRepos = false; // Stop showing loading
          });

          _cachedDataTimestamp = await _localStorage.getReposSyncTime();

          debugPrint(
            '[Dashboard] ✓ Loaded cached data: '
            '${repos.length} repos, ${cachedProjects.length} projects',
          );
        }
      }

      // Load local issues (vault) - this will add vault repo if needed
      await _loadLocalIssues();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, showSnackBar: false);
      debugPrint('[Dashboard] ✗ Error loading cached data: $e');

      // Check for authentication errors
      await _handleAuthError(e);
    }

    if (mounted) {
      setState(() {
        _isLoadingCachedData = false;
        _isLoadingComplete = true; // Mark as complete after loading cached data
      });
    }

    // FIX (Offline): ALWAYS update Riverpod provider, even if only vault repo exists
    if (mounted) {
      ref.read(repositoriesProvider.notifier).setRepos(_repositories);
      debugPrint(
        '[Dashboard] Updated Riverpod with ${_repositories.length} repos',
      );
      // Force rebuild after updating Riverpod
      setState(() {
        // Trigger rebuild to show loaded repos
      });
    }
  }

  /// Refresh data in background (non-blocking)
  Future<void> _refreshDataInBackground() async {
    // Check if we should refresh (data is stale or no data)
    final shouldRefresh = _shouldRefreshData();

    if (!shouldRefresh) {
      debugPrint(
        '[Dashboard] Cached data is fresh, skipping background refresh',
      );
      return;
    }

    debugPrint('[Dashboard] Starting background refresh...');

    // Refresh in background (non-blocking)
    Future.delayed(Duration.zero, () async {
      await _fetchRepositories();
      await _fetchProjects();
    });
  }

  /// Check if data should be refreshed
  bool _shouldRefreshData() {
    // Always refresh if no cached data
    if (_repositories.isEmpty) {
      debugPrint('[Dashboard] No cached data, should refresh');
      return true;
    }

    // Don't refresh in offline mode
    if (_isOfflineMode) {
      debugPrint('[Dashboard] Offline mode, skipping refresh');
      return false;
    }

    // Refresh if data is stale (>5 minutes old)
    if (_cachedDataTimestamp == null) {
      debugPrint('[Dashboard] No timestamp, should refresh');
      return true;
    }

    final age = DateTime.now().difference(_cachedDataTimestamp!);
    final shouldRefresh = age.inMinutes > 5;
    debugPrint(
      '[Dashboard] Data age: ${age.inMinutes}m, should refresh: $shouldRefresh',
    );
    return shouldRefresh;
  }

  /// Load saved filters from local storage with improved error handling.
  ///
  /// FIX (Task 20.3): Ensures filter state persists correctly across navigation.
  /// - Properly handles filter status and pinned repos
  /// - Adds debug logging for troubleshooting
  /// - Gracefully handles corrupted filter data
  Future<void> _loadSavedFilters() async {
    try {
      debugPrint('[Dashboard] Loading saved filters...');
      final filters = await _dashboardService.loadSavedFilters();
      if (mounted) {
        setState(() {
          _filterStatus = filters['filterStatus'] ?? 'open';
          // Update Riverpod provider
          ref.read(pinnedReposProvider.notifier).load();
        });
        debugPrint('[Dashboard] ✓ Loaded filters: status=$_filterStatus');
      }
    } catch (e, stackTrace) {
      debugPrint('[Dashboard] ✗ Error loading filters: $e');
      AppErrorHandler.handle(e, stackTrace: stackTrace, showSnackBar: false);
      // Set defaults on error
      if (mounted) {
        setState(() {
          _filterStatus = 'open';
        });
      }
    }
  }

  Future<void> _autoPinDefaultRepo() async {
    // If no pinned repos, auto-pin the default repo from settings OR first available repo
    final pinned = ref.read(pinnedReposProvider);
    if (pinned.isEmpty && _repositories.isNotEmpty) {
      // First, try to find the default repo from settings
      final defaultRepoName = await _localStorage.getDefaultRepo();
      if (defaultRepoName != null && mounted) {
        // Find repo by fullName and pin using Riverpod
        for (final repo in _repositories) {
          if (repo.fullName == defaultRepoName) {
            await ref.read(pinnedReposProvider.notifier).pin(repo.fullName);
            debugPrint('Auto-pinned default repo: $defaultRepoName');
            return;
          }
        }
      }
      // If no default repo set or not found, auto-pin the first available repo
      // This ensures the main dashboard shows something on first launch
      final firstRepo = _repositories.firstWhere(
        (r) => r.id != 'vault',
        orElse: () => _repositories.first,
      );
      if (mounted) {
        await ref.read(pinnedReposProvider.notifier).pin(firstRepo.fullName);
        debugPrint('Auto-pinned first available repo: ${firstRepo.fullName}');
      }
    }
  }

  Future<void> _loadLocalIssues() async {
    try {
      final localIssues = await _localStorage.getLocalIssues();
      final hasToken = await SecureStorageService.hasToken();
      debugPrint('Loaded ${localIssues.length} local issues');

      if (!mounted) return;
      setState(() {
        final shouldShowVault =
            localIssues.isNotEmpty || _isOfflineMode || !hasToken;
        final vaultName = _vaultFolderName ?? 'Vault';
        final openIssuesCount = localIssues
            .where((i) => i.status == ItemStatus.open)
            .length;
        final existingVaultIndex = _repositories.indexWhere(
          (r) => r.id == 'vault',
        );

        if (shouldShowVault) {
          final nextVaultRepo = RepoItem(
            id: 'vault',
            title: vaultName,
            fullName: 'local/$vaultName',
            description: 'Local vault folder (will sync when online)',
            openIssuesCount: openIssuesCount,
            children: localIssues,
          );

          if (existingVaultIndex == -1) {
            _repositories.insert(0, nextVaultRepo);
          } else {
            _repositories[existingVaultIndex] = nextVaultRepo;
            if (existingVaultIndex != 0) {
              final moved = _repositories.removeAt(existingVaultIndex);
              _repositories.insert(0, moved);
            }
          }
        } else if (existingVaultIndex != -1) {
          _repositories.removeAt(existingVaultIndex);
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(repositoriesProvider.notifier)
              .setRepos(List<RepoItem>.from(_repositories));
        }
      });
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
      debugPrint('Error loading local issues: $e');
    }
  }

  /// Fetch repositories with pagination support (Task 16.1)
  ///
  /// PERFORMANCE OPTIMIZATION:
  /// - Loads only first page initially (30 repos)
  /// - Caches each page for faster subsequent loads
  /// Fetch repositories with improved error handling and offline mode support.
  Future<void> _fetchRepositories() async {
    setState(() {
      _isFetchingRepos = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=== Fetching Repositories (Page 1) ===');

      // Check if we have a token
      final hasToken = await _dashboardService.getToken();
      debugPrint(
        'Token available: ${hasToken != null}, length: ${hasToken?.length ?? 0}',
      );

      if (hasToken == null || hasToken.isEmpty) {
        debugPrint('No token found, trying to load cached repos');
        await _loadCachedRepositories();
        return;
      }

      // Try to fetch from GitHub - let the API call determine network status
      // Don't do DNS lookup first as it can be unreliable
      try {
        debugPrint('Calling fetchMyRepositories()...');
        final repos = await _dashboardService.fetchMyRepositories();
        debugPrint('✓ Fetched ${repos.length} repositories from GitHub');

        if (!mounted) return;
        {
          final localIssues = await _localStorage.getLocalIssues();

          if (!mounted) return;
          // Update the repositories provider so the UI reflects the fetched data
          ref.read(repositoriesProvider.notifier).setRepos(repos);

          // Also update local state for vault repo handling and issue creation
          if (!mounted) return;
          setState(() {
            // Preserve vault repo if exists, but refresh its issues from local storage
            final vaultRepoIndex = _repositories.indexWhere(
              (r) => r.id == 'vault',
            );
            final existingVaultRepo = vaultRepoIndex != -1
                ? _repositories[vaultRepoIndex]
                : null;

            // Update local _repositories with fetched repos (excluding vault)
            _repositories = repos.toList();

            // Add vault repo back with updated local issues
            if (existingVaultRepo != null ||
                localIssues.isNotEmpty ||
                _isOfflineMode) {
              final vaultName = _vaultFolderName ?? 'Vault';
              final openIssuesCount = localIssues
                  .where((i) => i.status == ItemStatus.open)
                  .length;
              final vaultRepo = RepoItem(
                id: 'vault',
                title: vaultName,
                fullName: 'local/$vaultName',
                description: 'Local vault folder (will sync when online)',
                openIssuesCount:
                    openIssuesCount, // FIX (#33): Count open issues
                children: localIssues,
              );
              // Remove any existing vault repo first to prevent duplicates
              _repositories.removeWhere((r) => r.id == 'vault');
              _repositories.insert(0, vaultRepo);
            }

            _isFetchingRepos = false;
            debugPrint('✓ UI updated with ${_repositories.length} repos');
          });

          // Auto-pin default repo if no pinned repos exist
          await _autoPinDefaultRepo();

          // Fetch issues for ALL repositories in parallel
          if (_repositories.isNotEmpty) {
            debugPrint(
              'Fetching issues for all ${_repositories.length} repositories...',
            );
            await _fetchIssuesForAllRepos();
          }
        }
      } on SocketException catch (e) {
        // Network error - try to use cached data
        debugPrint('✗ Network error during fetch: $e');
        await _loadCachedRepositories();
      } catch (e) {
        // Other error during fetch - try to use cached data
        debugPrint('✗ Fetch error: $e');
        await _loadCachedRepositories();
      }
    } catch (e, stackTrace) {
      debugPrint('=== Fetch Error ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');

      // Try to load cached repos on any error
      await _loadCachedRepositories();

      // Don't show error in offline mode
      if (!_isOfflineMode && mounted) {
        setState(() {
          _errorMessage = 'Unable to load repositories. Using cached data.';
        });
      }
    }
  }

  /// Load cached repositories when network is unavailable (offline-first)
  /// FIX (Offline): Preserve existing repos if cache is empty
  Future<void> _loadCachedRepositories() async {
    debugPrint('=== Loading Cached Repositories (Offline Mode) ===');

    try {
      // Try to get cached repos from local storage (persistent storage)
      final cachedReposData = await _localStorage.getRepos();
      final localIssues = await _localStorage.getLocalIssues();

      // Convert cached repo data to RepoItem objects
      final cachedRepos = cachedReposData.map((data) {
        return RepoItem(
          id: data['id']?.toString() ?? '',
          title: data['name']?.toString() ?? '',
          fullName: data['full_name']?.toString() ?? '',
          description: data['description']?.toString() ?? '',
          openIssuesCount:
              data['openIssuesCount'] as int? ??
              0, // FIX (#33): Read from cache
        );
      }).toList();

      debugPrint(
        'Found ${cachedRepos.length} cached repos, ${localIssues.length} local issues',
      );

      if (mounted) {
        setState(() {
          _isFetchingRepos = false;

          // FIX (Offline): Only update if we have cached repos OR local issues
          // Don't clear existing repos if cache is empty
          if (cachedRepos.isNotEmpty || localIssues.isNotEmpty) {
            // Start with cached repos
            _repositories = cachedRepos.toList();

            // Add vault repo if there are local issues or in offline mode
            if (localIssues.isNotEmpty || _isOfflineMode) {
              final vaultName = _vaultFolderName ?? 'Vault';
              final openIssuesCount = localIssues
                  .where((i) => i.status == ItemStatus.open)
                  .length;
              final vaultRepo = RepoItem(
                id: 'vault',
                title: vaultName,
                fullName: 'local/$vaultName',
                description: 'Local vault folder (offline mode)',
                openIssuesCount:
                    openIssuesCount, // FIX (#33): Count open issues
                children: localIssues,
              );
              // Remove any existing vault repo first to prevent duplicates
              _repositories.removeWhere((r) => r.id == 'vault');
              _repositories.insert(0, vaultRepo);
            }

            // Update the repositories provider
            ref.read(repositoriesProvider.notifier).setRepos(_repositories);

            debugPrint(
              '✓ Loaded ${_repositories.length} repos from cache (offline)',
            );
          } else {
            debugPrint(
              '⚠️ No cached repos or local issues - keeping existing repos',
            );
          }
        });

        // Auto-pin default repo if no pinned repos exist
        if (_repositories.isNotEmpty) {
          await _autoPinDefaultRepo();
        }

        // Don't show error in offline mode - just show what we have
        if (!_isOfflineMode) {
          debugPrint('Network error - showing cached data');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached repos: $e');
      if (mounted) {
        setState(() {
          _isFetchingRepos = false;
          if (!_isOfflineMode) {
            _errorMessage =
                'Unable to load repositories. Please check your connection.';
          }
        });
      }
    }
  }

  /// Load more repositories for pagination (Task 16.1)
  ///
  /// PERFORMANCE OPTIMIZATION:
  /// - Appends new repos to existing list
  /// - Shows loading indicator while fetching
  /// - Updates hasMoreRepos flag
  /// Fetch issues for all repositories with batching for large datasets.
  ///
  /// PERFORMANCE OPTIMIZATION (Task 20.2):
  /// - Batches concurrent requests to avoid overwhelming the API
  /// - Tracks loading state per repository
  /// - Implements retry logic for failed requests
  /// - Provides detailed debug logging for troubleshooting
  Future<void> _fetchIssuesForAllRepos() async {
    if (_repositories.isEmpty) return;

    // Filter to only non-vault repos with valid fullName
    final reposToFetch = _repositories
        .where((repo) => repo.id != 'vault' && repo.fullName.contains('/'))
        .toList();

    debugPrint(
      '[Dashboard] Fetching issues for ${reposToFetch.length} repositories...',
    );

    // Batch processing for large datasets (Task 20.2)
    final batchSize = _maxConcurrentIssueFetches;
    final totalBatches = (reposToFetch.length / batchSize).ceil();

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final start = batchIndex * batchSize;
      final end = (batchIndex + 1) * batchSize;
      final batch = reposToFetch.sublist(
        start,
        end > reposToFetch.length ? reposToFetch.length : end,
      );

      debugPrint(
        '[Dashboard] Processing batch ${batchIndex + 1}/$totalBatches (${batch.length} repos)',
      );

      final futures = batch.map((repo) async {
        final repoKey = repo.fullName;

        // Mark as loading
        if (mounted) {
          setState(() {
            _repoIssueLoadingState[repoKey] = true;
            _repoErrorState[repoKey] = null;
          });
        }

        try {
          final parts = repo.fullName.split('/');
          debugPrint('[Dashboard] Fetching issues for $repoKey...');

          final issues = await _dashboardService.fetchIssues(
            parts[0],
            parts[1],
          );

          if (mounted) {
            setState(() {
              repo.children.addAll(issues);
              _repoIssueLoadingState[repoKey] = false;
            });
            debugPrint(
              '[Dashboard] ✓ Loaded ${issues.length} issues for $repoKey',
            );
          }
        } catch (e, stackTrace) {
          debugPrint('[Dashboard] ✗ Failed to fetch issues for $repoKey: $e');
          if (mounted) {
            setState(() {
              _repoIssueLoadingState[repoKey] = false;
              _repoErrorState[repoKey] = e.toString();
            });
            // Log error but don't show snackbar for each repo
            AppErrorHandler.handle(
              e,
              stackTrace: stackTrace,
              showSnackBar: false,
            );

            // Check for authentication errors
            await _handleAuthError(e);
          }
        }
      }).toList();

      // Wait for this batch to complete before starting next
      await Future.wait(futures);

      // Small delay between batches to avoid rate limiting
      if (batchIndex < totalBatches - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    final successCount =
        reposToFetch.length -
        _repoErrorState.values.where((e) => e != null).length;
    debugPrint(
      '[Dashboard] ✓ Finished fetching issues: $successCount/${reposToFetch.length} successful',
    );
  }

  /// Fetch projects and their field/column mappings
  Future<void> _fetchProjects() async {
    if (_isFetchingProjects) return;

    try {
      debugPrint('Fetching projects...');
      final projects = await _dashboardService.fetchProjects();
      debugPrint('Fetched ${projects.length} projects');

      if (mounted) {
        setState(() {
          _projects = projects;
          _isFetchingProjects = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching projects: $e');
      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() {
          _isFetchingProjects = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinnedRepos = ref.watch(pinnedReposProvider).toSet();
    // Use Riverpod repositories provider directly (always up-to-date)
    final allRepos = ref.watch(repositoriesProvider);

    // Show all repos if no pinned repos exist (first-time user experience)
    // Otherwise, show only pinned repositories on main dashboard
    List<RepoItem> displayedRepos;
    if (pinnedRepos.isEmpty) {
      displayedRepos = allRepos;
    } else {
      displayedRepos = allRepos
          .where((repo) => pinnedRepos.contains(repo.fullName))
          .toList();
      final vaultRepo = allRepos.where((repo) => repo.id == 'vault');
      for (final repo in vaultRepo) {
        if (!displayedRepos.any((existing) => existing.id == repo.id)) {
          displayedRepos.insert(0, repo);
        }
      }
    }

    // OFFLINE-FIRST: Show loading only while loading cached data
    if (_isLoadingCachedData) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrailleLoader(size: 48),
              SizedBox(height: 16.h),
              Text(
                'Loading your tasks...',
                style: TextStyle(color: Colors.white54, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'GitDoIt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          // Sync cloud icon with sync status widget
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isOfflineMode) ...[
                      // Cloud icon (static)
                      SyncCloudIcon(state: _getSyncCloudState(), size: 24.w),
                      // Sync status widget (BrailleLoader or time)
                      SizedBox(width: 4.w),
                      SyncStatusWidget(
                        isSyncing: _syncService.isSyncing,
                        lastSyncTime: _syncService.lastSyncTime,
                        size: 24.w,
                      ),
                      // Show pending count badge
                      if (_pendingOps.getPendingCount() > 0) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '${_pendingOps.getPendingCount()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Repository icon (SVG)
          IconButton(
            icon: SvgPicture.asset(
              'assets/repo.svg',
              width: 24.w,
              height: 24.w,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            onPressed: _navigateToRepoLibrary,
            tooltip: 'Repositories & Projects',
          ),
          // Project Board icon
          IconButton(
            icon: Icon(Icons.view_kanban, color: Colors.white, size: 24.w),
            onPressed: _navigateToProjectBoard,
            tooltip: 'Project Board',
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.white, size: 24.w),
            onPressed: _navigateToSearch,
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 24.w),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ConstrainedContent(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Filters
            DashboardFilters(
              filterStatus: _filterStatus,
              onFilterChanged: (status) async {
                debugPrint('[Dashboard] Filter changed: $status');
                setState(() {
                  _filterStatus = status;
                });
                // FIX (Task 20.3): Persist filter immediately with error handling
                try {
                  await _localStorage.saveFilters(filterStatus: _filterStatus);
                  debugPrint('[Dashboard] ✓ Filter persisted: $status');
                } catch (e, stackTrace) {
                  debugPrint('[Dashboard] ✗ Failed to persist filter: $e');
                  AppErrorHandler.handle(
                    e,
                    stackTrace: stackTrace,
                    showSnackBar: false,
                  );
                }
              },
              onHideUsernameToggle: (hide) {
                setState(() {
                  _hideUsernameInRepo = hide;
                });
                _localStorage.saveHideUsernameSetting(_hideUsernameInRepo);
              },
              hideUsernameInRepo: _hideUsernameInRepo,
              pendingOperationsCount: _pendingOps.getPendingCount(),
            ),

            // FIX (#32): Removed duplicate "Last updated" indicator
            // FIX (#32): Removed "Refreshing in background" indicator
            // SyncStatusWidget in AppBar already shows sync status with animation
            // Error message if any
            if (_errorMessage != null) _buildErrorMessage(),

            // Task List
            Expanded(
              child: allRepos.isEmpty && _isLoadingCachedData
                  // FIX (#32): Show single loading indicator (full-screen already shows loading)
                  // Don't show duplicate BrailleLoader in RefreshIndicator
                  ? const Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchRepositories,
                      color: AppColors.primary,
                      child: _buildTaskList(displayedRepos, pinnedRepos),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Issue'),
        onPressed: _createNewIssue,
      ),
    );
  }

  Widget _buildErrorMessage() {
    // Don't show error in offline mode
    if (_isOfflineMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: InlineError(
              message: 'Could not fetch repositories',
              details: _errorMessage!,
            ),
          ),
          TextButton(
            onPressed: _fetchRepositories,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the task list with pagination support (Task 16.1)
  ///
  /// PERFORMANCE OPTIMIZATION:
  /// - Shows "Load More" button when more repos are available
  /// - Displays loading indicator while loading more repos
  Widget _buildTaskList(
    List<RepoItem> displayedRepos,
    Set<String> pinnedRepos,
  ) {
    // Show empty state only if no repositories at all (not based on filter)
    if (displayedRepos.isEmpty && !_isFetchingRepos) {
      return const DashboardEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: RepoList(
            repositories: displayedRepos,
            githubApi: _dashboardService,
            expandedRepoId: _expandedRepoId,
            onExpandToggle: _onRepoToggle,
            onIssueTap: _openIssueDetail,
            onIssueStateChanged: _onIssueStateChanged,
            filterStatus: _filterStatus,
            hideUsernameInRepo: _hideUsernameInRepo,
            pinnedRepos: pinnedRepos,
            onPinToggle: _togglePinRepo,
          ),
        ),
      ],
    );
  }

  void _navigateToSearch() {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SearchScreen()));
  }

  void _navigateToRepoLibrary() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RepoProjectLibraryScreen()),
    );
  }

  void _navigateToSettings() {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _navigateToProjectBoard() {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProjectBoardScreen()));
  }

  /// Toggle pin status for a repository with improved error handling.
  ///
  /// FIX (Task 20.3): Ensures pin state persists correctly.
  void _togglePinRepo(String repoFullName) async {
    HapticFeedback.lightImpact();
    debugPrint('[Dashboard] Toggle pin for: $repoFullName');

    final pinned = ref.read(pinnedReposProvider);
    final notifier = ref.read(pinnedReposProvider.notifier);

    if (pinned.contains(repoFullName)) {
      await notifier.unpin(repoFullName);
      debugPrint('[Dashboard] Unpinned: $repoFullName');
    } else {
      await notifier.pin(repoFullName);
      debugPrint('[Dashboard] Pinned: $repoFullName');
    }
  }

  void _onRepoToggle(String repoId, bool isExpanded) {
    setState(() {
      if (isExpanded) {
        // Only set this repo as expanded (collapsing any others)
        _expandedRepoId = repoId;
      } else {
        // Collapsing this repo
        _expandedRepoId = null;
      }
    });
  }

  void _onIssueStateChanged(String repoFullName, IssueItem updatedIssue) {
    setState(() {
      final repoIndex = _repositories.indexWhere(
        (r) => r.fullName == repoFullName,
      );
      if (repoIndex == -1) {
        return;
      }

      final repo = _repositories[repoIndex];
      final issueIndex = repo.children.indexWhere(
        (item) => item.id == updatedIssue.id,
      );
      if (issueIndex == -1) {
        return;
      }

      final previousIssue = repo.children[issueIndex];
      repo.children[issueIndex] = updatedIssue;

      if (previousIssue is IssueItem) {
        if (previousIssue.status == ItemStatus.open &&
            updatedIssue.status == ItemStatus.closed) {
          repo.openIssuesCount = repo.openIssuesCount > 0
              ? repo.openIssuesCount - 1
              : 0;
        } else if (previousIssue.status == ItemStatus.closed &&
            updatedIssue.status == ItemStatus.open) {
          repo.openIssuesCount = repo.openIssuesCount + 1;
        }
      }
    });

    ref
        .read(repositoriesProvider.notifier)
        .setRepos(List<RepoItem>.from(_repositories));
  }

  /// Get sync cloud state based on sync service status
  SyncCloudState _getSyncCloudState() {
    return _dashboardService.getSyncCloudState(isOfflineMode: _isOfflineMode);
  }

  void _createNewIssue() async {
    debugPrint(
      '[Dashboard] Create New Issue pressed - repos: ${_repositories.length}, isLoadingComplete: $_isLoadingComplete',
    );

    // Trigger haptic feedback
    HapticFeedback.selectionClick();

    // Use Riverpod state directly for more reliable check
    final allRepos = ref.read(repositoriesProvider);

    final hasToken = await SecureStorageService.hasToken();
    if (!hasToken) {
      await _createLocalIssue(repoFullName: null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are not connected to GitHub. Creating local TODO issue.',
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (allRepos.isEmpty && !_isLoadingComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              BrailleLoader(size: 16),
              const SizedBox(width: 12),
              const Text('Loading repositories...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // In offline mode, check if Local Issues repo exists
    if (allRepos.isEmpty && !_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'No repositories available. Please fetch repositories first.',
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'FETCH',
            textColor: Colors.white,
            onPressed: _fetchRepositories,
          ),
        ),
      );
      return;
    }

    // In offline mode with no repos, create issue in Vault repo
    if (allRepos.isEmpty && _isOfflineMode) {
      await _createLocalIssue(repoFullName: null);
      return;
    }

    // Check if Vault repo exists for offline mode
    final hasVaultRepo = allRepos.any((r) => r.id == 'vault');
    if (_isOfflineMode && !hasVaultRepo) {
      await _createLocalIssue(repoFullName: null);
      return;
    }

    // Priority 1: Use currently expanded repo if one is open
    String? selectedRepo;
    if (_expandedRepoId != null) {
      // Find the expanded repo (skip vault)
      try {
        final expandedRepo = allRepos.firstWhere(
          (r) => r.id == _expandedRepoId && r.id != 'vault',
        );
        selectedRepo = expandedRepo.fullName;
        debugPrint('Creating issue in expanded repo: $selectedRepo');
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        // Expanded repo not found or is vault, will use default
        debugPrint('Expanded repo not available, will use default');
      }
    }

    // Priority 2: Use default repo from settings if no repo is expanded
    if (selectedRepo == null) {
      final defaultRepoName = await _localStorage.getDefaultRepo();
      if (defaultRepoName != null &&
          allRepos.any(
            (r) => r.fullName == defaultRepoName && r.id != 'vault',
          )) {
        selectedRepo = defaultRepoName;
        debugPrint('Creating issue in default repo: $selectedRepo');
      }
    }

    // Priority 3: Use first available repo (skip vault)
    if (selectedRepo == null) {
      try {
        selectedRepo = allRepos.firstWhere((r) => r.id != 'vault').fullName;
        debugPrint('Creating issue in first available repo: $selectedRepo');
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid repository found'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Get owner and repo parts
    final parts = selectedRepo.split('/');
    final owner = parts.isNotEmpty ? parts[0] : null;
    final repo = parts.length > 1 ? parts[1] : null;

    if (owner == null || repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid repository found'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to full-screen create issue screen
    if (mounted) {
      // Filter out vault repo from available repos for selection
      final availableRepos = allRepos.where((r) => r.id != 'vault').toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateIssueScreen(
            owner: owner,
            repo: repo,
            expandedRepoFullName: selectedRepo, // ISSUE #22: Visual indicator
            defaultProject: _projects.isNotEmpty
                ? _projects.first['title'] as String?
                : null,
            projects: _projects,
            availableRepos: availableRepos,
          ),
        ),
      ).then((result) {
        if (!mounted || result == null) {
          return;
        }

        IssueItem? createdIssue;
        String? successMessage;

        if (result is CreateIssueResult) {
          createdIssue = result.issue;
          successMessage = result.successMessage;
        } else if (result is IssueItem) {
          createdIssue = result;
        }

        if (successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }

        if (createdIssue != null) {
          _loadData();
        }
      });
    }
  }

  Future<void> _createLocalIssue({String? repoFullName}) async {
    _LocalIssueDraft? draft;
    try {
      draft = await showDialog<_LocalIssueDraft>(
        context: context,
        builder: (dialogContext) => _LocalIssueDialog(
          repoFullName: repoFullName,
          onCreated: (draft) => Navigator.of(dialogContext).pop(draft),
        ),
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        context: context,
        userMessage: 'Unable to open local issue form.',
      );
      return;
    }

    if (draft == null || !mounted) {
      return;
    }

    final newIssue = _localStorage.createStructuredLocalIssue(
      title: draft.title,
      bodyMarkdown: draft.body,
    );

    bool saved = false;
    try {
      saved = await _localStorage.saveLocalIssue(newIssue);
      await _loadLocalIssues();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        context: context,
        userMessage: 'Issue creation failed in offline mode.',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                saved
                    ? (repoFullName != null
                          ? 'Issue saved (will sync when online)'
                          : 'Local issue created')
                    : 'Unable to save local issue',
              ),
            ],
          ),
          backgroundColor: saved ? AppColors.primary : AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openIssueDetail(IssueItem issue) {
    // Trigger haptic feedback
    HapticFeedback.selectionClick();

    // Extract owner/repo from the repository that contains this issue
    String? owner;
    String? repo;

    for (final r in _repositories) {
      if (r.children.any((i) => i.id == issue.id)) {
        final parts = r.fullName.split('/');
        if (parts.length == 2) {
          owner = parts[0];
          repo = parts[1];
          break;
        }
      }
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                IssueDetailScreen(issue: issue, owner: owner, repo: repo),
          ),
        )
        .then((_) {
          if (mounted) {
            _loadData();
          }
        });
  }
}

class _LocalIssueDraft {
  final String title;
  final String? body;

  const _LocalIssueDraft({required this.title, this.body});
}

class _LocalIssueDialog extends StatefulWidget {
  final String? repoFullName;
  final ValueChanged<_LocalIssueDraft> onCreated;

  const _LocalIssueDialog({
    required this.repoFullName,
    required this.onCreated,
  });

  @override
  State<_LocalIssueDialog> createState() => _LocalIssueDialogState();
}

class _LocalIssueDialogState extends State<_LocalIssueDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    widget.onCreated(
      _LocalIssueDraft(
        title: trimmedTitle,
        body: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        widget.repoFullName != null
            ? 'Create Issue (Offline)'
            : 'Create Local Issue',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.repoFullName != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Repository: ${widget.repoFullName}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'This issue will be saved locally and synced when online',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title *',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0x4DFFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description (Markdown)',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0x4DFFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
