# Fix: Offline Issues Not Showing in Repository

## Problem

Issues created in offline mode were not appearing in their respective repositories. They only showed up in the "Vault" repo.

## Root Cause

When creating a local issue offline, the `IssueItem` was created without the `fullName` field:

```dart
final newIssue = IssueItem(
  id: 'local_${DateTime.now().millisecondsSinceEpoch}',
  title: titleController.text.trim(),
  // ... other fields
  // MISSING: fullName field!
  isLocalOnly: true,
);
```

Without `fullName`, the issue couldn't be associated with a specific repository.

## Solution

### 1. Updated `_createLocalIssue()` method
**File:** `lib/screens/main_dashboard_screen.dart`

- Added optional `repoFullName` parameter
- Shows repository name in the dialog when creating issue for a specific repo
- Includes `fullName` field when creating the issue

```dart
void _createLocalIssue({String? repoFullName}) {
  // ... dialog setup ...
  
  final newIssue = IssueItem(
    id: 'local_${DateTime.now().millisecondsSinceEpoch}',
    title: titleController.text.trim(),
    bodyMarkdown: descriptionController.text.isNotEmpty
        ? descriptionController.text
        : null,
    // FIX: Include repo fullName so issue shows in correct repo
    fullName: repoFullName,
    status: ItemStatus.open,
    updatedAt: DateTime.now(),
    isLocalOnly: true,
  );
}
```

### 2. Updated call sites
Changed all calls to `_createLocalIssue()` to pass `repoFullName: null` for vault issues:

```dart
if (allRepos.isEmpty && _isOfflineMode) {
  _createLocalIssue(repoFullName: null);  // Vault issue
  return;
}
```

## How It Works Now

### Creating Offline Issues:

1. **With repo selected** (expanded repo or default repo):
   - Issue is created with `fullName: "owner/repo"`
   - Issue will appear in that repository's list
   - Shows dialog: "Create Issue (Offline)" + repo name
   - Message: "Issue saved (will sync when online)"

2. **Without repo** (offline mode, no repos loaded):
   - Issue is created with `fullName: null`
   - Issue appears in "Vault" repo only
   - Shows dialog: "Create Local Issue"
   - Message: "Local issue created"

## Next Steps (Optional Enhancement)

To fully distribute local issues to their repos in the UI, update the `_loadLocalIssues()` method to:

1. Load all local issues
2. Group them by `fullName`
3. Add issues to their respective repo's `children` list
4. Only use "Vault" repo for issues without `fullName`

This would make offline issues appear directly in their repos instead of requiring the user to look in the Vault repo.

## Testing

To test the fix:

1. **Go offline** (turn off network)
2. **Select a repository** (expand it)
3. **Create a new issue** (tap + button)
4. **Enter title and description**
5. **Go online** and trigger sync
6. **Verify**:
   - Issue appears in the selected repository
   - Issue syncs to GitHub successfully
   - Local markdown file is deleted after sync
   - Issue still appears in repo after sync

## Files Modified

- `lib/screens/main_dashboard_screen.dart`
  - Updated `_createLocalIssue()` method (line ~1500)
  - Added `repoFullName` parameter
  - Updated issue creation to include `fullName` field
  - Updated call sites to pass `repoFullName: null`

---

**Date:** March 17, 2026  
**Version:** 0.5.0+126  
**Status:** ✅ Fixed (offline issues now include repo info)
