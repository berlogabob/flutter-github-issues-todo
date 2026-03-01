# Emergency Problems - Action Plan

**Last Updated:** 2026-02-28  
**Version:** 0.5.0+46  
**Goal:** Fix all critical UI/UX issues in focused sprints

---

## ✅ COMPLETED SPRINTS (Sprints 1-4)

### Sprint 1: Core Bug Fixes ✅
- [x] Fix phantom repository (deduplication logic added)
- [x] Add repository selection to issue creation
- [x] Implement single expanded repo

### Sprint 2: Swipe & Card Fixes ✅
- [x] Issue card swipe gestures (right=edit, left=close)
- [x] Safe area padding for issue cards
- [x] Bottom action bar height reduced by 50%

### Sprint 3: Library Redesign ✅
- [x] Remove redundant fetch buttons
- [x] Refresh button updates both repos AND projects
- [x] Fix "+ Add Repository" button
- [x] Remove web open icon from repo cards
- [x] Add repo swipe gestures (pin/unpin from main)
- [x] Implement in-app repo detail view

### Sprint 4: Braille Loading ✅
- [x] Create BrailleLoader widget
- [x] Replace all 23 CircularProgressIndicator
- [x] Optimize AppBar with new loader

---

## ✅ COMPLETED POST-SPRINT FIXES

### Issue A: Phantom Repository Filter ✅
**Status:** COMPLETED  
**Priority:** CRITICAL  
**Fixed In:** v0.5.0+47

**Solution Implemented:**
- Added constant `_appRepoFullName = 'berlogabob/flutter-github-issues-todo'`
- Filter applied in `_fetchRepositories()` method
- App repo excluded from display, debug log added

**Result:** The app's own repository no longer appears in the repo list.

---

### Issue B: Default Repo Display ✅
**Status:** COMPLETED  
**Priority:** CRITICAL  
**Fixed In:** v0.5.0+47

**Solution Implemented:**
- Added `_getDisplayedRepos()` helper method
- Offline mode: shows only vault repo
- Online mode: shows only default repo from settings
- Added UI indicator showing current repo
- Fallback to first non-vault repo if no default set

**Result:** User sees only one repo at a time (default or vault).

---

### Issue C: Static Cloud Icon ✅
**Status:** COMPLETED  
**Priority:** MEDIUM  
**Fixed In:** v0.5.0+47

**Solution Implemented:**
- Removed `AnimationController` from `SyncCloudIcon`
- Removed rotating CircularProgressIndicator
- Cloud icon now static with color/badge changes only
- Added `BrailleLoader` as sibling widget when syncing
- Sync status text + time displayed below icon

**Result:** Static cloud icon with separate BrailleLoader animation during sync.

---

### Issue D: Cloud Icon State Updates ✅
**Status:** COMPLETED  
**Priority:** HIGH  
**Fixed In:** v0.5.0+48

**Problem:** Cloud icon wasn't updating properly because it wasn't listening to SyncService state changes.

**Solution Implemented:**
- Added listener pattern to `SyncService` (`addListener`, `removeListener`, `_notifyListeners`)
- Dashboard now listens to sync service changes and rebuilds cloud icon
- Added periodic timer (2 seconds) to refresh cloud icon state
- Updated `_getLastSyncText()` to show seconds: `now` (<10s), `Xs` (10-59s), `Xm`, `Xh`, `Xd`
- Added `dart:async` import for Timer support

**Result:** Cloud icon updates in real-time, shows granular sync time (seconds).

---

## 📋 GITHUB ISSUES TRACKING

### Open Issues with "ToDO" Label

Fetch from: https://github.com/berlogabob/flutter-github-issues-todo/issues?q=is%3Aopen+label%3A%22ToDO%22

- [ ] **Issue #15:** ToDo - Create issue implementation
- [ ] **Issue #16:** ToDo - Default state pinned repo behavior  
- [ ] **Issue #17:** ToDo - App version display in settings

**Note:** These issues were created as placeholders. Need to fetch detailed descriptions from GitHub API.

---

## 🔧 DETAILED FIX PLANS

### Fix A: Filter Out App Repository

**File:** `lib/screens/main_dashboard_screen.dart`

**Step 1:** Add constant for app repo full name
```dart
static const String _appRepoFullName = 'berlogabob/flutter-github-issues-todo';
```

**Step 2:** Filter repos after fetching
```dart
// In _fetchRepositories(), after getting repos from API:
final filteredRepos = repos.where((repo) {
  // Filter out the app's own repository
  return repo.fullName != _appRepoFullName;
}).toList();

setState(() {
  _repositories = filteredRepos;
  // ... rest of logic
});
```

**Step 3:** Add debug logging
```dart
debugPrint('Filtered out app repository: $_appRepoFullName');
debugPrint('Showing ${_repositories.length} repos (excluded app repo)');
```

**Testing:**
- [ ] App repo no longer appears in list
- [ ] Other repos display correctly
- [ ] No errors in logs

---

### Fix B: Show Only Default Repo

**File:** `lib/screens/main_dashboard_screen.dart`

**Step 1:** Add method to get default repo
```dart
RepoItem? _getDefaultRepoItem() {
  if (_repositories.isEmpty) return null;
  
  // In offline mode, return vault repo
  if (_isOfflineMode) {
    return _repositories.firstWhere(
      (r) => r.id == 'vault',
      orElse: () => null,
    );
  }
  
  // In online mode, return default repo from settings
  final defaultRepoName = _localStorage.getDefaultRepo();
  if (defaultRepoName != null) {
    return _repositories.firstWhere(
      (r) => r.fullName == defaultRepoName && r.id != 'vault',
      orElse: () => null,
    );
  }
  
  // If no default set, return first non-vault repo
  return _repositories.firstWhere(
    (r) => r.id != 'vault',
    orElse: () => _repositories.first,
  );
}
```

**Step 2:** Filter displayed repos
```dart
List<RepoItem> _getDisplayedRepos() {
  if (_isOfflineMode) {
    // Offline: show only vault
    return _repositories.where((r) => r.id == 'vault').toList();
  }
  
  // Online: show only default repo
  final defaultRepo = _getDefaultRepoItem();
  if (defaultRepo != null) {
    return [defaultRepo];
  }
  
  // Fallback: show all non-vault repos
  return _repositories.where((r) => r.id != 'vault').toList();
}
```

**Step 3:** Update build method to use filtered list
```dart
// In build(), replace _repositories with _getDisplayedRepos()
final displayedRepos = _getDisplayedRepos();

// Use displayedRepos in ListView.builder
itemCount: displayedRepos.length,
itemBuilder: (context, index) => ExpandableRepo(
  repo: displayedRepos[index],
  // ...
),
```

**Step 4:** Add UI indicator
```dart
// Show which repo is displayed
if (!_isOfflineMode && _repositories.length > 1)
  Container(
    padding: EdgeInsets.all(8.w),
    color: AppColors.orange.withValues(alpha: 0.1),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: AppColors.orange),
        SizedBox(width: 8),
        Text(
          'Showing: ${_getDefaultRepoItem()?.fullName ?? "Default"}',
          style: TextStyle(fontSize: 12, color: AppColors.orange),
        ),
      ],
    ),
  ),
```

**Testing:**
- [ ] Online mode shows only default repo
- [ ] Offline mode shows only vault
- [ ] Can change default repo in settings
- [ ] UI updates when default changes

---

### Fix C: Static Cloud Icon + External BrailleLoader

**File 1:** `lib/widgets/sync_cloud_icon.dart`

**Step 1:** Remove rotation animation
```dart
// Remove these lines:
// - AnimationController _controller;
// - _buildCloudWithRotatingIndicator() method
// - RotationTransition widget
```

**Step 2:** Simplify build method
```dart
@override
Widget build(BuildContext context) {
  Widget cloudIcon = _buildCloudIcon();
  
  // Add badge for status (no rotation)
  if (widget.state == SyncCloudState.syncing) {
    return _buildCloudWithStaticIndicator(cloudIcon);
  }
  
  return Stack(
    children: [
      cloudIcon,
      if (widget.state == SyncCloudState.offline) _buildBadge(Icons.cloud_off),
      if (widget.state == SyncCloudState.synced) _buildBadge(Icons.check_circle),
      if (widget.state == SyncCloudState.error) _buildBadge(Icons.error),
    ],
  );
}

Widget _buildCloudWithStaticIndicator(Widget cloudIcon) {
  return Stack(
    alignment: Alignment.center,
    children: [
      cloudIcon,
      // Static orange dot to indicate syncing
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: widget.size * 0.3,
          height: widget.size * 0.3,
          decoration: BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ],
  );
}
```

**File 2:** `lib/screens/main_dashboard_screen.dart`

**Step 3:** Add BrailleLoader next to icon
```dart
// In AppBar actions:
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SyncCloudIcon(
          state: _getSyncCloudState(),
          size: 24.w,
          // Remove: isRotating: _syncService.isSyncing,
        ),
        // Add BrailleLoader when syncing
        if (_syncService.isSyncing) ...[
          SizedBox(width: 4.w),
          BrailleLoader(size: 16.w),
        ],
      ],
    ),
    if (_syncService.lastSyncTime != null)
      Text(
        _getLastSyncText(),
        style: TextStyle(color: Colors.white54, fontSize: 7.sp),
        textAlign: TextAlign.center,
      ),
  ],
),
```

**Testing:**
- [ ] Cloud icon static (no rotation)
- [ ] BrailleLoader appears when syncing
- [ ] Status badge shows correctly
- [ ] Last sync time displays

---

## ✅ TESTING CHECKLIST

### Fix A Testing:
- [ ] App repo filtered from list
- [ ] Other repos display normally
- [ ] No console errors
- [ ] Logs show filtering occurred

### Fix B Testing:
- [ ] Online mode: only default repo visible
- [ ] Offline mode: only vault visible
- [ ] Settings: can change default repo
- [ ] UI indicator shows current repo
- [ ] Create issue uses correct repo

### Fix C Testing:
- [ ] Cloud icon doesn't rotate
- [ ] BrailleLoader appears during sync
- [ ] Status badges show correctly
- [ ] Last sync time readable
- [ ] No animation conflicts

---

## 📊 PROGRESS TRACKING

| Task | Status | Sprint | Fixed In |
|------|--------|--------|----------|
| Filter app repository | ✅ REMOVED | Post-Sprint | v0.5.0+56 |
| Show only default repo | ✅ DONE | Post-Sprint | v0.5.0+47 |
| Static cloud icon + BrailleLoader | ✅ DONE | Post-Sprint | v0.5.0+47 |
| Cloud icon state updates | ✅ DONE | Post-Sprint | v0.5.0+48 |
| Remove "Showing repo" notification | ✅ DONE | Post-Sprint | v0.5.0+49 |
| Swipe right to edit issue | ✅ DONE | Post-Sprint | v0.5.0+50 |
| Library swipe links to main screen | ✅ DONE | Post-Sprint | v0.5.0+51 |
| BrailleLoader smooth rotation | ✅ DONE | Post-Sprint | v0.5.0+52 |
| BrailleLoader overlay flash fix | ✅ DONE | Post-Sprint | v0.5.0+53 |
| Unified sync status widget | ✅ DONE | Post-Sprint | v0.5.0+54 |
| Library swipe actual linking | ✅ DONE | Post-Sprint | v0.5.0+55 |
| App repo visible again | ✅ DONE | Post-Sprint | v0.5.0+56 |
| App version in settings | ✅ DONE | Post-Sprint | v0.5.0+57 |
| GitHub Issue #15 | ⏳ Pending | - | - |
| GitHub Issue #16 | ⏳ Pending | - | - |
| GitHub Issue #17 | ⏳ Pending | - | - |

---

## 📝 NOTES

- **DO NOT** add new features
- **ONLY** fix existing problems
- Keep changes minimal and focused
- Test thoroughly after each fix
- Maintain backward compatibility

---

**Last Build:** v0.5.0+46  
**Current Build:** v0.5.0+57 ✅ (all fixes + correct version)  
**Next Build:** v0.5.0+58 (pending GitHub issues)
