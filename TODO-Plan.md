TODO-Plan.md

The plan uses short (3–10 day) focused sprints with clear acceptance criteria. Priorities reflect:

- Risk reduction (crashes, data loss, auth breakage)
- User experience & polish
- Long-term maintainability
- Production readiness (builds, testing, observability)

### Sprint 0 – Pre-Release Hardening (4–6 days)
Goal: Make the app safe to ship (no data loss, no hard crashes).

1. [ ] Implement **pending local mutations queue** in Hive  
   → Offline created/updated/closed issues → stored as list of operations  
   → Replay on next successful sync (in order)  
   → Show “Pending sync (3 changes)” badge

2. [ ] Add **optimistic updates + rollback** on issue create/edit/close  
   → Use Riverpod AsyncNotifier + .whenData() pattern  
   → Rollback UI + show snackbar on sync failure

3. [ ] Fix / complete **SyncService** edge cases  
   → Handle 401/403/422 properly (force re-auth)  
   → Exponential backoff retry (3 attempts)  
   → Debounce network change events properly (dispose subscription)

4. [ ] Wrap entire app in global **ErrorBoundary** widget  
   → Catch unhandled exceptions → show “Something went wrong” screen + report button (copy logs)

5. [ ] Add **Dio** instead of raw `http` package  
   → Auth interceptor (token from secure storage)  
   → Logging interceptor (debug only)  
   → Connectivity-aware retry

**Acceptance**:  
- Can work fully offline → make changes → reconnect → changes appear on GitHub  
- App never hard-crashes on network errors / JSON parse fails  
- Build succeeds with `--release --analyze-size`

### Sprint 1 – Navigation & Routing (3–5 days)
Goal: Replace fragile initial-route logic with real navigation.

1. [ ] Add **go_router** + riverpod integration  
   → Typed routes for all 7 screens  
   → `/dashboard`, `/issue/:id`, `/project/:nodeId/board`, etc.

2. [ ] Implement **auth redirect guard**  
   → Unauthenticated → `/onboarding`  
   → Authenticated but no repo selected → `/onboarding?step=repo`  
   → Deep link support (issue URLs)

3. [ ] Migrate all `Navigator.push` → `context.go()` / `context.push()`

**Acceptance**:  
- No more manual `if (token != null)` in main.dart  
- Back button / system navigation works correctly everywhere  
- Can open issue detail from search / dashboard

### Sprint 2 – Models & Code Generation (4–7 days)
Goal: Stop manual JSON hell, make models safe & immutable.

1. [ ] Add **freezed** + **json_serializable** (or built_value)  
   → Convert Item → IssueItem, ProjectItem, RepoItem to @freezed

2. [ ] Add **hive_generator** + @HiveType / @HiveField  
   → Generate adapters for all models  
   → Register adapters in main.dart

3. [ ] Replace manual toJson/fromJson everywhere  
   → Use .toJson() / .fromJson() from freezed

4. [ ] Add **copyWith** usage in forms & state updates

**Acceptance**:  
- No more `UnimplementedError` in fromJson  
- Hive boxes read/write complex objects without crashes  
- Models are immutable → easier reasoning & testing

### Sprint 3 – Testing & Quality Gates (5–8 days)
Goal: Stop regressions before they reach users.

1. [ ] Write **widget tests** for critical flows (30–40 tests)  
   → Onboarding → auth → dashboard load  
   → Issue create/edit → sync indicator changes

2. [ ] Add **golden tests** for main screens (dark mode only)

3. [ ] Add **very basic integration test** (one happy path: login → create issue → close)

4. [ ] Set up **GitHub Actions** CI (flutter analyze + test + build apk/ios)

**Acceptance**:  
- CI passes on every push  
- At least 60–70% coverage on business logic (models + services)  
- No new lint warnings

### Sprint 4 – Production & Release Polish (5–7 days)
Goal: Ship something people can install & love.

1. [ ] Add **skeleton loading** (skeletonizer package) on dashboard & lists

2. [ ] Implement **pull-to-refresh** + loading indicators everywhere data is fetched

3. [ ] Final UI micro-polish pass  
   → Consistent spacing/padding (use constants/)  
   → Fix any layout overflows on small devices  
   → Improve sync icon states & animations

4. [ ] Write proper **release build instructions** in README  
   → Signing, fastlane / codemagic snippet, version bumping

5. [ ] Create **v1.0.0 tag** + GitHub Release with changelog

**Acceptance**:  
- App feels snappy & professional  
- Users can install APK / TestFlight without docs gymnastics  
- First public release published

### Post 1.0 – Quick Wins Phase (after release, 2–4 weeks)

**Sprint A – Background & Reliability** (priority)  
- Add workmanager → background sync every 15–30 min (when online)  
- Add simple crash reporting (Sentry / Firebase Crashlytics free tier)

**Sprint B – User Requested Features** (vote-based)  
- Issue comments read/write  
- Pagination (issues list > 30 items)  
- Light theme toggle (low effort now that design system exists)

**Sprint C – Maintainability**  
- Replace reorderables → native ReorderableListView / SliverReorderableList  
- Introduce Talker / Logger instead of print  
- Extract clean repository pattern (IssueRepository, ProjectRepository)

This plan keeps sprints **short & outcome-focused**. You can release after Sprint 4 with confidence that core offline/sync/auth/edit flows are robust.

If you want any sprint expanded into detailed subtasks / file change suggestions / example code structure — tell me which one and I'll go deeper. Good luck shipping!