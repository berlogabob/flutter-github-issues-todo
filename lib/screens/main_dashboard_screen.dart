import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/dashboard_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/pending_operations_service.dart';
import '../services/secure_storage_service.dart';
import '../services/cache_service.dart';
import '../widgets/braille_loader.dart';
import '../widgets/loading_skeleton.dart'; // PERFORMANCE: Loading skeletons (Task 16.5)
import '../widgets/dashboard_filters.dart';
import '../widgets/dashboard_empty_state.dart';
import '../widgets/repo_list.dart';
import '../widgets/sync_cloud_icon.dart';
import '../widgets/sync_status_widget.dart';
import 'create_issue_screen.dart';
import '../utils/responsive_utils.dart';
import 'issue_detail_screen.dart';
import 'project_board_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'repo_project_library_screen.dart';

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
  final CacheService _cache = CacheService();

  // Dashboard state
  String _filterStatus = 'open';
  bool _hideUsernameInRepo = true;
  bool _isOfflineMode = false;
  bool _isFetchingRepos = false;
  bool _isFetchingProjects = false;
  String? _errorMessage;
  String? _vaultFolderName;

  // Large dataset optimization: Track issue loading per repo
  final Map<String, bool> _repoIssueLoadingState = {};
  final Map<String, String?> _repoErrorState = {};
  static const int _maxConcurrentIssueFetches = 5;

  List<RepoItem> _repositories = [];
  Set<String> _pinnedRepos = {};
  String? _expandedRepoId;
  List<Map<String, dynamic>> _projects = [];
  // Cloud icon now updates via SyncService listener only (no timer)
  late VoidCallback _syncListener;

  @override
  void initState() {
    super.initState();
    _syncService.init();
    _checkOfflineMode();
    _loadHideUsernameSetting();
    _loadDefaultRepoSetting();

    // Set up callback for when internet becomes available with local issues
    _syncService.onSyncNeeded = _showSyncLocalIssuesDialog;

    // Listen to sync service changes to update cloud icon
    _syncListener = () {
      if (mounted) {
        setState(() {
          // This will trigger rebuild and update cloud icon
        });
      }
    };
    _syncService.addListener(_syncListener);

    // Check immediately if there are local issues to sync
    _checkLocalIssuesToSync();

    _loadData();
    
    // Reload pinned repos when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadPinnedRepos();
    });
  }

  /// Reload pinned repos from storage (called when returning to screen)
  Future<void> _reloadPinnedRepos() async {
    final filters = await _localStorage.getFilters();
    if (mounted) {
      final pinnedList = filters['pinnedRepos'] as List? ?? [];
      final newPinnedRepos = pinnedList.map((e) => e.toString()).toSet();
      
      // Only update if changed
      if (!_setEquals(_pinnedRepos, newPinnedRepos)) {
        setState(() {
          _pinnedRepos = newPinnedRepos;
        });
        debugPrint('[Dashboard] ✓ Reloaded pinned repos: ${_pinnedRepos.length}');
      }
    }
  }

  /// Check if two sets are equal
  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.every((e) => b.contains(e));
  }

  Future<void> _loadHideUsernameSetting() async {
    final hide = await _localStorage.getHideUsernameSetting();
    if (mounted) {
      setState(() {
        _hideUsernameInRepo = hide;
      });
    }
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
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.sync, color: AppColors.orangePrimary),
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
                    leading: const Icon(
                      Icons.folder,
                      color: AppColors.orangePrimary,
                    ),
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
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkOfflineMode() async {
    final authType = await SecureStorageService.instance.read(key: 'auth_type');
    final vaultFolder = await SecureStorageService.instance.read(
      key: 'vault_folder',
    );

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
  }

  @override
  void dispose() {
    _syncService.removeListener(_syncListener);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload filters when screen becomes visible (e.g., after returning from library)
    _reloadFiltersIfNeeded();
  }

  bool _isInitialLoad = true;
  Future<void> _reloadFiltersIfNeeded() async {
    // Only reload after initial load is complete
    if (!_isInitialLoad) {
      await _loadSavedFilters();
      await _reloadPinnedRepos(); // ✅ Reload pinned repos when returning from library
    }
  }

  Future<void> _loadData() async {
    // Load saved filters
    await _loadSavedFilters();
    _isInitialLoad = false;

    // Load local issues
    await _loadLocalIssues();

    // Then try to fetch from GitHub
    await _fetchRepositories();

    // Fetch projects for issue creation
    await _fetchProjects();

    // Show pending operations count
    final pendingCount = _pendingOps.getPendingCount();
    if (pendingCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$pendingCount changes pending sync'),
          backgroundColor: AppColors.orangePrimary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
          // Convert List to Set properly
          final pinnedList = filters['pinnedRepos'] as List? ?? [];
          _pinnedRepos = pinnedList.map((e) => e.toString()).toSet();
        });
        debugPrint(
          '[Dashboard] ✓ Loaded filters: status=$_filterStatus, pinned=${_pinnedRepos.length} repos',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[Dashboard] ✗ Error loading filters: $e');
      AppErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        showSnackBar: false,
      );
      // Set defaults on error
      if (mounted) {
        setState(() {
          _filterStatus = 'open';
          _pinnedRepos = {};
        });
      }
    }
  }

  Future<void> _autoPinDefaultRepo() async {
    // If no pinned repos, auto-pin the default repo from settings
    if (_pinnedRepos.isEmpty) {
      final defaultRepoName = await _localStorage.getDefaultRepo();
      if (defaultRepoName != null && mounted) {
        // Find repo by fullName and pin using fullName
        for (final repo in _repositories) {
          if (repo.fullName == defaultRepoName) {
            setState(() {
              _pinnedRepos.add(repo.fullName);
            });
            await _localStorage.saveFilters(
              filterStatus: _filterStatus,
              pinnedRepos: _pinnedRepos.toList(),
            );
            debugPrint('Auto-pinned default repo: $defaultRepoName');
            break;
          }
        }
      }
    }
  }

  Future<void> _loadLocalIssues() async {
    try {
      final localIssues = await _localStorage.getLocalIssues();
      debugPrint('Loaded ${localIssues.length} local issues');

      if (mounted) {
        setState(() {
          // CRITICAL: Remove any existing vault repo FIRST to prevent duplicates
          _repositories.removeWhere((r) => r.id == 'vault');

          // Add vault repo only if local issues exist OR offline mode
          if (localIssues.isNotEmpty || _isOfflineMode) {
            final vaultName = _vaultFolderName ?? 'Vault';
            final vaultRepo = RepoItem(
              id: 'vault',
              title: vaultName,
              fullName: 'local/$vaultName',
              description: 'Local vault folder (will sync when online)',
              children: localIssues,
            );
            _repositories.insert(0, vaultRepo);
          }
        });
      }
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
      // Clear cache on manual refresh
      await _cache.clear();

      debugPrint('=== Fetching Repositories (Page 1) ===');

      // Check network connectivity first
      debugPrint('Checking network connectivity...');
      try {
        final result = await InternetAddress.lookup('api.github.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint('✓ Network OK - api.github.com reachable');
        } else {
          throw Exception('DNS lookup returned empty result');
        }
      } on SocketException catch (e) {
        debugPrint('✗ Network check failed: $e');
        throw Exception(
          'No internet connection. Please check your network settings.\n\nCannot reach api.github.com\n\nDetails: ${e.message}',
        );
      } catch (e, stackTrace) {
        debugPrint('✗ Network check error: $e');
        if (mounted) {
          AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        }
        throw Exception('Network error: $e');
      }

      // Check if we have a token
      final hasToken = await _dashboardService.getToken();
      debugPrint(
        'Token available: ${hasToken != null}, length: ${hasToken?.length ?? 0}',
      );

      if (hasToken == null || hasToken.isEmpty) {
        debugPrint('No token found, showing demo data');
        throw Exception('Not authenticated. Please login with a GitHub token.');
      }

      debugPrint('Calling fetchMyRepositories()...');
      final repos = await _dashboardService.fetchMyRepositories();
      debugPrint('✓ Fetched ${repos.length} repositories from GitHub');

      if (!mounted) return;
      {
        // Preserve vault repo if exists, but refresh its issues from local storage
        final vaultRepoIndex = _repositories.indexWhere((r) => r.id == 'vault');
        final existingVaultRepo = vaultRepoIndex != -1
            ? _repositories[vaultRepoIndex]
            : null;

        // Always reload local issues
        final localIssues = await _localStorage.getLocalIssues();

        if (!mounted) return;
        setState(() {
          _repositories = repos; // Don't filter, show all repos

          // Add vault repo back with updated local issues
          if (existingVaultRepo != null ||
              localIssues.isNotEmpty ||
              _isOfflineMode) {
            final vaultName = _vaultFolderName ?? 'Vault';
            final vaultRepo = RepoItem(
              id: 'vault',
              title: vaultName,
              fullName: 'local/$vaultName',
              description: 'Local vault folder (will sync when online)',
              children: localIssues,
            );
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
    } catch (e, stackTrace) {
      debugPrint('=== Fetch Error ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');

      if (mounted) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() {
          // In offline mode, don't show error - just show local issues if any
          if (!_isOfflineMode) {
            _errorMessage = e.toString();
          }
          _isFetchingRepos = false;
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

    final successCount = reposToFetch.length -
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
                          color: AppColors.orangePrimary,
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
            // Error message if any
            if (_errorMessage != null) _buildErrorMessage(),
            // Fetching indicator
            if (_isFetchingRepos) _buildFetchingIndicator(),
            // Task List
            Expanded(
              child: _isFetchingRepos
                  ? const Center(child: BrailleLoader(size: 32))
                  : RefreshIndicator(
                      onRefresh: _fetchRepositories,
                      color: AppColors.orangePrimary,
                      child: _buildTaskList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orangePrimary,
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
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Could not fetch repositories',
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppColors.red.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _fetchRepositories,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.orangePrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// Build fetching indicator with loading skeleton (Task 16.5)
  /// 
  /// PERFORMANCE OPTIMIZATION:
  /// - Uses LoadingSkeleton with shimmer effect
  /// - Replaces BrailleLoader for better visual feedback
  /// - Matches list item dimensions for consistent layout
  Widget _buildFetchingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header text
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                BrailleLoader(size: 16),
                const SizedBox(width: 8),
                Text(
                  'Fetching your repositories...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // PERFORMANCE: Loading skeleton for repo list (Task 16.5)
          const LoadingSkeleton(
            height: 72, // Match repo header height
            itemCount: 3,
            spacing: 16,
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
  Widget _buildTaskList() {
    final displayedRepos = _getDisplayedRepos();

    if (displayedRepos.isEmpty && !_isFetchingRepos) {
      return const DashboardEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: RepoList(
            repositories: _getDisplayedRepos(),
            githubApi: _dashboardService,
            expandedRepoId: _expandedRepoId,
            onExpandToggle: _onRepoToggle,
            onIssueTap: _openIssueDetail,
            filterStatus: _filterStatus,
            hideUsernameInRepo: _hideUsernameInRepo,
            pinnedRepos: _pinnedRepos,
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProjectBoardScreen()),
    );
  }

  /// Toggle pin status for a repository with improved error handling.
  ///
  /// FIX (Task 20.3): Ensures pin state persists correctly.
  void _togglePinRepo(String repoFullName) {
    HapticFeedback.lightImpact();
    debugPrint('[Dashboard] Toggle pin for: $repoFullName');
    setState(() {
      if (_pinnedRepos.contains(repoFullName)) {
        _pinnedRepos.remove(repoFullName);
        debugPrint('[Dashboard] Unpinned: $repoFullName');
      } else {
        _pinnedRepos.add(repoFullName);
        debugPrint('[Dashboard] Pinned: $repoFullName');
      }
    });
    // Persist pin state with error handling
    _dashboardService.togglePinRepo(
      repoFullName: repoFullName,
      pinnedRepos: _pinnedRepos,
      filterStatus: _filterStatus,
    ).catchError((e, stackTrace) {
      debugPrint('[Dashboard] ✗ Failed to toggle pin: $e');
      AppErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        showSnackBar: false,
      );
    });
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

  /// Get list of repos to display on main screen
  List<RepoItem> _getDisplayedRepos() {
    return _dashboardService.getDisplayedRepos(
      repositories: _repositories,
      isOfflineMode: _isOfflineMode,
      pinnedRepos: _pinnedRepos,
    );
  }

  /// Get sync cloud state based on sync service status
  SyncCloudState _getSyncCloudState() {
    return _dashboardService.getSyncCloudState(isOfflineMode: _isOfflineMode);
  }

  void _createNewIssue() async {
    // Trigger haptic feedback
    HapticFeedback.selectionClick();
    
    // In offline mode, check if Local Issues repo exists
    if (_repositories.isEmpty && !_isOfflineMode) {
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
          backgroundColor: AppColors.red,
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
    if (_repositories.isEmpty && _isOfflineMode) {
      _createLocalIssue();
      return;
    }

    // Check if Vault repo exists for offline mode
    final hasVaultRepo = _repositories.any((r) => r.id == 'vault');
    if (_isOfflineMode && !hasVaultRepo) {
      _createLocalIssue();
      return;
    }

    // Priority 1: Use currently expanded repo if one is open
    String? selectedRepo;
    if (_expandedRepoId != null) {
      // Find the expanded repo (skip vault)
      try {
        final expandedRepo = _repositories.firstWhere(
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
          _repositories.any(
            (r) => r.fullName == defaultRepoName && r.id != 'vault',
          )) {
        selectedRepo = defaultRepoName;
        debugPrint('Creating issue in default repo: $selectedRepo');
      }
    }

    // Priority 3: Use first available repo (skip vault)
    if (selectedRepo == null) {
      try {
        selectedRepo = _repositories
            .firstWhere((r) => r.id != 'vault')
            .fullName;
        debugPrint('Creating issue in first available repo: $selectedRepo');
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid repository found'),
            backgroundColor: AppColors.red,
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
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    // Navigate to full-screen create issue screen
    if (mounted) {
      // Filter out vault repo from available repos for selection
      final availableRepos = _repositories
          .where((r) => r.id != 'vault')
          .toList();

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
      ).then((createdIssue) {
        if (createdIssue != null && mounted) {
          _loadData();
        }
      });
    }
  }

  void _createLocalIssue() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Create Local Issue',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0x4DFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.orangePrimary),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (Markdown)',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0x4DFFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.orangePrimary),
                  ),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              titleController.dispose();
              descriptionController.dispose();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                final newIssue = IssueItem(
                  id: 'local_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim(),
                  bodyMarkdown: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  status: ItemStatus.open,
                  updatedAt: DateTime.now(),
                  isLocalOnly: true,
                );

                await _localStorage.saveLocalIssue(newIssue);

                // Reload to show the new issue
                await _loadLocalIssues();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Local issue created'),
                        ],
                      ),
                      backgroundColor: AppColors.orangePrimary,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }

                titleController.dispose();
                descriptionController.dispose();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangePrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            IssueDetailScreen(issue: issue, owner: owner, repo: repo),
      ),
    );
  }
}
