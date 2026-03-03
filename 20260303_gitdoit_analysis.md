# GitDoIt Project Structure & UI Analysis

**Generated:** March 3, 2026  
**Purpose:** Complete project structure visualization and UI breakdown  
**Status:** Analysis Complete

---

## Part 1: Complete Project Text Structure

```
flutter-github-issues-todo/
│
├── 📱 APPLICATION LAYER (lib/)
│   │
│   ├── main.dart                                    # App entry point, background sync
│   │
│   ├── 📁 constants/                                # Design System
│   │   └── app_colors.dart                          # Colors, Typography, Spacing, BorderRadius, Config
│   │
│   ├── 📁 models/                                   # Data Models (7 files)
│   │   ├── item.dart                                # Abstract base class (ItemStatus enum)
│   │   ├── repo_item.dart                           # Repository model (extends Item)
│   │   ├── issue_item.dart                          # Issue model (extends Item)
│   │   ├── project_item.dart                        # Project model
│   │   ├── pending_operation.dart                   # Offline operation queue model
│   │   ├── sync_history_entry.dart                  # Sync history model
│   │   └── models.dart                              # Barrel export
│   │
│   ├── 📁 providers/                                # State Management (Riverpod)
│   │   └── app_providers.dart                       # Riverpod providers
│   │
│   ├── 📁 screens/                                  # UI Screens (13 screens)
│   │   ├── main_dashboard_screen.dart               # Screen 2: Task hierarchy (1291 lines)
│   │   ├── onboarding_screen.dart                   # Screen 1: First-time tutorial
│   │   ├── issue_detail_screen.dart                 # Screen 3: Issue details (1857 lines)
│   │   ├── project_board_screen.dart                # Screen 4: Kanban board (735 lines)
│   │   ├── edit_issue_screen.dart                   # Screen 5: Edit issue
│   │   ├── search_screen.dart                       # Screen 6: Global search (684 lines)
│   │   ├── settings_screen.dart                     # Screen 7: Settings (1393 lines)
│   │   ├── create_issue_screen.dart                 # Create new issue (883 lines)
│   │   ├── repo_detail_screen.dart                  # Repository details
│   │   ├── repo_project_library_screen.dart         # Browse repos/projects
│   │   ├── sync_status_dashboard_screen.dart        # Sync monitoring
│   │   ├── error_log_screen.dart                    # Error logs viewer
│   │   └── debug_screen.dart                        # Debug utilities
│   │
│   ├── 📁 services/                                 # Business Logic (18 files)
│   │   ├── github_api_service.dart                  # REST + GraphQL API (main)
│   │   ├── github_api_service.g.dart                # Generated code
│   │   ├── cache_service.dart                       # TTL in-memory cache
│   │   ├── sync_service.dart                        # Auto-sync, conflict resolution
│   │   ├── sync_service.g.dart                      # Generated code
│   │   ├── local_storage_service.dart               # Hive storage (main)
│   │   ├── local_storage_service.g.dart             # Generated code
│   │   ├── secure_storage_service.dart              # Token storage (singleton)
│   │   ├── oauth_service.dart                       # OAuth Device Flow (main)
│   │   ├── oauth_service.g.dart                     # Generated code
│   │   ├── network_service.dart                     # Connectivity monitoring
│   │   ├── dashboard_service.dart                   # Dashboard data
│   │   ├── dashboard_data_service.dart              # Dashboard helpers
│   │   ├── issue_service.dart                       # Issue operations
│   │   ├── pending_operations_service.dart          # Offline queue
│   │   ├── conflict_detection_service.dart          # Conflict detection
│   │   ├── search_history_service.dart              # Search history
│   │   └── error_logging_service.dart               # Error logging
│   │
│   ├── 📁 utils/                                    # Utilities (4 files)
│   │   ├── app_error_handler.dart                   # Centralized error handling
│   │   ├── responsive_utils.dart                    # Responsive breakpoints
│   │   ├── relative_time.dart                       # Time formatting
│   │   └── retry_helper.dart                        # Retry logic
│   │
│   └── 📁 widgets/                                  # Reusable Widgets (19 widgets)
│       ├── expandable_repo.dart                     # Repo expansion with issues
│       ├── issue_card.dart                          # Issue display card
│       ├── repo_list.dart                           # Repository list
│       ├── error_boundary.dart                      # Error catching wrapper
│       ├── braille_loader.dart                      # Loading animation
│       ├── loading_skeleton.dart                    # Skeleton loaders
│       ├── empty_state_illustrations.dart           # Empty state graphics
│       ├── dashboard_empty_state.dart               # Dashboard empty state
│       ├── dashboard_filters.dart                   # Filter chips
│       ├── sync_cloud_icon.dart                     # Sync status indicator
│       ├── sync_status_widget.dart                  # Sync status display
│       ├── status_badge.dart                        # Status badges (open/closed)
│       ├── label_chip.dart                          # Label display
│       ├── search_filters_panel.dart                # Search filters
│       ├── search_result_item.dart                  # Search results
│       ├── tutorial_overlay.dart                    # Onboarding tutorial
│       ├── conflict_resolution_dialog.dart          # Conflict resolver
│       ├── pending_operations_list.dart             # Offline queue viewer
│       └── tutorial_overlay.dart                    # First-time guide
│
├── 📁 test/                                         # Unit & Widget Tests
│   ├── models/                                      # Model tests
│   ├── providers/                                   # Provider tests
│   ├── screens/                                     # Screen tests
│   ├── services/                                    # Service tests
│   └── widgets/                                     # Widget tests
│
├── 📁 integration_test/                             # E2E Tests
│
├── 📁 assets/                                       # Images, Icons, SVGs
│
├── 📁 docs/                                         # Documentation
│
├── 📁 android/                                      # Android platform
├── 📁 ios/                                          # iOS platform
├── 📁 web/                                          # Web platform
├── 📁 linux/                                        # Linux platform
├── 📁 macos/                                        # macOS platform
├── 📁 windows/                                      # Windows platform
│
├── 📄 pubspec.yaml                                  # Dependencies (version: 0.5.0+81)
├── 📄 analysis_options.yaml                         # Linting rules
├── 📄 CHANGELOG.md                                  # Version history
├── 📄 README.md                                     # User documentation
├── 📄 QWEN.md                                       # Project context
├── 📄 Plan.md                                       # Implementation plan
├── 📄 run_report.md                                 # Comprehensive report
└── 📄 LICENSE                                       # MIT License
```

---

## Part 2: ASCII Screen Visualizations

### Screen 1: Main Dashboard Screen (1291 lines)

```
┌─────────────────────────────────────────────────────────┐
│  [☁️ Sync]  GitDoIt                      [🔍] [⚙️]       │  ← AppBar
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ [All Issues ▼]  [📌 Pinned]  [+ Add Repo]        │ │  ← Filter Bar
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 📁 berlogabob/flutter-github-issues-todo     [3] │ │  ← Repo Card 1
│  │    Local vault folder (will sync when online)    │ │    (Pinned)
│  │  ▶ #23 КЭШ                                       │ │
│  │    #22 CREATE ISSUE                              │ │
│  │    #21 ГЛАВНЫЙ ЭКРАН                             │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 📁 flutter/packages                            [5] │ │  ← Repo Card 2
│  │    A collection of packages                       │ │
│  │  ▶ #1234 Add new feature                         │ │
│  │    #1235 Fix bug                                 │ │
│  │    #1236 Update docs                             │ │
│  │    #1237 Performance improvement                 │ │
│  │    #1238 Security patch                          │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 📁 dart-lang/sdk                              [12] │ │  ← Repo Card 3
│  │    The Dart programming language                  │ │
│  │  ▶ #50001 Fix null safety issue                  │ │
│  │    #50002 Improve error messages                 │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ 📁 Local Issues                               [2] │ │  ← Local Repo
│  │    local/Vault                                    │ │
│  │  ▶ Local task 1                                  │ │
│  │    Local task 2                                  │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [🏠 Dashboard]  [📊 Projects]  [🔍 Search]  [⚙️ Settings] │  ← Bottom Nav
└─────────────────────────────────────────────────────────┘

Legend:
  [☁️ Sync]       - Sync cloud icon (shows sync status)
  [🔍]            - Search button
  [⚙️]            - Settings button
  [All Issues ▼]  - Filter dropdown (All/Open/Closed)
  [📌 Pinned]     - Pinned repos filter
  [+ Add Repo]    - Add repository button
  ▶               - Expanded repo indicator
  [3], [5], [12]  - Issue count badges
```

**Widget Breakdown:**
```
MainDashboardScreen (StatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   ├── SyncCloudIcon widget
│   │   ├── Title text "GitDoIt"
│   │   └── Row (Search icon, Settings icon)
│   ├── Body (SingleChildScrollView)
│   │   ├── DashboardFilters widget
│   │   │   ├── FilterChip (All Issues)
│   │   │   ├── FilterChip (Open)
│   │   │   ├── FilterChip (Closed)
│   │   │   └── IconButton (Add Repo)
│   │   └── RepoList widget
│   │       └── ListView.builder
│   │           └── ExpandableRepo[] (filtered)
│   │               ├── Card
│   │               │   ├── InkWell (header tap)
│   │               │   │   ├── Row
│   │               │   │   │   ├── AnimatedRotation (arrow)
│   │               │   │   │   ├── Icon (folder)
│   │               │   │   │   ├── Icon (push_pin if pinned)
│   │               │   │   │   ├── Column (repo info)
│   │               │   │   │   │   ├── Text (repo name)
│   │               │   │   │   │   └── Text (description)
│   │               │   │   │   ├── Container (issue count badge)
│   │               │   │   │   └── BrailleLoader (if loading)
│   │               │   └── Column (issues list if expanded)
│   │               │       └── ListView.builder
│   │               │           └── IssueCard[]
│   │               └── Dismissible (swipe to pin/unpin)
│   └── BottomNavigationBar
│       ├── BottomNavigationBarItem (Dashboard)
│       ├── BottomNavigationBarItem (Projects)
│       ├── BottomNavigationBarItem (Search)
│       └── BottomNavigationBarItem (Settings)
```

---

### Screen 2: Settings Screen (1393 lines)

```
┌─────────────────────────────────────────────────────────┐
│  ← Settings                                             │  ← AppBar
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [👤]  GitHub User                          [✓]   │ │  ← User Card
│  │         @berlogabob                               │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [📁]  Default Repository              [>]        │ │  ← Default Repo
│  │        berlogabob/flutter-github-issues-todo     │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [📊]  Default Project                 [>]        │ │  ← Default Project
│  │        Mobile Development                        │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [📶]  Auto-sync on WiFi               [●━━━○]    │ │  ← Auto-sync WiFi
│  │        Automatically sync when on WiFi           │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [📱]  Auto-sync on any network        [━━━○]     │ │  ← Auto-sync Any
│  │        Use mobile data (may incur charges)       │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [🔄]  Sync Now                        [>]        │ │  ← Sync Now
│  │        Manually trigger sync                     │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [🗑️]  Clear Cache                     [>]        │ │  ← Clear Cache
│  │        Clear local cache and reload              │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [📋]  Pending Operations              [>]  [3]   │ │  ← Pending Ops
│  │        3 changes pending sync                    │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [🐛]  Error Logs                      [>]        │ │  ← Error Logs
│  │        View application error logs               │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [🔓]  Logout                          [>]        │ │  ← Logout
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│                                         Version 0.5.0+81 │  ← Version
└─────────────────────────────────────────────────────────┘

Legend:
  [●━━━○]  - Switch (ON)
  [━━━○]   - Switch (OFF)
  [>]      - Chevron (navigation)
  [✓]      - Verified badge
```

**Widget Breakdown:**
```
SettingsScreen (ConsumerStatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   └── Title text "Settings"
│   └── Body (ListView)
│       ├── _buildUserTile()
│       │   └── Card
│       │       └── ListTile
│       │           ├── Leading: ClipOval (avatar image)
│       │           ├── Title: Text (user name)
│       │           ├── Subtitle: Text (@login)
│       │           └── Trailing: Icon (verified_user)
│       ├── _buildDefaultRepoTile()
│       │   └── Card
│       │       └── ListTile
│       │           ├── Leading: Icon (folder)
│       │           ├── Title: Text ("Default Repository")
│       │           ├── Subtitle: Text (repo name)
│       │           └── Trailing: Icon (chevron_right)
│       ├── _buildDefaultProjectTile()
│       │   └── Card
│       │       └── ListTile (similar structure)
│       ├── _buildAutoSyncWifiTile()
│       │   └── Card
│       │       └── SwitchListTile
│       │           ├── secondary: Icon (wifi)
│       │           ├── title: Text
│       │           ├── subtitle: Text
│       │           └── value: Switch
│       ├── _buildAutoSyncAnyTile()
│       │   └── Card
│       │       └── SwitchListTile (similar structure)
│       ├── _buildSyncNowTile()
│       │   └── Card
│       │       └── ListTile
│       ├── _buildClearCacheTile()
│       │   └── Card
│       │       └── ListTile
│       ├── _buildPendingOpsTile()
│       │   └── Card
│       │       └── ListTile
│       ├── _buildErrorLogsTile()
│       │   └── Card
│       │       └── ListTile
│       └── _buildLogoutTile()
│           └── Card
│               └── ListTile
└── Text (version at bottom)
```

---

### Screen 3: Create Issue Screen (883 lines)

```
┌─────────────────────────────────────────────────────────┐
│  [✕]  Create Issue                    [Create]         │  ← AppBar
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Repository                                       │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │ 📁 berlogabob/flutter-github-issues-todo [>]│ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Title *                                          │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │ Add issue title...                          │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  │  0/256                                            │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Description                                      │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │                                              │ │ │
│  │  │  Add description here...                     │ │ │
│  │  │  (Markdown supported)                        │ │ │
│  │  │                                              │ │ │
│  │  │                                              │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  │  0/65536                                          │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Labels                                [+ Add]    │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  [bug]  [enhancement]  [documentation]      │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Assignee                              [Select]   │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  [👤] berlogabob                           │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Project                               [Select]   │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  📊 Mobile Development                     │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘

Legend:
  * - Required field
  [>] - Dropdown selector
```

**Widget Breakdown:**
```
CreateIssueScreen (StatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   ├── leading: IconButton (close)
│   │   ├── title: Text "Create Issue"
│   │   └── actions: [TextButton "Create"]
│   └── Body (SingleChildScrollView)
│       ├── ErrorBanner (if _errorMessage != null)
│       ├── _buildRepoSelector()
│       │   └── InputDecorator
│       │       └── ListTile (triggers dialog)
│       ├── _buildTitleField()
│       │   └── TextField
│       │       ├── decoration: InputDecoration
│       │       ├── maxLength: 256
│       │       └── onChanged: validation
│       ├── _buildBodyField()
│       │   └── TextField
│       │       ├── maxLines: 8
│       │       ├── maxLength: 65536
│       │       └── decoration: InputDecoration
│       ├── _buildLabelsSection()
│       │   └── Column
│       │       ├── Row (header + Add button)
│       │       └── Wrap
│       │           └── LabelChip[] (selectable)
│       ├── _buildAssigneeSection()
│       │   └── ListTile
│       │       └── Triggers assignee picker dialog
│       └── _buildProjectSection()
│           └── ListTile
│               └── Triggers project picker dialog
```

---

### Screen 4: Issue Detail Screen (1857 lines)

```
┌─────────────────────────────────────────────────────────┐
│  ←  #23 КЭШ                                  [✏️ Edit]  │  ← AppBar
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [🟢 Open]  ·  Created 2 days ago  ·  @berlogabob│ │  ← Status Bar
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Labels                                           │ │
│  │  [bug] [enhancement]                              │ │  ← Labels
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Description                                      │ │
│  │  ───────────────────────────────────────────────  │ │
│  │  добавить кэширование дэйблов и тэгов к оффлайн   │ │
│  │  версии. приложение оффлайн Фёрст. все должно     │ │
│  │  работать оффлайн и синхронизироваться при        │ │
│  │  подсоединении к сети                            │ │
│  │                                                   │ │
│  │  [Expand ▼]                                       │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Assignee                                         │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  [👤] berlogabob                         [x]│ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Project                                          │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  📊 Mobile Development                   [x]│ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  Comments (5)                                           │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [👤] user1  ·  1 day ago                         │ │
│  │  ───────────────────────────────────────────────  │ │
│  │  Great idea! This would be very useful.          │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [👤] user2  ·  12 hours ago                      │ │
│  │  ───────────────────────────────────────────────  │ │
│  │  I agree, looking forward to this feature.       │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  [Load More Comments]                                   │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Add a comment...                              [↑]│ │  ← Comment Input
│  └───────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘

Legend:
  [🟢 Open] - Status badge (green for open, gray for closed)
  [x]       - Remove button
  [↑]       - Send button
```

**Widget Breakdown:**
```
IssueDetailScreen (ConsumerStatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   ├── leading: IconButton (back)
│   │   ├── title: Text "#23 КЭШ"
│   │   └── actions: [IconButton (edit)]
│   └── Body (SingleChildScrollView)
│       ├── _buildStatusBanner()
│       │   └── Row
│       │       ├── StatusBadge
│       │       ├── Text (created date)
│       │       └── Text (author)
│       ├── _buildLabelsSection()
│       │   └── Wrap
│       │       └── LabelChip[]
│       ├── _buildDescriptionSection()
│       │   └── Column
│       │       ├── Text (header)
│       │       ├── Divider
│       │       ├── MarkdownBody (description)
│       │       └── TextButton (Expand/Collapse)
│       ├── _buildAssigneeSection()
│       │   └── ListTile
│       │       └── Triggers assignee picker
│       ├── _buildProjectSection()
│       │   └── ListTile
│       │       └── Triggers project picker
│       ├── Divider
│       ├── _buildCommentsSection()
│       │   ├── Row (header + count)
│       │   ├── ListView.builder
│       │   │   └── _CommentCard[]
│       │   │       ├── ListTile
│       │   │       │   ├── Leading: CircleAvatar
│       │   │       │   ├── Title: Row (user + time)
│       │   │       │   └── Subtitle: MarkdownBody
│       │   │       └── Row (actions: edit, delete)
│       │   └── TextButton (Load More)
│       └── _buildCommentInput()
│           └── TextField
│               ├── decoration: InputDecoration
│               └── suffixIcon: IconButton (send)
```

---

### Screen 5: Search Screen (684 lines)

```
┌─────────────────────────────────────────────────────────┐
│  ← Search                                               │  ← AppBar
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  [🔍]  Search issues...                        [x]│ │  ← Search Field
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Quick Filters:                                         │
│  [My Issues] [Open] [Closed]                           │  ← Quick Filters
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Filters                                          │ │
│  │  ───────────────────────────────────────────────  │ │
│  │  Status:  [All ▼]                                 │ │
│  │  Type:    [☑] Title  [☑] Body  [☑] Labels         │ │
│  │  Author:  [Search...]                             │ │
│  │  Date:    [From] [To]                             │ │
│  │  Sort:    [Created ▼] [Desc ▼]                    │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Search Results (15):                                   │
│  ┌───────────────────────────────────────────────────┐ │
│  │  🟢 #23 КЭШ                                       │ │
│  │     berlogabob/flutter-github-issues-todo        │ │
│  │     [bug] [enhancement]  @berlogabob             │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  🟢 #22 CREATE ISSUE                              │ │
│  │     berlogabob/flutter-github-issues-todo        │ │
│  │     [bug]  @berlogabob                           │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  🔴 #21 ГЛАВНЫЙ ЭКРАН                             │ │
│  │     berlogabob/flutter-github-issues-todo        │ │
│  │     [ToDo]  @berlogabob                          │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  [Loading...]                                           │
│                                                         │
└─────────────────────────────────────────────────────────┘

Legend:
  [🟢] - Open issue status indicator
  [🔴] - Closed issue status indicator
  [x]  - Clear search button
```

**Widget Breakdown:**
```
SearchScreen (StatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   └── title: Text "Search"
│   └── Body (Column)
│       ├── _buildSearchField()
│       │   └── TextField
│       │       ├── decoration: InputDecoration
│       │       ├── focusNode: _focusNode
│       │       └── onChanged: _debouncedSearch
│       ├── _buildQuickFilters()
│       │   └── Wrap
│       │       └── FilterChip[] (My Issues, Open, Closed)
│       ├── _buildFiltersPanel()
│       │   └── SearchFiltersPanel widget
│       │       ├── ExpansionTile (Filters)
│       │       │   ├── DropdownButton (Status)
│       │       │   ├── CheckboxListTile[] (Type)
│       │       │   ├── TextField (Author)
│       │       │   ├── Row (Date range)
│       │       │   └── Row (Sort options)
│       ├── Divider
│       ├── _buildResultsHeader()
│       │   └── Row (count)
│       └── _buildResultsList()
│           └── ListView.builder
│               └── SearchResultItem[]
│                   ├── ListTile
│                   │   ├── Leading: StatusBadge
│                   │   ├── Title: Text (issue title)
│                   │   ├── Subtitle: Text (repo name)
│                   │   └── Trailing: Row (labels, assignee)
```

---

### Screen 6: Project Board Screen (735 lines)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ← Project Board                                                        │  ← AppBar
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐│
│  │   Todo       │  │  In Progress │  │    Review    │  │    Done      ││  ← Column Headers
│  │      [2]     │  │       [1]    │  │      [0]     │  │      [3]     ││
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤│
│  │              │  │              │  │              │  │              ││
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │              │  │ ┌──────────┐ ││
│  │ │ #23 КЭШ  │ │  │ │ #22 CREATE││  │              │  │ │ #20 MENU  │ ││
│  │ │ [bug]    │ │  │ │ [ToDo]   │ │  │              │  │ │ [Done]   │ ││
│  │ └──────────┘ │  │ └──────────┘ │  │              │  │ └──────────┘ ││
│  │              │  │              │  │              │  │              ││
│  │ ┌──────────┐ │  │              │  │              │  │ ┌──────────┐ ││
│  │ │ #21 MAIN │ │  │              │  │              │  │ │ #19 FIX  │ ││
│  │ │ [ToDo]   │ │  │              │  │              │  │ │ [Done]   │ ││
│  │ └──────────┘ │  │              │  │              │  │ └──────────┘ ││
│  │              │  │              │  │              │  │              ││
│  │              │  │              │  │              │  │ ┌──────────┐ ││
│  │              │  │              │  │              │  │ │ #18 ADD  │ ││
│  │              │  │              │  │              │  │ │ [Done]   │ ││
│  │              │  │              │  │              │  │ └──────────┘ ││
│  │              │  │              │  │              │  │              ││
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘│
│       │                   │                │                 │         │
│  [Drop here]        [Drop here]      [Drop here]       [Drop here]     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

Legend:
  [2], [1], [0], [3] - Issue count per column
  [Drop here]        - Drop zone indicator
```

**Widget Breakdown:**
```
ProjectBoardScreen (ConsumerStatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   └── title: Text "Project Board"
│   └── Body (SingleChildScrollView)
│       └── Row (horizontal scroll)
│           └── ReorderableColumn[] (one per status)
│               ├── Column
│               │   ├── Container (header)
│               │   │   └── Text (column name + count)
│               │   └── ReorderableListView
│               │       └── IssueCard[] (draggable)
│               │           ├── Dismissible
│               │           │   ├── background: Color indicator
│               │           │   └── child: Card
│               │           │       └── ListTile
│               │           │           ├── Title: Text (issue title)
│               │           │           ├── Subtitle: Wrap (labels)
│               │           │           └── Trailing: Icon (assignee)
│               └── Container (drop zone)
│                   └── Text "[Drop here]"
```

---

### Screen 7: Onboarding Screen

```
┌─────────────────────────────────────────────────────────┐
│                                              [Skip]     │  ← Skip Button
├─────────────────────────────────────────────────────────┤
│                                                         │
│              ┌─────────────────────┐                    │
│              │                     │                    │
│              │    [Illustration]   │                    │
│              │                     │                    │
│              │   📱 → ✅ → ☁️      │                    │
│              │                     │                    │
│              └─────────────────────┘                    │
│                                                         │
│                                                         │
│           Welcome to GitDoIt!                           │  ← Title
│                                                         │
│    Transform GitHub Issues into your TODO list         │  ← Description
│    with offline-first support.                          │
│                                                         │
│                                                         │
│    ○ ○ ● ○ ○                                            │  ← Page Indicators
│                                                         │
│              [Next]                                     │  ← Next Button
│                                                         │
└─────────────────────────────────────────────────────────┘

Step 1: Welcome
Step 2: Offline First
Step 3: Sync
Step 4: Projects
Step 5: Get Started
```

**Widget Breakdown:**
```
OnboardingScreen (StatefulWidget)
├── Scaffold
│   ├── Body (Stack)
│   │   ├── PageView
│   │   │   └── _OnboardingPage[] (5 pages)
│   │   │       ├── Column
│   │   │       │   ├── SvgPicture (illustration)
│   │   │       │   ├── SizedBox
│   │   │       │   ├── Text (title)
│   │   │       │   ├── SizedBox
│   │   │       │   └── Text (description)
│   │   └── Column (controls)
│   │       ├── Row (page indicators)
│   │       │   └── DotIndicator[]
│   │       └── Row (buttons)
│   │           ├── TextButton (Skip)
│   │           └── ElevatedButton (Next/Get Started)
└── TutorialOverlay widget (optional)
```

---

## Part 3: Widget Library Analysis

### Current Widget Inventory (19 Widgets)

| Widget | File | Purpose | Reusability | Swipe Support |
|--------|------|---------|-------------|---------------|
| **ExpandableRepo** | `expandable_repo.dart` | Repo expansion with issues | ✅ High | ❌ No |
| **IssueCard** | `issue_card.dart` | Issue display card | ✅ High | ✅ Yes |
| **RepoList** | `repo_list.dart` | Repository list container | ✅ Medium | ❌ No |
| **ErrorBoundary** | `error_boundary.dart` | Error catching wrapper | ✅ High | N/A |
| **BrailleLoader** | `braille_loader.dart` | Loading animation | ✅ High | N/A |
| **LoadingSkeleton** | `loading_skeleton.dart` | Skeleton loaders | ✅ High | N/A |
| **EmptyStateIllustrations** | `empty_state_illustrations.dart` | Empty state graphics | ✅ High | N/A |
| **DashboardEmptyState** | `dashboard_empty_state.dart` | Dashboard empty state | ✅ Medium | N/A |
| **DashboardFilters** | `dashboard_filters.dart` | Filter chips | ✅ Medium | N/A |
| **SyncCloudIcon** | `sync_cloud_icon.dart` | Sync status indicator | ✅ Medium | N/A |
| **SyncStatusWidget** | `sync_status_widget.dart` | Sync status display | ✅ Medium | N/A |
| **StatusBadge** | `status_badge.dart` | Status badges (open/closed) | ✅ High | N/A |
| **LabelChip** | `label_chip.dart` | Label display | ✅ High | N/A |
| **SearchFiltersPanel** | `search_filters_panel.dart` | Search filters | ✅ Medium | N/A |
| **SearchResultItem** | `search_result_item.dart` | Search results | ✅ Medium | ❌ No |
| **TutorialOverlay** | `tutorial_overlay.dart` | Onboarding tutorial | ✅ Medium | N/A |
| **ConflictResolutionDialog** | `conflict_resolution_dialog.dart` | Conflict resolver | ✅ Low | N/A |
| **PendingOperationsList** | `pending_operations_list.dart` | Offline queue viewer | ✅ Low | N/A |

### Widget Library Assessment

**✅ Strengths:**
1. **Well-organized** - Each widget has single responsibility
2. **Reusable** - Most widgets are modular and reusable
3. **Performance optimized** - Uses ListView.builder, RepaintBoundary, CachedNetworkImage
4. **Consistent styling** - All use AppColors, AppSpacing constants

**❌ Gaps (per 20260303 gitdoit.md):**
1. **No PageTemplate** - No unified page template with safe zone
2. **Incomplete swipe support** - Only IssueCard has swipe, ExpandableRepo missing
3. **No system bar safe zone** - Each screen implements its own Scaffold

---

## Part 4: Color Palette Verification

### Current State: ✅ CONSOLIDATED

**Location:** `/lib/constants/app_colors.dart`

**Palette Structure:**
```dart
AppColors
├── Background Colors
│   ├── background: #121212
│   ├── backgroundGradientStart: #121212
│   ├── backgroundGradientEnd: #1E1E1E
│   ├── cardBackground: #1E1E1E
│   ├── surfaceColor: #111111
│   ├── darkBackground: #0A0A0A
│   └── borderColor: #333333
│
├── Primary Colors
│   ├── orangePrimary: #FF6200
│   ├── orangeSecondary: #FF5E00
│   ├── orangeLight: #FF8A33
│   ├── red: #FF3B30
│   └── blue: #0A84FF
│
├── Text Colors
│   ├── white: #FFFFFF
│   └── secondaryText: #A0A0A5
│
├── Status Colors
│   ├── success: #4CAF50
│   ├── error: #FF3B30
│   ├── warning: #FFC107
│   ├── issueOpen: #238636
│   └── issueClosed: #6E7781
│
AppTypography
├── fontFamily: '.SF Pro Text'
├── Sizes: titleLarge (32), titleMedium (20), titleSmall (16)
├── Sizes: bodyLarge (14), bodyMedium (14), labelSmall (12), caption (11)
└── Weights: bold, medium, regular

AppSpacing
├── xs: 4.0px
├── sm: 8.0px
├── md: 16.0px
├── lg: 24.0px
└── xl: 32.0px

AppBorderRadius
├── sm: 4.0px
├── md: 8.0px
├── lg: 12.0px
└── xl: 16.0px

AppConfig
├── appName: 'GitDoIt'
├── appVersion: '1.0.0'
├── githubApiBase: 'https://api.github.com'
├── githubGraphQl: 'https://api.github.com/graphql'
├── requiredScopes: ['repo', 'read:org', 'write:org', 'project']
├── syncInterval: 5 minutes
└── maxOfflineItems: 1000
```

**Assessment:** ✅ **FULLY CONSOLIDATED**
- All colors in one place
- Typography defined
- Spacing system (4px grid)
- Border radius constants
- App configuration

---

## Part 5: Swipe Features Analysis

### Current Swipe Implementation

| Widget | Swipe Right | Swipe Left | Status |
|--------|-------------|------------|--------|
| **IssueCard** | Edit (blue) | Close (red) | ✅ Implemented |
| **ExpandableRepo** | ❌ Missing | ❌ Missing | ❌ Not implemented |
| **SearchResultItem** | ❌ Missing | ❌ Missing | ❌ Not implemented |

### IssueCard Swipe (Implemented)
```dart
Dismissible(
  key: ValueKey('issue-${issue.id}'),
  direction: DismissDirection.horizontal,
  background: Container(
    alignment: Alignment.centerLeft,
    color: AppColors.blue,
    child: Icon(Icons.edit),  // Edit action
  ),
  secondaryBackground: Container(
    alignment: Alignment.centerRight,
    color: AppColors.red,
    child: Icon(Icons.close),  // Close action
  ),
  confirmDismiss: (direction) async {
    HapticFeedback.lightImpact();
    if (direction == startToEnd) onSwipeRight?.call();
    else onSwipeLeft?.call();
    return false;  // Don't dismiss
  },
)
```

### Required Swipe Implementation

**ExpandableRepo needs:**
- Swipe right → Pin repo
- Swipe left → Unpin repo

---

## Part 6: Recommendations

### 1. Create PageTemplate Widget ✅ PRIORITY

**Purpose:** Unified page template with safe zone for system bar

**Location:** `/lib/widgets/page_template.dart`

**Features:**
- SafeArea wrapper
- Consistent AppBar styling
- System bar padding (clock, battery, camera)
- Optional bottom navigation slot
- Consistent background gradient

**Implementation:**
```dart
class PageTemplate extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int? bottomNavIndex;
  final Function(int)? onBottomNavTap;
  final bool showBottomNav;

  const PageTemplate({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavIndex,
    this.onBottomNavTap,
    this.showBottomNav = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildAppBar(),
              // Body
              Expanded(child: body),
              // Bottom Navigation (optional)
              if (showBottomNav) _buildBottomNav(),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
```

### 2. Add Swipe to ExpandableRepo ✅ PRIORITY

**Location:** `/lib/widgets/expandable_repo.dart`

**Wrap Card with Dismissible:**
```dart
return Dismissible(
  key: ValueKey('repo-${widget.repo.id}'),
  direction: widget.isPinned 
    ? DismissDirection.endToStart  // Swipe left to unpin
    : DismissDirection.startToEnd, // Swipe right to pin
  background: Container(
    color: AppColors.orangePrimary.withValues(alpha: 0.3),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 16),
    child: const Icon(Icons.push_pin, color: Colors.white),
  ),
  secondaryBackground: Container(
    color: AppColors.red.withValues(alpha: 0.3),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    child: const Icon(Icons.push_pin_outlined, color: Colors.white),
  ),
  confirmDismiss: (direction) async {
    HapticFeedback.lightImpact();
    return true;
  },
  onDismissed: (direction) {
    widget.onPinToggle?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isPinned ? 'Unpinned' : 'Pinned'),
        backgroundColor: AppColors.orangePrimary,
      ),
    );
  },
  child: Card(
    // ... existing card content
  ),
);
```

### 3. Project Structure Cleanup

**Current structure is GOOD** - No major restructuring needed:
- ✅ Clear separation of concerns
- ✅ Modular widgets
- ✅ Services well-organized
- ✅ Models properly defined

**Minor improvements:**
- Consider adding `/lib/features/` for feature-based organization (optional)
- Consider adding `/lib/core/` for core utilities (optional)

---

## Summary

### ✅ Completed Analysis

1. **Project Structure:** Well-organized, no major issues
2. **Widget Library:** 19 reusable widgets, good coverage
3. **Color Palette:** Fully consolidated in `app_colors.dart`
4. **Screen Visualizations:** 7 screens documented with ASCII art
5. **Widget Breakdowns:** Complete hierarchy for each screen

### ❌ Identified Gaps

1. **No PageTemplate** - Each screen implements own Scaffold
2. **Incomplete swipe** - Only IssueCard has swipe support
3. **No system bar safe zone** - Inconsistent across screens

### 📋 Next Steps

1. Create `PageTemplate` widget with safe zone
2. Add swipe support to `ExpandableRepo`
3. Refactor all screens to use `PageTemplate`
4. Add swipe to `SearchResultItem` (optional)

---

**Analysis Complete**  
**Generated:** March 3, 2026  
**Total Screens:** 7  
**Total Widgets:** 19  
**Total Services:** 18  
**Total Models:** 7
