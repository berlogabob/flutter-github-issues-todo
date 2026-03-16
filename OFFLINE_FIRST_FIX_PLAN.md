# Offline-First Architecture Fix - Comprehensive Plan

**Created:** March 16, 2026  
**Priority:** CRITICAL  
**Status:** Ready for Implementation  
**Agents Involved:** PMA, FDA, UDA, TQA, RCA, DDA

---

## 🚨 Problem Statement

**Current Issue:** On startup, repositories must be fetched from GitHub API. If user is offline, this fails and user cannot:
- Create new issues
- Read previously loaded issues
- Use the app at all

**Violation:** This breaks the core **offline-first** principle - the #1 requirement of GitDoIt.

**Expected Behavior:** 
- If user has previously fetched repos and issues, they must persist in phone memory
- User must be able to work offline immediately on startup
- Network is optional, not required

---

## 🔍 Root Cause Analysis

### Current Flow (BROKEN)
```
App Start → main.dart → MainDashboardScreen → _initialize() → _loadData()
         → _fetchRepositories() → GitHub API call
         → FAILS if offline → User stuck with loading/error
```

### Issues Identified

1. **No Persistent Repository Cache on Startup**
   - `main_dashboard_screen.dart:_fetchRepositories()` always tries API first
   - Cached repos only loaded as fallback AFTER API fails
   - No check for "already have data, show immediately"

2. **No Persistent Issue Cache on Startup**
   - Issues are fetched per-repo on expansion
   - No pre-loading of cached issues for pinned repos
   - User must expand each repo manually even if issues exist locally

3. **Startup Sequence Doesn't Prioritize Local Data**
   - `_loadData()` calls `_fetchRepositories()` immediately
   - No "load cached data first, then refresh" pattern
   - Network timeout delays UI rendering

4. **Offline Mode Detection Only Checks Auth Type**
   - `_checkOfflineMode()` only checks `auth_type == 'offline'`
   - Doesn't check network availability
   - Doesn't check if cached data exists

5. **Sync Service Not Integrated at Startup**
   - `SyncService.init()` is called but doesn't load cached data
   - Sync happens after UI is already waiting for network

---

## ✅ Solution Architecture

### New Flow (FIXED)
```
App Start → main.dart → Check Auth & Network
         → Load Cached Data IMMEDIATELY (repos, issues, projects)
         → Show Dashboard with cached data INSTANTLY
         → Background: Check network
         → If network available → Sync in background
         → Update UI when sync completes
```

### Key Principles

1. **Cached Data First** - Load from storage before any network call
2. **Optimistic UI** - Show cached data immediately, refresh later
3. **Background Sync** - Network operations don't block UI
4. **Smart Refresh** - Only refresh if data is stale (>5 min old)
5. **Graceful Degradation** - Full functionality offline with cached data

---

## 📋 Implementation Tasks

### Task 1: Enhance LocalStorageService for Complete Caching
**File:** `lib/services/local_storage_service.dart`

**Changes:**
- ✅ Already has `saveRepos()` and `getRepos()` methods
- ✅ Already has `saveSyncedIssues()` and `getSyncedIssues()`
- ✅ Already has `saveSyncedProjects()` and `getSyncedProjects()`
- **ADD:** `getCachedDashboardData()` - Load all cached data in one call
- **ADD:** `hasCachedData()` - Check if any cached data exists
- **ADD:** `getCachedDataAge()` - Get age of oldest cached data

**New Methods:**
```dart
/// Check if cached dashboard data exists
bool hasCachedData() async {
  final repos = await getRepos();
  return repos.isNotEmpty;
}

/// Get age of cached data in minutes
int getCachedDataAge() async {
  final timestamp = await getReposSyncTime();
  if (timestamp == null) return -1;
  return DateTime.now().difference(timestamp).inMinutes;
}

/// Load all cached dashboard data at once
Future<CachedDashboardData> getCachedDashboardData() async {
  final repos = await getRepos();
  final projects = await getSyncedProjects();
  final localIssues = await getLocalIssues();
  
  // Load issues for each repo
  final reposWithIssues = <RepoItem>[];
  for (final repoData in repos) {
    final repo = RepoItem.fromJson(repoData);
    final issues = await getSyncedIssues(repo.fullName);
    repo.children = issues;
    reposWithIssues.add(repo);
  }
  
  return CachedDashboardData(
    repositories: reposWithIssues,
    projects: projects,
    localIssues: localIssues,
    timestamp: await getReposSyncTime(),
  );
}
```

---

### Task 2: Create Cached Data Model
**File:** `lib/models/cached_dashboard_data.dart` (NEW)

**Content:**
```dart
import '../models/repo_item.dart';
import '../models/issue_item.dart';

/// Model for cached dashboard data
class CachedDashboardData {
  final List<RepoItem> repositories;
  final List<Map<String, dynamic>> projects;
  final List<IssueItem> localIssues;
  final DateTime? timestamp;
  
  CachedDashboardData({
    required this.repositories,
    required this.projects,
    required this.localIssues,
    this.timestamp,
  });
  
  bool get isStale {
    if (timestamp == null) return true;
    return DateTime.now().difference(timestamp!).inMinutes > 5;
  }
  
  bool get hasData => repositories.isNotEmpty || localIssues.isNotEmpty;
}
```

---

### Task 3: Update SyncService to Load Cached Data on Init
**File:** `lib/services/sync_service.dart`

**Changes:**
- **MODIFY:** `init()` to load cached data immediately
- **ADD:** `loadCachedData()` method
- **ADD:** `cachedData` property to hold loaded data
- **MODIFY:** `syncAll()` to update cached data after sync

**New Flow:**
```dart
Future<void> init() async {
  debugPrint('SyncService: Initializing...');
  await _loadCachedData(); // ← NEW: Load cached data first
  _setupConnectivityListener();
  _checkNetworkStatus();
  _loadLastSyncTimes();
  await _initHistory();
}

Future<void> _loadCachedData() async {
  try {
    final cachedData = await _localStorage.getCachedDashboardData();
    _cachedData = cachedData;
    debugPrint('SyncService: Loaded cached data: ${cachedData.repositories.length} repos');
  } catch (e) {
    debugPrint('SyncService: No cached data found');
  }
}
```

---

### Task 4: Refactor MainDashboardScreen Startup Sequence
**File:** `lib/screens/main_dashboard_screen.dart`

**CRITICAL CHANGES:**

**Current `_loadData()` (BROKEN):**
```dart
Future<void> _loadData() async {
  await _loadSavedFilters();
  await _loadLocalIssues();
  await _reloadPinnedRepos();
  await _fetchRepositories(); // ← BLOCKS on network
  await _fetchProjects();     // ← BLOCKS on network
}
```

**New `_loadData()` (FIXED):**
```dart
Future<void> _loadData() async {
  // STEP 1: Load cached data IMMEDIATELY
  await _loadCachedData();
  
  // STEP 2: Show UI with cached data (no blocking)
  setState(() {
    _isLoadingComplete = true;
  });
  
  // STEP 3: Refresh in background (non-blocking)
  _refreshDataInBackground();
}

Future<void> _loadCachedData() async {
  setState(() {
    _isLoadingCachedData = true;
  });
  
  try {
    // Load cached repos
    final cachedRepos = await _localStorage.getRepos();
    if (cachedRepos.isNotEmpty) {
      final repos = cachedRepos.map((r) => RepoItem.fromJson(r)).toList();
      
      // Load cached issues for each repo
      for (final repo in repos) {
        final issues = await _localStorage.getSyncedIssues(repo.fullName);
        repo.children = issues;
      }
      
      // Load cached projects
      final cachedProjects = await _localStorage.getSyncedProjects();
      
      setState(() {
        _repositories = repos;
        _projects = cachedProjects;
        _cachedDataTimestamp = await _localStorage.getReposSyncTime();
      });
      
      debugPrint('Loaded cached data: ${repos.length} repos');
    }
  } catch (e) {
    debugPrint('Error loading cached data: $e');
  }
  
  setState(() {
    _isLoadingCachedData = false;
  });
}

Future<void> _refreshDataInBackground() async {
  // Check if we should refresh (data is stale or force refresh)
  final shouldRefresh = _shouldRefreshData();
  
  if (!shouldRefresh) {
    debugPrint('Cached data is fresh, skipping refresh');
    return;
  }
  
  // Refresh in background (non-blocking)
  Future.delayed(Duration.zero, () async {
    await _fetchRepositories();
    await _fetchProjects();
  });
}

bool _shouldRefreshData() {
  // Always refresh if no cached data
  if (_repositories.isEmpty) return true;
  
  // Don't refresh in offline mode
  if (_isOfflineMode) return false;
  
  // Refresh if data is stale (>5 minutes old)
  if (_cachedDataTimestamp == null) return true;
  final age = DateTime.now().difference(_cachedDataTimestamp!);
  return age.inMinutes > 5;
}
```

---

### Task 5: Add Loading States for Cached Data
**File:** `lib/screens/main_dashboard_screen.dart`

**New State Variables:**
```dart
bool _isLoadingCachedData = false;
bool _isLoadingComplete = false;
DateTime? _cachedDataTimestamp;
```

**Updated Build Method:**
```dart
@override
Widget build(BuildContext context) {
  // Show loading only on first launch (no cached data)
  if (!_isLoadingComplete && !_isLoadingCachedData) {
    return Scaffold(
      body: Center(child: BrailleLoader()),
    );
  }
  
  // Show dashboard with cached data (even if refreshing)
  return Scaffold(
    body: RefreshIndicator(
      onRefresh: _fetchRepositories,
      child: _buildDashboard(),
    ),
    // Show sync indicator if refreshing in background
    floatingActionButton: _isRefreshingInBackground
        ? SyncCloudIcon(state: SyncCloudState.syncing)
        : null,
  );
}
```

---

### Task 6: Update Repositories Provider to Support Cached Data
**File:** `lib/providers/repositories_provider.dart`

**Changes:**
- **ADD:** `loadCachedRepos()` method to notifier
- **MODIFY:** `build()` to check for cached data on init

```dart
class RepositoriesNotifier extends Notifier<List<RepoItem>> {
  @override
  List<RepoItem> build() {
    // Load cached repos on provider initialization
    _loadCachedRepos();
    return [];
  }
  
  Future<void> _loadCachedRepos() async {
    try {
      final localStorage = LocalStorageService();
      final cachedRepos = await localStorage.getRepos();
      
      if (cachedRepos.isNotEmpty) {
        state = cachedRepos.map((r) => RepoItem.fromJson(r)).toList();
        debugPrint('RepositoriesNotifier: Loaded ${state.length} cached repos');
      }
    } catch (e) {
      debugPrint('RepositoriesNotifier: Failed to load cached repos: $e');
    }
  }
  
  void setRepos(List<RepoItem> repos) {
    state = repos;
    // Also cache to local storage
    _cacheToLocalStorage(repos);
  }
  
  Future<void> _cacheToLocalStorage(List<RepoItem> repos) async {
    try {
      final localStorage = LocalStorageService();
      await localStorage.saveRepos(repos.map((r) => r.toJson()).toList());
      debugPrint('RepositoriesNotifier: Cached ${repos.length} repos');
    } catch (e) {
      debugPrint('RepositoriesNotifier: Failed to cache repos: $e');
    }
  }
}
```

---

### Task 7: Update GitHubApiService to Cache on Every Fetch
**File:** `lib/services/github_api_service.dart`

**Changes:**
- **MODIFY:** `fetchMyRepositories()` to cache results automatically
- **MODIFY:** `fetchIssues()` to cache results automatically
- **MODIFY:** `fetchProjects()` to cache results automatically

```dart
Future<List<RepoItem>> fetchMyRepositories({
  int page = 1,
  int perPage = 30,
}) async {
  try {
    // ... existing API call ...
    
    final repos = await _executeWithRetry(...);
    
    // CACHE RESULTS AUTOMATICALLY
    await _localStorage.saveRepos(repos.map((r) => r.toJson()).toList());
    
    return repos;
  } catch (e) {
    // On error, try to return cached data
    final cachedRepos = await _localStorage.getRepos();
    if (cachedRepos.isNotEmpty) {
      debugPrint('Returning cached repos due to error');
      return cachedRepos.map((r) => RepoItem.fromJson(r)).toList();
    }
    rethrow;
  }
}
```

---

### Task 8: Add Smart Refresh Indicator
**File:** `lib/screens/main_dashboard_screen.dart`

**New Method:**
```dart
Widget _buildRefreshIndicator() {
  return RefreshIndicator(
    onRefresh: () async {
      // Force refresh
      await _fetchRepositories(forceRefresh: true);
      await _fetchProjects(forceRefresh: true);
    },
    child: _buildDashboard(),
  );
}
```

**Visual Indicator:**
```dart
// Show "Last updated" text
if (_cachedDataTimestamp != null) {
  final lastUpdated = _formatLastUpdated(_cachedDataTimestamp!);
  Text(
    'Last updated: $lastUpdated',
    style: TextStyle(
      fontSize: 12.sp,
      color: Colors.white54,
    ),
  );
}

String _formatLastUpdated(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);
  
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
```

---

### Task 9: Update Onboarding Screen for Better Offline UX
**File:** `lib/screens/onboarding_screen.dart`

**Changes:**
- **MODIFY:** `_continueOffline()` to pre-populate with demo data
- **ADD:** Show explanation of offline mode capabilities

**Enhanced Offline Mode:**
```dart
Future<void> _continueOffline() async {
  // ... existing code ...
  
  // Create demo repository for first-time offline users
  final hasData = await _localStorage.hasCachedData();
  if (!hasData) {
    await _createDemoData();
  }
  
  // ... navigate to dashboard ...
}

Future<void> _createDemoData() async {
  // Create a demo repo with example issues
  final demoRepo = RepoItem(
    id: 'demo_local_tasks',
    title: 'My Local Tasks',
    fullName: 'local/My Local Tasks',
    description: 'Your personal task repository (offline)',
    children: [
      IssueItem(
        id: 'demo_issue_1',
        title: 'Welcome to GitDoIt Offline Mode!',
        bodyMarkdown: '''
This is your local vault. You can:
- Create issues offline
- Edit issues offline
- All changes sync when you go online

Try creating your first issue!
''',
        labels: ['welcome', 'offline'],
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: true,
      ),
    ],
  );
  
  await _localStorage.saveRepos([demoRepo.toJson()]);
  await _localStorage.saveLocalIssue(demoRepo.children.first);
}
```

---

### Task 10: Add Settings for Cache Management
**File:** `lib/screens/settings_screen.dart`

**New Settings:**
- **ADD:** "Clear Cache" button
- **ADD:** "Cache Size" display
- **ADD:** "Auto-refresh Interval" setting
- **ADD:** "Last Sync Time" display

```dart
ListTile(
  title: const Text('Clear Cache'),
  subtitle: Text('Free up ${_cacheSize} of storage'),
  onTap: () => _showClearCacheDialog(),
),

ListTile(
  title: const Text('Auto-refresh'),
  subtitle: Text(_getRefreshIntervalText()),
  onTap: () => _changeRefreshInterval(),
),
```

---

### Task 11: Update Tests for Offline-First Flow
**Files:** `test/services/`, `test/screens/`

**New Tests:**
```dart
test('Dashboard loads cached data on startup', () async {
  // Setup: Pre-populate cache
  await localStorage.saveRepos(testRepos);
  await localStorage.saveSyncedIssues('test/repo', testIssues);
  
  // Act: Load dashboard
  await dashboard.loadData();
  
  // Assert: Cached data loaded immediately
  expect(dashboard.repositories, equals(testRepos));
  expect(dashboard.repositories.first.children, equals(testIssues));
});

test('Dashboard works offline with cached data', () async {
  // Setup: No network, cached data exists
  when(networkService.isOnline).thenReturn(false);
  await localStorage.saveRepos(testRepos);
  
  // Act: Load dashboard
  await dashboard.loadData();
  
  // Assert: Shows cached data
  expect(dashboard.repositories, isNotEmpty);
});

test('Background refresh updates cached data', () async {
  // Setup: Stale cached data
  await localStorage.saveRepos(oldRepos);
  
  // Act: Trigger background refresh
  await dashboard.refreshDataInBackground();
  
  // Assert: New data cached
  final cachedRepos = await localStorage.getRepos();
  expect(cachedRepos, equals(newRepos));
});
```

---

### Task 12: Documentation Updates
**Files:** `README.md`, `QWEN.md`, `AGENTS.md`

**Updates:**
- **ADD:** Offline-first architecture section
- **ADD:** Cached data flow diagram
- **ADD:** Performance characteristics
- **UPDATE:** User guide for offline mode

---

## 🎯 Success Criteria

### Functional Requirements
- ✅ App loads in <2 seconds with cached data (even offline)
- ✅ User can create issues immediately on startup (offline)
- ✅ User can view previously loaded issues (offline)
- ✅ User can expand repos and see cached issues (offline)
- ✅ Background sync updates data when network available
- ✅ Pull-to-refresh forces sync when online

### Performance Requirements
- ✅ Cold start with cache: <2 seconds
- ✅ Cold start without cache: <5 seconds (with loading state)
- ✅ Background sync: Non-blocking
- ✅ Cache hit rate: >90% for repeated views

### Quality Requirements
- ✅ All existing tests pass
- ✅ New tests for offline scenarios
- ✅ No regression in online performance
- ✅ Linting passes (`flutter analyze`)
- ✅ Code formatted (`dart format .`)

---

## 📊 Implementation Order

1. **Task 2** - Create `CachedDashboardData` model (foundation)
2. **Task 1** - Enhance `LocalStorageService` (data access)
3. **Task 7** - Update `GitHubApiService` caching (auto-cache)
4. **Task 3** - Update `SyncService` init (load cached data)
5. **Task 6** - Update `RepositoriesProvider` (provider support)
6. **Task 4** - Refactor `MainDashboardScreen` (critical UX fix)
7. **Task 5** - Add loading states (UX polish)
8. **Task 8** - Add smart refresh indicator (UX polish)
9. **Task 9** - Update onboarding (first-time UX)
10. **Task 10** - Add cache settings (user control)
11. **Task 11** - Update tests (quality assurance)
12. **Task 12** - Update documentation (knowledge transfer)

---

## 🚨 Risk Mitigation

### Potential Issues

1. **Cache Corruption**
   - **Mitigation:** Try-catch all cache reads, fallback to empty state
   - **Recovery:** "Clear Cache" button in settings

2. **Stale Data**
   - **Mitigation:** 5-minute stale threshold, auto-refresh
   - **Recovery:** Pull-to-refresh forces update

3. **Storage Bloat**
   - **Mitigation:** Limit cache to 100 repos, 1000 issues
   - **Recovery:** Cache size display, clear cache option

4. **Sync Conflicts**
   - **Mitigation:** "Remote wins" strategy (already implemented)
   - **Recovery:** Conflict detection service (already exists)

---

## 📈 Performance Metrics

### Before Fix
- Cold start (offline): **FAILS** ❌
- Cold start (online): ~5-10 seconds
- Issue creation (offline): Works ✅
- View issues (offline): **FAILS** ❌

### After Fix (Target)
- Cold start (offline): <2 seconds ✅
- Cold start (online): <2 seconds (cached) ✅
- Issue creation (offline): Works ✅
- View issues (offline): Works ✅
- Background sync: Non-blocking ✅

---

## 🔧 Technical Debt Addressed

1. **Tight Coupling:** Dashboard no longer tightly coupled to network
2. **Single Responsibility:** Each service handles its own caching
3. **Error Handling:** Graceful degradation on cache miss
4. **User Experience:** Instant loading, background updates

---

## 📝 Notes

- **Backward Compatible:** Existing users keep their data
- **Incremental Rollout:** Can test with beta users first
- **Monitoring:** Add analytics for cache hit/miss rates
- **Future Enhancement:** Pre-fetching for predicted user actions

---

**Plan Approved By:** Agent Team (PMA, FDA, UDA, TQA, RCA, COORD)  
**Ready for Implementation:** ✅  
**Estimated Implementation Time:** 2-3 hours  
**Testing Time:** 1 hour  
**Documentation Time:** 30 minutes

---

*This plan ensures GitDoIt delivers on its core promise: **Offline-first TODO manager that works when you need it most**.*
