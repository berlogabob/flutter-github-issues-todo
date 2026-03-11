# Flutter GitHub Issues Todo - Implementation Plan

## Project Overview
Offline-first GitHub issues manager (todo app) with main dashboard showing default and pinned repositories.

---

## Part 1: Offline Caching Fixes

### Problem Statement
The app has all infrastructure (CacheService, LocalStorageService, SyncService, NetworkService) but caching doesn't work due to critical bugs.

### Root Causes

| # | Issue | File | Line |
|---|-------|------|------|
| 1 | CacheService.get() calls init() without await - always returns null | cache_service.dart | 137-141 |
| 2 | CacheService.init() never called in main.dart | main.dart | 63-64 |
| 3 | Network failure throws exception instead of returning cached data | github_api_service.dart | 313-315 |
| 4 | Only TTL cache (5 min), no persistent fallback | github_api_service.dart | - |
| 5 | No network status check in providers | app_providers.dart | 46-55 |

### Implementation Plan

#### Phase 1: Fix Cache Initialization (P0 - Critical)

**1.1 Fix CacheService.get() - Add await**
```dart
// File: lib/services/cache_service.dart
// Lines 135-142
T? get<T>(String key) {
  if (!_isInitialized) {
    // FIX: Await initialization instead of fire-and-forget
    await init();  // Add await
    if (!_isInitialized) return null;  // Double check after init
  }
  // ... rest of method
}
```

**1.2 Add CacheService.init() to main.dart**
```dart
// File: lib/main.dart
// After line 64 (after Hive.initFlutter)
// Import cache_service.dart at top
import 'services/cache_service.dart';

// Add after Hive.initFlutter():
await CacheService().init();
debugPrint('CacheService initialized');
```

#### Phase 2: Offline-First Data Flow (P1 - High)

**2.1 Modify GitHubApiService to return cached data on network failure**

```dart
// File: lib/services/github_api_service.dart
// Replace lines 311-318 with:
} catch (e, stackTrace) {
  AppErrorHandler.handle(e, stackTrace: stackTrace);
  
  // Try to return cached data on network failure
  if (e.toString().contains('SocketException') ||
      e.toString().contains('Network') ||
      e.toString().contains('TimeoutException')) {
    
    // Return cached data if available
    final cachedData = _cache.get<List>(cacheKey);
    if (cachedData != null) {
      debugPrint('Returning cached data due to network error');
      if (cacheKey.startsWith('issues_')) {
        return cachedData.map((json) => IssueItem.fromJson(json as Map<String, dynamic>)).toList();
      } else if (cacheKey.startsWith('repos_')) {
        return cachedData.map((json) => RepoItem.fromJson(json as Map<String, dynamic>)).toList();
      }
    }
  }
  
  // Only throw if no cached data available
  rethrow;
}
```

**2.2 Add network check wrapper to providers**

```dart
// File: lib/providers/app_providers.dart
// Create offline-first providers

final offlineReposProvider = FutureProvider<List<RepoItem>>((ref) async {
  final networkService = NetworkService();
  final api = ref.read(githubApiServiceProvider);
  
  try {
    // Try online first
    return await api.fetchMyRepositories(perPage: 30);
  } catch (e) {
    // On failure, cache will be checked by GitHubApiService
    // Re-fetch which will return cached data
    return await api.fetchMyRepositories(perPage: 30);
  }
});

final offlineIssuesProvider = FutureProvider.family<List<IssueItem>, String>((
  ref,
  repoFullName,
) async {
  final api = ref.read(githubApiServiceProvider);
  final parts = repoFullName.split('/');
  try {
    return await api.fetchIssues(parts[0], parts[1]);
  } catch (e) {
    // On failure, will return cached data
    return await api.fetchIssues(parts[0], parts[1]);
  }
});
```

#### Phase 3: Persistent Storage Fallback (P2 - Medium)

**3.1 Save to LocalStorageService after successful API fetch**

```dart
// In github_api_service.dart after successful fetch:
// Add after caching to Hive

// Also save to persistent storage for long-term offline access
final localStorage = LocalStorageService();
if (cacheKey.startsWith('repos_')) {
  await localStorage.saveRepos(repos.map((r) => r.toJson()).toList());
} else if (cacheKey.startsWith('issues_')) {
  await localStorage.saveSyncedIssues('$owner/$repo', issues);
}
```

**3.2 Load from persistent storage when cache expires**

Modify fetch methods to check LocalStorageService when cache is empty/expired.

---

## Part 2: Main Screen & Library Screen Improvements

### Current State

| Feature | Status | Notes |
|---------|--------|-------|
| Default repo on first launch | ✅ | onboarding_screen.dart |
| Default repo in settings | ✅ | settings_screen.dart |
| Main screen shows default repo | ✅ | main_dashboard_screen.dart |
| Swipe to pin/unpin in library | ✅ | repo_project_library_screen.dart |
| Add repo by URL | ❌ | Missing feature |

### Implementation Plan

#### Phase 4: Add "Add Repo by URL" Feature (P1 - High)

**4.1 Add addRepoByUrl() to GitHubApiService**

```dart
// File: lib/services/github_api_service.dart
// Add new method

/// Fetch a single public repository by owner/repo name
/// Does not require authentication for public repos
Future<RepoItem?> fetchRepoByUrl(String owner, String repo) async {
  try {
    final headers = await _headers;
    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo');
    
    final response = await http.get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseRepo(data);
    } else if (response.statusCode == 404) {
      return null; // Repo not found
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching repo by URL: $e');
    return null;
  }
}
```

**4.2 Add "Add Repo" button to Library Screen**

```dart
// File: lib/screens/repo_project_library_screen.dart
// Add to AppBar actions

IconButton(
  icon: const Icon(Icons.add_link),
  tooltip: 'Add repo by URL',
  onPressed: () => _showAddRepoDialog(context),
)

// Add dialog method
Future<void> _showAddRepoDialog(BuildContext context) async {
  final controller = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Repository'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'owner/repository',
          labelText: 'Repository (e.g., flutter/flutter)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final input = controller.text.trim();
            if (!input.contains('/')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use format: owner/repository')),
              );
              return;
            }
            
            // Fetch repo by URL
            final parts = input.split('/');
            final repo = await _githubApi.fetchRepoByUrl(parts[0], parts[1]);
            
            if (repo != null) {
              // Add to repositories list
              ref.read(repositoriesProvider.notifier).addRepo(repo);
              // Pin to main screen
              await ref.read(pinnedReposProvider.notifier).pin(repo.fullName);
              if (context.mounted) Navigator.pop(context);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Repository not found')),
                );
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
```

#### Phase 5: UI Improvements (P2 - Medium)

**5.1 Improve swipe feedback in Library Screen**

Currently the swipe works but user feedback can be improved:

```dart
// File: lib/screens/repo_project_library_screen.dart
// Update onDismissed to show better feedback

onDismissed: (direction) async {
  HapticFeedback.mediumImpact(); // Stronger feedback
  if (direction == DismissDirection.startToEnd) {
    await _pinRepo(repo.fullName);
  } else {
    await _unpinRepo(repo.fullName);
  }
},
```

**5.2 Add "Set as Main" long-press action**

```dart
// In _buildRepoItem, add onLongPress:

onLongPress: () async {
  final mainRepo = ref.read(mainRepoProvider);
  if (repo.fullName != mainRepo) {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set as Main Repository?'),
        content: Text('${repo.fullName} will become your default repo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Set as Main'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await ref.read(mainRepoProvider.notifier).setMain(repo.fullName);
    }
  }
},
```

**5.3 Add MainRepoNotifier.setMain() method**

```dart
// File: lib/providers/pinned_repos_provider.dart
// Add to MainRepoNotifier class

Future<void> setMain(String fullName) async {
  state = fullName;
  final storage = LocalStorageService();
  await storage.saveDefaultRepo(fullName);
}
```

---

## Summary: Task Breakdown

### Phase 1: Offline Fixes (Critical)
- [ ] 1.1 Fix CacheService.get() - add await (cache_service.dart:137)
- [ ] 1.2 Add CacheService.init() call (main.dart:64)
- [ ] 1.3 Return cached data on network failure (github_api_service.dart:311)
- [ ] 1.4 Add persistent storage fallback (github_api_service.dart)

### Phase 2: Main Screen & Library (Features)
- [ ] 2.1 Add fetchRepoByUrl() method (github_api_service.dart)
- [ ] 2.2 Add "Add Repo" button to Library screen (repo_project_library_screen.dart)
- [ ] 2.3 Add "Set as Main" long-press (repo_project_library_screen.dart)
- [ ] 2.4 Add setMain() to MainRepoNotifier (pinned_repos_provider.dart)

---

## Files to Modify

| File | Changes |
|------|---------|
| lib/services/cache_service.dart | Fix get() method |
| lib/main.dart | Add CacheService.init() |
| lib/services/github_api_service.dart | Offline fallback + fetchRepoByUrl |
| lib/services/local_storage_service.dart | Add saveRepos/getRepos if needed |
| lib/providers/app_providers.dart | Add offline-first providers |
| lib/providers/pinned_repos_provider.dart | Add setMain() |
| lib/screens/repo_project_library_screen.dart | Add URL dialog + long-press |
