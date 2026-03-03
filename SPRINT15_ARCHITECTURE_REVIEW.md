# Sprint 15: Architecture Review

**Review Date:** March 2, 2026
**Reviewer:** System Architect
**Status:** READY FOR IMPLEMENTATION
**Sprint Goal:** Implement real GitHub API integration for assignees, labels, and project management

---

## Executive Summary

This review evaluates the current codebase against Sprint 15 requirements. The existing architecture provides a solid foundation with well-designed services for networking, caching, offline operations, and error handling. However, **none of the four main Sprint 15 tasks have been implemented yet** - they remain as stub methods or TODO comments in the code.

### Overall Architecture Compliance: PARTIAL

| Component | Status | Notes |
|-----------|--------|-------|
| NetworkService | ✅ Implemented | Available but not consistently used |
| CacheService | ✅ Implemented | 5-minute TTL support available |
| PendingOperationsService | ✅ Implemented | Operation types defined, not integrated |
| SecureStorageService | ✅ Implemented | Token and user data storage available |
| AppErrorHandler | ✅ Implemented | Centralized error handling in place |
| AppColors | ✅ Implemented | Dark theme colors defined |
| GitHubApiService | ⚠️ Partial | Base methods exist, Sprint 15 methods missing |

---

## Task-by-Task Architecture Review

### Task 15.1: Assignee Picker

**Requirement:** Use GitHub API `GET /repos/{owner}/{repo}/assignees`, cache for 5 minutes, work offline, queue operations.

#### Current Implementation Status: NOT STARTED

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart`

**Current Code (Lines 871-947):**
```dart
void _showAssigneeDialog() {
  showModalBottomSheet(
    context: context,
    // ... shows only current assignee with remove option
  );
}

Future<void> _addAssignee() async {
  _showErrorSnackBar('Assignee selection coming soon'); // STUB!
}
```

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| GitHub API: GET /assignees | ❌ Missing | `fetchRepoCollaborators()` exists but returns collaborators, not assignees specifically |
| Cache results (5 min) | ❌ Missing | No caching implemented for assignees |
| Work offline (cached) | ❌ Missing | No offline fallback |
| Queue operations offline | ❌ Missing | `_addAssignee()` is a stub |

#### Existing Infrastructure

**GitHubApiService** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/github_api_service.dart`, Lines 676-701):
```dart
/// Fetch collaborators for a repository
Future<List<Map<String, dynamic>>> fetchRepoCollaborators(
  String owner,
  String repo,
) async {
  try {
    debugPrint('Fetching collaborators for $owner/$repo...');
    final headers = await _headers;

    final response = await http
        .get(
          Uri.parse(
            'https://api.github.com/repos/$owner/$repo/collaborators',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> collaboratorsData = json.decode(response.body);
      return collaboratorsData.cast<Map<String, dynamic>>();
    }
    // ... error handling
  }
}
```

**Note:** GitHub's API documentation states that collaborators can be assigned to issues, so `fetchRepoCollaborators()` can serve as the assignee endpoint. However, it lacks:
- Caching with 5-minute TTL
- Network connectivity check before API call
- Offline fallback to cached data

**PendingOperation** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/models/pending_operation.dart`, Lines 154-168):
```dart
factory PendingOperation.updateAssignee({
  required String id,
  required int issueNumber,
  required String owner,
  required String repo,
  required String? assignee,
}) {
  return PendingOperation(
    id: id,
    type: OperationType.updateAssignee,
    issueNumber: issueNumber,
    owner: owner,
    repo: repo,
    data: {'assignee': assignee},
    createdAt: DateTime.now(),
  );
}
```

**Status:** Operation type defined but not integrated into UI flow.

#### Recommendations

1. **Add caching to `fetchRepoCollaborators()`:**
```dart
// Check cache first
final cacheKey = 'assignees_${owner}_$repo';
final cachedAssignees = _cache.get<List>(cacheKey);
if (cachedAssignees != null) {
  return cachedAssignees.cast<Map<String, dynamic>>();
}
// ... fetch from API ...
// Cache for 5 minutes
await _cache.set(cacheKey, assignees, ttl: const Duration(minutes: 5));
```

2. **Implement `_addAssignee()` with network check:**
```dart
Future<void> _addAssignee() async {
  final isOnline = await _networkService.checkConnectivity();
  
  if (!isOnline) {
    // Show cached assignees only, queue selection
    _showAssigneePicker(offline: true);
  } else {
    // Fetch fresh assignees
    _showAssigneePicker(offline: false);
  }
}
```

3. **Queue assignee changes when offline:**
```dart
if (!isOnline) {
  final operation = PendingOperation.updateAssignee(
    id: 'assignee_${issue.id}_${DateTime.now().millisecondsSinceEpoch}',
    issueNumber: issue.number!,
    owner: owner,
    repo: repo,
    assignee: selectedAssignee,
  );
  await _pendingOps.addOperation(operation);
}
```

---

### Task 15.2: Label Picker

**Requirement:** Use GitHub API `GET /repos/{owner}/{repo}/labels`, cache for 5 minutes, work offline, queue operations.

#### Current Implementation Status: NOT STARTED

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart`

**Current Code (Lines 948-1019):**
```dart
void _showLabelsDialog() {
  showModalBottomSheet(
    // ... shows current labels
    // "Add Label" button calls _addLabel() which shows text input
  );
}

Future<void> _addLabel() async {
  _showErrorSnackBar('Label selection coming soon'); // STUB!
}
```

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| GitHub API: GET /labels | ⚠️ Partial | `fetchRepoLabels()` exists but not used in UI |
| Cache results (5 min) | ❌ Missing | No caching implemented |
| Work offline (cached) | ❌ Missing | No offline fallback |
| Queue operations offline | ❌ Missing | `_addLabel()` is a stub |

#### Existing Infrastructure

**GitHubApiService** (Lines 643-674):
```dart
/// Fetch available labels for a repository
Future<List<Map<String, dynamic>>> fetchRepoLabels(
  String owner,
  String repo,
) async {
  try {
    debugPrint('Fetching labels for $owner/$repo...');
    final headers = await _headers;

    final response = await http
        .get(
          Uri.parse('https://api.github.com/repos/$owner/$repo/labels'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> labelsData = json.decode(response.body);
      return labelsData.cast<Map<String, dynamic>>();
    }
    // ... error handling
  }
}
```

**Issue:** Method exists but lacks caching and network check.

**PendingOperation** (Lines 137-152):
```dart
factory PendingOperation.updateLabels({
  required String id,
  required int issueNumber,
  required String owner,
  required String repo,
  required List<String> labels,
}) {
  return PendingOperation(
    id: id,
    type: OperationType.updateLabels,
    issueNumber: issueNumber,
    owner: owner,
    repo: repo,
    data: {'labels': labels},
    createdAt: DateTime.now(),
  );
}
```

**Status:** Operation type defined but not integrated.

#### Recommendations

1. **Add caching to `fetchRepoLabels()`:**
```dart
final cacheKey = 'labels_${owner}_$repo';
final cachedLabels = _cache.get<List>(cacheKey);
if (cachedLabels != null) {
  return cachedLabels.cast<Map<String, dynamic>>();
}
// ... fetch and cache ...
```

2. **Implement label picker UI with multi-select:**
```dart
void _showLabelsDialog() {
  // Fetch repo labels (cached)
  // Show as selectable chips with checkboxes
  // Allow multi-select
  // Save changes via API or queue
}
```

3. **Queue label changes when offline:**
```dart
final operation = PendingOperation.updateLabels(
  id: 'labels_${issue.id}_${DateTime.now().millisecondsSinceEpoch}',
  issueNumber: issue.number!,
  owner: owner,
  repo: repo,
  labels: selectedLabels,
);
```

---

### Task 15.3: My Issues Filter

**Requirement:** Get current user login from SecureStorageService or GitHub API, filter issues where `assignee.login == currentLogin`, work offline.

#### Current Implementation Status: NOT STARTED

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/search_screen.dart`

**Current Code (Lines 475-485):**
```dart
// Apply quick filters
final quickFiltered = authorFiltered.where((issue) {
  // My Issues filter
  if (_filterMyIssues) {
    // You'll need to get current user login - for now use placeholder
    // In production, fetch from auth service
    final currentLogin = 'current_user'; // TODO: Get from auth
    if (issue.assigneeLogin != currentLogin) return false;
  }
  // ...
});
```

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Get user from SecureStorage/GitHub API | ⚠️ Partial | `getCurrentUser()` exists, `getUserData()` exists |
| Filter by assignee.login | ❌ Missing | Uses hardcoded placeholder |
| Work offline (cached) | ❌ Missing | No cached user fallback |

#### Existing Infrastructure

**GitHubApiService** (Lines 703-728):
```dart
/// Get current user info
Future<Map<String, dynamic>?> getCurrentUser() async {
  try {
    final headers = await _headers;
    final response = await http
        .get(Uri.parse('https://api.github.com/user'), headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      return userData;
    }
    // ... error handling
  }
}
```

**LocalStorageService** (Lines 234-250):
```dart
/// Save user data locally
Future<void> saveUserData(Map<String, dynamic> userData) async {
  try {
    await _storage.write(key: _userKey, value: json.encode(userData));
  }
}

/// Get saved user data
Future<Map<String, dynamic>?> getUserData() async {
  try {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    return json.decode(userJson);
  }
}
```

**SettingsScreen** already uses this pattern (Lines 106-145):
```dart
Future<void> _loadUserData() async {
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
```

#### Recommendations

1. **Fetch user at SearchScreen initialization:**
```dart
String? _currentLogin;
bool _isLoadingUser = true;

@override
void initState() {
  super.initState();
  _loadCurrentUser();
}

Future<void> _loadCurrentUser() async {
  // Try cached first (offline support)
  final cachedUser = await _localStorage.getUserData();
  if (cachedUser != null) {
    setState(() {
      _currentLogin = cachedUser['login'] as String;
      _isLoadingUser = false;
    });
  }
  
  // Then fetch fresh
  try {
    final user = await _githubApi.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentLogin = user['login'] as String;
      });
      await _localStorage.saveUserData(user);
    }
  } catch (e) {
    // Use cached if available
  }
}
```

2. **Use actual login in filter:**
```dart
if (_filterMyIssues && _currentLogin != null) {
  if (issue.assigneeLogin != _currentLogin) return false;
}
```

3. **Show loading state when user not loaded:**
```dart
if (_isLoadingUser) {
  return Center(child: BrailleLoader(size: 24));
}
```

---

### Task 15.4: Project Picker

**Requirement:** Use existing project fetching logic, show user's projects, allow selection and save to settings.

#### Current Implementation Status: PARTIAL

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/settings_screen.dart`

**Current Code (Lines 355-375):**
```dart
Widget _buildDefaultProjectTile() {
  return Card(
    // ...
    subtitle: Text(
      _defaultProject, // Hardcoded 'Mobile Development'
    ),
    onTap: _changeDefaultProject, // Method needs implementation
  );
}

// Method declaration missing - needs implementation
```

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Use existing project fetching | ✅ Available | `fetchProjects()` exists with caching |
| Show user's projects | ❌ Missing | No project picker dialog |
| Allow selection | ❌ Missing | No selection UI |
| Save to settings | ✅ Available | `saveDefaultProject()` exists |

#### Existing Infrastructure

**GitHubApiService** (Lines 730-795):
```dart
/// Fetch user's Projects v2 using GraphQL
Future<List<Map<String, dynamic>>> fetchProjects({int first = 30}) async {
  try {
    // Check cache first
    final cacheKey = 'projects_$first';
    final cachedProjects = _cache.get<List>(cacheKey);
    if (cachedProjects != null) {
      return cachedProjects.cast<Map<String, dynamic>>();
    }
    // ... GraphQL query ...
    // Cache for 5 minutes
    await _cache.set(cacheKey, projects, ttl: const Duration(minutes: 5));
    return projects.cast<Map<String, dynamic>>();
  }
}
```

**LocalStorageService** (Lines 437-461):
```dart
/// Save default project for issue creation
Future<void> saveDefaultProject(String projectName) async {
  await _storage.write(key: 'default_project', value: projectName);
}

/// Get default project for issue creation
Future<String?> getDefaultProject() async {
  final project = await _storage.read(key: 'default_project');
  return project;
}
```

**SettingsScreen** (Lines 93-98):
```dart
Future<void> _loadDefaultRepo() async {
  final savedRepo = await _localStorage.getDefaultRepo();
  if (savedRepo != null && mounted) {
    setState(() {
      _defaultRepo = savedRepo;
    });
  }
}
```

**Note:** Similar pattern needed for projects.

#### Recommendations

1. **Add state and load default project:**
```dart
String _defaultProject = 'Mobile Development'; // Fallback

@override
void initState() {
  super.initState();
  _loadDefaultRepo();
  _loadDefaultProject(); // Add this
}

Future<void> _loadDefaultProject() async {
  final savedProject = await _localStorage.getDefaultProject();
  if (savedProject != null && mounted) {
    setState(() {
      _defaultProject = savedProject;
    });
  }
}
```

2. **Implement `_changeDefaultProject()`:**
```dart
Future<void> _changeDefaultProject() async {
  // Check network
  final isOnline = await _networkService.checkConnectivity();
  
  List<Map<String, dynamic>> projects;
  
  if (!isOnline) {
    // Use cached projects
    projects = await _localStorage.getSyncedProjects();
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cached projects available')),
      );
      return;
    }
  } else {
    // Fetch fresh
    projects = await _githubApi.fetchProjects();
    // Cache for offline use
    await _localStorage.saveSyncedProjects(projects);
  }
  
  // Show picker dialog
  final selected = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text('Select Project'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ListTile(
              title: Text(project['title'] as String),
              onTap: () => Navigator.pop(context, project['title'] as String),
            );
          },
        ),
      ),
    ),
  );
  
  if (selected != null) {
    await _localStorage.saveDefaultProject(selected);
    setState(() {
      _defaultProject = selected;
    });
  }
}
```

---

## Cross-Cutting Concerns Review

### 1. Network Connectivity Checks

**Status:** INCONSISTENT

**Good Example** (IssueDetailScreen, Line 784):
```dart
// CHECK NETWORK
final isOnline = await _networkService.checkConnectivity();

if (!isOnline) {
  // Queue operation
  final operation = PendingOperation(...);
  await _pendingOps.addOperation(operation);
} else {
  // Online - call API
  await _githubApi.updateIssue(...);
}
```

**Issue:** `fetchRepoLabels()` and `fetchRepoCollaborators()` don't check network before calling API. They will throw exceptions when offline instead of returning cached data.

**Recommendation:** Add network check at start of all API methods:
```dart
Future<List<Map<String, dynamic>>> fetchRepoLabels(...) async {
  final isOnline = await NetworkService().checkConnectivity();
  
  // Try cache first (works offline)
  final cached = _cache.get<List>(cacheKey);
  if (cached != null) return cached.cast<Map<String, dynamic>>();
  
  if (!isOnline) {
    throw Exception('No network connection and no cached data available');
  }
  
  // ... fetch from API ...
}
```

### 2. Caching Strategy

**Status:** AVAILABLE BUT UNDERUTILIZED

**CacheService** provides 5-minute TTL:
```dart
await _cache.set(key, value, ttl: const Duration(minutes: 5));
final cached = _cache.get<List>(key);
```

**Issue:** Only `fetchMyRepositories()`, `fetchIssues()`, and `fetchProjects()` use caching. Sprint 15 methods need caching added.

**Recommendation:** Add caching to:
- `fetchRepoLabels()` - cache key: `labels_${owner}_$repo`
- `fetchRepoCollaborators()` - cache key: `assignees_${owner}_$repo`
- `getCurrentUser()` - cache key: `current_user`

### 3. Offline Operation Queuing

**Status:** INFRASTRUCTURE READY, NOT INTEGRATED

**PendingOperationsService** supports:
- `OperationType.updateLabels`
- `OperationType.updateAssignee`

**SyncService** has handlers (Lines 720-742, 807-825):
```dart
case OperationType.updateLabels:
  await _executeUpdateLabels(operation);

case OperationType.updateAssignee:
  // Handler needs implementation
```

**Issue:** UI doesn't queue operations when offline.

**Recommendation:** Update `_addLabel()` and `_addAssignee()` to:
```dart
final isOnline = await _networkService.checkConnectivity();

if (!isOnline) {
  final operation = PendingOperation.updateLabels(...);
  await _pendingOps.addOperation(operation);
  _showSnackBar('Changes queued for sync');
} else {
  await _githubApi.updateIssue(...);
}
```

### 4. Error Handling

**Status:** GOOD

**AppErrorHandler** is consistently used:
```dart
catch (e, stackTrace) {
  AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
}
```

**Recommendation:** Continue using this pattern. Consider adding specific error messages for offline scenarios.

### 5. Dark Theme Compliance

**Status:** EXCELLENT

**AppColors** is consistently used throughout:
```dart
backgroundColor: AppColors.background,
color: AppColors.orangePrimary,
```

**Recommendation:** No changes needed. Continue using AppColors for all new UI.

---

## API Usage Review

### GitHub API Endpoints

| Endpoint | Current Status | Sprint 15 Requirement |
|----------|---------------|----------------------|
| `GET /repos/{owner}/{repo}/labels` | ✅ Implemented | Task 15.2 |
| `GET /repos/{owner}/{repo}/collaborators` | ✅ Implemented | Task 15.1 (as assignees) |
| `GET /user` | ✅ Implemented | Task 15.3 |
| `POST /graphql` (Projects V2) | ✅ Implemented | Task 15.4 |

### API Best Practices Compliance

| Practice | Status | Notes |
|----------|--------|-------|
| Authentication headers | ✅ | All methods use `_headers` with token |
| Timeout handling | ✅ | 10-15 second timeouts configured |
| Retry logic | ✅ | `_executeWithRetry()` with exponential backoff |
| Error parsing | ✅ | JSON error responses parsed |
| Rate limit awareness | ⚠️ | 403 errors handled but no rate limit tracking |

**Recommendation:** Add rate limit tracking:
```dart
// Check rate limit headers
final remaining = response.headers['x-ratelimit-remaining'];
if (remaining != null && int.parse(remaining) < 10) {
  debugPrint('Warning: Rate limit nearly exhausted');
}
```

---

## State Management Review (Riverpod)

**Status:** MINIMAL USAGE

**Current Usage:**
- `githubApiService` provider (Lines 1195-1198)
- `localStorageService` provider

**Issue:** Screens create service instances directly instead of using providers:
```dart
final GitHubApiService _githubApi = GitHubApiService(); // Direct instantiation
```

**Recommendation:** Consider using Riverpod more extensively for:
- Current user state
- Cached assignees/labels
- Network status

Example:
```dart
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.read(githubApiServiceProvider).getCurrentUser();
});

// In widget:
final user = ref.watch(currentUserProvider);
```

---

## Offline-First Architecture Review

**Status:** PARTIAL

### What Works Well

1. **LocalStorageService** saves user data, projects, and settings
2. **CacheService** provides 5-minute TTL caching
3. **PendingOperationsService** queues operations for later sync
4. **NetworkService** provides connectivity checks

### Gaps

1. **Assignees/Labels not cached** - Will fail when offline
2. **User login not cached for search** - "My Issues" filter won't work offline
3. **Projects partially cached** - `fetchProjects()` caches but settings doesn't use cached version

### Recommendations

1. **Implement cache-first strategy:**
```dart
Future<List<Map<String, dynamic>>> fetchRepoLabels(...) async {
  // 1. Return cached immediately if available
  final cached = _cache.get<List>(cacheKey);
  if (cached != null) return cached.cast<Map<String, dynamic>>();
  
  // 2. Check network
  final isOnline = await NetworkService().checkConnectivity();
  if (!isOnline) {
    throw Exception('Offline and no cached data');
  }
  
  // 3. Fetch fresh
  // ... API call ...
  
  // 4. Cache for next time
  await _cache.set(cacheKey, labels, ttl: const Duration(minutes: 5));
  return labels;
}
```

2. **Add offline indicators to UI:**
```dart
if (!isOnline) {
  // Show cached data badge
  Text('SHOWING CACHED DATA - LAST SYNC 5m ago')
}
```

---

## Security Review

**Status:** GOOD

### Secure Storage

**SecureStorageService** properly uses `flutter_secure_storage`:
```dart
static final FlutterSecureStorage _instance = const FlutterSecureStorage(
  aOptions: AndroidOptions(),
);
```

### Token Handling

- Tokens stored in secure storage (encrypted)
- Tokens passed via Authorization header (not in URL)
- Token cleared on logout

### Recommendations

1. **Add token expiry check:**
```dart
Future<bool> isTokenValid() async {
  final user = await getCurrentUser();
  return user != null;
}
```

2. **Handle 401 errors gracefully:**
```dart
if (response.statusCode == 401) {
  await SecureStorageService.deleteToken();
  // Navigate to login
}
```

---

## Performance Considerations

### Current Performance Patterns

**Good:**
- Debounced search (500ms) in SearchScreen
- Pagination support in `fetchMyRepositories()`
- Caching reduces API calls

**Concerns:**
- `fetchRepoCollaborators()` and `fetchRepoLabels()` called every time dialogs open
- No pagination for labels/assignees (could be many)
- Search screen fetches all repos (up to 100) before filtering

### Recommendations

1. **Add pagination to assignees/labels:**
```dart
Future<List<Map<String, dynamic>>> fetchRepoCollaborators(
  String owner,
  String repo, {
  int page = 1,
  int perPage = 30,
}) async {
  // ...
}
```

2. **Lazy load assignees/labels:**
```dart
// Don't fetch until dialog opens
void _showAssigneeDialog() {
  // Fetch on-demand
  _fetchAssignees();
}
```

3. **Add search/filter to assignee/label pickers:**
```dart
// For repos with many assignees/labels
TextField(
  onChanged: (query) {
    // Filter cached list
  },
)
```

---

## Testing Recommendations

### Unit Tests Needed

1. **CacheService tests:**
   - Verify 5-minute TTL
   - Verify expiry handling
   - Verify null on cache miss

2. **PendingOperationsService tests:**
   - Verify operation queuing
   - Verify status updates
   - Verify serialization/deserialization

3. **GitHubApiService tests:**
   - Mock HTTP responses
   - Test retry logic
   - Test error handling

### Integration Tests Needed

1. **Offline flow:**
   - Turn off network
   - Open assignee picker
   - Verify cached data shown
   - Select assignee
   - Verify operation queued
   - Turn on network
   - Verify sync completes

2. **"My Issues" filter:**
   - Login as user A
   - Filter by "My Issues"
   - Verify only user A's issues shown

---

## Summary of Required Changes

### Task 15.1: Assignee Picker

| File | Change | Priority |
|------|--------|----------|
| `github_api_service.dart` | Add caching to `fetchRepoCollaborators()` | HIGH |
| `issue_detail_screen.dart` | Implement `_addAssignee()` with network check | HIGH |
| `issue_detail_screen.dart` | Add assignee picker UI with list | HIGH |
| `issue_detail_screen.dart` | Queue assignee changes when offline | HIGH |

### Task 15.2: Label Picker

| File | Change | Priority |
|------|--------|----------|
| `github_api_service.dart` | Add caching to `fetchRepoLabels()` | HIGH |
| `issue_detail_screen.dart` | Implement `_addLabel()` with network check | HIGH |
| `issue_detail_screen.dart` | Add label picker UI with multi-select | HIGH |
| `issue_detail_screen.dart` | Queue label changes when offline | HIGH |

### Task 15.3: My Issues Filter

| File | Change | Priority |
|------|--------|----------|
| `search_screen.dart` | Add `_currentLogin` state variable | HIGH |
| `search_screen.dart` | Load user from cache/API at init | HIGH |
| `search_screen.dart` | Use actual login in filter logic | HIGH |
| `search_screen.dart` | Add loading state for user fetch | MEDIUM |

### Task 15.4: Project Picker

| File | Change | Priority |
|------|--------|----------|
| `settings_screen.dart` | Add `_loadDefaultProject()` method | MEDIUM |
| `settings_screen.dart` | Implement `_changeDefaultProject()` dialog | MEDIUM |
| `settings_screen.dart` | Show project list from API/cache | MEDIUM |
| `settings_screen.dart` | Save selection to LocalStorageService | MEDIUM |

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| GitHub API rate limits | HIGH | MEDIUM | Implement caching, add rate limit tracking |
| Large repos (1000+ labels/assignees) | MEDIUM | LOW | Add pagination, search/filter UI |
| Token expiry during operation | MEDIUM | LOW | Handle 401 errors, re-authenticate |
| Sync conflicts (offline changes) | HIGH | MEDIUM | Already handled by ConflictDetectionService |
| Network flakiness | MEDIUM | HIGH | Retry logic already in place |

---

## Conclusion

The codebase has excellent architectural foundations for Sprint 15:

**Strengths:**
- Well-designed service layer (NetworkService, CacheService, PendingOperationsService)
- Consistent error handling with AppErrorHandler
- Dark theme properly enforced with AppColors
- Operation types already defined for labels and assignees
- Sync infrastructure in place

**Gaps:**
- Sprint 15 features not implemented (stubs/TODOs)
- Caching not applied to assignees/labels
- Network checks not consistent across all API calls
- "My Issues" filter uses hardcoded placeholder
- Project picker dialog not implemented

**Recommendation:** Proceed with implementation following the patterns established in the codebase. The architecture is sound and ready to support Sprint 15 features.

---

**Reviewed by:** System Architect
**Date:** March 2, 2026
**Next Steps:** Flutter Developer should begin implementation following recommendations above

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
