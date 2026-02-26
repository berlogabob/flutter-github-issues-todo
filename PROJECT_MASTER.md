# GitDoIt — Master Project Document

**Version:** 1.0.0 MVP  
**Last Updated:** 26 February 2026  
**Status:** ✅ READY FOR RELEASE

---

## 📊 Executive Summary

**GitDoIt** is a minimalist GitHub Issues & Projects TODO Manager built with Flutter, featuring offline-first architecture, real-time sync, and a beautiful dark theme.

### Key Metrics

| Metric | Value |
|--------|-------|
| **Total Tasks** | 43 |
| **Completed** | 40 (93%) |
| **Screens** | 7/7 MVP ✅ |
| **Services** | 5 ✅ |
| **Models** | 4 ✅ |
| **Unit Tests** | 15 ✅ |
| **Build Size** | 54.0 MB (release) |

---

## 📅 Development History

### Sprint 0 — Foundation (✅ 100%)
**Date:** 24 February 2026

**Completed:**
- ✅ Flutter project setup
- ✅ Dependencies configured
- ✅ 4 data models (Item, RepoItem, IssueItem, ProjectItem)
- ✅ All 7 MVP screens implemented
- ✅ Agent system created (5 agents)

**Duration:** 40 hours

---

### Sprint 1 — Critical User Journeys (✅ 100%)
**Date:** 24-26 February 2026

**Completed:**
- ✅ GraphQL mutation for Project Board drag-and-drop
- ✅ Issue creation with project/column selection
- ✅ Close/Reopen issue functionality
- ✅ PATCH API for issue updates
- ✅ User Journeys #3, #4, #5 tested

**Duration:** 8 hours (vs 36h estimated)

---

### Sprint 2 — Sync & Offline (✅ 100%)
**Date:** 26 February 2026

**Completed:**
- ✅ SyncService (singleton with status tracking)
- ✅ syncIssues() with remote-wins conflict resolution
- ✅ syncProjects() with 5-min cache
- ✅ Auto-sync on network restore (2s debounce)
- ✅ Sync status indicators in UI
- ✅ Network connectivity monitoring

**Duration:** 14 hours (vs 32h estimated)

---

### Sprint 3 — Edit & Filters (✅ 100%)
**Date:** 26 February 2026

**Completed:**
- ✅ EditIssueScreen (title, body, labels)
- ✅ Markdown editing with live preview
- ✅ Status filtering (Open/Closed/All)
- ✅ Project filtering (dropdown)
- ✅ Filter persistence in LocalStorage

**Duration:** 7.5 hours (vs 22h estimated)

---

### Sprint 4 — OAuth & Polish (✅ 100%)
**Date:** 26 February 2026

**Completed:**
- ✅ OAuth Device Flow (demo mode)
- ✅ Error Boundary widget
- ✅ Retry logic with exponential backoff
- ✅ PAT validation and persistence

**Duration:** 6 hours (vs 18h estimated)

---

### Sprint 5 — Testing & Documentation (✅ 60%)
**Date:** 26 February 2026

**Completed:**
- ✅ Unit tests for models (15 tests)
- ✅ README.md updated
- ✅ Release notes prepared

**Deferred:**
- ⏸️ Widget tests (not critical for MVP)
- ⏸️ Integration tests (not critical for MVP)

**Duration:** 4 hours (vs 23h estimated)

---

### Sprint 6 — Responsive Design (✅ 100%)
**Date:** 26 February 2026

**Completed:**
- ✅ responsive_utils.dart (AppBreakpoints, AppResponsive, ResponsiveLayout, ConstrainedContent)
- ✅ flutter_screenutil integration
- ✅ All 7 screens adapted (mobile/tablet/desktop)
- ✅ Adaptive typography and padding
- ✅ SafeArea + ConstrainedContent

**Files Modified:** 10  
**Breakpoints:** 4 (mobile <600px, tablet 600-1024px, desktop >1024px, wide >1440px)

---

### Sprint 7 — UI Polish (✅ 100%)
**Date:** 26 February 2026

**Completed:**
- ✅ AppBar simplification (removed duplicate refresh button)
- ✅ Sync cloud icon with 4 states (offline, syncing, synced, error)
- ✅ Custom SVG repository icon
- ✅ Rotation animation for sync button
- ✅ flutter_svg dependency added

**Files Created:** 2 (sync_cloud_icon.dart, cloud.svg)  
**Files Modified:** 1 (main_dashboard_screen.dart)

---

### Sprint 8 — Code Quality (✅ 100%)
**Date:** 26 February 2026

**Completed:**
- ✅ Deprecated API fix: 111 `withOpacity()` → `withValues(alpha:)`
- ✅ Dependencies updated to major versions
- ✅ Build warnings eliminated
- ✅ Release build successful (54.0 MB)

**Files Modified:** 20  
**Warnings:** 0 (was 111)

---

### Sprint 9 — Bug Fixes (✅ 100%)
**Date:** 26 February 2026

**Completed:**
- ✅ PAT login stuck on "Loading repositories" — fixed repo picker dialog state
- ✅ 422 error on issue creation — fixed null labels/assignee
- ✅ Default repo picker on first login — working for both OAuth and PAT

**Files Modified:** 3 (onboarding_screen.dart, github_api_service.dart, local_storage_service.dart)

---

## 🏗️ Architecture

### Tech Stack

| Category | Package | Version |
|----------|---------|---------|
| **State Management** | flutter_riverpod | ^3.0.3 |
| **Local Database** | hive + hive_flutter | ^2.2.3 |
| **REST API** | http | ^1.6.0 |
| **GraphQL API** | graphql_flutter | ^5.2.1 |
| **Secure Storage** | flutter_secure_storage | ^10.0.0 |
| **Markdown** | flutter_markdown | ^0.7.6 |
| **Drag & Drop** | reorderables | ^0.6.0 |
| **URL Launcher** | url_launcher | ^6.3.2 |
| **Connectivity** | connectivity_plus | ^6.1.3 |
| **Responsive UI** | flutter_screenutil | ^5.9.3 |
| **SVG Support** | flutter_svg | ^2.0.17 |

### Project Structure

```
lib/
├── main.dart                          # App entry point with ScreenUtilInit
├── agents/                            # Multi-agent development system
│   ├── agent_coordinator.dart
│   ├── base_agent.dart
│   ├── project_manager_agent.dart
│   ├── flutter_developer_agent.dart
│   ├── ui_designer_agent.dart
│   ├── testing_quality_agent.dart
│   └── documentation_deployment_agent.dart
├── constants/
│   └── app_colors.dart                # Dark theme colors
├── models/
│   ├── item.dart                      # Abstract base class
│   ├── repo_item.dart                 # Repository model
│   ├── issue_item.dart                # Issue model
│   └── project_item.dart              # Project model
├── screens/
│   ├── onboarding_screen.dart         # Auth choice (OAuth/PAT/Offline)
│   ├── main_dashboard_screen.dart    # Hierarchical repo/issue view
│   ├── issue_detail_screen.dart       # Detailed issue view
│   ├── project_board_screen.dart      # Kanban board
│   ├── edit_issue_screen.dart         # Edit issue
│   ├── search_screen.dart             # Global search
│   ├── settings_screen.dart           # App settings
│   └── repo_project_library_screen.dart  # Manage repos/projects
├── services/
│   ├── github_api_service.dart        # REST + GraphQL API
│   ├── sync_service.dart              # Auto-sync, conflict resolution
│   ├── local_storage_service.dart     # Hive local storage
│   ├── secure_storage_service.dart    # Token storage (singleton)
│   └── oauth_service.dart             # OAuth Device Flow
├── providers/
│   └── app_providers.dart             # Riverpod providers
├── widgets/
│   ├── expandable_repo.dart           # Collapsible repo widget
│   ├── issue_card.dart                # Issue card
│   ├── error_boundary.dart            # Error handling
│   └── sync_cloud_icon.dart           # 4-state sync icon
└── utils/
    └── responsive_utils.dart          # Responsive design utilities
```

---

## 🎨 Design System

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Background** | `#121212` → `#1E1E1E` | Gradient background |
| **Card Background** | `#1E1E1E` | Cards, containers |
| **Orange (Primary)** | `#FF6200` | Main actions, FAB |
| **Red (Secondary)** | `#FF3B30` | Connectors, danger actions |
| **Blue (Accent)** | `#0A84FF` | Assignee links |
| **Green (Success)** | `#4CAF50` | Open status, synced |
| **Grey (Disabled)** | `#757575` | Offline, disabled |

### Typography

| Element | Size | Weight | Opacity |
|---------|------|--------|---------|
| Screen Title | 32.sp | Bold | 1.0 |
| AppBar Title | 20.sp | Bold | 1.0 |
| Repo Name | 16-18.sp | Bold | 1.0 |
| Issue Title | 14-16.sp | Medium | 1.0 |
| Body Text | 14.sp | Regular | 1.0 |
| Secondary Text | 12-14.sp | Regular | 0.5-0.85 |
| Labels/Meta | 10-13.sp | Regular | 0.7 |

### Spacing

```dart
SizedBox(height: 4.h)    // xs
SizedBox(height: 8.h)    // sm
SizedBox(height: 12.h)   // md
SizedBox(height: 16.h)   // lg
SizedBox(height: 24.h)   // xl
SizedBox(height: 32.h)   // xxl

SizedBox(width: 4.w)     // xs
SizedBox(width: 8.w)     // sm
SizedBox(width: 12.w)    // md
SizedBox(width: 16.w)    // lg
SizedBox(width: 24.w)    // xl
```

### Responsive Breakpoints

| Breakpoint | Width | Layout |
|------------|-------|--------|
| **Mobile** | < 600px | 1 column, vertical filters |
| **Tablet** | 600-1024px | 2 columns, horizontal filters |
| **Desktop** | > 1024px | 3-4 columns, ConstrainedContent (max 1200px) |
| **Wide** | > 1440px | 4 columns, max content width |

---

## 📱 Screens Overview

### 1. OnboardingScreen
**Purpose:** Authentication method selection

**Features:**
- OAuth Device Flow (demo mode)
- Personal Access Token (PAT) with validation
- Continue Offline mode
- Default repo picker on first login

**File:** `lib/screens/onboarding_screen.dart`

---

### 2. MainDashboardScreen
**Purpose:** Hierarchical view of repositories and issues

**Features:**
- ExpandableRepo widgets
- Filter chips (Open/Closed/All)
- Project dropdown filter
- Sync cloud icon (4 states)
- Search, Settings, Repo Library actions
- FAB for new issue creation

**File:** `lib/screens/main_dashboard_screen.dart`

---

### 3. IssueDetailScreen
**Purpose:** Detailed issue view with markdown

**Features:**
- Metadata (status, assignee, time)
- Labels display
- Project column indicator
- Markdown body rendering
- Close/Reopen toggle
- Edit Issue button
- Add Comment button

**File:** `lib/screens/issue_detail_screen.dart`

---

### 4. ProjectBoardScreen
**Purpose:** Kanban-style project board

**Features:**
- 4 columns (Todo, In Progress, Review, Done)
- Horizontal scroll
- Drag-and-drop between columns
- GraphQL mutation for status update
- Real-time sync

**File:** `lib/screens/project_board_screen.dart`

---

### 5. EditIssueScreen
**Purpose:** Edit issue details

**Features:**
- Title editing
- Body editing (Markdown with preview)
- Labels management (add/remove)
- Save to GitHub or local

**File:** `lib/screens/edit_issue_screen.dart`

---

### 6. SearchScreen
**Purpose:** Global search across issues

**Features:**
- Search by title, body, labels
- Filter chips
- Results list with issue cards
- Empty state

**File:** `lib/screens/search_screen.dart`

---

### 7. SettingsScreen
**Purpose:** App settings and account management

**Features:**
- Account section (user info, logout)
- Default repo/project settings
- Sync settings (WiFi/Any network toggles)
- Sync now button
- Danger Zone (clear cache, reset token)
- App info (version, description)

**File:** `lib/screens/settings_screen.dart`

---

### 8. RepoProjectLibraryScreen
**Purpose:** Manage repositories and projects

**Features:**
- Filter tabs (All/Repositories/Projects)
- Fetch Repos/Projects buttons
- Set as default action
- Remove action
- Tap to open in browser

**File:** `lib/screens/repo_project_library_screen.dart`

---

## 🔌 Services

### SecureStorageService (Singleton)
**File:** `lib/services/secure_storage_service.dart`

**Methods:**
- `getToken({forceRefresh})` → `String?`
- `saveToken(String token)` → `Future<void>`
- `deleteToken()` → `Future<void>`
- `clearAll()` → `Future<void>`
- `hasToken()` → `Future<bool>`

---

### GitHubApiService
**File:** `lib/services/github_api_service.dart`

**Methods:**
- `fetchMyRepositories({page, perPage})` → `List<RepoItem>`
- `fetchIssues(owner, repo, {state})` → `List<IssueItem>`
- `createIssue(owner, repo, {title, body, labels, assignee})` → `IssueItem`
- `updateIssue(owner, repo, number, {title, body, state, labels})` → `IssueItem`
- `fetchProjects({first})` → `List<Map<String, dynamic>>`
- `getCurrentUser()` → `Map<String, dynamic>?`
- `moveItemToColumn(...)` → GraphQL mutation

---

### SyncService (Singleton)
**File:** `lib/services/sync_service.dart`

**Properties:**
- `syncStatus` → 'idle' | 'syncing' | 'success' | 'error'
- `isSyncing` → `bool`
- `isNetworkAvailable` → `bool`

**Methods:**
- `init()` → Initialize network listener
- `syncAll({forceRefresh})` → Sync issues and projects
- `syncIssues()` → Sync issues with conflict resolution
- `syncProjects()` → Sync projects with 5-min cache
- `dispose()` → Clean up listeners

---

### LocalStorageService
**File:** `lib/services/local_storage_service.dart`

**Methods:**
- `saveLocalIssue(IssueItem issue)` → `Future<void>`
- `getLocalIssues()` → `List<IssueItem>`
- `removeLocalIssue(String issueId)` → `Future<void>`
- `saveSyncedIssues(repo, issues)` → `Future<void>`
- `getSyncedIssues(repo)` → `List<IssueItem>`
- `saveSyncedProjects(projects)` → `Future<void>`
- `getSyncedProjects()` → `List<Map<String, dynamic>>`
- `saveFilters(filterStatus, selectedProject)` → `Future<void>`
- `getFilters()` → `Map<String, String?>`
- `saveDefaultRepo(repo)` → `Future<void>`
- `getDefaultRepo()` → `RepoItem?`

---

## 🤖 Agent System

### 5 Agents

| Agent | Role | Responsibilities |
|-------|------|------------------|
| **PMA** | Project Manager | Backlog, task assignment, deadlines |
| **FDA** | Flutter Developer | Code implementation |
| **UDA** | UI/UX Designer | Design system, screen specs |
| **TQA** | Testing & Quality | Tests, validation, brief compliance |
| **DDA** | Documentation | README, docs, deployment |

### Coordinator Pattern

```dart
final coordinator = AgentCoordinator();
coordinator.registerAgent(ProjectManagerAgent());
coordinator.registerAgent(FlutterDeveloperAgent());
// ... register other agents
await coordinator.startAll();
```

---

## 🧪 Testing

### Unit Tests (15 tests)
**File:** `test/models/models_test.dart`

- ✅ ItemStatus enum tests
- ✅ IssueItem serialize/deserialize
- ✅ RepoItem children management
- ✅ Integration tests

### Test Coverage

| Suite | Tests | Status |
|-------|-------|--------|
| Models | 15 | ✅ Pass |
| Widgets | 0 | ⏸️ Deferred |
| Integration | 0 | ⏸️ Deferred |
| User Journeys | 5 | ✅ Manual |
| Performance | 6 | ✅ Manual |

---

## 🚀 Build & Deployment

### Build Commands

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release

# iOS IPA (App Store)
flutter build ipa --release
```

### Current Build Status

| Build Type | Size | Status |
|------------|------|--------|
| **Debug APK** | N/A | ✅ Success |
| **Release APK** | 54.0 MB | ✅ Success |
| **App Bundle** | N/A | ⏸️ Not tested |
| **iOS IPA** | N/A | ⏸️ Not tested |

### Warnings
- ✅ 0 deprecated API warnings
- ✅ 0 compilation errors
- ✅ Build successful

---

## 📦 Dependencies

### Production

```yaml
dependencies:
  flutter_riverpod: ^3.0.3
  riverpod_annotation: ^3.0.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5
  http: ^1.6.0
  graphql_flutter: ^5.2.1
  flutter_secure_storage: ^10.0.0
  flutter_markdown: ^0.7.6
  reorderables: ^0.6.0
  url_launcher: ^6.3.2
  connectivity_plus: ^6.1.3
  flutter_screenutil: ^5.9.3
  flutter_svg: ^2.0.17
  cupertino_icons: ^1.0.8
```

### Development

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.11.1
  riverpod_generator: ^3.0.3
  flutter_lints: ^6.0.0
```

---

## 🎯 MVP Scope

### Included (Brief v1.0) ✅

- ✅ 7 MVP screens
- ✅ Dark theme only
- ✅ OAuth + PAT + Offline authentication
- ✅ Offline-first with Hive
- ✅ Issues sync (REST)
- ✅ Projects v2 board (GraphQL)
- ✅ Drag-and-drop between columns
- ✅ Hierarchical expandable items
- ✅ Global search
- ✅ Markdown rendering
- ✅ Edit issues (title, body, labels)
- ✅ Close/Reopen issues
- ✅ Filter by status and project
- ✅ Auto-sync on network restore
- ✅ Conflict resolution (remote wins)
- ✅ Responsive design (mobile/tablet/desktop)

### Explicitly Excluded (per brief section 10) ❌

- ❌ Light theme
- ❌ Push notifications
- ❌ Home screen widgets
- ❌ Share sheet
- ❌ Other service integrations (Slack, Trello)
- ❌ Custom icons/illustrations (except SVG repo icon)
- ❌ Lottie animations
- ❌ Inline editing in lists
- ❌ Comments to issues
- ❌ Additional features beyond brief

---

## 📈 Progress Tracking

### Overall Progress: 93% (40/43 tasks)

| Sprint | Tasks | Done | Progress |
|--------|-------|------|----------|
| Sprint 0 | 10 | 10 | ✅ 100% |
| Sprint 1 | 9 | 9 | ✅ 100% |
| Sprint 2 | 6 | 6 | ✅ 100% |
| Sprint 3 | 6 | 6 | ✅ 100% |
| Sprint 4 | 6 | 6 | ✅ 100% |
| Sprint 5 | 5 | 3 | ✅ 60% |
| Responsive | 7 | 7 | ✅ 100% |
| UI Polish | 4 | 4 | ✅ 100% |
| Code Quality | 3 | 3 | ✅ 100% |
| Bug Fixes | 3 | 3 | ✅ 100% |

---

## 🔮 Future Planning (Post-MVP)

### High Priority

1. **Widget Tests** — Test all 7 screens
2. **Integration Tests** — Full user journey automation
3. **Background Sync** — Sync when app is closed
4. **Comments Support** — View/add comments to issues
5. **Pagination** — Load repos/issues in batches

### Medium Priority

1. **Bulk Edit** — Edit multiple issues at once
2. **Custom Filters** — Save custom filter combinations
3. **Issue Templates** — Support GitHub issue templates
4. **Notifications** — Push notifications for mentions (if allowed)
5. **Multi-Account** — Switch between GitHub accounts

### Low Priority

1. **Light Theme** — Optional light mode
2. **Home Widgets** — iOS/Android home screen widgets
3. **Share Sheet** — Create issues from shared content
4. **Slack Integration** — Link issues to Slack messages
5. **Custom Illustrations** — Onboarding graphics

---

## 📝 Known Limitations

1. **OAuth Device Flow** — Requires backend setup (demo mode only)
2. **Labels Sync** — Labels not loaded from GitHub during edit
3. **Project Filter** — Only works if issue is in a project
4. **No Bulk Edit** — Edit one issue at a time
5. **No Background Sync** — Sync only when app is open
6. **No Comments** — Comments not implemented in MVP
7. **No Pagination** — All repos loaded at once

---

## 🎓 Key Learnings

### Technical

1. **flutter_screenutil** — Excellent for responsive design, use `.w`, `.h`, `.sp`, `.r`
2. **Riverpod 3.x** — Breaking changes from 2.x, plan migration
3. **GraphQL + REST** — Use both for GitHub API (REST for issues, GraphQL for projects)
4. **Hive** — Fast local storage, but codegen can be tricky
5. **flutter_secure_storage v10** — Deprecated `encryptedSharedPreferences`, auto-migrates

### Architectural

1. **Offline-First** — Design for offline from day 1
2. **Conflict Resolution** — "Remote wins" is simplest for MVP
3. **Sync Debounce** — 2-second debounce prevents race conditions
4. **Responsive Utils** — Centralize breakpoints and utilities
5. **Agent System** — Parallel development works well for MVP

### Process

1. **Sprint Estimates** — Often overestimate, actual is 30-50% of estimate
2. **MVP Scope** — Stick to brief, resist feature creep
3. **Testing** — Unit tests for models are essential, widget tests can wait
4. **Documentation** — Write as you go, not at the end
5. **Code Quality** — Fix deprecated APIs early, don't accumulate tech debt

---

## 📞 Support & Contact

**Repository:** github.com/berlogabob/gitdoit  
**License:** MIT  
**Version:** 1.0.0 MVP  
**Release Date:** 26 February 2026

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
