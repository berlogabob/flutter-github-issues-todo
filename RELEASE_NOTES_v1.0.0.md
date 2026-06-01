# GitDoIt v1.0.0

Release date: 2026-06-02

GitDoIt v1.0.0 is the first stable release of the offline-first GitHub Issues
TODO manager. It focuses on reliable issue workflows, local-first operation,
sync recovery, GitHub Projects support, and release-grade test coverage.

## Highlights

- Offline-first issue management with local queueing and later sync.
- Repository and project defaults with persisted selection state.
- Create, edit, close, reopen, label, assign, and comment workflows.
- Background sync, pending-operation visibility, and sync status dashboard.
- Dashboard, search, repository detail, issue detail, project board, settings,
  onboarding, error log, and debug screens.
- Error boundary, local error logging, retry affordances, and auth error handling.
- First-time tutorial, empty-state illustrations, skeleton loading, and
  pull-to-refresh support.

## Fixed Issues

- #16: Default repository/project state now persists across restarts.
- #20: Repository and project picker search, filtering, highlighting, and
  selection persistence are fixed.
- #21: Dashboard loading, filter persistence, pin persistence, and batch issue
  fetching are fixed for larger repository sets.
- #22: Create issue flow validation, repo switching, error handling, offline
  fallback, and auto-selected repository visibility are fixed.
- #23: Cache initialization, TTL handling, explicit invalidation, and refresh
  behavior are fixed.

## Release Artifacts

- Android APK: `app-release.apk`
- Android App Bundle: `app-release.aab`
- Web build: generated with `--base-href=/flutter-github-issues-todo/`

## Validation

- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`
- `flutter build apk --release`
- `flutter build appbundle --release`
- `flutter build web --release --base-href=/flutter-github-issues-todo/`
