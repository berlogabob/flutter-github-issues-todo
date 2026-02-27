import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/expandable_repo.dart';
import '../widgets/sync_cloud_icon.dart';
import 'create_issue_screen.dart';
import '../utils/responsive_utils.dart';
import 'issue_detail_screen.dart';
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
  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  final SyncService _syncService = SyncService();

  String _filterStatus = 'open';
  bool _hideUsernameInRepo = false;
  bool _isLoading = false;
  bool _isOfflineMode = false;
  bool _isFetchingRepos = false;
  bool _isFetchingProjects = false;
  String? _errorMessage;
  String? _vaultFolderName;

  // Repositories with issues
  List<RepoItem> _repositories = [];

  // Pinned repos (stored as set of repo IDs)
  Set<String> _pinnedRepos = {};

  // Projects for issue creation
  List<Map<String, dynamic>> _projects = [];
  Map<String, String> _projectFieldIds = {}; // projectName -> fieldId
  Map<String, Map<String, String>> _columnOptionIds =
      {}; // projectName -> {columnName -> optionId}

  @override
  void initState() {
    super.initState();
    _syncService.init();
    _checkOfflineMode();
    _loadHideUsernameSetting();

    // Set up callback for when internet becomes available with local issues
    _syncService.onSyncNeeded = _showSyncLocalIssuesDialog;

    // Check immediately if there are local issues to sync
    _checkLocalIssuesToSync();

    _loadData();
  }

  Future<void> _loadHideUsernameSetting() async {
    final hide = await _localStorage.getHideUsernameSetting();
    if (mounted) {
      setState(() {
        _hideUsernameInRepo = hide;
      });
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
            Icon(Icons.sync, color: AppColors.orange),
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
                    leading: const Icon(Icons.folder, color: AppColors.orange),
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
    _syncService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load saved filters
    await _loadSavedFilters();

    // Load local issues
    await _loadLocalIssues();

    // Then try to fetch from GitHub
    await _fetchRepositories();

    // Fetch projects for issue creation
    await _fetchProjects();
  }

  Future<void> _loadSavedFilters() async {
    try {
      final filters = await _localStorage.getFilters();
      if (mounted) {
        setState(() {
          _filterStatus = filters['filterStatus'] ?? 'open';
          final pinnedList = filters['pinnedRepos'];
          if (pinnedList != null) {
            _pinnedRepos = (pinnedList as List)
                .map((e) => e.toString())
                .toSet();
          }
        });
        debugPrint(
          'Loaded saved filters: $_filterStatus, pinned: $_pinnedRepos',
        );
      }
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _autoPinDefaultRepo() async {
    // If no pinned repos, auto-pin the default repo from settings
    if (_pinnedRepos.isEmpty) {
      final defaultRepoName = await _localStorage.getDefaultRepo();
      if (defaultRepoName != null && mounted) {
        // Find repo by fullName and get its ID
        for (final repo in _repositories) {
          if (repo.fullName == defaultRepoName) {
            setState(() {
              _pinnedRepos.add(repo.id);
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

      // In offline mode, always show Vault repo (even if empty)
      // so users can create new issues
      if ((localIssues.isNotEmpty || _isOfflineMode) && mounted) {
        final vaultName = _vaultFolderName ?? 'Vault';

        // Check if Vault repo already exists
        final hasVaultRepo = _repositories.any((r) => r.id == 'vault');

        if (!hasVaultRepo) {
          final vaultRepo = RepoItem(
            id: 'vault',
            title: vaultName,
            fullName: 'local/$vaultName',
            description: 'Local vault folder (will sync when online)',
            children: localIssues,
          );

          setState(() {
            _repositories.insert(0, vaultRepo);
          });
        } else {
          // Update existing vault repo with local issues
          final index = _repositories.indexWhere((r) => r.id == 'vault');
          if (index != -1) {
            setState(() {
              _repositories[index] = RepoItem(
                id: 'vault',
                title: vaultName,
                fullName: 'local/$vaultName',
                description: 'Local vault folder (will sync when online)',
                children: localIssues,
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local issues: $e');
    }
  }

  Future<void> _fetchRepositories() async {
    setState(() {
      _isFetchingRepos = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=== Fetching Repositories ===');

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
      } catch (e) {
        debugPrint('✗ Network check error: $e');
        throw Exception('Network error: $e');
      }

      // Check if we have a token
      final hasToken = await _githubApi.getToken();
      debugPrint(
        'Token available: ${hasToken != null}, length: ${hasToken?.length ?? 0}',
      );

      if (hasToken == null || hasToken.isEmpty) {
        debugPrint('No token found, showing demo data');
        throw Exception('Not authenticated. Please login with a GitHub token.');
      }

      debugPrint('Calling fetchMyRepositories()...');
      final repos = await _githubApi.fetchMyRepositories(perPage: 30);
      debugPrint('✓ Fetched ${repos.length} repositories from GitHub');

      if (mounted) {
        // Preserve vault repo if exists, but refresh its issues from local storage
        final vaultRepoIndex = _repositories.indexWhere((r) => r.id == 'vault');
        final existingVaultRepo = vaultRepoIndex != -1
            ? _repositories[vaultRepoIndex]
            : null;

        // Always reload local issues
        final localIssues = await _localStorage.getLocalIssues();

        setState(() {
          _repositories = List.from(
            repos,
          ); // Create new list to avoid race conditions

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
        setState(() {
          // In offline mode, don't show error - just show local issues if any
          if (!_isOfflineMode) {
            _errorMessage = e.toString();
          }
          _isFetchingRepos = false;
          // Add demo data only if NOT in offline mode
          if (_repositories.isEmpty && !_isOfflineMode) {
            debugPrint('Showing demo data as fallback');
            _addDemoData();
          }
        });
      }
    }
  }

  Future<void> _fetchIssuesForAllRepos() async {
    // Fetch issues for all repos concurrently
    final futures = _repositories.map((repo) async {
      try {
        final parts = repo.fullName.split('/');
        if (parts.length == 2) {
          debugPrint('Fetching issues for ${repo.fullName}...');
          final issues = await _githubApi.fetchIssues(parts[0], parts[1]);
          if (mounted) {
            setState(() {
              repo.children.addAll(issues);
            });
            debugPrint('✓ Loaded ${issues.length} issues for ${repo.fullName}');
          }
        }
      } catch (e) {
        debugPrint('✗ Failed to fetch issues for ${repo.fullName}: $e');
        // Don't fail the entire operation if one repo fails
      }
    });

    // Wait for all fetches to complete
    await Future.wait(futures);
    debugPrint('✓ Finished fetching issues for all repos');
  }

  Future<void> _fetchIssues(String owner, String repo) async {
    try {
      debugPrint('Fetching issues for $owner/$repo...');
      final issues = await _githubApi.fetchIssues(owner, repo);
      if (mounted && _repositories.isNotEmpty) {
        setState(() {
          _repositories.first.children.clear();
          _repositories.first.children.addAll(issues);
        });
        debugPrint('✓ Fetched ${issues.length} issues');
      }
    } catch (e) {
      debugPrint('✗ Error fetching issues: $e');
      // Don't fail silently - log the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch issues: ${e.toString()}'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Fetch projects and their field/column mappings
  Future<void> _fetchProjects() async {
    if (_isFetchingProjects) return;

    setState(() => _isFetchingProjects = true);

    try {
      debugPrint('Fetching projects...');
      final projects = await _githubApi.fetchProjects();
      debugPrint('Fetched ${projects.length} projects');

      if (mounted) {
        // Fetch field IDs for each project
        final projectFieldIds = <String, String>{};
        final columnOptionIds = <String, Map<String, String>>{};

        for (final project in projects) {
          final projectId = project['id'] as String;
          final projectTitle = project['title'] as String;

          debugPrint('Fetching fields for project: $projectTitle ($projectId)');
          final fields = await _githubApi.getProjectFields(projectId);

          if (fields != null && fields.isNotEmpty) {
            // Find the Status field (single select)
            for (final field in fields) {
              if (field['__typename'] == 'ProjectV2SingleSelectField') {
                final fieldId = field['id'] as String;

                // Store field ID for this project
                projectFieldIds[projectTitle] = fieldId;

                // Store option IDs for columns
                final options =
                    (field['options'] as List?)?.cast<Map<String, dynamic>>() ??
                    [];
                final optionMap = <String, String>{};
                for (final option in options) {
                  optionMap[option['name'] as String] = option['id'] as String;
                }
                columnOptionIds[projectTitle] = optionMap;

                debugPrint(
                  '  Status field: $fieldId with ${options.length} options',
                );
                break; // Only need the first single-select field (Status)
              }
            }
          }
        }

        setState(() {
          _projects = projects;
          _projectFieldIds = projectFieldIds;
          _columnOptionIds = columnOptionIds;
          _isFetchingProjects = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      if (mounted) {
        setState(() => _isFetchingProjects = false);
      }
    }
  }

  void _addDemoData() {
    _repositories.add(
      RepoItem(
        id: 'demo1',
        title: 'gitdoit',
        fullName: 'user/gitdoit',
        description: 'Minimalist GitHub Issues & Projects TODO Manager (Demo)',
        children: [
          IssueItem(
            id: 'issue1',
            title: 'Implement authentication',
            number: 1,
            status: ItemStatus.closed,
            labels: ['feature', 'priority'],
            assigneeLogin: 'user',
            isLocalOnly: true,
          ),
          IssueItem(
            id: 'issue2',
            title: 'Create main dashboard',
            number: 2,
            status: ItemStatus.open,
            labels: ['ui'],
            assigneeLogin: 'user',
            isLocalOnly: true,
          ),
          IssueItem(
            id: 'issue3',
            title: 'Add offline support',
            number: 3,
            status: ItemStatus.open,
            labels: ['feature', 'offline'],
            isLocalOnly: true,
          ),
        ],
      ),
    );
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
          // Sync cloud icon with states + Last sync time
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SyncCloudIcon(
                state: _getSyncCloudState(),
                size: 24.w,
                isRotating: _syncService.isSyncing,
              ),
              if (_syncService.lastSyncTime != null)
                Text(
                  _getLastSyncText(),
                  style: TextStyle(color: Colors.white54, fontSize: 8.sp),
                ),
            ],
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
            _buildFilters(),
            // Error message if any
            if (_errorMessage != null) _buildErrorMessage(),
            // Fetching indicator
            if (_isFetchingRepos) _buildFetchingIndicator(),
            // Task List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.orange,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchRepositories,
                      color: AppColors.orange,
                      child: _buildTaskList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
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
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFetchingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Fetching your repositories...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ResponsiveLayout(
            mobile: _buildFiltersMobile(),
            tablet: _buildFiltersTablet(),
            desktop: _buildFiltersTablet(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersMobile() {
    return Row(
      children: [
        _buildFilterChip('Open'),
        SizedBox(width: 8.w),
        _buildFilterChip('Closed'),
        SizedBox(width: 8.w),
        _buildFilterChip('All'),
        const Spacer(),
        _buildHideUsernameButton(),
      ],
    );
  }

  Widget _buildFiltersTablet() {
    return Row(
      children: [
        _buildFilterChip('Open'),
        SizedBox(width: 8.w),
        _buildFilterChip('Closed'),
        SizedBox(width: 8.w),
        _buildFilterChip('All'),
        const Spacer(),
        _buildHideUsernameButton(),
      ],
    );
  }

  Widget _buildHideUsernameButton() {
    return IconButton(
      icon: Icon(
        _hideUsernameInRepo ? Icons.visibility_off : Icons.visibility,
        color: _hideUsernameInRepo ? Colors.white54 : AppColors.orange,
        size: 20.w,
      ),
      onPressed: () {
        setState(() {
          _hideUsernameInRepo = !_hideUsernameInRepo;
        });
        _localStorage.saveHideUsernameSetting(_hideUsernameInRepo);
      },
      tooltip: _hideUsernameInRepo
          ? 'Show username in repo name'
          : 'Hide username in repo name',
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label.toLowerCase();
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 13.sp)),
      selected: isSelected,
      backgroundColor: AppColors.background,
      selectedColor: AppColors.orange.withValues(alpha: 0.3),
      checkmarkColor: AppColors.orange,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.orange
            : Colors.white.withValues(alpha: 0.8),
        fontSize: 13.sp,
      ),
      onSelected: (selected) async {
        setState(() {
          _filterStatus = label.toLowerCase();
        });
        await _localStorage.saveFilters(filterStatus: _filterStatus);
      },
    );
  }

  Widget _buildTaskList() {
    if (_repositories.isEmpty && !_isFetchingRepos) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No repositories',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the folder icon to add repositories',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Filter repositories and issues based on selected filter
    final filteredRepos = <RepoItem>[];
    for (final repo in _repositories) {
      final filteredIssues = repo.children.where((item) {
        // Cast to IssueItem for filtering
        final issue = item is IssueItem ? item : null;
        if (issue == null) return false;

        // Filter by status
        if (_filterStatus == 'all') {
          // Continue
        } else if (_filterStatus == 'open') {
          if (issue.status != ItemStatus.open) return false;
        } else if (_filterStatus == 'closed') {
          if (issue.status != ItemStatus.closed) return false;
        }

        return true;
      }).toList();

      // Include repo if it has issues matching the filter, or if filter is 'all'
      if (filteredIssues.isNotEmpty || _filterStatus == 'all') {
        final filteredRepo = RepoItem(
          id: repo.id,
          title: repo.title,
          fullName: repo.fullName,
          description: repo.description,
          status: repo.status,
          children: filteredIssues,
        );
        filteredRepos.add(filteredRepo);
      }
    }

    // Sort repos - pinned ones first
    final sortedFilteredRepos = _getSortedRepos(filteredRepos);

    // Find the index where unpinned repos start
    int? dividerIndex;
    for (int i = 0; i < sortedFilteredRepos.length; i++) {
      if (!_pinnedRepos.contains(sortedFilteredRepos[i].id)) {
        if (i > 0) {
          dividerIndex = i;
        }
        break;
      }
    }

    // Add top padding if first repo is pinned to avoid overlap with filters
    final double topPadding =
        (dividerIndex != null ||
            (sortedFilteredRepos.isNotEmpty &&
                _pinnedRepos.contains(sortedFilteredRepos.first.id)))
        ? 8.0
        : 0.0;

    return ListView.builder(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.02,
        right: MediaQuery.of(context).size.width * 0.02,
        top: topPadding,
      ),
      itemCount: sortedFilteredRepos.length,
      itemBuilder: (context, index) {
        final repo = sortedFilteredRepos[index];
        final isPinned = _pinnedRepos.contains(repo.id);

        // Add divider after pinned repos
        if (dividerIndex != null && index == dividerIndex) {
          return Column(
            children: [
              ExpandableRepo(
                repo: repo,
                githubApi: _githubApi,
                onIssueTap: _openIssueDetail,
                initiallyExpanded: false,
                hideUsernameInRepo: _hideUsernameInRepo,
                isPinned: isPinned,
                onPinToggle: () => _togglePinRepo(repo.id),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          );
        }

        // First unpinned repo should be expanded
        final isFirstUnpinned = dividerIndex != null && index == dividerIndex;

        return ExpandableRepo(
          repo: repo,
          githubApi: _githubApi,
          onIssueTap: _openIssueDetail,
          initiallyExpanded: index == 0 || isFirstUnpinned,
          hideUsernameInRepo: _hideUsernameInRepo,
          isPinned: isPinned,
          onPinToggle: () => _togglePinRepo(repo.id),
        );
      },
    );
  }

  void _sync() async {
    setState(() => _isLoading = true);

    try {
      final success = await _syncService.syncAll(forceRefresh: true);

      if (success && mounted) {
        await _fetchRepositories();

        // Show detailed sync results
        final issuesCount = _syncService.syncedIssuesCount;
        final projectsCount = _syncService.syncedProjectsCount;

        String message = 'Synced $issuesCount issues';
        if (projectsCount > 0) {
          message += ' • $projectsCount projects';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: AppColors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sync failed: ${_syncService.syncErrorMessage ?? 'Unknown error'}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _sync,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Sync failed: $e')),
              ],
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _forceRefresh() async {
    setState(() {
      _repositories = [];
      _errorMessage = null;
    });
    await _fetchRepositories();
  }

  void _navigateToSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SearchScreen()));
  }

  void _navigateToRepoLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RepoProjectLibraryScreen()),
    );
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _togglePinRepo(String repoId) {
    setState(() {
      if (_pinnedRepos.contains(repoId)) {
        _pinnedRepos.remove(repoId);
      } else {
        _pinnedRepos.add(repoId);
      }
    });
    _localStorage.saveFilters(
      filterStatus: _filterStatus,
      pinnedRepos: _pinnedRepos.toList(),
    );
  }

  List<RepoItem> _getSortedRepos(List<RepoItem> repos) {
    final sorted = List<RepoItem>.from(repos);
    sorted.sort((a, b) {
      final aPinned = _pinnedRepos.contains(a.id);
      final bPinned = _pinnedRepos.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });
    return sorted;
  }

  /// Get sync cloud state based on sync service status
  SyncCloudState _getSyncCloudState() {
    // Check offline mode first (user selected offline on startup)
    if (_isOfflineMode || !_syncService.isNetworkAvailable) {
      return SyncCloudState.offline;
    }
    if (_syncService.isSyncing) {
      return SyncCloudState.syncing;
    }
    if (_syncService.syncStatus == 'error') {
      return SyncCloudState.error;
    }
    return SyncCloudState.synced;
  }

  /// Get last sync time as human-readable text
  String _getLastSyncText() {
    final lastSync = _syncService.lastSyncTime;
    if (lastSync == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}d';
    }
  }

  void _createNewIssue() async {
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

    // Load default repo from settings
    final defaultRepoName = await _localStorage.getDefaultRepo();

    // Use default repo if available and exists in loaded repos, otherwise use first repo (skip vault)
    String? selectedRepo =
        defaultRepoName != null &&
            _repositories.any(
              (r) => r.fullName == defaultRepoName && r.id != 'vault',
            )
        ? defaultRepoName
        : _repositories
              .firstWhere(
                (r) => r.id != 'vault',
                orElse: () => _repositories.first,
              )
              .fullName;

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateIssueScreen(
            owner: owner,
            repo: repo,
            defaultProject: _projects.isNotEmpty
                ? _projects.first['title'] as String?
                : null,
            projects: _projects,
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
                    borderSide: BorderSide(color: AppColors.orange),
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
                    borderSide: BorderSide(color: AppColors.orange),
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
                      backgroundColor: AppColors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }

                titleController.dispose();
                descriptionController.dispose();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.black,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openIssueDetail(IssueItem issue) {
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

  void _showCreateIssueDialog() async {
    // In offline mode, check if Local Issues repo exists
    if (_repositories.isEmpty && !_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
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

    // Load default repo from settings
    final defaultRepoName = await _localStorage.getDefaultRepo();

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    // Use default repo if available and exists in loaded repos, otherwise use first repo
    String? selectedRepo =
        defaultRepoName != null &&
            _repositories.any((r) => r.fullName == defaultRepoName)
        ? defaultRepoName
        : _repositories.first.fullName;

    String? selectedProject;
    String? selectedColumn;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Create New Issue',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Repository selector
                const Text(
                  'Repository *',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRepo,
                    underline: const SizedBox(),
                    isExpanded: true,
                    dropdownColor: AppColors.background,
                    items: _repositories.map((repo) {
                      return DropdownMenuItem(
                        value: repo.fullName,
                        child: Text(
                          repo.fullName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRepo = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Project selector (optional) - with real projects from GitHub
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Project (Optional)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    if (_isFetchingProjects)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedProject,
                    hint: const Text(
                      'No project',
                      style: TextStyle(color: Colors.white54),
                    ),
                    underline: const SizedBox(),
                    isExpanded: true,
                    dropdownColor: AppColors.background,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'No project',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      ..._projects.map((project) {
                        return DropdownMenuItem(
                          value: project['title'] as String,
                          child: Text(
                            project['title'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }),
                    ],
                    onChanged: _projects.isEmpty
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedProject = value;
                              selectedColumn = null;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 16),

                // Column selector (appears when project is selected)
                if (selectedProject != null) ...[
                  const Text(
                    'Column (Optional)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedColumn,
                      hint: const Text(
                        'Select column',
                        style: TextStyle(color: Colors.white54),
                      ),
                      underline: const SizedBox(),
                      isExpanded: true,
                      dropdownColor: AppColors.background,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Select column',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        ...(_columnOptionIds[selectedProject]?.entries.map((
                              entry,
                            ) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList() ??
                            []),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedColumn = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
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
                      borderSide: BorderSide(color: AppColors.orange),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Description
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
                      borderSide: BorderSide(color: AppColors.orange),
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
              onPressed: () {
                if (titleController.text.trim().isNotEmpty &&
                    selectedRepo != null) {
                  _createIssue(
                    titleController.text.trim(),
                    descriptionController.text,
                    selectedRepo!,
                    selectedProject,
                    selectedColumn,
                  );
                  Navigator.pop(context);
                  titleController.dispose();
                  descriptionController.dispose();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.black,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createIssue(
    String title,
    String description,
    String? repo,
    String? project,
    String? column,
  ) async {
    if (_repositories.isEmpty || repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No repositories to add issue to'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    // Parse owner and repo from fullName
    final parts = repo.split('/');
    if (parts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid repository format'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    final owner = parts[0];
    final repoName = parts[1];

    // Find the selected repository
    final targetRepo = _repositories.firstWhere(
      (r) => r.fullName == repo,
      orElse: () => _repositories.first,
    );

    try {
      // Create issue in GitHub
      final createdIssue = await _githubApi.createIssue(
        owner,
        repoName,
        title: title,
        body: description.isNotEmpty ? description : null,
      );

      debugPrint('✓ Created issue #${createdIssue.number} in $owner/$repoName');

      // If project and column are selected, add issue to project
      String? projectColumnName;
      if (project != null && column != null) {
        final projectId = _projectFieldIds[project];
        final fieldId = _projectFieldIds[project];
        final optionId = _columnOptionIds[project]?[column];

        if (projectId != null && fieldId != null && optionId != null) {
          debugPrint('Adding issue to project: $project, column: $column');

          // Add the issue to the project using GraphQL mutation
          final projectItemId = await _githubApi.addProjectItem(
            projectId: projectId,
            issueNodeId: createdIssue.id,
          );

          if (projectItemId != null) {
            debugPrint('✓ Issue added to project with item ID: $projectItemId');

            // Set the column (status) for the newly added item
            final moved = await _githubApi.moveProjectItem(
              projectId: projectId,
              itemId: projectItemId,
              fieldId: fieldId,
              optionId: optionId,
            );

            if (moved) {
              debugPrint('✓ Issue column set to: $column');
              projectColumnName = column;
            } else {
              debugPrint('⚠ Failed to set column for issue');
              projectColumnName = column; // Still store the column name
            }
          } else {
            debugPrint('⚠ Failed to add issue to project');
          }
        } else {
          debugPrint('⚠ Missing project/field/column IDs');
          debugPrint('  Project ID: $projectId');
          debugPrint('  Field ID: $fieldId');
          debugPrint('  Option ID: $optionId');
        }
      }

      // Create IssueItem with GitHub data
      final newIssue = IssueItem(
        id: createdIssue.id,
        title: createdIssue.title,
        number: createdIssue.number,
        bodyMarkdown: createdIssue.bodyMarkdown,
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: false,
        projectColumnName: projectColumnName,
        labels: createdIssue.labels,
      );

      if (mounted) {
        setState(() {
          targetRepo.children.insert(0, newIssue);
        });

        String statusText = 'Issue #${createdIssue.number} created';
        if (project != null && column != null && projectColumnName != null) {
          statusText += ' in $project → $column';
        } else {
          statusText += ' in $repo';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(statusText)),
              ],
            ),
            backgroundColor: AppColors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('✗ Failed to create issue: $e');

      // Fallback: create local issue
      final newIssue = IssueItem(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        number: null,
        bodyMarkdown: description.isNotEmpty ? description : null,
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: true,
        projectColumnName: column,
      );

      await _localStorage.saveLocalIssue(newIssue);

      if (mounted) {
        setState(() {
          targetRepo.children.insert(0, newIssue);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Saved locally: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
