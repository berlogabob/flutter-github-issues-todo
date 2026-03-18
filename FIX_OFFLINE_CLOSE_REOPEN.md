# Fix: Offline Mode - Close/Reopen Issues

## Problem

In offline mode, users couldn't close or reopen issues. The functionality was missing for local issues created offline.

## Solution

Added offline support for closing and reopening issues:

### 1. Issue Detail Screen (`issue_detail_screen.dart`)

**Updated `_toggleStatus()` method:**
- For local issues (`isLocalOnly: true`):
  - Updates the issue status (open ↔ closed)
  - **Saves the change to the local markdown file**
  - Shows appropriate snackbar message

```dart
if (_currentIssue.isLocalOnly) {
  // Local issue - update state and save to file
  final updatedIssue = IssueItem(
    id: _currentIssue.id,
    title: _currentIssue.title,
    status: _currentIssue.status == ItemStatus.open
        ? ItemStatus.closed
        : ItemStatus.open,
    updatedAt: DateTime.now(),
    // ... other fields
    isLocalOnly: true,
  );
  
  setState(() {
    _currentIssue = updatedIssue;
  });
  
  // Save the status change to the local file
  await _localStorage.saveLocalIssue(updatedIssue);
  
  _showSnackBar(
    updatedIssue.status == ItemStatus.open
        ? 'Issue reopened (local)'
        : 'Issue closed (local)',
  );
  return;
}
```

### 2. Expandable Repo Widget (`expandable_repo.dart`)

**Updated `_closeIssue()` method:**
- For local issues:
  - Creates updated issue with `status: ItemStatus.closed`
  - **Saves the change to the local markdown file**
  - Updates the issue list in UI
  - Shows "Issue closed (local)" message

**Added imports:**
- `import '../services/local_storage_service.dart';`

**Added service instance:**
```dart
final LocalStorageService _localStorage = LocalStorageService();
```

## How It Works

### Closing an Issue Offline:

1. **Swipe left on issue** OR **Tap close button**
2. Issue status changes to `closed`
3. Status is saved to local markdown file
4. Issue appears as closed in the UI
5. When network is restored:
   - Issue is synced to GitHub as closed
   - Local markdown file is deleted

### Reopening an Issue Offline:

1. **Tap on closed issue** to open detail screen
2. **Tap "Reopen" button**
3. Issue status changes to `open`
4. Status is saved to local markdown file
5. Issue appears as open in the UI
6. When network is restored:
   - Issue is synced to GitHub as open
   - Local markdown file is deleted

## Sync Behavior

When the network is restored:

1. **Local issues are synced to GitHub** with their current status
2. **Queued operations** (for GitHub issues edited offline) are executed
3. **Local markdown files are deleted** after successful sync
4. **UI is refreshed** to show the synced state

## Files Modified

1. `lib/screens/issue_detail_screen.dart`
   - Updated `_toggleStatus()` method
   - Added save to local storage for local issues

2. `lib/widgets/expandable_repo.dart`
   - Updated `_closeIssue()` method
   - Added LocalStorageService import and instance
   - Save status changes to local files

## Testing

To test the fix:

1. **Go offline** (turn off network)
2. **Create a new issue** (or use existing local issue)
3. **Close the issue**:
   - Swipe left on the issue card, OR
   - Open issue detail and tap "Close"
4. **Verify**:
   - Issue shows as closed (strikethrough title, closed icon)
   - Status persists after app restart
   - Markdown file contains `status: closed`

5. **Reopen the issue**:
   - Tap on the closed issue
   - Tap "Reopen" button
6. **Verify**:
   - Issue shows as open again
   - Status persists after app restart
   - Markdown file contains `status: open`

7. **Go online and sync**:
   - Issue is created on GitHub with correct status
   - Local markdown file is deleted
   - Issue appears in GitHub repo

## User Experience

### Visual Feedback:
- ✅ Closed issues show with strikethrough title
- ✅ Closed icon (checkmark) appears
- ✅ Snackbar messages confirm status changes
- ✅ "(local)" indicator shows issue is offline-only

### Messages:
- "Issue closed (local)" - when closing offline issue
- "Issue reopened (local)" - when reopening offline issue
- "Issue queued for sync" - when closing GitHub issue offline

---

**Date:** March 17, 2026  
**Version:** 0.5.0+127  
**Status:** ✅ Fixed - Offline close/reopen now works!
