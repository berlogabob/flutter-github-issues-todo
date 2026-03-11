# GitDoIt - QWEN Context File

**Project:** GitDoIt - Minimalist GitHub Issues & Projects TODO Manager  
**Version:** 0.5.0+70  
**Framework:** Flutter 3.24+ / Dart 3.11+  
**Last Updated:** March 2, 2026

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
| **State Management** | Riverpod 3.0.3 |
| **Local Storage** | Hive |
| **Network** | http + graphql_flutter |
| **Secure Storage** | flutter_secure_storage |
| **Markdown** | flutter_markdown_plus |
| **Drag & Drop** | reorderables |

---

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                          # App entry point
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
├── screens/                           # 7 MVP screens
│   ├── onboarding_screen.dart
│   ├── main_dashboard_screen.dart
│   ├── issue_detail_screen.dart
│   ├── project_board_screen.dart
│   ├── edit_issue_screen.dart
│   ├── search_screen.dart
│   ├── settings_screen.dart
│   └── repo_project_library_screen.dart
├── providers/
│   └── app_providers.dart             # Riverpod providers
├── services/
│   ├── github_api_service.dart        # REST + GraphQL API
│   ├── sync_service.dart              # Auto-sync, conflict resolution
│   ├── local_storage_service.dart     # Hive local storage
│   ├── secure_storage_service.dart    # Token storage (singleton)
│   └── oauth_service.dart             # OAuth Device Flow
├── widgets/
│   ├── expandable_repo.dart
│   ├── issue_card.dart
│   ├── error_boundary.dart
│   └── sync_cloud_icon.dart
└── utils/
    └── responsive_utils.dart          # Responsive design utilities
```

### Design System
- **Theme:** Dark theme only (per MVP scope)
- **Background:** `#121212` → `#1E1E1E` (gradient)
- **Primary Color:** Orange `#FF6200`
- **Secondary Color:** Red `#FF3B30`
- **Accent:** Blue `#0A84FF`
- **Responsive:** Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)

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
cp .env.example .env
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

### Test Coverage
- ✅ Model tests (24 tests)
- ✅ Widget tests (42 tests)
- ✅ ExpandableItem tests (14 tests)
- ✅ Auth service tests (12 tests)
- ✅ Sync service tests (18 tests)
- ✅ User journey tests (5 tests)
- ✅ Performance tests (6 tests)
- ✅ Brief compliance (15 checks)

### Test Structure
```
test/
├── models/
├── providers/
├── screens/
├── services/
└── widgets/
```

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
- `flutter_riverpod` - State management
- `hive` + `hive_flutter` - Local database
- `http` - REST API client
- `graphql_flutter` - GraphQL client
- `flutter_secure_storage` - Secure token storage
- `flutter_markdown_plus` - Markdown rendering
- `reorderables` - Drag-and-drop lists
- `url_launcher` - Open URLs
- `connectivity_plus` - Network connectivity
- `flutter_screenutil` - Responsive design

### Development
- `build_runner` - Code generation
- `riverpod_generator` - Riverpod codegen
- `flutter_lints` - Linting rules
- `test` - Testing framework

---

## 🎯 MVP Scope

### Included ✅
- 7 MVP screens
- Dark theme only
- OAuth + PAT authentication
- Offline-first with Hive
- Issues sync (REST)
- Projects v2 board (GraphQL)
- Drag-and-drop between columns
- Hierarchical expandable items
- Global search
- Markdown rendering
- Edit issues (title, body, labels)
- Close/Reopen issues
- Filter by status and project
- Auto-sync on network restore
- Responsive design (mobile/tablet/desktop)

### Explicitly Excluded ❌
- Light theme
- Push notifications
- Home screen widgets
- Share sheet
- Other service integrations (Slack, Trello)
- Custom icons/illustrations
- Lottie animations
- Inline editing in lists
- Comments to issues

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

---

## 📞 Support

- **Repository:** https://github.com/berlogabob/flutter-github-issues-todo
- **Issues:** Create issue for bugs/feature requests
- **License:** MIT

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
