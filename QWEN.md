# GitDoIt - QWEN Context File

**Project:** GitDoIt - Minimalist GitHub Issues & Projects TODO Manager  
**Version:** 0.5.0+126  
**Framework:** Flutter 3.24+ / Dart 3.11+  
**Last Updated:** March 18, 2026  
**Total Codebase:** ~24,773 lines of Dart code

---

## 📋 Project Overview

GitDoIt is a **cross-platform mobile application** (Android + iOS) that transforms GitHub Issues and GitHub Projects (v2) into a minimalist TODO manager with a strong **offline-first approach**.

### Core Purpose
- Transform GitHub Issues/Projects into a convenient TODO manager
- Work offline with local storage, sync when connected
- Provide hierarchical view: Repo → Issues → Sub-issues
- Kanban-style project board with drag-and-drop
- Support dual authentication: OAuth Device Flow or Personal Access Token

### Key Technologies
| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.24+ |
| **State Management** | Riverpod 3.3.1 |
| **Navigation** | GoRouter 17.1.0 |
| **Local Storage** | Hive CE 2.10.1 (Community Edition) |
| **Network** | Dio 5.7.0 + http 1.2.0 |
| **Secure Storage** | flutter_secure_storage 10.0.0 |
| **Markdown** | flutter_markdown_plus 1.0.6 |
| **Drag & Drop** | reorderables 0.6.0 |
| **Background Sync** | workmanager 0.9.0+3 |

---

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                          # App entry point with background sync
├── agents/                            # Multi-agent development system (9 files)
│   ├── agents.dart                    # Library exports
│   ├── base_agent.dart                # Base agent class
│   ├── coordinator_agent.dart         # Central coordinator (singleton)
│   ├── project_manager_agent.dart     # Task coordination
│   ├── flutter_developer_agent.dart   # Code implementation
│   ├── ui_designer_agent.dart         # Design compliance
│   ├── testing_quality_agent.dart     # Quality assurance
│   ├── documentation_agent.dart       # Documentation & releases
│   └── rules_compliance_agent.dart    # Proactive rule checking
├── constants/
│   └── app_colors.dart                # Dark theme colors, typography, spacing
├── models/                            # Data models (8 files)
│   ├── item.dart                      # Abstract base class
│   ├── repo_item.dart                 # Repository model
│   ├── issue_item.dart                # Issue model
│   ├── project_item.dart              # Project model
│   ├── cached_dashboard_data.dart     # Dashboard cache
│   ├── pending_operation.dart         # Offline queue operations
│   ├── sync_history_entry.dart        # Sync history tracking
│   └── models.dart                    # Model exports
├── screens/                           # 14 MVP screens
│   ├── onboarding_screen.dart         # Login & offline mode
│   ├── main_dashboard_screen.dart     # Main TODO view
│   ├── repo_detail_screen.dart        # Repository issues
│   ├── issue_detail_screen.dart       # Issue details & comments
│   ├── edit_issue_screen.dart         # Edit issue
│   ├── create_issue_screen.dart       # Create new issue
│   ├── project_board_screen.dart      # Kanban board
│   ├── search_screen.dart             # Global search
│   ├── settings_screen.dart           # App settings
│   ├── repo_project_library_screen.dart # Repo/project selector
│   ├── sync_status_dashboard_screen.dart # Sync status
│   ├── error_log_screen.dart          # Error logs
│   ├── debug_screen.dart              # Debug utilities
│   └── onboarding_screen.dart.backup  # Backup file
├── providers/                         # Riverpod providers
│   └── app_providers.dart             # All providers
├── services/                          # Business logic (14 files)
│   ├── github_api_service.dart        # REST + GraphQL API
│   ├── sync_service.dart              # Auto-sync, conflict resolution
│   ├── local_storage_service.dart     # Hive local storage
│   ├── secure_storage_service.dart    # Token storage (singleton)
│   ├── oauth_service.dart             # OAuth Device Flow
│   ├── network_service.dart           # Network connectivity
│   ├── cache_service.dart             # API response caching
│   ├── pending_operations_service.dart # Offline operation queue
│   ├── issue_service.dart             # Issue CRUD operations
│   ├── dashboard_service.dart         # Dashboard data
│   ├── dashboard_data_service.dart    # Dashboard data fetching
│   ├── conflict_detection_service.dart # Conflict detection
│   ├── error_logging_service.dart     # Error logging
│   └── search_history_service.dart    # Search history
├── widgets/                           # Reusable components (20 files)
│   ├── expandable_repo.dart           # Expandable repo list
│   ├── issue_card.dart                # Issue card widget
│   ├── error_boundary.dart            # Error boundary
│   ├── sync_cloud_icon.dart           # Sync status icon
│   ├── optimistic_update_listener.dart # Optimistic updates
│   ├── loading_skeleton.dart          # Loading skeletons
│   ├── label_chip.dart                # Label display
│   ├── status_badge.dart              # Status badges
│   ├── conflict_resolution_dialog.dart # Conflict resolution
│   ├── pending_operations_list.dart   # Offline queue display
│   ├── search_filters_panel.dart      # Search filters
│   ├── search_result_item.dart        # Search results
│   ├── repo_list.dart                 # Repo list widget
│   ├── dashboard_empty_state.dart     # Empty state
│   ├── dashboard_filters.dart         # Dashboard filters
│   ├── empty_state_illustrations.dart # Empty state graphics
│   ├── page_template.dart             # Page template
│   ├── sync_status_widget.dart        # Sync status display
│   ├── tutorial_overlay.dart          # Tutorial overlay
│   └── braille_loader.dart            # Loading indicator
└── utils/                             # Utilities (5 files)
    ├── responsive_utils.dart          # Responsive design
    ├── app_error_handler.dart         # Global error handling
    ├── auth_error_handler.dart        # Auth error handling
    ├── relative_time.dart             # Time formatting
    └── retry_helper.dart              # Retry logic
```

### Design System
- **Theme:** Dark theme only (per MVP scope)
- **Background:** `#121212` → `#1E1E1E` (gradient)
- **Primary Color:** Orange `#FF6200`
- **Secondary Color:** Red `#FF3B30`
- **Accent:** Blue `#0A84FF`
- **Responsive:** Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)

### Color Palette (Simplified - 12 colors)
```dart
// Back grounds (3)
static const Color background = Color(0xFF121212);
static const Color card = Color(0xFF1E1E1E);
static const Color dark = Color(0xFF0A0A0A);

// Accents (3)
static const Color primary = Color(0xFFFF6200);
static const Color link = Color(0xFF0A84FF);
static const Color error = Color(0xFFFF3B30);

// Status (3)
static const Color success = Color(0xFF4CAF50);
static const Color warning = Color(0xFFFFC107);
static const Color muted = Color(0xFF6E7781);

// Text & Borders (3)
static const Color text = Color(0xFFFFFFFF);
static const Color textSecondary = Color(0xFFA0A0A5);
static const Color border = Color(0xFF333333);
```

---

## 🚀 Building and Running

### Prerequisites
- Flutter SDK 3.24 or higher
- Dart SDK 3.11 or higher
- Android Studio / Xcode
- GitHub account (for authentication)

### Initial Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (required for Riverpod/Hive)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Configure OAuth (for GitHub login)
cp .env.default .env
# Edit .env and add your GITHUB_CLIENT_ID
```

### Running the App

```bash
# Standard run
flutter run

# Run with OAuth configuration
make run-with-env

# Watch mode for code generation
flutter pub run build_runner watch
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS IPA (App Store)
flutter build ipa --release

# Web (GitHub Pages)
flutter build web --release --base-href="/flutter-github-issues-todo/"
```

### Using the Makefile

```bash
# Show help
make

# Build Android APK with version increment
make build-android

# Build Web release for GitHub Pages
make build-web

# Full release (both Android and Web)
make release

# Clean build directories
make clean

# Only increment build number
make version-increment
```

---

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Test Structure
```
test/
├── agents/                          # Agent system tests
│   └── wake_agents_test.dart        # Wake all agents test
├── models/                          # Model tests
│   ├── issue_item_test.dart
│   └── models_test.dart
├── screens/                         # Screen tests
│   ├── create_issue_screen_test.dart
│   ├── edit_issue_screen_test.dart
│   ├── error_log_screen_test.dart
│   ├── issue_detail_screen_*.dart   # Issue detail tests
│   ├── onboarding_screen_test.dart
│   ├── repo_detail_screen_test.dart
│   ├── search_screen_*.dart         # Search tests
│   └── settings_screen_full_test.dart
├── sprint16/                        # Sprint 16 tests
│   ├── sprint16_background_sync_test.dart
│   ├── sprint16_image_caching_test.dart
│   ├── sprint16_list_optimization_test.dart
│   ├── sprint16_loading_skeletons_test.dart
│   └── sprint16_pagination_test.dart
└── widget_test.dart                 # Widget tests
```

### Test Coverage
- ✅ Model tests
- ✅ Widget tests
- ✅ Screen tests (14+ screens)
- ✅ Agent system tests (5 tests)
- ✅ Sprint 16 integration tests (5 tests)
- ✅ Background sync tests
- ✅ Offline operation tests

---

## 🛠️ Development Commands

### Code Quality
```bash
# Linting
flutter analyze

# Formatting
dart format .

# Generate API documentation
dart doc
```

### Code Generation
```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate on changes)
flutter pub run build_runner watch
```

### Version Management
```bash
# Increment build number automatically
make version-increment
```

---

## 🔐 Authentication Methods

### 1. OAuth Device Flow (Recommended)
- Click "Login with GitHub"
- Enter provided code on GitHub's device verification page
- Grant permissions
- **Setup:** Requires GitHub OAuth App with Client ID in `.env`

### 2. Personal Access Token (PAT)
Generate token with scopes:
- `repo` - Full control of private repositories
- `read:org` - Read org membership
- `write:org` - Read and write org membership
- `project` - Read and write projects

### 3. Offline Mode
- Click "Continue Offline"
- Creates local repository "My Local Tasks"
- All features work without network
- Changes sync when logged in later

---

## 📦 Key Dependencies

### Production
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.3.1 | State management |
| `go_router` | ^17.1.0 | Navigation |
| `hive_ce` | ^2.10.1 | Local database (CE) |
| `hive_ce_flutter` | ^2.2.0 | Hive Flutter integration |
| `dio` | ^5.7.0 | HTTP client (advanced) |
| `http` | ^1.2.0 | HTTP client (basic) |
| `flutter_secure_storage` | ^10.0.0 | Secure token storage |
| `flutter_markdown_plus` | ^1.0.6 | Markdown rendering |
| `reorderables` | ^0.6.0 | Drag-and-drop lists |
| `url_launcher` | ^6.3.2 | Open URLs |
| `connectivity_plus` | ^7.0.0 | Network connectivity |
| `flutter_screenutil` | ^5.9.3 | Responsive design |
| `flutter_svg` | ^2.0.17 | SVG support |
| `cached_network_image` | ^3.3.1 | Image caching |
| `workmanager` | ^0.9.0+3 | Background sync |
| `shimmer` | ^3.0.0 | Loading skeletons |
| `share_plus` | ^12.0.1 | Share functionality |
| `flutter_dotenv` | ^5.1.0 | Environment variables |
| `file_picker` | ^10.3.10 | File/folder selection |
| `permission_handler` | ^12.0.1 | Permissions |
| `package_info_plus` | ^9.0.0 | Package info |
| `gap` | ^3.0.0 | Layout gaps |
| `cupertino_icons` | ^1.0.8 | Icons |

### Development
| Package | Version | Purpose |
|---------|---------|---------|
| `build_runner` | ^2.4.12 | Code generation |
| `lints` | ^6.1.0 | Linting rules |
| `very_good_analysis` | ^10.2.0 | Strict linting |
| `build_config` | ^1.1.0 | Build configuration |
| `integration_test` | SDK | Integration testing |
| `benchmark_harness` | ^2.3.1 | Performance testing |
| `flutter_test` | SDK | Widget testing |

---

## 🎯 MVP Scope

### Included ✅
- 14 MVP screens (including debug & error log)
- Dark theme only
- OAuth + PAT authentication
- Offline-first with Hive CE
- Issues sync (REST)
- Projects v2 board (GraphQL)
- Drag-and-drop between columns
- Hierarchical expandable items
- Global search with history
- Markdown rendering
- Create/Edit issues
- Close/Reopen issues
- Filter by status and project
- Auto-sync on network restore
- Responsive design (mobile/tablet/desktop)
- Background sync (every 15 min)
- Error logging & sharing
- Conflict detection & resolution
- Pending operations queue
- Optimistic updates
- Loading skeletons
- Image caching
- Sync status dashboard
- Tutorial overlay

### Explicitly Excluded ❌
- Light theme
- Push notifications
- Home screen widgets
- Share sheet (basic share only)
- Other service integrations (Slack, Trello)
- Custom icons/illustrations
- Lottie animations
- Inline editing in lists
- Comments to issues (read-only)

---

## 🤖 Agent System

GitDoIt uses a unique **multi-agent system** for parallel development with proactive compliance checking.

### Agent Team

| Agent | Role | Status |
|-------|------|--------|
| **PMA** | Project Manager | ✅ Active |
| **FDA** | Flutter Developer | ✅ Active |
| **UDA** | UI/UX Designer | ✅ Active |
| **TQA** | Testing & Quality | ✅ Active |
| **DDA** | Documentation | ✅ Active |
| **RCA** | Rules & Compliance | 🆕 **PROACTIVE** |
| **COORD** | Agent Coordinator | 🆕 **CONTROLLER** |

### Agent Responsibilities

- **PMA (ProjectManagerAgent)**: Coordinates team, assigns tasks, tracks sprint progress
- **FDA (FlutterDeveloperAgent)**: Writes code, implements features, runs build_runner
- **UDA (UiDesignerAgent)**: Designs interfaces, ensures design system compliance
- **TQA (TestingQualityAgent)**: Validates code, runs tests, enforces linting
- **DDA (DocumentationAgent)**: Maintains docs, prepares releases, manages changelog
- **RCA (RulesComplianceAgent)**: 🆕 **PROACTIVE** - Continuously monitors project rules, conventions, offline-first compliance, security
- **COORD (AgentCoordinator)**: 🆕 **CONTROLLER** - Central control, manages all agents, health monitoring

### Parallel Execution

All agents work concurrently and communicate through a message bus:

```dart
import 'package:gitdoit/agents/agents.dart';

final coordinator = get coordinator; // Singleton
await coordinator.startAll();

// Check status
print(coordinator.getAgentStatus());
print(coordinator.getComplianceStatus());

await coordinator.stopAll();
```

### Project Rules (Enforced by RCA)

The Rules & Compliance Agent proactively checks:

| Rule | Severity | Description |
|------|----------|-------------|
| `offline_first` | **Critical** | All features must work offline |
| `error_handling` | **Critical** | All async ops need error handling |
| `secure_storage` | **Critical** | Tokens in flutter_secure_storage |
| `no_env_commit` | **Critical** | Never commit .env file |
| `naming_convention` | Warning | PascalCase classes, camelCase variables |
| `dark_theme_only` | Warning | Use only dark theme colors |
| `no_shortcuts` | Error | No quick and dirty solutions |
| `trailing_commas` | Warning | Use trailing commas |
| `single_quotes` | Warning | Use single quotes |
| `responsive_design` | Warning | Use ScreenUtil |

📚 **Full Documentation:** See [AGENTS.md](AGENTS.md)

---

## 📝 Development Conventions

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format .` before committing
- Run `flutter analyze` to catch issues
- Add dartdoc comments to public APIs
- Use trailing commas
- Prefer single quotes

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: Add new feature
fix: Fix bug
docs: Update documentation
style: Format code
refactor: Refactor code
test: Add tests
chore: Update dependencies
```

### Testing Practices
- Write tests for new features
- Maintain or improve code coverage
- Run `flutter test` before committing
- Unit tests for models are essential
- Widget tests can be deferred for MVP

### Architecture Principles
- **Offline-First:** Design for offline from day 1
- **Conflict Resolution:** "Remote wins" is simplest for MVP
- **Sync Debounce:** 2-second debounce prevents race conditions
- **Responsive Utils:** Centralize breakpoints and utilities
- **No Shortcut Engineering:** Avoid "quick and dirty" solutions

---

## 🔧 Common Issues & Solutions

### OAuth Setup
**Problem:** "GITHUB_CLIENT_ID not set"  
**Solution:** 
1. Go to https://github.com/settings/developers
2. Create new OAuth App
3. Copy Client ID to `.env`
4. Run `make run-with-env`

### Code Generation Errors
**Problem:** Build runner conflicts  
**Solution:** 
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Build Warnings
**Problem:** Deprecated API warnings  
**Solution:** 
```bash
flutter analyze
# Fix all deprecated API usage (e.g., withOpacity → withValues)
```

---

## 📚 Documentation

- **README.md** - User-facing documentation
- **QWEN.md** - This file (project context)
- **AGENTS.md** - Multi-agent system documentation
- **PROJECT_MASTER.md** - Complete project architecture
- **CONTRIBUTING.md** - Contribution guidelines
- **CHANGELOG.md** - Version history
- **docs/api/** - Generated API documentation

---

## 🚨 Important Notes

### Security
- **Never commit `.env` file** - Already in `.gitignore`
- Use `flutter_secure_storage` for tokens
- OAuth Device Flow is safer than storing PATs

### Build Automation
- Makefile automatically increments build number
- GitHub Pages deployment uses `/docs` folder
- GitHub Release automation requires `gh` CLI

### Offline Mode
- Issues saved as Markdown files in vault folder
- No network required for basic functionality
- Sync happens automatically when network restored

### Background Sync
- Runs every 15 minutes when connected
- Respects auto-sync settings (WiFi only / Any network)
- Handles pending operations queue

---

## 📞 Support

- **Repository:** https://github.com/berlogabob/flutter-github-issues-todo
- **Issues:** Create issue for bugs/feature requests
- **License:** MIT

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
