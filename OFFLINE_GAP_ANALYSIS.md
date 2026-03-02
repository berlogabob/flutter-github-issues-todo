# Offline Mode Gap Analysis

**Date:** March 1, 2026  
**Analyzed By:** Senior Flutter Developer  
**Scope:** Complete offline functionality audit

---

## Executive Summary

The application has **partial offline support** with significant gaps in implementation. While the foundation exists (local storage, vault folder support, isLocalOnly flag), critical functionality is missing or incomplete.

---

## 1. Current State

### What Works ✅

1. **Offline Mode Selection**
   - Users can choose "Continue Offline" on onboarding (`/lib/screens/onboarding_screen.dart:596-663`)
   - Vault folder selection via FilePicker (`/lib/screens/onboarding_screen.dart:737-743`)
   - Auth type stored as 'offline' in secure storage

2. **Local Issue Storage**
   - Issues saved as markdown files in vault folder (`/lib/services/local_storage_service.dart:43-77`)
   - YAML frontmatter with metadata (title, labels, status, created, local_only)
   - Issues can be loaded from vault folder (`/lib/services/local_storage_service.dart:118-151`)

3. **Local Issue Display**
   - Vault repo shown in dashboard with local issues (`/lib/screens/main_dashboard_screen.dart:328-353`)
   - Issues display with cloud_off icon and "Local" label (`/lib/widgets/issue_card.dart:117-129`)
   - Issue count badge shows local issues (`/lib/widgets/expandable_repo.dart:164-173`)

4. **Local Issue Editing**
   - Edit screen handles local-only issues (`/lib/screens/edit_issue_screen.dart:418-444`)
   - Changes saved back to vault folder
   - Status toggle works for local issues (`/lib/screens/issue_detail_screen.dart:743-764`)

5. **Sync Service Foundation**
   - Connectivity monitoring via `connectivity_plus` (`/lib/services/sync_service.dart:93-112`)
   - Auto-sync trigger when network returns (`/lib/services/sync_service.dart:104-111`)
   - Sync dialog shown when network available with local issues (`/lib/screens/main_dashboard_screen.dart:126-181`)
   - Local issues can be synced to GitHub repo (`/lib/services/sync_service.dart:414-453`)

### What Doesn't Work ❌

1. **No Network Connectivity Check Before API Calls**
   - GitHub API service doesn't check network before making calls
   - Relies on catching SocketException after failure
   - No proactive offline detection

2. **No Operation Queue for Offline Changes**
   - No pending operations queue
   - No tracking of what needs to be synced
   - Sync relies on isLocalOnly flag only

3. **Limited Offline CRUD Operations**
   - Cannot add comments to issues offline
   - Cannot assign/unassign users offline (UI shows error)
   - Cannot add/remove labels offline (UI shows error)
   - Close/reopen works but only updates local state

4. **No Conflict Resolution**
   - Sync service has basic "remote wins" strategy
   - No user-facing conflict resolution UI
   - No detection of conflicting changes

5. **No Sync Status Feedback**
   - Cloud icon shows generic status
   - No detailed sync progress
   - No error reporting for failed syncs

6. **Vault Folder Permission Issues**
   - Permission requested but not persisted properly
   - User asked again after app restart
   - No fallback if permission denied

---

## 2. Critical Gaps

### Gap 1: No Network Connectivity Check Before API Calls
- **Impact:** HIGH
- **Location:** `/lib/services/github_api_service.dart:156-203` (fetchMyRepositories)
- **Issue:** Network check happens in dashboard screen, not in API service
- **Fix Complexity:** M (Medium)
- **Code:**
```dart
// Line 369-388 in main_dashboard_screen.dart
try {
  final result = await InternetAddress.lookup('api.github.com');
  // ... check network
} on SocketException catch (e) {
  throw Exception('No internet connection...');
}
```
**Problem:** This check is in UI layer, not service layer. API calls can still fail unexpectedly.

### Gap 2: No Pending Operations Queue
- **Impact:** CRITICAL
- **Location:** Missing entirely
- **Issue:** No mechanism to track pending create/update/delete operations
- **Fix Complexity:** XL (Extra Large)
- **Required:** New service or major refactor of LocalStorageService

### Gap 3: Incomplete Offline CRUD
- **Impact:** HIGH
- **Location:** 
  - `/lib/screens/issue_detail_screen.dart:1136-1145` (addComment)
  - `/lib/screens/issue_detail_screen.dart:973-1001` (removeAssignee)
  - `/lib/screens/issue_detail_screen.dart:1019-1047` (removeLabel)
- **Issue:** These operations show errors or do nothing for local issues
- **Fix Complexity:** L (Large)
- **Code Example:**
```dart
// Line 1136-1145 in issue_detail_screen.dart
if (_currentIssue.isLocalOnly) {
  _showErrorSnackBar('Cannot add comments to local issues');
  return;
}
```

### Gap 4: No Conflict Resolution UI
- **Impact:** MEDIUM
- **Location:** `/lib/services/sync_service.dart:374-408` (_resolveIssuesConflict)
- **Issue:** Silent "remote wins" strategy, user not informed of conflicts
- **Fix Complexity:** L (Large)
- **Code:**
```dart
// Line 374-408 in sync_service.dart
/// Strategy:
/// - Remote issues always win for existing issues (by issue number)
/// - Local-only issues (isLocalOnly=true) are kept for sync to GitHub
```

### Gap 5: Permission Not Persisted
- **Impact:** HIGH
- **Location:** `/lib/screens/onboarding_screen.dart:665-677`
- **Issue:** Permission requested every app start
- **Fix Complexity:** M (Medium)
- **Code:**
```dart
Future<bool> _requestStoragePermission() async {
  if (await Permission.manageExternalStorage.isGranted) {
    return true;
  }
  final status = await Permission.manageExternalStorage.request();
  return status.isGranted;
}
```
**Problem:** No check if permission was previously granted and saved.

### Gap 6: No Auto-Sync Configuration
- **Impact:** MEDIUM
- **Location:** `/lib/screens/settings_screen.dart:47-50`
- **Issue:** Auto-sync toggles exist but don't work (`_syncNow()` is TODO)
- **Fix Complexity:** M (Medium)
- **Code:**
```dart
// Line 837-841 in settings_screen.dart
void _syncNow() {
  // TODO: Trigger sync
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Syncing...')),
  );
}
```

### Gap 7: No Offline Indicator in Cloud Icon
- **Impact:** LOW
- **Location:** `/lib/widgets/sync_cloud_icon.dart` (not analyzed, referenced in dashboard)
- **Issue:** Cloud icon doesn't show offline status clearly
- **Fix Complexity:** S (Small)

### Gap 8: Demo Data Shown in Offline Mode
- **Impact:** MEDIUM
- **Location:** `/lib/screens/main_dashboard_screen.dart:454-481`
- **Issue:** Demo data added as fallback even in offline mode
- **Fix Complexity:** S (Small)
- **Code:**
```dart
// Line 477-480
if (_repositories.isEmpty && !_isOfflineMode) {
  debugPrint('Showing demo data as fallback');
  _addDemoData();
}
```
**Note:** Condition exists but demo issues still appear.

---

## 3. Required Features

### Feature 1: Network Connectivity Service
- **Priority:** CRITICAL
- **Dependencies:** connectivity_plus (already installed)
- **Description:** Centralized service to check and monitor network status
- **Implementation:**
  - Check network before any API call
  - Broadcast network status changes
  - Cache network state

### Feature 2: Pending Operations Queue
- **Priority:** CRITICAL
- **Dependencies:** LocalStorageService, Hive
- **Description:** Queue to track all offline operations
- **Operations to Track:**
  - CreateIssue
  - UpdateIssue
  - DeleteIssue
  - AddComment
  - RemoveComment
  - AddLabel
  - RemoveLabel
  - AddAssignee
  - RemoveAssignee
  - ToggleIssueStatus
- **Storage:** Hive box with operation type, payload, timestamp, retry count

### Feature 3: Enhanced Sync Service
- **Priority:** CRITICAL
- **Dependencies:** Pending Operations Queue, GitHubApiService
- **Description:** Process pending operations when network available
- **Features:**
  - Process queue in order
  - Retry failed operations
  - Report sync status
  - Handle conflicts with user input

### Feature 4: Conflict Resolution UI
- **Priority:** HIGH
- **Dependencies:** Enhanced Sync Service
- **Description:** Dialog to resolve conflicts between local and remote changes
- **UI Requirements:**
  - Show local vs remote versions
  - Allow user to choose which to keep
  - Merge option for simple conflicts

### Feature 5: Offline-Complete Issue Detail Screen
- **Priority:** HIGH
- **Dependencies:** Pending Operations Queue
- **Description:** Full CRUD support for offline issues
- **Operations:**
  - Add comments (queued for sync)
  - Add/remove labels (queued for sync)
  - Add/remove assignees (queued for sync)
  - All changes saved locally immediately

### Feature 6: Sync Status Dashboard
- **Priority:** MEDIUM
- **Dependencies:** Enhanced Sync Service
- **Description:** Detailed sync status in settings or dedicated screen
- **Information:**
  - Last sync time
  - Pending operations count
  - Failed operations with errors
  - Manual sync trigger

### Feature 7: Permission Persistence
- **Priority:** HIGH
- **Dependencies:** SecureStorageService or SharedPreferences
- **Description:** Remember permission grant status
- **Implementation:**
  - Save permission status after first grant
  - Check on app start
  - Only re-request if explicitly denied

---

## 4. Implementation Plan

### Phase 1: Foundation (Week 1)
**Goal:** Fix critical gaps and establish offline-first architecture

1. **Network Connectivity Service** (2 days)
   - Create `NetworkService` with connectivity monitoring
   - Add network check to all API calls
   - Update GitHubApiService to use NetworkService

2. **Permission Persistence** (1 day)
   - Save permission status in secure storage
   - Check on app startup
   - Skip permission dialog if previously granted

3. **Remove Demo Data in Offline Mode** (1 day)
   - Fix condition in main_dashboard_screen.dart
   - Ensure clean offline experience

**Deliverables:**
- NetworkService created and integrated
- Permission flow fixed
- No demo data in offline mode

### Phase 2: Pending Operations (Week 2)
**Goal:** Implement operation queue for offline changes

1. **Operation Queue Data Model** (2 days)
   - Define PendingOperation enum
   - Create PendingOperation model
   - Set up Hive box for operations

2. **Queue Management Service** (3 days)
   - Create `PendingOperationsService`
   - Implement add, remove, get all operations
   - Add operation retry logic

3. **Integrate with Create/Edit Screens** (2 days)
   - Update create_issue_screen.dart to queue operations
   - Update edit_issue_screen.dart to queue operations
   - Update issue_detail_screen.dart for all actions

**Deliverables:**
- PendingOperationsService fully functional
- All CRUD operations queued when offline

### Phase 3: Enhanced Sync (Week 3)
**Goal:** Robust sync when network returns

1. **Sync Queue Processor** (3 days)
   - Update SyncService to process pending operations
   - Implement retry logic for failed operations
   - Add sync progress tracking

2. **Sync Status UI** (2 days)
   - Update SyncCloudIcon with detailed status
   - Add sync status screen or panel
   - Show pending operations count

3. **Auto-Sync Implementation** (2 days)
   - Complete _syncNow() in settings
   - Implement auto-sync on network return
   - Respect auto-sync settings (WiFi vs any)

**Deliverables:**
- Pending operations sync automatically
- User can see sync status
- Manual sync trigger works

### Phase 4: Conflict Resolution (Week 4)
**Goal:** Handle conflicts gracefully

1. **Conflict Detection** (2 days)
   - Enhance _resolveIssuesConflict()
   - Detect conflicting changes (same issue edited locally and remotely)
   - Flag conflicts for user resolution

2. **Conflict Resolution UI** (3 days)
   - Create conflict resolution dialog
   - Show side-by-side comparison
   - Allow user to choose version or merge

3. **Testing & Polish** (2 days)
   - Test all offline scenarios
   - Fix edge cases
   - Add error handling

**Deliverables:**
- Conflicts detected and reported
- User can resolve conflicts
- Comprehensive offline testing complete

---

## 5. File-by-File Analysis

### `/lib/screens/main_dashboard_screen.dart`

**What Works:**
- Line 237-252: `_checkOfflineMode()` correctly reads auth_type
- Line 328-353: `_loadLocalIssues()` loads from vault and creates vault repo
- Line 126-181: Sync dialog shown when network available
- Line 689-714: Error message hidden in offline mode

**What Doesn't Work:**
- Line 369-388: Network check in UI layer, should be in service
- Line 454-481: Demo data logic flawed
- Line 78-82: `_checkLocalIssuesToSync()` has 2-second delay (hack)

**Missing:**
- No visual offline indicator in app bar
- No pending operations count display

---

### `/lib/services/sync_service.dart`

**What Works:**
- Line 93-112: `_setupConnectivityListener()` monitors network
- Line 104-111: Auto-sync triggered on network return
- Line 137-157: `syncLocalIssuesToRepo()` syncs to GitHub
- Line 374-408: Basic conflict resolution (remote wins)

**What Doesn't Work:**
- No pending operations queue
- No operation retry logic
- No detailed sync status
- Line 269-272: Auto-sync debounce too short (2 seconds)

**Missing:**
- Operation queue processing
- Conflict resolution UI trigger
- Sync progress tracking

---

### `/lib/services/local_storage_service.dart`

**What Works:**
- Line 43-77: `_saveIssueToVaultFile()` saves markdown with YAML frontmatter
- Line 118-151: `_loadIssuesFromVault()` loads issues from files
- Line 153-239: `_parseMarkdownToIssue()` parses markdown back to IssueItem
- Line 244-263: `removeLocalIssue()` deletes vault file

**What Doesn't Work:**
- No operation queue storage
- No tracking of pending changes
- No metadata for sync status

**Missing:**
- Pending operations storage
- Last sync time per issue
- Conflict flags

---

### `/lib/screens/create_issue_screen.dart`

**What Works:**
- Line 284-337: `_createIssue()` creates via GitHub API
- Repository selection works

**What Doesn't Work:**
- No offline mode handling
- Always calls GitHub API directly
- No queue for offline creation

**Missing:**
- Check for offline mode before API call
- Save to vault folder when offline
- Queue operation for later sync

---

### `/lib/screens/edit_issue_screen.dart`

**What Works:**
- Line 418-444: Handles local-only issues
- Line 418-438: Updates vault file for local issues
- Line 446-478: Updates GitHub for remote issues

**What Doesn't Work:**
- No operation queue
- Changes saved directly, not queued

**Missing:**
- Queue update operation when offline
- Track what was changed for smart sync

---

### `/lib/services/github_api_service.dart`

**What Works:**
- Line 59-97: `_executeWithRetry()` has retry logic
- Line 156-203: Error handling for network issues
- Line 329-380: `createIssue()` with proper error handling
- Line 387-436: `updateIssue()` for edits

**What Doesn't Work:**
- No proactive network check
- Reacts to errors instead of preventing them
- Timeouts may be too short for poor connections (10-15 seconds)

**Missing:**
- NetworkService integration
- Configurable timeouts
- Offline mode awareness

---

### `/lib/screens/issue_detail_screen.dart`

**What Works:**
- Line 743-764: Toggle status for local issues
- Line 973-1001: Remove assignee for local issues
- Line 1019-1047: Remove label for local issues

**What Doesn't Work:**
- Line 1136-1145: Comments blocked for local issues
- No operation queue for any changes
- Changes not persisted properly

**Missing:**
- Add comment offline (queue for sync)
- Add/remove labels offline (queue for sync)
- Add/remove assignee offline (queue for sync)

---

### `/lib/screens/onboarding_screen.dart`

**What Works:**
- Line 596-663: `_continueOffline()` flow
- Line 737-743: Folder selection with FilePicker
- Line 648-654: Saves auth_type and vault_folder

**What Doesn't Work:**
- Line 665-677: Permission not persisted
- User asked again on app restart

**Missing:**
- Save permission grant status
- Check saved status on startup

---

## 6. Test Scenarios Status

### Scenario A: Pure Offline (no repos)
- [x] Can create local issues - **PARTIAL** (works but no operation queue)
- [x] Can view local issues - **WORKS**
- [x] Can edit local issues - **PARTIAL** (basic edit works, no comments/labels/assignees)
- [ ] Issues saved to vault folder - **WORKS** but files not visible (permission issue)

### Scenario B: Offline with Cached Repos
- [x] Can view cached repos - **WORKS** (via vault repo)
- [x] Can view cached issues - **WORKS** (loaded from vault)
- [x] Can create new issues - **PARTIAL** (saved locally, no queue)
- [x] Can edit existing issues - **PARTIAL** (basic edit only)
- [x] Can close/reopen issues - **WORKS** (local state only)
- [ ] Changes queued for sync - **NOT IMPLEMENTED**

### Scenario C: Network Returns
- [x] Auto-detect network return - **WORKS** (connectivity listener)
- [x] Sync pending changes - **PARTIAL** (only isLocalOnly issues, no queue)
- [ ] Resolve conflicts - **NOT IMPLEMENTED** (silent remote wins)
- [ ] Update UI with sync status - **PARTIAL** (basic cloud icon only)

---

## 7. Recommendations

### Immediate Actions (Before Implementation)

1. **Add NetworkService** - Critical for preventing API failures
2. **Fix Permission Persistence** - High user friction point
3. **Remove Demo Data Bug** - Confusing for offline users

### Short-Term (Phase 1-2)

1. **Implement Operation Queue** - Foundation for all offline features
2. **Complete Offline CRUD** - Comments, labels, assignees
3. **Enhanced Sync Service** - Process queue automatically

### Long-Term (Phase 3-4)

1. **Conflict Resolution UI** - User-friendly conflict handling
2. **Sync Dashboard** - Visibility into sync status
3. **Comprehensive Testing** - All edge cases covered

---

## 8. Technical Debt

1. **Network Check in UI Layer** - Should be in service layer
2. **2-Second Delay Hack** - `_checkLocalIssuesToSync()` uses arbitrary delay
3. **No Error Boundaries** - Single sync failure can break entire flow
4. **Tight Coupling** - Services instantiate each other instead of DI
5. **No Unit Tests** - Offline logic untested

---

## 9. Dependencies Status

| Package | Version | Used For | Status |
|---------|---------|----------|--------|
| connectivity_plus | ^6.1.3 | Network monitoring | ✅ Implemented |
| flutter_secure_storage | ^10.0.0 | Auth & vault path | ✅ Implemented |
| hive | ^2.2.3 | Caching | ⚠️ Partial (no operation queue) |
| path_provider | ^2.1.5 | File paths | ⚠️ Not used for vault |
| file_picker | ^10.3.10 | Vault folder selection | ✅ Implemented |
| permission_handler | ^12.0.1 | Storage permission | ⚠️ Not persisted |

---

## 10. Conclusion

The offline mode implementation is **40% complete**. The foundation is solid (vault folder, markdown storage, isLocalOnly flag), but critical gaps exist:

1. **No operation queue** - Biggest gap
2. **Incomplete offline CRUD** - Comments, labels, assignees missing
3. **No conflict resolution** - Silent data loss possible
4. **Permission friction** - Asked every app start

**Estimated Effort:** 4 weeks for complete implementation
**Risk Level:** MEDIUM - Foundation exists but needs significant work

---

**Next Steps:**
1. Review this analysis with team
2. Prioritize gaps based on user impact
3. Begin Phase 1 implementation
4. Set up testing infrastructure for offline scenarios
