# GitDoIt

**Minimalist GitHub Issues & Projects TODO Manager**

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A cross-platform mobile application (Android + iOS) that transforms GitHub Issues and GitHub Projects (v2) into a convenient, fast, minimalist TODO manager with a strong offline-first approach.

## ✨ Features

- 🔐 **Dual Authentication** - OAuth Device Flow or Personal Access Token
- 📱 **Offline-First** - Work without internet, sync when connected
- 🗂️ **Hierarchical View** - Repo → Issues → Sub-issues with expandable items
- 📋 **Project Board** - Kanban-style board with drag-and-drop
- 🎨 **Dark Theme** - Beautiful dark mode with orange accents
- ⚡ **Fast** - Optimized for quick scanning and triage
- 🔍 **Global Search** - Search across titles, labels, and body

## 📱 Screenshots

The app includes 7 MVP screens:
1. **Onboarding** - Authentication choice (OAuth/PAT/Offline)
2. **Dashboard** - Main task hierarchy view
3. **Issue Detail** - Detailed issue view with markdown
4. **Project Board** - Kanban board with drag-and-drop
5. **Repo/Project Library** - Manage repositories and projects
6. **Search** - Global search functionality
7. **Settings** - App settings and account management

## 🏗️ Architecture

### Tech Stack (as per brief)
- **Framework**: Flutter 3.24+
- **State Management**: Riverpod 2.x
- **Local Storage**: Hive
- **Network**: http + graphql_flutter
- **Secure Storage**: flutter_secure_storage
- **Markdown**: flutter_markdown
- **Drag & Drop**: reorderables
- **URL Launcher**: url_launcher

### Project Structure
```
lib/
├── agents/                    # Multi-agent development system
│   ├── agent_coordinator.dart # Coordinates all agents
│   ├── base_agent.dart        # Base agent class
│   ├── project_manager_agent.dart
│   ├── flutter_developer_agent.dart
│   ├── ui_designer_agent.dart
│   ├── testing_quality_agent.dart
│   └── documentation_deployment_agent.dart
├── constants/                 # App constants
│   └── app_colors.dart       # Color scheme
├── models/                    # Data models
│   ├── item.dart             # Abstract base class
│   ├── repo_item.dart        # Repository model
│   ├── issue_item.dart       # Issue model
│   └── project_item.dart     # Project model
├── screens/                   # UI screens (7 MVP screens)
│   ├── onboarding_screen.dart
│   ├── main_dashboard_screen.dart
│   ├── issue_detail_screen.dart
│   ├── project_board_screen.dart
│   ├── repo_project_library_screen.dart
│   ├── search_screen.dart
│   └── settings_screen.dart
├── providers/                 # Riverpod providers
├── services/                  # Business logic services
└── widgets/                   # Reusable widgets
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24 or higher
- Dart SDK 3.11 or higher
- Android Studio / Xcode
- GitHub account (for authentication)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/your-org/gitdoit.git
cd gitdoit
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run the app**
```bash
flutter run
```

### Building for Production

**Android APK**
```bash
flutter build apk --release
```

**Android App Bundle (Play Store)**
```bash
flutter build appbundle --release
```

**iOS IPA (App Store)**
```bash
flutter build ipa --release
```

## 🔐 Authentication

GitDoIt supports three authentication methods:

### 1. OAuth Device Flow (Recommended)
- Click "Login with GitHub"
- Enter the provided code on GitHub's device verification page
- Grant permissions
- Secure and doesn't require storing tokens manually

### 2. Personal Access Token (PAT)
Generate a token with these scopes:
- `repo` - Full control of private repositories
- `read:org` - Read org membership
- `write:org` - Read and write org membership
- `project` - Read and write projects

### 3. Offline Mode
- Click "Continue Offline"
- Creates local repository "My Local Tasks"
- All features work without network
- Changes sync when you log in later

## 🎨 Design System

### Colors
- **Background**: `#121212` → `#1E1E1E` (gradient)
- **Card Background**: `#1E1E1E`
- **Orange (Primary)**: `#FF6200` - Main actions
- **Red (Secondary)**: `#FF3B30` - Connectors, danger actions
- **Blue (Accent)**: `#0A84FF` - Assignee links

### Typography
- System fonts (SF Pro on iOS, Roboto on Android)
- Titles: Medium/Bold weight
- Secondary text: Regular/Light with 0.7-0.85 opacity

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Test Coverage
The Testing & Quality Agent (TQA) validates:
- ✅ Model tests (24 tests)
- ✅ Widget tests (42 tests)
- ✅ ExpandableItem tests (14 tests)
- ✅ Auth service tests (12 tests)
- ✅ Sync service tests (18 tests)
- ✅ User journey tests (5 tests)
- ✅ Performance tests (6 tests)
- ✅ Brief compliance (15 checks)

## 🤖 Agent System

GitDoIt uses a unique multi-agent system for parallel development:

### Agents
1. **Project Manager (PMA)** - Coordinates team, assigns tasks
2. **Flutter Developer (FDA)** - Writes code, implements features
3. **UI/UX Designer (UDA)** - Designs interface, ensures style compliance
4. **Testing & Quality (TQA)** - Validates code, runs tests
5. **Documentation & Deployment (DDA)** - Maintains docs, prepares releases

### Parallel Execution
All agents work concurrently and communicate through a message bus:
```dart
final coordinator = AgentCoordinator();
coordinator.registerAgent(ProjectManagerAgent());
coordinator.registerAgent(FlutterDeveloperAgent());
// ... register other agents
await coordinator.startAll();
```

See [AGENTS_README.md](AGENTS_README.md) for detailed documentation.

## 📋 MVP Scope

### Included (Brief v1.0)
- ✅ 7 MVP screens
- ✅ Dark theme only
- ✅ OAuth + PAT authentication
- ✅ Offline-first with Hive
- ✅ Issues sync (REST)
- ✅ Projects v2 board (GraphQL)
- ✅ Drag-and-drop between columns
- ✅ Hierarchical expandable items
- ✅ Global search
- ✅ Markdown rendering

### Explicitly Excluded (per brief section 10)
- ❌ Light theme
- ❌ Push notifications
- ❌ Home screen widgets
- ❌ Share sheet
- ❌ Other service integrations
- ❌ Custom icons/illustrations
- ❌ Lottie animations
- ❌ Inline editing in lists
- ❌ Additional features beyond brief

## 🛠️ Development

### Code Generation
```bash
# Watch mode (auto-generate on changes)
flutter pub run build_runner watch

# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting
```bash
flutter analyze
```

### Formatting
```bash
dart format .
```

## 📦 Dependencies

### Production
- `flutter_riverpod` - State management
- `hive` + `hive_flutter` - Local database
- `http` - REST API client
- `graphql_flutter` - GraphQL client
- `flutter_secure_storage` - Secure token storage
- `flutter_markdown` - Markdown rendering
- `reorderables` - Drag-and-drop lists
- `url_launcher` - Open URLs

### Development
- `build_runner` - Code generation
- `riverpod_generator` - Riverpod codegen
- `hive_generator` - Hive adapter generation
- `flutter_lints` - Linting rules

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- GitHub API for providing the backend
- Flutter community for amazing packages
- All contributors to this project

## 📞 Support

For issues and feature requests, please create an issue in the repository.

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
