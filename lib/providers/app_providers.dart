import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/secure_storage_service.dart';
import '../services/local_storage_service.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import 'repositories_provider.dart';
import 'service_providers.dart';

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final String authType;
  final String? token;

  AuthState({
    required this.isAuthenticated,
    required this.authType,
    this.token,
  });
}

/// Auth provider using FutureProvider pattern
final authStateProvider = FutureProvider<AuthState>((ref) async {
  try {
    final token = await SecureStorageService.getToken();
    final authType = await SecureStorageService.read(key: 'auth_type');

    if (token != null && token.isNotEmpty) {
      return AuthState(
        isAuthenticated: true,
        authType: authType ?? 'pat',
        token: token,
      );
    }

    if (authType == 'offline') {
      return AuthState(isAuthenticated: true, authType: 'offline', token: null);
    }

    return AuthState(isAuthenticated: false, authType: 'none', token: null);
  } catch (e) {
    return AuthState(isAuthenticated: false, authType: 'error', token: null);
  }
});

/// Repositories provider - fetches from GitHub API
final reposProvider = FutureProvider<List<RepoItem>>((ref) async {
  final api = ref.read(githubApiServiceProvider);
  final repos = await api.fetchMyRepositories(perPage: 30);

  // Update the local state notifier
  final notifier = ref.read(repositoriesProvider.notifier);
  notifier.setRepos(repos);

  return repos;
});

/// Issues provider for a specific repo
final issuesProvider = FutureProvider.family<List<IssueItem>, String>((
  ref,
  repoFullName,
) async {
  final parts = repoFullName.split('/');
  final api = ref.read(githubApiServiceProvider);
  return await api.fetchIssues(parts[0], parts[1]);
});

/// Local issues provider (offline vault)
final localIssuesProvider = FutureProvider<List<IssueItem>>((ref) async {
  final storage = ref.read(localStorageServiceProvider);
  return await storage.getLocalIssues();
});

/// Sync status provider
final syncStatusProvider = Provider<String>((ref) {
  final sync = ref.read(syncServiceProvider);
  return sync.syncStatus;
});

/// Last sync time provider
final lastSyncProvider = Provider<DateTime?>((ref) {
  final sync = ref.read(syncServiceProvider);
  return sync.lastSyncTime;
});

/// Is online provider
final isOnlineProvider = Provider<bool>((ref) {
  final sync = ref.read(syncServiceProvider);
  return sync.isNetworkAvailable;
});

/// Settings state class
class SettingsState {
  final bool autoSyncWifi;
  final bool autoSyncAny;
  final String defaultRepo;
  final String defaultProject;
  final String appVersion;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> projects;
  final bool isLoadingUser;
  final bool isLoadingProjects;

  SettingsState({
    this.autoSyncWifi = true,
    this.autoSyncAny = false,
    this.defaultRepo = '',
    this.defaultProject = '',
    this.appVersion = '...',
    this.user = const {},
    this.projects = const [],
    this.isLoadingUser = true,
    this.isLoadingProjects = false,
  });

  SettingsState copyWith({
    bool? autoSyncWifi,
    bool? autoSyncAny,
    String? defaultRepo,
    String? defaultProject,
    String? appVersion,
    Map<String, dynamic>? user,
    List<Map<String, dynamic>>? projects,
    bool? isLoadingUser,
    bool? isLoadingProjects,
  }) {
    return SettingsState(
      autoSyncWifi: autoSyncWifi ?? this.autoSyncWifi,
      autoSyncAny: autoSyncAny ?? this.autoSyncAny,
      defaultRepo: defaultRepo ?? this.defaultRepo,
      defaultProject: defaultProject ?? this.defaultProject,
      appVersion: appVersion ?? this.appVersion,
      user: user ?? this.user,
      projects: projects ?? this.projects,
      isLoadingUser: isLoadingUser ?? this.isLoadingUser,
      isLoadingProjects: isLoadingProjects ?? this.isLoadingProjects,
    );
  }
}

/// Settings provider - manages settings state
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

/// Settings notifier
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadInitialSettings();
    return SettingsState();
  }

  /// Load initial settings from local storage
  Future<void> _loadInitialSettings() async {
    final localStorage = ref.read(localStorageServiceProvider);
    final autoSyncWifi = await localStorage.getAutoSyncWifi();
    final autoSyncAny = await localStorage.getAutoSyncAny();
    final defaultRepo = await localStorage.getDefaultRepo() ?? '';
    final defaultProject = await localStorage.getDefaultProject() ?? '';
    final appVersion = await _getAppVersion();

    state = state.copyWith(
      autoSyncWifi: autoSyncWifi,
      autoSyncAny: autoSyncAny,
      defaultRepo: defaultRepo,
      defaultProject: defaultProject,
      appVersion: appVersion,
      isLoadingUser: false,
    );
  }

  /// Get app version
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Update auto-sync settings
  Future<void> updateAutoSyncSettings({
    required bool autoSyncWifi,
    required bool autoSyncAny,
  }) async {
    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.saveAutoSyncWifi(autoSyncWifi);
    await localStorage.saveAutoSyncAny(autoSyncAny);
    state = state.copyWith(
      autoSyncWifi: autoSyncWifi,
      autoSyncAny: autoSyncAny,
    );
  }

  /// Update default repo
  Future<void> updateDefaultRepo(String repo) async {
    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.saveDefaultRepo(repo);
    state = state.copyWith(defaultRepo: repo);
  }

  /// Update default project
  Future<void> updateDefaultProject(String project) async {
    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.saveDefaultProject(project);
    state = state.copyWith(defaultProject: project);
  }

  /// Load user data
  Future<void> loadUserData() async {
    state = state.copyWith(isLoadingUser: true);
    // Load from GitHub API or local storage
  }

  /// Load projects
  Future<void> loadProjects() async {
    state = state.copyWith(isLoadingProjects: true);
    try {
      final githubApi = ref.read(githubApiServiceProvider);
      final projects = await githubApi.fetchProjects();
      state = state.copyWith(projects: projects, isLoadingProjects: false);
    } catch (e) {
      state = state.copyWith(isLoadingProjects: false);
    }
  }
}

/// Dashboard state class
class DashboardState {
  final String filterStatus;
  final bool hideUsernameInRepo;
  final bool isOfflineMode;
  final bool isFetchingRepos;
  final bool isFetchingProjects;
  final String? errorMessage;
  final bool isLoadingComplete;
  final List<RepoItem> repositories;
  final String? expandedRepoId;
  final List<Map<String, dynamic>> projects;

  DashboardState({
    this.filterStatus = 'open',
    this.hideUsernameInRepo = true,
    this.isOfflineMode = false,
    this.isFetchingRepos = true,
    this.isFetchingProjects = false,
    this.errorMessage,
    this.isLoadingComplete = false,
    this.repositories = const [],
    this.expandedRepoId,
    this.projects = const [],
  });

  DashboardState copyWith({
    String? filterStatus,
    bool? hideUsernameInRepo,
    bool? isOfflineMode,
    bool? isFetchingRepos,
    bool? isFetchingProjects,
    String? errorMessage,
    bool? isLoadingComplete,
    List<RepoItem>? repositories,
    String? expandedRepoId,
    List<Map<String, dynamic>>? projects,
  }) {
    return DashboardState(
      filterStatus: filterStatus ?? this.filterStatus,
      hideUsernameInRepo: hideUsernameInRepo ?? this.hideUsernameInRepo,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      isFetchingRepos: isFetchingRepos ?? this.isFetchingRepos,
      isFetchingProjects: isFetchingProjects ?? this.isFetchingProjects,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingComplete: isLoadingComplete ?? this.isLoadingComplete,
      repositories: repositories ?? this.repositories,
      expandedRepoId: expandedRepoId ?? this.expandedRepoId,
      projects: projects ?? this.projects,
    );
  }
}

/// Dashboard provider - manages dashboard state
final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  () {
    return DashboardNotifier();
  },
);

/// Dashboard notifier
class DashboardNotifier extends Notifier<DashboardState> {
  final LocalStorageService _localStorage = LocalStorageService();

  @override
  DashboardState build() {
    _loadInitialSettings();
    return DashboardState();
  }

  /// Load initial settings
  Future<void> _loadInitialSettings() async {
    final hideUsername = await _localStorage.getHideUsernameSetting();
    state = state.copyWith(
      hideUsernameInRepo: hideUsername,
      isLoadingComplete: true,
    );
  }

  /// Update filter status
  void updateFilterStatus(String status) {
    state = state.copyWith(filterStatus: status);
  }

  /// Toggle expanded repo
  void toggleExpandedRepo(String? repoId) {
    state = state.copyWith(expandedRepoId: repoId);
  }

  /// Set repositories
  void setRepositories(List<RepoItem> repos) {
    state = state.copyWith(repositories: repos, isFetchingRepos: false);
  }

  /// Set projects
  void setProjects(List<Map<String, dynamic>> projects) {
    state = state.copyWith(projects: projects, isFetchingProjects: false);
  }

  /// Set error message
  void setErrorMessage(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  /// Load hide username setting
  Future<void> loadHideUsernameSetting() async {
    final hide = await _localStorage.getHideUsernameSetting();
    state = state.copyWith(hideUsernameInRepo: hide);
  }
}

/// Search state class
class SearchState {
  final String query;
  final bool isLoading;
  final String? error;
  final List<IssueItem> results;
  final String filterStatus;
  final bool filterTitle;
  final bool filterBody;
  final bool filterLabels;
  final bool filterMyIssues;
  final String sortBy;
  final String sortOrder;

  SearchState({
    this.query = '',
    this.isLoading = false,
    this.error,
    this.results = const [],
    this.filterStatus = 'all',
    this.filterTitle = true,
    this.filterBody = true,
    this.filterLabels = true,
    this.filterMyIssues = false,
    this.sortBy = 'created',
    this.sortOrder = 'desc',
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    String? error,
    List<IssueItem>? results,
    String? filterStatus,
    bool? filterTitle,
    bool? filterBody,
    bool? filterLabels,
    bool? filterMyIssues,
    String? sortBy,
    String? sortOrder,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      results: results ?? this.results,
      filterStatus: filterStatus ?? this.filterStatus,
      filterTitle: filterTitle ?? this.filterTitle,
      filterBody: filterBody ?? this.filterBody,
      filterLabels: filterLabels ?? this.filterLabels,
      filterMyIssues: filterMyIssues ?? this.filterMyIssues,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Search provider - manages search state
final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});

/// Search notifier
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState();
  }

  /// Update search query
  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set search results
  void setResults(List<IssueItem> results) {
    state = state.copyWith(results: results, isLoading: false, error: null);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Update filter status
  void updateFilterStatus(String status) {
    state = state.copyWith(filterStatus: status);
  }

  /// Update content filters
  void updateContentFilters({
    bool? filterTitle,
    bool? filterBody,
    bool? filterLabels,
  }) {
    state = state.copyWith(
      filterTitle: filterTitle ?? state.filterTitle,
      filterBody: filterBody ?? state.filterBody,
      filterLabels: filterLabels ?? state.filterLabels,
    );
  }

  /// Update my issues filter
  void updateMyIssuesFilter(bool value) {
    state = state.copyWith(filterMyIssues: value);
  }

  /// Update sort
  void updateSort({String? sortBy, String? sortOrder}) {
    state = state.copyWith(
      sortBy: sortBy ?? state.sortBy,
      sortOrder: sortOrder ?? state.sortOrder,
    );
  }

  /// Clear search
  void clear() {
    state = SearchState();
  }
}
