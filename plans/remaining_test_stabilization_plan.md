# Remaining Flutter Offline-First Stabilization Plan

## Summary

Continue from the current modified state, where analyzer, debug APK build, repo-detail tests, and search tests are green. The next work is to stabilize the remaining broad widget/service tests without undoing the validated offline-first fixes.

## Key Changes

- Preserve current production fixes:
  - cached dashboard hydration must remain read-only and must not create/probe fallback vault storage during first render.
  - empty-state UI must remain responsive/scrollable in short containers.
- Stabilize stale tests in this order:
  1. `settings_screen_full_test.dart`
  2. `edit_issue_screen_test.dart`
  3. `project_board_screen_test.dart`
  4. `error_logging_service_test.dart`
- Replace broad `pumpAndSettle()` usage with bounded pumps or small helpers, because animated loaders/empty states keep frames scheduled.
- Replace old `CircularProgressIndicator` expectations with current `BrailleLoader`, or with "loaded state appears immediately" assertions when cache hydration is fast.
- For `ErrorLoggingService`, add a test-only reset hook if needed:
  - `@visibleForTesting Future<void> resetForTesting()`
  - clears `_isInitialized` and `_logFile`
  - use it in test setup to avoid singleton state leaking between temp directories.

## Implementation Steps

1. Run each focused suite before editing to confirm current failure shape.
2. Patch only the failing suite or the smallest shared production bug.
3. After each patch, run its focused suite:
   - `flutter test test/screens/settings_screen_full_test.dart --reporter compact`
   - `flutter test test/screens/edit_issue_screen_test.dart --reporter compact`
   - `flutter test test/screens/project_board_screen_test.dart --reporter compact`
   - `flutter test test/services/error_logging_service_test.dart --reporter compact`
4. Re-run:
   - `flutter analyze`
   - `flutter build apk --debug`
   - `flutter test --reporter compact --concurrency=1`
5. Do not use `--fail-fast`; this Flutter runner can crash after assertion failures.
6. Clean `flutter_*.log` after any runner crash.

## Test Plan

- Focused green gates:
  - repo detail remains green
  - search full remains green
  - search my-issues remains green
  - settings/edit/project-board/error-logging become green
- Full serial gate target:
  - `flutter test --reporter compact --concurrency=1` completes without hangs.
- Final Android gate:
  - `flutter build apk --debug` succeeds.

## Assumptions

- Stale widget tests should be updated to current UI behavior; do not add artificial production delays just to expose transient loading states.
- Production changes are allowed only when tests expose a real user-facing issue, such as overflow, blocked first paint, singleton state leakage, or offline-first regression.
- Keep the plan file in `plans/` rather than adding another top-level plan document.
