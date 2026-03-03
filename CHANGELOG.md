# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **Issue #16: Default State Persistence Fixed**
  - Fixed default repository and project not persisting correctly across app restarts
  - Fixed settings pickers to save selection to LocalStorageService with confirmation
  - Create Issue screen now auto-loads saved defaults on open
  - Dashboard monitors for default repo changes and updates pinned repos
  - State restoration verified after app termination and restart
  - Added user confirmation feedback (snackbar) after default selection

- **Issue #21: Main Dashboard Loading and Filter Issues Fixed**
  - Fixed dashboard loading with batch processing for large datasets (100+ repos)
  - Implemented concurrent issue fetching with max 5 repos per batch
  - Fixed filter persistence across navigation sessions
  - Fixed pin state persistence for repositories
  - Added per-repository loading and error state tracking
  - Improved error handling to avoid overwhelming users with multiple snackbars
  - Added rate limiting (200ms delay between batches) to avoid API throttling

- **Issue #20: Repo/Project Menu and Selection Persistence Fixed**
  - Added search functionality to repository picker dialog
  - Added search functionality to project picker dialog
  - Fixed project picker to filter out closed projects by default
  - Fixed offline mode detection in repo/project library screen
  - Fixed default repo auto-pinning on dashboard
  - Fixed default project selection persistence in settings
  - Added visual highlighting for selected items in pickers
  - Improved debug logging for troubleshooting selection issues

- **Issue #23: Cache Invalidation Logic Fixed**
  - Fixed cache initialization race conditions with `_isInitializing` flag
  - Added comprehensive error handling with try/catch for all cache operations
  - Implemented cache HIT/MISS/EXPIRED logging for debugging
  - Enforced TTL (5 minutes default) with automatic expiration
  - Added fallback to network when cache miss occurs
  - Added `invalidate()` method for explicit cache invalidation
  - Added `getStats()` method for cache debugging
  - Added `refresh()` method for pull-to-refresh scenarios

- **Issue #22: Create Issue Flow Bugs Fixed**
  - Fixed repository selector state management (clears data when repo changes)
  - Added comprehensive input validation (title required, max length checks)
  - Improved error messages for API failures (422, 401, 403, network errors)
  - Added retry button for failed label/assignee loading
  - Improved offline queue handling with proper error recovery
  - Added network error fallback (queues issue for later sync)
  - Added title validation: required, max 256 characters, no line breaks
  - Added body validation: max 65536 characters

### Added

- **Testing & Quality**
  - Widget tests for all 7 screens (210+ tests)
  - Integration tests for 5 user journeys (50+ tests)
  - Performance benchmarks (5 scenarios, 30+ tests)
  - Total test count: 290+ automated tests

- **Error Handling**
  - Error boundary with retry and go back buttons
  - Expandable error details with copy functionality
  - Local error logging service
  - Error log viewer in settings screen
  - Error count badge in settings

- **Comments Feature**
  - View issue comments in detail screen with pagination (20 per page)
  - Delete your own comments with confirmation dialog
  - Markdown rendering for comment bodies using `flutter_markdown_plus`
  - Comment avatars cached with `cached_network_image`
  - "Load more comments" button for issues with 20+ comments
  - Expandable/collapsible comments section

- **Empty State Illustrations**
  - 5 custom illustrations using `CustomPainter` (lightweight, <5KB each)
  - No Repos: Folder with question mark
  - No Issues: Checklist with X mark
  - No Comments: Speech bubble with question mark
  - No Projects: Kanban board with question mark
  - Search Empty: Magnifying glass with question mark
  - Subtle opacity pulse animation (2 second cycle)
  - Dark theme compatible with `AppColors`

- **Tutorial System**
  - First-time user onboarding (5 steps)
  - Welcome + app purpose
  - Swipe gestures explanation
  - Create new issue guidance
  - Sync status indicator meaning
  - Filter chips usage
  - Persistent completion status via `LocalStorageService`
  - Skip and "Got It" options
  - Reset functionality via `TutorialManager`

- **Pagination for Comments**
  - Comments load in pages of 20 items
  - Page-based caching with 5-minute TTL
  - Efficient loading for issues with many comments

### Changed

- **Error Boundary**: Now shows recovery options (retry, go back, expandable details)
- **Error Logging**: Now saves to file at `${appDirectory}/errors.log`
- **Comments Section**: Now expandable/collapsible (was: always expanded)
- **Empty States**: Now use custom illustrations (was: text only)
- **Tutorial**: Custom implementation (was: no tutorial)

### Fixed

- All analyzer warnings (was: 6 warnings, now: 0 errors, 0 warnings)
- Comment avatar caching with `CachedNetworkImage`
- Tutorial dismiss persistence in local storage
- Unused imports and dead code across 7 files
- Switch exhaustiveness for `OperationType.deleteComment`
- Public API documentation with dartdoc comments
- Error boundary styling with `AppColors`
- Error log screen loading states

### Testing

| Metric | Before Sprint 18 | After Sprint 18 | Improvement |
|--------|-----------------|-----------------|-------------|
| Total Tests | ~130 | 290+ | +123% |
| Widget Tests | ~75 | 210+ | +180% |
| Integration Tests | ~5 | 50+ | +900% |
| Benchmark Tests | 0 | 30+ | New |
| Test Coverage | ~30% | ~60% | +100% |

### Performance

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Analyzer Errors | 6 | 0 | -100% |
| Analyzer Warnings | 6 | 0 | -100% |
| Comment Load Time | N/A | <500ms | New |
| Illustration Size | N/A | <5KB each | New |
| Tutorial Dismissal | N/A | 1 tap | New |

## [0.5.0] - 2026-03-02

### Added

- Sprint 15: GitHub Integration Enhancements
- Real assignee picker with GitHub API integration
- Real label picker with GitHub API integration
- Project picker in settings screen
- My Issues filter with actual user authentication
- Haptic feedback for swipe actions and button taps

### Changed

- Assignee selection now uses GitHub API
- Label selection now uses GitHub API
- Search My Issues filter now uses real user data

## [0.4.0] - Previous Release

### Added

- Initial offline-first architecture
- Pending operations queue
- Basic issue management
- Repository browsing

---

**Note**: Version numbers are for reference. Actual versioning decisions are made by the project maintainer.
