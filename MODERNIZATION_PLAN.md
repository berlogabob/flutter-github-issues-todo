# GitDoIt Modernization Plan

**Goal:** Upgrade GitDoIt to modern Flutter standards while maintaining stability  
**Duration:** 8 Sprints (2-3 days each)  
**Risk Level:** Medium (incremental changes with testing)

---

## 📊 Sprint Overview

| Sprint | Focus | Duration | Risk |
|--------|-------|----------|------|
| 1 | Code Quality Foundation | 1-2 days | Low |
| 2 | Dio HTTP Client | 2-3 days | Medium |
| 3 | GoRouter Navigation | 2-3 days | Medium |
| 4 | Freezed Models (Part 1) | 2-3 days | Medium |
| 5 | Freezed Models (Part 2) | 2-3 days | Medium |
| 6 | Flutter Hooks & Riverpod | 1-2 days | Low |
| 7 | UI Polish (Gap, Formz) | 1-2 days | Low |
| 8 | Testing & Cleanup | 2-3 days | Low |

---

## 🎯 Sprint 1: Code Quality Foundation

**Goal:** Establish stricter code quality standards

### Tasks
- [ ] **1.1** Add `very_good_analysis` to `pubspec.yaml`
- [ ] **1.2** Update `analysis_options.yaml`
- [ ] **1.3** Run `flutter analyze` and fix critical issues
- [ ] **1.4** Add `gap` package for consistent spacing
- [ ] **1.5** Run `dart format .`

### Dependencies to Add
```yaml
dev_dependencies:
  very_good_analysis: ^6.0.0
dependencies:
  gap: ^3.0.0
```

### Acceptance Criteria
- ✅ `flutter analyze` passes with 0 errors
- ✅ Code is properly formatted
- ✅ No deprecated API usage

### Files to Modify
- `pubspec.yaml`
- `analysis_options.yaml`

---

## 🎯 Sprint 2: Dio HTTP Client

**Goal:** Replace `http` package with `dio` for better error handling and logging

### Tasks
- [ ] **2.1** Add `dio` and `talker_dio_logger` to `pubspec.yaml`
- [ ] **2.2** Create `DioClient` service (singleton with configuration)
- [ ] **2.3** Update `GitHubApiService` to use Dio
- [ ] **2.4** Implement Dio interceptors (logging, retry, error handling)
- [ ] **2.5** Remove old `http` package
- [ ] **2.6** Test all API calls (repos, issues, comments)

### Dependencies to Add
```yaml
dependencies:
  dio: ^5.7.0
  talker_dio_logger: ^4.0.0
```

### Acceptance Criteria
- ✅ All API calls work with Dio
- ✅ Retry logic works (test with network issues)
- ✅ Logging shows in console
- ✅ Error messages are user-friendly

### Files to Modify
- `pubspec.yaml`
- `lib/services/dio_client.dart` (new)
- `lib/services/github_api_service.dart`

---

## 🎯 Sprint 3: GoRouter Navigation

**Goal:** Implement declarative navigation with go_router

### Tasks
- [ ] **3.1** Add `go_router` to `pubspec.yaml`
- [ ] **3.2** Create `app_router.dart` with route definitions
- [ ] **3.3** Define all 7 MVP screen routes
- [ ] **3.4** Update `main.dart` to use GoRouter
- [ ] **3.5** Replace `Navigator.push()` calls with `context.go()`/`context.push()`
- [ ] **3.6** Add route parameters (repo_id, issue_number, etc.)
- [ ] **3.7** Test deep navigation scenarios

### Dependencies to Add
```yaml
dependencies:
  go_router: ^14.0.0
```

### Acceptance Criteria
- ✅ All screens navigable via routes
- ✅ Back button works correctly
- ✅ Route parameters pass correctly
- ✅ Can navigate with named routes

### Files to Modify
- `pubspec.yaml`
- `lib/main.dart`
- `lib/router/app_router.dart` (new)
- All screen files

---

## 🎯 Sprint 4: Freezed Models (Part 1) - Core Models

**Goal:** Migrate `Item`, `RepoItem`, `IssueItem` to freezed

### Tasks
- [ ] **4.1** Add `freezed` and `json_serializable` to `pubspec.yaml`
- [ ] **4.2** Update `Item` model with `@freezed`
- [ ] **4.3** Update `RepoItem` model with `@freezed`
- [ ] **4.4** Update `IssueItem` model with `@freezed`
- [ ] **4.5** Run `build_runner` to generate code
- [ ] **4.6** Update all usages of `copyWith()` (now auto-generated)
- [ ] **4.7** Fix any breaking changes

### Dependencies to Add
```yaml
dependencies:
  freezed_annotation: ^2.4.4
  json_serializable: ^6.8.0

dev_dependencies:
  freezed: ^2.5.2
```

### Acceptance Criteria
- ✅ All models compile without errors
- ✅ `build_runner` generates files
- ✅ All `copyWith()` calls still work
- ✅ JSON serialization works
- ✅ Tests pass

### Files to Modify
- `pubspec.yaml`
- `lib/models/item.dart`
- `lib/models/repo_item.dart`
- `lib/models/issue_item.dart`
- `lib/models/project_item.dart`

---

## 🎯 Sprint 5: Freezed Models (Part 2) - Services & Providers

**Goal:** Update all services and providers to use new freezed models

### Tasks
- [ ] **5.1** Update `GitHubApiService` to use freezed models
- [ ] **5.2** Update `LocalStorageService` to use freezed models
- [ ] **5.3** Update `SyncService` to use freezed models
- [ ] **5.4** Update all providers in `app_providers.dart`
- [ ] **5.5** Update all widgets that use models
- [ ] **5.6** Run full test suite
- [ ] **5.7** Fix any runtime issues

### Acceptance Criteria
- ✅ API service parses responses correctly
- ✅ Local storage saves/loads correctly
- ✅ Sync service works with new models
- ✅ All screens render correctly
- ✅ No runtime type errors

### Files to Modify
- `lib/services/github_api_service.dart`
- `lib/services/local_storage_service.dart`
- `lib/services/sync_service.dart`
- `lib/providers/app_providers.dart`
- All widget files that use models

---

## 🎯 Sprint 6: Flutter Hooks & Riverpod

**Goal:** Add flutter_hooks for cleaner widget code

### Tasks
- [ ] **6.1** Add `flutter_hooks` and `hooks_riverpod` to `pubspec.yaml`
- [ ] **6.2** Identify widgets that benefit from hooks
- [ ] **6.3** Convert `MainDashboardScreen` to use hooks (optional)
- [ ] **6.4** Convert `IssueDetailScreen` to use hooks (optional)
- [ ] **6.5** Update Riverpod providers to use `hooks_riverpod`
- [ ] **6.6** Test converted widgets

### Dependencies to Add
```yaml
dependencies:
  flutter_hooks: ^0.20.0
  hooks_riverpod: ^3.3.1
```

### Acceptance Criteria
- ✅ Hooks work correctly in converted widgets
- ✅ No state management bugs
- ✅ Code is cleaner

### Files to Modify
- `pubspec.yaml`
- Selected screen files (optional)

---

## 🎯 Sprint 7: UI Polish (Gap, Formz)

**Goal:** Add UI helper packages for better UX

### Tasks
- [ ] **7.1** Replace `SizedBox` with `Gap` where appropriate
- [ ] **7.2** Add `formz` for form validation
- [ ] **7.3** Create validation classes for forms
- [ ] **7.4** Update `CreateIssueScreen` with formz validation
- [ ] **7.5** Update `EditIssueScreen` with formz validation

### Dependencies to Add
```yaml
dependencies:
  formz: ^0.8.0
```

### Acceptance Criteria
- ✅ UI spacing is consistent
- ✅ Forms validate input correctly
- ✅ Error messages show for invalid input

### Files to Modify
- All screen files (Gap replacement)
- `lib/screens/create_issue_screen.dart`
- `lib/screens/edit_issue_screen.dart`

---

## 🎯 Sprint 8: Testing & Cleanup

**Goal:** Ensure everything works and clean up technical debt

### Tasks
- [ ] **8.1** Run `flutter test` and fix failing tests
- [ ] **8.2** Run `flutter analyze` and fix all warnings
- [ ] **8.3** Update `CHANGELOG.md` with all changes
- [ ] **8.4** Update `README.md` with new dependencies
- [ ] **8.5** Remove unused imports
- [ ] **8.6** Remove old code
- [ ] **8.7** Run `flutter pub upgrade`
- [ ] **8.8** Build release APK
- [ ] **8.9** Manual testing of all screens

### Acceptance Criteria
- ✅ All tests pass
- ✅ Zero analysis errors
- ✅ App builds successfully
- ✅ All screens work correctly

### Files to Modify
- `CHANGELOG.md`
- `README.md`

---

## 📦 Final Dependencies Summary

### Production Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management (upgraded)
  flutter_riverpod: ^3.3.1
  hooks_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2

  # Navigation (NEW)
  go_router: ^14.0.0

  # Network (upgraded)
  dio: ^5.7.0
  talker_dio_logger: ^4.0.0

  # Local storage (keep current)
  hive_ce: ^2.10.1
  hive_ce_flutter: ^2.2.0

  # Code generation (NEW)
  freezed_annotation: ^2.4.4
  json_serializable: ^6.8.0

  # Forms (NEW)
  formz: ^0.8.0

  # UI helpers (NEW)
  gap: ^3.0.0
  flutter_hooks: ^0.20.0

  # Existing packages (keep)
  flutter_secure_storage: ^10.0.0
  flutter_markdown_plus: ^1.0.6
  reorderables: ^0.6.0
  url_launcher: ^6.3.2
  connectivity_plus: ^7.0.0
  file_picker: ^10.3.10
  permission_handler: ^12.0.1
  flutter_screenutil: ^5.9.3
  flutter_svg: ^2.0.17
  cupertino_icons: ^1.0.8
  package_info_plus: ^9.0.0
  cached_network_image: ^3.3.1
  workmanager: ^0.9.0+3
  shimmer: ^3.0.0
  share_plus: ^12.0.1
  path_provider: ^2.1.5
```

### Development Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.12
  riverpod_generator: ^4.0.3
  freezed: ^2.5.2
  json_serializable: ^6.8.0

  # Linting (upgraded)
  very_good_analysis: ^6.0.0

  # Build tools
  build_config: ^1.2.0

  # Testing
  integration_test:
    sdk: flutter
  benchmark_harness: ^2.3.1
```

---

## ⚠️ Risk Mitigation

### High-Risk Changes
1. **Dio migration** - Test thoroughly with network errors
2. **GoRouter** - Test all navigation paths
3. **Freezed models** - Run full test suite after migration

### Rollback Plan
- Commit after each sprint
- Keep old code in git history
- If issues arise, revert to previous commit

### Testing Strategy
- Manual testing after each sprint
- Run `flutter test` before committing
- Build APK at end of each sprint

---

## 🚀 Getting Started

### Before Starting
```bash
# Ensure clean state
git checkout main
git pull
flutter clean
flutter pub get

# Create feature branch
git checkout -b feature/modernization
```

### After Each Sprint
```bash
# Commit changes
git add .
git commit -m "feat: Sprint X - [feature name]

Co-authored-by: Qwen-Coder <qwen-coder@alibabacloud.com>"

# Test
flutter analyze
flutter test
flutter build apk --debug
```

---

## 📈 Success Metrics

- ✅ Code quality score improved (flutter analyze)
- ✅ Reduced boilerplate code (freezed)
- ✅ Better error handling (dio)
- ✅ Improved navigation (go_router)
- ✅ All tests passing
- ✅ No regression in functionality

---

**Ready to start?** Begin with Sprint 1! 🎯
