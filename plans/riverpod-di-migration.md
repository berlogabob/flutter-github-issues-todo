# Phase 4: Riverpod DI Migration Plan

## Current State

The project uses a **hybrid approach**:
- 4 functional `@Riverpod` providers defined (but mostly unused)
- 15+ files directly instantiate services with `new ServiceName()`

### Providers Defined (Not Used)
```dart
// lib/services/github_api_service.dart
@Riverpod(keepAlive: true)
GitHubApiService githubApiService(Ref ref) {
  return GitHubApiService();
}

// lib/services/local_storage_service.dart
@Riverpod(keepAlive: true)
LocalStorageService localStorageService(Ref ref) {
  return LocalStorageService();
}

// lib/services/sync_service.dart
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  return SyncService();
}

// lib/services/oauth_service.dart
@Riverpod(keepAlive: true)
OAuthService oauthService(Ref ref) {
  return OAuthService();
}
```

### Direct Instantiation (Used Instead)
```dart
// 15+ files do this:
final GitHubApiService _githubApi = GitHubApiService();
final LocalStorageService _localStorage = LocalStorageService();
final SyncService _syncService = SyncService();
final PendingOperationsService _pendingOps = PendingOperationsService();
```

## Problem
- Services are instantiated directly, not via Riverpod
- No dependency injection — hard to mock for testing
- Functional `@Riverpod` pattern is legacy in Riverpod 3.x
- 15+ files need updates

## Solution: Incremental Migration

### Step 1: Create Class-Based Notifiers (Easy)
Convert functional providers to class-based Notifiers:

```dart
// BEFORE (functional - legacy)
@Riverpod(keepAlive: true)
GitHubApiService githubApiService(Ref ref) {
  return GitHubApiService();
}

// AFTER (class-based - modern)
class GitHubApiServiceNotifier extends Notifier<GitHubApiService> {
  @override
  GitHubApiService build() => GitHubApiService();
}

final githubApiServiceProvider = NotifierProvider<GitHubApiServiceNotifier, GitHubApiService>(
  GitHubApiServiceNotifier.new,
);
```

### Step 2: Update Import Statements
Change all files to import from providers instead of service files:

```dart
// BEFORE
import '../services/github_api_service.dart';

// AFTER
import '../services/github_api_service.dart';  // Keep for type
import '../providers/service_providers.dart';  // Add for providers
```

### Step 3: Replace Direct Instantiation (Medium Effort)
In each file, replace:

```dart
// BEFORE
final GitHubApiService _githubApi = GitHubApiService();

// AFTER
final githubApi = ref.read(githubApiServiceProvider);
```

## Files to Update

### Service Files (4)
1. `lib/services/github_api_service.dart` — add Notifier provider
2. `lib/services/local_storage_service.dart` — add Notifier provider
3. `lib/services/sync_service.dart` — add Notifier provider
4. `lib/services/oauth_service.dart` — add Notifier provider

### Provider File (1) - Create new
5. `lib/providers/service_providers.dart` — consolidate all providers

### Screen Files (11) - Update instantiation
6. `lib/screens/create_issue_screen.dart`
7. `lib/screens/search_screen.dart`
8. `lib/screens/repo_detail_screen.dart`
9. `lib/screens/issue_detail_screen.dart`
10. `lib/screens/project_board_screen.dart`
11. `lib/screens/onboarding_screen.dart`
12. `lib/screens/edit_issue_screen.dart`
13. `lib/screens/repo_project_library_screen.dart`
14. `lib/screens/settings_screen.dart`

### Other Service Files (3)
15. `lib/services/sync_service.dart` (uses other services)
16. `lib/services/issue_service.dart`
17. `lib/services/dashboard_data_service.dart`

### Provider Files (2)
18. `lib/providers/app_providers.dart`

## Execution Order

```
1. Create lib/providers/service_providers.dart with all Notifier providers
2. Update lib/services/github_api_service.dart
3. Update lib/services/local_storage_service.dart  
4. Update lib/services/sync_service.dart
5. Update lib/services/oauth_service.dart
6. Update screens one by one:
   - create_issue_screen.dart
   - search_screen.dart
   - repo_detail_screen.dart
   - issue_detail_screen.dart
   - project_board_screen.dart
   - edit_issue_screen.dart
   - repo_project_library_screen.dart
   - settings_screen.dart
   - onboarding_screen.dart
7. Update services that use other services:
   - sync_service.dart
   - issue_service.dart
   - dashboard_data_service.dart
8. Update providers/app_providers.dart
```

## Effort Estimate
- **Step 1** (create providers): 30 min
- **Step 2-4** (update services): 1 hour
- **Step 5** (update screens): 2-3 hours
- **Total**: ~4-5 hours for full migration

## Alternative: Minimal Approach

If full migration is too much, do **minimal DI** without changing architecture:

1. Keep functional `@Riverpod` providers (they work fine)
2. Just use them in screens via `ref.read(provider)`

This gives you DI without rewriting all 15+ files.

## Risks
- Runtime errors if any file is missed
- Must test each screen after changes
- May break existing functionality if not careful

## Recommendation
**Do incremental migration**: Convert one service + its consumers at a time, testing each step.
