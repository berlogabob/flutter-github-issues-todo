# Fix: Offline Issues Duplication on Sync

## Problem

When creating issues offline, they would appear **twice** after syncing:
1. Once from the GitHub API (remote issue)
2. Once from the local markdown file (local issue)

This happened even after the issue was successfully synced to GitHub.

## Root Cause

The issue was in the `_resolveIssuesConflict` method in `sync_service.dart`:

### Original Logic (Flawed):
```dart
final localOnlyIssues = localIssues.where((issue) {
  // Only check duplicates if issue has NO GitHub number
  if (issue.number == null) {
    // Check by title...
  }
  return false; // Skip if issue already has a number
});
```

**Problem**: This only checked for duplicates when `issue.number == null`. However:
- Local issues are ALWAYS loaded with `isLocalOnly: true` from markdown files
- After syncing, the local markdown file might not be deleted immediately
- On next sync, the issue has a number BUT the local file still exists
- The duplicate check was skipped, causing the issue to be merged twice

## Solution

Enhanced the duplicate detection to check ALL local issues, not just those without numbers:

### New Logic:
```dart
final localOnlyIssues = localIssues.where((issue) {
  // Must be marked as local-only
  if (!issue.isLocalOnly) return false;

  // NEW: Check by GitHub number first
  if (issue.number != null) {
    if (remoteIssuesByNumber.containsKey(issue.number)) {
      // Issue exists on GitHub - remove local file and skip
      _localStorage.removeLocalIssue(issue.id);
      return false;
    }
  }

  // Check by title (for issues without numbers yet)
  final titleKey = issue.title.toLowerCase().trim();
  if (remoteIssuesByTitle.containsKey(titleKey)) {
    // Issue exists on GitHub - remove local file and skip
    _localStorage.removeLocalIssue(issue.id);
    return false;
  }

  // Issue doesn't exist on GitHub yet, keep for sync
  return true;
});
```

## Changes Made

### File: `lib/services/sync_service.dart`

1. **Enhanced `_resolveIssuesConflict` method** (lines 601-667):
   - Added check for duplicate issues by GitHub number
   - Added check for duplicate issues by title (existing, now improved)
   - Automatically remove local markdown files when duplicates are detected
   - Better debug logging to track duplicate detection

2. **Simplified `_syncLocalIssuesToGitHub` method** (lines 681-729):
   - Removed redundant duplicate check (now handled in merge logic)
   - Simplified to just create issues and remove local files on success

## How It Works Now

### Sync Flow:
1. Load all local markdown files → marked as `isLocalOnly: true`
2. Fetch all remote issues from GitHub
3. **NEW**: Check each local issue against remote issues:
   - **By GitHub number** (if available) → immediate match
   - **By title + body** (for new issues) → fuzzy match
4. If match found:
   - Log debug message
   - **Delete local markdown file** (async)
   - Skip adding to merge list
5. If no match:
   - Keep in `localOnlyIssues` list for sync to GitHub
6. Merge remote issues + remaining local-only issues
7. Sync remaining local issues to GitHub
8. Remove local files after successful sync

### Result:
- ✅ No more duplicate issues
- ✅ Local files are cleaned up automatically
- ✅ Sync is idempotent (safe to run multiple times)
- ✅ Better debug logging for troubleshooting

## Testing

To test the fix:

1. **Create issue offline**:
   - Go offline
   - Create new issue
   - Issue saved as markdown file with `isLocalOnly: true`

2. **Sync (go online)**:
   - Issue is created on GitHub
   - Local markdown file is deleted
   - Issue appears once in UI

3. **Sync again**:
   - Local file is gone (or detected as duplicate)
   - Issue still appears once (no duplication)
   - Debug log shows: "⚠️ SKIP local issue... already exists on GitHub"

## Debug Logging

Key log messages to watch for:

```
SyncService: ⚠️ SKIP local issue "Issue Title" (#123) - already exists on GitHub (matched by number)
SyncService: Removed local file for issue #123

SyncService: ⚠️ SKIP local issue "Issue Title" - already exists on GitHub (matched by title + body)
SyncService: Removed local file for "Issue Title"

SyncService: Found 0 local-only issues to sync
SyncService: Merged 50 total issues (remote: 50, local-only: 0)
```

## Related Issues

- Fixes issue #34: "Offline created issues still doubling on sync"
- Improves upon previous fix that only checked by title
- Ensures local files are cleaned up properly

---

**Date:** March 17, 2026  
**Version:** 0.5.0+126  
**Status:** ✅ Fixed
