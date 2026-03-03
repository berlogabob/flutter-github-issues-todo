# Sprint 16: Architecture Review

**Review Date:** March 2, 2026
**Reviewer:** System Architect
**Status:** READY FOR IMPLEMENTATION
**Sprint Goal:** Implement performance optimizations for large datasets and improved user experience

---

## Executive Summary

This review evaluates the current codebase architecture against Sprint 16 performance optimization requirements. The existing architecture provides a **solid foundation** with well-designed services for caching, synchronization, and API communication. However, **none of the five main Sprint 16 tasks have been implemented yet** - they remain as planned features in `SPRINT16_PROGRESS.md`.

### Overall Architecture Compliance: PARTIAL

| Component | Status | Sprint 16 Readiness | Notes |
|-----------|--------|---------------------|-------|
| GitHubApiService | ✅ Implemented | ⚠️ Partial | Pagination params exist in `fetchMyRepositories()` but not consistently used |
| CacheService | ✅ Implemented | ✅ Ready | TTL-based caching available, needs image cache extension |
| SyncService | ✅ Implemented | ⚠️ Partial | Manual sync works, background sync not configured |
| ListView.builder | ✅ Verified | ✅ Ready | Already in use across 10 files |
| AppColors | ✅ Implemented | ✅ Ready | Dark theme colors defined and consistently used |
| BrailleLoader | ✅ Implemented | ⚠️ Replace | Should be replaced with skeletons for list loading |

---

## Task-by-Task Architecture Review

### Task 16.1: Pagination (Cursor-Based)

**Requirement:** Implement cursor-based pagination for repos and issues with "Load More" button, cache each page separately, work offline.

#### Current Implementation Status: PARTIAL

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/github_api_service.dart`

**Current Code (Lines 133-199):**
```dart
/// Fetch current user's repositories
Future<List<RepoItem>> fetchMyRepositories({
  int page = 1,
  int perPage = 30,
}) async {
  try {
    debugPrint(
      'fetchMyRepositories() called - page: $page, perPage: $perPage',
    );

    // Check cache first
    final cacheKey = 'repos_page_${page}_perPage_$perPage';
    final cachedRepos = _cache.get<List>(cacheKey);
    if (cachedRepos != null) {
      debugPrint('Cache hit for repositories');
      return cachedRepos
          .map((json) => RepoItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    // ... API call with pagination params ...
    final uri = Uri.parse(
      'https://api.github.com/user/repos?sort=updated&per_page=$perPage&page=$page',
    );
    // ... cache result for 5 minutes ...
    await _cache.set(
      cacheKey,
      repos.map((r) => r.toJson()).toList(),
      ttl: const Duration(minutes: 5),
    );
  }
}
```

**Status:** ✅ Pagination already implemented for `fetchMyRepositories()` with:
- `page` and `perPage` parameters
- Per-page caching with key: `repos_page_${page}_perPage_$perPage`
- 5-minute TTL

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Pagination for repos | ✅ Implemented | `fetchMyRepositories()` has page/perPage params |
| Pagination for issues | ❌ Missing | `fetchIssues()` lacks page/perPage params |
| "Load More" button | ❌ Missing | UI not implemented |
| Cache each page separately | ✅ Implemented | Cache key includes page number |
| Work offline (cached pages) | ⚠️ Partial | Cache exists but needs offline-first logic |

#### Issues API - Missing Pagination

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/github_api_service.dart` (Lines 228-271)

**Current Code:**
```dart
/// Fetch issues from a repository
Future<List<IssueItem>> fetchIssues(
  String owner,
  String repo, {
  String state = 'open',
}) async {
  // ...
  final response = await http
      .get(
        Uri.parse(
          'https://api.github.com/repos/$owner/$repo/issues?state=$state&per_page=50',
        ),
        headers: headers,
      )
      .timeout(const Duration(seconds: 10));
  // ...
}
```

**Issue:** Hardcoded `per_page=50`, no `page` parameter, no caching.

#### Recommendations

1. **Add pagination to `fetchIssues()`:**
```dart
Future<List<IssueItem>> fetchIssues(
  String owner,
  String repo, {
  String state = 'open',
  int page = 1,
  int perPage = 30,
}) async {
  // Check cache first
  final cacheKey = 'issues_${owner}_${repo}_${state}_page_${page}_per_${perPage}';
  final cachedIssues = _cache.get<List>(cacheKey);
  if (cachedIssues != null) {
    return cachedIssues
        .map((json) => IssueItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Check network
  final isOnline = await NetworkService().checkConnectivity();
  if (!isOnline) {
    throw Exception('No network connection and no cached data available');
  }

  // Fetch from API
  final uri = Uri.parse(
    'https://api.github.com/repos/$owner/$repo/issues?state=$state&page=$page&per_page=$perPage',
  );
  // ... rest of implementation ...

  // Cache for 5 minutes
  await _cache.set(
    cacheKey,
    issues.map((i) => i.toJson()).toList(),
    ttl: const Duration(minutes: 5),
  );
  return issues;
}
```

2. **Implement "Load More" in UI (MainDashboardScreen):**
```dart
// In _RepositoriesTab
int _currentPage = 1;
bool _isLoadingMore = false;
bool _hasMoreRepos = true;

Future<void> _loadMoreRepos() async {
  if (_isLoadingMore || !_hasMoreRepos) return;

  setState(() => _isLoadingMore = true);

  try {
    _currentPage++;
    final newRepos = await _githubApi.fetchMyRepositories(
      page: _currentPage,
      perPage: 30,
    );

    setState(() {
      _userRepos.addAll(newRepos);
      _hasMoreRepos = newRepos.length == 30; // If < 30, no more pages
      _isLoadingMore = false;
    });
  } catch (e) {
    setState(() => _isLoadingMore = false);
    AppErrorHandler.handle(e, context: context);
  }
}

// In ListView.builder
ListView.builder(
  itemCount: _userRepos.length + (_hasMoreRepos ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == _userRepos.length) {
      return _buildLoadMoreTile();
    }
    return _buildRepoTile(_userRepos[index]);
  },
)
```

3. **Add offline-first support:**
```dart
// Always try cache first, even when online
final cachedRepos = _cache.get<List>(cacheKey);
if (cachedRepos != null) {
  // Return cached immediately for instant UI
  return cachedRepos;
}

// Then fetch fresh in background
final freshRepos = await _fetchFromApi();
// Update cache
await _cache.set(cacheKey, freshRepos);
return freshRepos;
```

---

### Task 16.2: Image Caching

**Requirement:** Use `cached_network_image` package OR implement simple file cache, cache avatar images from GitHub, set cache size limit (10MB max), implement LRU eviction, work offline.

#### Current Implementation Status: NOT STARTED

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart` (Lines 645-660)

**Current Code:**
```dart
CircleAvatar(
  radius: 12.r,
  backgroundColor: AppColors.orangeSecondary,
  backgroundImage: avatarUrl != null
      ? NetworkImage(avatarUrl)  // ❌ No caching!
      : null,
  child: avatarUrl == null
      ? Text(
          login.isNotEmpty ? login[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        )
      : null,
)
```

**Files using avatars without caching:**
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart` (Lines 645, 948)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/create_issue_screen.dart` (Lines 476-482)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/settings_screen.dart` (Lines 286-308)

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Use cached_network_image OR file cache | ❌ Missing | Currently using `NetworkImage` directly |
| Cache avatar images | ❌ Missing | No caching implemented |
| Cache size limit (10MB) | ❌ Missing | No size tracking |
| LRU eviction | ❌ Missing | No eviction policy |
| Work offline (cached images) | ❌ Missing | Images fail when offline |

#### Existing Infrastructure

**CacheService** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/cache_service.dart`):
```dart
/// Cache service with TTL support
class CacheService {
  late Box<String> _cache;

  T? get<T>(String key) {
    // Gets cached value with TTL check
  }

  Future<void> set<T>(String key, T value, {Duration ttl = const Duration(minutes: 5)}) async {
    // Sets cached value with expiry
  }
}
```

**Issue:** CacheService uses Hive for key-value storage, suitable for JSON/metadata but not ideal for binary image data.

#### Recommendations

**Option A: Use `cached_network_image` Package (RECOMMENDED)**

1. **Add dependency to `pubspec.yaml`:**
```yaml
dependencies:
  cached_network_image: ^3.3.1
  flutter_cache_manager: ^3.3.1  # Required by cached_network_image
```

2. **Create custom cache manager with 10MB limit:**
```dart
// lib/utils/image_cache_manager.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheManager {
  static const key = 'customCacheKey';
  
  static final custom = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
```

3. **Replace CircleAvatar with CachedNetworkImage:**
```dart
// In issue_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';

CircleAvatar(
  radius: 12.r,
  backgroundColor: AppColors.orangeSecondary,
  child: CachedNetworkImage(
    imageUrl: avatarUrl,
    imageBuilder: (context, imageProvider) => CircleAvatar(
      radius: 12.r,
      backgroundImage: imageProvider,
    ),
    placeholder: (context, url) => CircleAvatar(
      radius: 12.r,
      backgroundColor: AppColors.orangeSecondary,
      child: Icon(Icons.person, size: 12.r, color: Colors.white),
    ),
    errorWidget: (context, url, error) => CircleAvatar(
      radius: 12.r,
      backgroundColor: AppColors.orangeSecondary,
      child: Text(
        login.isNotEmpty ? login[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 10.sp, color: Colors.white),
      ),
    ),
  ),
)
```

**Option B: Implement Custom File Cache (if avoiding new dependencies)**

```dart
// lib/services/image_cache_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

class ImageCacheService {
  static const int _maxCacheSizeMB = 10;
  static const int _maxCacheSizeBytes = _maxCacheSizeMB * 1024 * 1024;

  late Box<Map> _metadataBox; // Stores URL -> {path, size, lastAccess}
  String? _cacheDir;

  Future<void> init() async {
    _metadataBox = await Hive.openBox('image_cache_metadata');
    final dir = await getTemporaryDirectory();
    _cacheDir = '${dir.path}/image_cache';
    await Directory(_cacheDir!).create(recursive: true);
  }

  Future<String?> getCachedImagePath(String url) async {
    final key = _hashUrl(url);
    final metadata = _metadataBox.get(key);
    
    if (metadata == null) return null;
    
    final path = metadata['path'] as String;
    final file = File(path);
    
    if (!await file.exists()) {
      _metadataBox.delete(key);
      return null;
    }
    
    // Update last access time for LRU
    await _metadataBox.put(key, {
      ...metadata,
      'lastAccess': DateTime.now().millisecondsSinceEpoch,
    });
    
    return path;
  }

  Future<void> cacheImage(String url, Uint8List imageData) async {
    final key = _hashUrl(url);
    final filename = '$key.jpg';
    final path = '$_cacheDir/$filename';
    
    final file = await File(path).writeAsBytes(imageData);
    final size = await file.length();
    
    // Check if cache exceeds limit
    await _enforceCacheLimit(size);
    
    // Store metadata
    await _metadataBox.put(key, {
      'path': path,
      'size': size,
      'lastAccess': DateTime.now().millisecondsSinceEpoch,
      'url': url,
    });
  }

  Future<void> _enforceCacheLimit(int newSize) async {
    int totalSize = await _calculateCacheSize();
    
    while (totalSize + newSize > _maxCacheSizeBytes) {
      // Find LRU entry
      String? lruKey;
      int? lruTime;
      
      for (final entry in _metadataBox.entries) {
        final metadata = entry.value as Map;
        final lastAccess = metadata['lastAccess'] as int;
        if (lruTime == null || lastAccess < lruTime) {
          lruTime = lastAccess;
          lruKey = entry.key as String;
        }
      }
      
      if (lruKey == null) break;
      
      // Delete LRU entry
      final metadata = _metadataBox.get(lruKey) as Map;
      final path = metadata['path'] as String;
      await File(path).delete();
      await _metadataBox.delete(lruKey);
      
      totalSize = await _calculateCacheSize();
    }
  }

  String _hashUrl(String url) {
    // Simple hash for filename
    return url.hashCode.abs().toString();
  }

  Future<int> _calculateCacheSize() async {
    int total = 0;
    for (final entry in _metadataBox.entries) {
      final metadata = entry.value as Map;
      final path = metadata['path'] as String;
      final file = File(path);
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }
}
```

---

### Task 16.3: Background Sync

**Requirement:** Use workmanager package for background tasks, sync every 15 minutes when on WiFi, sync only if there are pending operations, respect user settings (auto-sync on WiFi/any), must not drain battery.

#### Current Implementation Status: PARTIAL

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/services/sync_service.dart`

**Current Code (Lines 283-308):**
```dart
/// Trigger auto-sync when network becomes available (with debounce)
Future<void> _triggerAutoSync() async {
  // Cancel any pending auto-sync
  _autoSyncTimer?.cancel();

  // Debounce: wait 2 seconds before syncing
  _autoSyncTimer = Timer(const Duration(seconds: 2), () async {
    if (!_isSyncing && _isNetworkAvailable) {
      debugPrint('SyncService: Starting auto-sync');
      await syncAll(forceRefresh: false);
    }
  });
}
```

**Current Settings Screen** (`/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/settings_screen.dart`, Lines 425-453):
```dart
Widget _buildAutoSyncWifiTile() {
  return Card(
    color: AppColors.cardBackground,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: SwitchListTile(
      secondary: const Icon(Icons.wifi, color: AppColors.orangePrimary),
      title: const Text('Auto-sync on WiFi', style: TextStyle(color: Colors.white)),
      subtitle: Text('Automatically sync when on WiFi', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      value: _autoSyncWifi,
      activeThumbColor: AppColors.orangePrimary,
      onChanged: (value) {
        setState(() {
          _autoSyncWifi = value;
          if (value) _autoSyncAny = false;
        });
      },
    ),
  );
}
```

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Use workmanager package | ❌ Missing | Not in pubspec.yaml |
| Sync every 15 minutes | ❌ Missing | Only triggers on network change |
| Sync only if pending operations | ⚠️ Partial | `_processPendingOperations()` exists but not scheduled |
| Respect user settings | ⚠️ Partial | Settings UI exists but not integrated with sync logic |
| Battery efficient | ❌ Missing | No WorkManager constraints configured |

#### Existing Infrastructure

**SyncService** has:
- `_processPendingOperations()` method (Lines 720-760)
- `syncAll()` method (Lines 311-368)
- Network connectivity listener (Lines 228-250)
- User settings state (`_autoSyncWifi`, `_autoSyncAny`)

**Issue:** Settings are not persisted or integrated with sync logic.

#### Recommendations

1. **Add workmanager dependency to `pubspec.yaml`:**
```yaml
dependencies:
  workmanager: ^0.5.2
```

2. **Create background sync service:**
```dart
// lib/services/background_sync_service.dart
import 'package:workmanager/workmanager.dart';
import 'sync_service.dart';
import 'local_storage_service.dart';

const String backgroundSyncTask = 'com.gitdoit.background_sync';
const String backgroundSyncTaskName = 'background_sync';

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final SyncService _syncService = SyncService();
  final LocalStorageService _localStorage = LocalStorageService();

  /// Initialize background sync
  Future<void> initialize() async {
    // Register background callback
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Load user preferences
    final autoSyncWifi = await _localStorage.getAutoSyncWifi();
    final autoSyncAny = await _localStorage.getAutoSyncAny();

    // Cancel existing tasks
    await Workmanager().cancelByUniqueName(backgroundSyncTaskName);

    // Register periodic sync if enabled
    if (autoSyncWifi || autoSyncAny) {
      await Workmanager().registerPeriodicTask(
        backgroundSyncTaskName,
        backgroundSyncTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: autoSyncWifi ? NetworkType.connected : NetworkType.not_required,
          requiresBatteryNotLow: true,
          requiresCharging: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
    }
  }

  /// Update background sync based on user settings
  Future<void> updateSyncSettings({
    required bool autoSyncWifi,
    required bool autoSyncAny,
  }) async {
    // Save settings
    await _localStorage.saveAutoSyncWifi(autoSyncWifi);
    await _localStorage.saveAutoSyncAny(autoSyncAny);

    // Reinitialize with new settings
    await initialize();
  }
}

/// Background callback (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case backgroundSyncTask:
        final syncService = SyncService();
        syncService.init();
        
        // Check if there are pending operations
        final pendingOps = PendingOperationsService();
        await pendingOps.init();
        final operations = pendingOps.getAllOperations();
        
        if (operations.isNotEmpty) {
          debugPrint('BackgroundSync: Found ${operations.length} pending operations');
          await syncService.syncAll(forceRefresh: false);
        } else {
          debugPrint('BackgroundSync: No pending operations, skipping');
        }
        
        break;
    }
    return Future.value(true);
  });
}
```

3. **Update LocalStorageService to persist sync settings:**
```dart
// Add to local_storage_service.dart
Future<void> saveAutoSyncWifi(bool value) async {
  await _storage.write(key: 'auto_sync_wifi', value: value.toString());
}

Future<bool> getAutoSyncWifi() async {
  final value = await _storage.read(key: 'auto_sync_wifi');
  return value == 'true';
}

Future<void> saveAutoSyncAny(bool value) async {
  await _storage.write(key: 'auto_sync_any', value: value.toString());
}

Future<bool> getAutoSyncAny() async {
  final value = await _storage.read(key: 'auto_sync_any');
  return value == 'true';
}
```

4. **Integrate settings with BackgroundSyncService:**
```dart
// In settings_screen.dart
Future<void> _saveSyncSettings() async {
  final backgroundSync = BackgroundSyncService();
  await backgroundSync.updateSyncSettings(
    autoSyncWifi: _autoSyncWifi,
    autoSyncAny: _autoSyncAny,
  );
}

// In _buildAutoSyncWifiTile onChanged
onChanged: (value) async {
  setState(() {
    _autoSyncWifi = value;
    if (value) _autoSyncAny = false;
  });
  await _saveSyncSettings();
}
```

5. **Initialize in main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background sync
  final backgroundSync = BackgroundSyncService();
  await backgroundSync.initialize();
  
  runApp(const GitDoItApp());
}
```

---

### Task 16.4: Large List Optimization

**Requirement:** Use ListView.builder (already in use - verify), add itemExtent for consistent heights, implement caching for expensive widgets, reduce rebuilds with const constructors, profile with DevTools.

#### Current Implementation Status: PARTIAL

**Verification:** ListView.builder is used in 10 files:
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/repo_list.dart` (Line 60)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/settings_screen.dart` (Lines 900, 976)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/main_dashboard_screen.dart` (Line 151)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/debug_screen.dart` (Line 80)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/search_screen.dart` (Line 424)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/project_board_screen.dart` (Line 275)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart` (Lines 938, 1252)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/onboarding_screen.dart` (Line 876)

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Use ListView.builder | ✅ Verified | Used in 10 files |
| Add itemExtent | ❌ Missing | Not used in any ListView.builder |
| Cache expensive widgets | ❌ Missing | No RepaintBoundary or caching |
| Const constructors | ⚠️ Partial | Some widgets use const, many don't |
| Profile with DevTools | ❌ Not done | No baseline measurements |

#### Current Code Example (Missing Optimizations)

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/repo_list.dart` (Lines 55-85):
```dart
@override
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: repos.length,
    itemBuilder: (context, index) {
      final repo = repos[index];
      return ExpandableRepoWidget(repo: repo); // ❌ No itemExtent
    },
  );
}
```

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/issue_card.dart`:
```dart
class IssueCard extends StatelessWidget {
  // ❌ Missing const constructor
  const IssueCard({  // ✅ Actually has const!
    super.key,
    required this.issue,
    this.onTap,
    this.showRepoName = false,
    this.onSwipeRight,
    this.onSwipeLeft,
  });
  // ...
}
```

#### Recommendations

1. **Add itemExtent to all ListView.builder instances:**
```dart
// In repo_list.dart
ListView.builder(
  itemCount: repos.length,
  itemExtent: 80.0, // Estimate based on card height
  addAutomaticKeepAlives: true,
  cacheExtent: 200.0, // Pre-load items off-screen
  itemBuilder: (context, index) {
    final repo = repos[index];
    return ExpandableRepoWidget(repo: repo);
  },
)
```

2. **Add RepaintBoundary for expensive widgets:**
```dart
// In issue_card.dart
@override
Widget build(BuildContext context) {
  return RepaintBoundary(  // ✅ Add this
    child: Dismissible(
      key: Key('issue-${issue.id}'),
      // ... rest of widget
    ),
  );
}
```

3. **Use const constructors everywhere possible:**
```dart
// GOOD - Already done in IssueCard
const IssueCard({super.key, required this.issue, this.onTap});

// BAD - Should be const
Container(  // ❌ Missing const
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  // ...
)

// GOOD
const Container(  // ✅
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  // ...
)
```

4. **Cache expensive widget trees:**
```dart
// In search_result_item.dart
class SearchResultItem extends StatelessWidget {
  const SearchResultItem({super.key, required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // Cache the leading widget
        leading: const RepaintBoundary(  // ✅ Add this
          child: StatusBadge(status: issue.status),
        ),
        // ...
      ),
    );
  }
}
```

5. **Profile with DevTools (Manual Step):**
```bash
# Run app in profile mode
flutter run --profile

# Then:
# 1. Open DevTools: flutter pub global activate devtools
# 2. Navigate to Performance tab
# 3. Record while scrolling lists
# 4. Check for:
#    - Frame rendering time > 16ms (jank)
#    - High widget rebuild counts
#    - Memory spikes during scroll
```

---

### Task 16.5: Loading Skeletons

**Requirement:** Create LoadingSkeleton widget (shimmer effect), replace BrailleLoader with skeletons in lists, skeleton should match content shape, animate opacity (not shimmer color for performance), follow existing dark theme.

#### Current Implementation Status: NOT STARTED

**Current Loading Pattern:**

**File:** `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/braille_loader.dart`:
```dart
class BrailleLoader extends StatefulWidget {
  const BrailleLoader({super.key, this.size = 24.0, this.color});

  @override
  State<BrailleLoader> createState() => _BrailleLoaderState();
}

class _BrailleLoaderState extends State<BrailleLoader>
    with SingleTickerProviderStateMixin {
  // Braille character animation (⠁ → ⠃ → ⠇ → ⠧ → ⠷ → ⠿)
  // Used in 34 locations across the codebase
}
```

**Usage Examples:**
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/search_screen.dart` (Line 291): `const BrailleLoader(size: 32)`
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart` (Lines 139, 598, 925, 1184)
- `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/main_dashboard_screen.dart` (Lines 650, 730)

#### Architecture Compliance Analysis

| Requirement | Status | Gap |
|-------------|--------|-----|
| Create LoadingSkeleton widget | ❌ Missing | Need new widget |
| Shimmer effect | ❌ Missing | Need shimmer animation |
| Replace BrailleLoader in lists | ❌ Missing | Still using BrailleLoader |
| Match content shape | ❌ Missing | Need skeleton variants |
| Animate opacity (not color) | ❌ N/A | Not implemented |
| Follow dark theme | ⚠️ Ready | AppColors available |

#### Recommendations

1. **Create LoadingSkeleton widget with shimmer:**
```dart
// lib/widgets/loading_skeleton.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Loading skeleton with shimmer effect
/// Uses opacity animation for better performance than color animation
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Duration duration;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
```

2. **Create IssueCardSkeleton matching IssueCard layout:**
```dart
// lib/widgets/issue_card_skeleton.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_border_radius.dart';
import 'loading_skeleton.dart';

/// Skeleton for IssueCard - matches exact layout for smooth transition
class IssueCardSkeleton extends StatelessWidget {
  const IssueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBackground.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge Skeleton
          const LoadingSkeleton(width: 20, height: 20),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (2 lines)
                const LoadingSkeleton(width: double.infinity, height: 16),
                const SizedBox(height: 6),
                const LoadingSkeleton(width: 200, height: 16),
                // Metadata
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Labels (3 chips)
                    const LoadingSkeleton(width: 50, height: 18),
                    const SizedBox(width: 6),
                    const LoadingSkeleton(width: 50, height: 18),
                    const SizedBox(width: 6),
                    const LoadingSkeleton(width: 50, height: 18),
                  ],
                ),
              ],
            ),
          ),
          // Chevron
          const LoadingSkeleton(width: 20, height: 20),
        ],
      ),
    );
  }
}
```

3. **Create RepoCardSkeleton:**
```dart
// lib/widgets/repo_card_skeleton.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'loading_skeleton.dart';

class RepoCardSkeleton extends StatelessWidget {
  const RepoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repo name
            const LoadingSkeleton(width: 200, height: 20),
            const SizedBox(height: 8),
            // Description
            const LoadingSkeleton(width: double.infinity, height: 14),
            const SizedBox(height: 4),
            const LoadingSkeleton(width: 150, height: 14),
            const SizedBox(height: 8),
            // Stats
            Row(
              children: [
                const LoadingSkeleton(width: 60, height: 16),
                const SizedBox(width: 16),
                const LoadingSkeleton(width: 60, height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

4. **Replace BrailleLoader with skeletons in lists:**
```dart
// In search_screen.dart
@override
Widget build(BuildContext context) {
  if (_isLoading) {
    // ❌ OLD: Return spinner
    // return const Center(child: BrailleLoader(size: 32));
    
    // ✅ NEW: Return skeleton list
    return ListView.builder(
      itemCount: 5, // Show 5 skeleton items
      itemBuilder: (context, index) {
        return const IssueCardSkeleton();
      },
    );
  }
  
  // ... rest of build method
}
```

5. **Keep BrailleLoader for full-page loads:**
```dart
// For initial page load, keep spinner (appropriate)
if (_isInitialLoad) {
  return const Center(child: BrailleLoader(size: 32));
}

// For list refresh/infinite scroll, use skeletons
if (_isLoadingMore) {
  return ListView.builder(
    itemCount: _issues.length + 1,
    itemBuilder: (context, index) {
      if (index == _issues.length) {
        return const IssueCardSkeleton();
      }
      return IssueCard(issue: _issues[index]);
    },
  );
}
```

---

## Cross-Cutting Concerns Review

### 1. Caching Strategy

**Status:** AVAILABLE BUT NEEDS EXTENSION

**Current:**
- CacheService provides TTL-based caching (5-minute default)
- Used for: `fetchMyRepositories()`, `fetchIssues()`, `fetchProjects()`
- Cache keys: `repos_page_${page}_perPage_$perPage`, `issues_${owner}_${repo}_${state}`

**Gaps:**
- No image caching
- No cache size monitoring
- No manual cache clear option for users

**Recommendations:**
1. Add image caching (see Task 16.2)
2. Add cache statistics to DebugScreen:
```dart
// In debug_screen.dart
Future<void> _loadCacheStats() async {
  final cacheBox = await Hive.openBox('cache');
  final size = cacheBox.toMap().length;
  // Display to user
}
```
3. Add "Clear Cache" button in SettingsScreen

### 2. Offline-First Architecture

**Status:** PARTIAL

**What Works:**
- CacheService with TTL
- LocalStorageService for user data
- PendingOperationsService for queuing

**Gaps:**
- Image caching not implemented
- Some API methods don't check cache first
- No offline indicator in UI

**Recommendations:**
1. Implement cache-first strategy in all API methods:
```dart
// Pattern for all fetch methods
Future<List<T>> fetchData() async {
  // 1. Return cached immediately
  final cached = _cache.get<List>(cacheKey);
  if (cached != null) return cached;

  // 2. Check network
  final isOnline = await NetworkService().checkConnectivity();
  if (!isOnline) {
    throw Exception('Offline and no cached data');
  }

  // 3. Fetch fresh
  // ... API call ...

  // 4. Cache for next time
  await _cache.set(cacheKey, data);
  return data;
}
```

2. Add offline indicator to UI:
```dart
// In app bar
if (!isOnline) {
  Row(
    children: [
      Icon(Icons.cloud_off, size: 16, color: AppColors.orangePrimary),
      SizedBox(width: 4),
      Text('OFFLINE', style: TextStyle(fontSize: 10, color: AppColors.orangePrimary)),
    ],
  )
}
```

### 3. Performance Monitoring

**Status:** NOT IMPLEMENTED

**Current:** No performance metrics or monitoring

**Recommendations:**
1. Add performance logging to key operations:
```dart
Future<List<RepoItem>> fetchMyRepositories() async {
  final stopwatch = Stopwatch()..start();
  try {
    // ... implementation ...
  } finally {
    stopwatch.stop();
    debugPrint('fetchMyRepositories took ${stopwatch.elapsedMilliseconds}ms');
  }
}
```

2. Add DevTools performance testing to CI/CD:
```yaml
# In .github/workflows/test.yml
- name: Run performance tests
  run: flutter test --profile
```

### 4. Battery Efficiency

**Status:** NEEDS IMPROVEMENT

**Current:**
- Auto-sync triggers on network change
- No battery level checks
- No charging state awareness

**Recommendations:**
1. Add battery constraints to WorkManager:
```dart
Constraints(
  networkType: NetworkType.connected,
  requiresBatteryNotLow: true,  // Don't sync if battery < 15%
  requiresCharging: false,  // Set to true for charging-only sync
)
```

2. Add battery-aware sync settings:
```dart
// In settings_screen.dart
bool _syncOnlyOnCharge = false;

Widget _buildSyncOnlyOnChargeTile() {
  return SwitchListTile(
    title: const Text('Sync only when charging'),
    subtitle: const Text('Save battery by syncing only while charging'),
    value: _syncOnlyOnCharge,
    onChanged: (value) {
      setState(() => _syncOnlyOnCharge = value);
      _saveSyncSettings();
    },
  );
}
```

---

## API Usage Review

### GitHub API Endpoints for Pagination

| Endpoint | Current Status | Sprint 16 Requirement |
|----------|---------------|----------------------|
| `GET /user/repos?page={page}&per_page={perPage}` | ✅ Implemented | Task 16.1 |
| `GET /repos/{owner}/{repo}/issues?page={page}&per_page={perPage}` | ❌ Missing | Task 16.1 |
| `GET /search/issues?q={query}&page={page}&per_page={perPage}` | ❌ Not used | Task 16.1 |

### Rate Limit Considerations

**Current:** No rate limit tracking

**Recommendation:** Add rate limit monitoring:
```dart
// In github_api_service.dart
Future<Map<String, dynamic>> _checkRateLimit() async {
  final headers = await _headers;
  final response = await http.get(
    Uri.parse('https://api.github.com/rate_limit'),
    headers: headers,
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  }
  return {};
}

// Check before expensive operations
final rateLimit = await _checkRateLimit();
final remaining = rateLimit['resources']?['core']?['remaining'] as int?;
if (remaining != null && remaining < 10) {
  debugPrint('Warning: Rate limit nearly exhausted ($remaining remaining)');
}
```

---

## State Management Review (Riverpod)

**Status:** MINIMAL USAGE

**Current:**
- `githubApiService` provider (Line 1393-1396 in github_api_service.dart)
- `syncService` provider (Line 872-876 in sync_service.dart)

**Issue:** Screens create service instances directly:
```dart
final GitHubApiService _githubApi = GitHubApiService(); // Direct instantiation
```

**Recommendation:** Consider using Riverpod for state that changes:
```dart
// In providers/pagination_provider.dart
@riverpod
class PaginationState extends _$PaginationState {
  @override
  PaginationData build(String cacheKey) {
    return PaginationData(page: 1, hasMore: true, isLoading: false);
  }

  Future<void> loadNextPage() async {
    state = state.copyWith(isLoading: true);
    // ... load data ...
    state = state.copyWith(page: state.page + 1, isLoading: false);
  }
}
```

---

## Testing Recommendations

### Performance Tests

1. **List scrolling test:**
```dart
// test/performance/list_scroll_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Scroll 100 items at 60fps', (tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Start performance tracking
    final timeline = await tester.binding.traceAction(() async {
      // Scroll through list
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
    });
    
    // Analyze frame timing
    // Expect average frame time < 16ms
  });
}
```

2. **Cache effectiveness test:**
```dart
// test/services/cache_service_test.dart
test('Cache returns data within TTL', () async {
  await cacheService.set('test', 'value', ttl: Duration(minutes: 5));
  expect(cacheService.get('test'), equals('value'));
});

test('Cache expires after TTL', () async {
  await cacheService.set('test', 'value', ttl: Duration(milliseconds: 100));
  await Future.delayed(Duration(milliseconds: 150));
  expect(cacheService.get('test'), isNull);
});
```

### Manual Testing Checklist

- [ ] Scroll through 100+ issues without jank
- [ ] Turn off WiFi, open app, see cached repos/issues
- [ ] Turn off WiFi, open app, see cached avatars
- [ ] Background sync triggers every 15 minutes (check logs)
- [ ] Loading skeletons shown during list refresh
- [ ] "Load More" button works at end of lists
- [ ] Cache clear button works in settings
- [ ] Battery drain acceptable (measure over 1 hour)

---

## Summary of Required Changes

### Task 16.1: Pagination

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `github_api_service.dart` | Add page/perPage to `fetchIssues()` | HIGH | ~30 |
| `main_dashboard_screen.dart` | Implement "Load More" for repos | HIGH | ~50 |
| `search_screen.dart` | Implement pagination for issues | HIGH | ~50 |
| `repo_list.dart` | Add itemExtent to ListView | MEDIUM | ~5 |

### Task 16.2: Image Caching

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `pubspec.yaml` | Add cached_network_image dependency | HIGH | ~2 |
| `issue_detail_screen.dart` | Replace NetworkImage with CachedNetworkImage | HIGH | ~20 |
| `create_issue_screen.dart` | Replace NetworkImage with CachedNetworkImage | HIGH | ~10 |
| `settings_screen.dart` | Replace NetworkImage with CachedNetworkImage | HIGH | ~10 |

### Task 16.3: Background Sync

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `pubspec.yaml` | Add workmanager dependency | HIGH | ~2 |
| `background_sync_service.dart` | Create new service | HIGH | ~100 |
| `local_storage_service.dart` | Add sync settings persistence | MEDIUM | ~30 |
| `settings_screen.dart` | Integrate settings with BackgroundSyncService | MEDIUM | ~20 |
| `main.dart` | Initialize BackgroundSyncService | HIGH | ~5 |

### Task 16.4: List Optimization

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `repo_list.dart` | Add itemExtent, cacheExtent | MEDIUM | ~5 |
| `search_screen.dart` | Add itemExtent to ListView | MEDIUM | ~5 |
| `issue_card.dart` | Add RepaintBoundary | LOW | ~5 |
| Multiple screens | Add const constructors | LOW | ~50 |

### Task 16.5: Loading Skeletons

| File | Change | Priority | Lines |
|------|--------|----------|-------|
| `loading_skeleton.dart` | Create new widget | HIGH | ~50 |
| `issue_card_skeleton.dart` | Create skeleton widget | HIGH | ~60 |
| `repo_card_skeleton.dart` | Create skeleton widget | HIGH | ~50 |
| `search_screen.dart` | Replace BrailleLoader with skeletons | MEDIUM | ~20 |
| `main_dashboard_screen.dart` | Replace BrailleLoader with skeletons | MEDIUM | ~20 |

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Pagination breaks existing UI | HIGH | LOW | Thorough testing, gradual rollout |
| Image cache grows unbounded | MEDIUM | MEDIUM | Implement 10MB limit with LRU eviction |
| Background sync drains battery | HIGH | LOW | Use WorkManager constraints (battery not low) |
| List optimization causes bugs | MEDIUM | LOW | Extensive scroll testing on old devices |
| Skeletons don't match design | LOW | LOW | UI review before merge |
| WorkManager not reliable on iOS | MEDIUM | MEDIUM | Fallback to timer-based sync for iOS |

---

## Performance Targets

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| Initial Load Time (Repos) | TBD | -50% | DevTools Timeline |
| Initial Load Time (Issues) | TBD | -50% | DevTools Timeline |
| List Scroll FPS (100 items) | TBD | 60 fps | DevTools Performance |
| Memory Usage (Idle) | TBD | -20% | DevTools Memory |
| Image Load Time (Avatar) | TBD | -80% | Network tab |
| Cache Hit Rate | TBD | >90% | CacheService logs |
| Background Sync Success | N/A | >95% | WorkManager logs |

---

## Implementation Priority

**Week 1 (Days 1-3):**
1. Task 16.1 - Pagination (foundation for other optimizations)
2. Task 16.5 - Loading Skeletons (UI-only, low risk)

**Week 1 (Days 4-5):**
3. Task 16.2 - Image Caching (user-perceived improvement)
4. Task 16.4 - List Optimization (complements pagination)

**Week 2 (Days 1-2):**
5. Task 16.3 - Background Sync (requires platform configuration)

**Week 2 (Days 3-5):**
- Performance testing and optimization
- Bug fixes
- Documentation

---

**Last Updated:** March 2, 2026
**Updated By:** System Architect

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
