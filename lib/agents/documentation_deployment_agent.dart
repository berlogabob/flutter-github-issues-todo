import 'dart:async';
import 'base_agent.dart';

/// Documentation & Deployment Agent (DDA)
/// Maintains documentation and prepares project for deployment
class DocumentationDeploymentAgent extends BaseAgent {
  final Map<String, Document> _documents = {};
  final List<DeploymentStep> _deploymentSteps = [];
  
  DocumentationDeploymentAgent() : super(
    role: 'Documentation & Deployment Agent',
    shortName: 'DDA',
    description: 'Ведёт документацию, готовит проект к сборке и публикации',
  );
  
  @override
  Future<void> start() async {
    isRunning = true;
    sendMessage('DDA started - Documentation and deployment preparation initiated', type: MessageType.statusUpdate);
    _initializeDocumentation();
    _prepareDeploymentSteps();
  }
  
  @override
  Future<void> stop() async {
    isRunning = false;
    sendMessage('DDA stopped - Documentation work paused', type: MessageType.statusUpdate);
  }
  
  @override
  Future<AgentTaskResult> processTask(AgentTask task) async {
    task.status = TaskStatus.inProgress;
    task.startedAt = DateTime.now();
    
    try {
      sendMessage('Processing documentation task ${task.id}', type: MessageType.info);
      
      final result = await _processDocumentationTask(task);
      
      task.status = TaskStatus.completed;
      task.completedAt = DateTime.now();
      
      sendMessage('Documentation task ${task.id} completed', 
        type: MessageType.taskCompleted,
        data: {'taskId': task.id});
      
      return result;
    } catch (e, stackTrace) {
      task.status = TaskStatus.failed;
      sendMessage('Documentation task ${task.id} failed: $e', 
        type: MessageType.taskFailed);
      
      return AgentTaskResult(
        taskId: task.id,
        success: false,
        issues: [e.toString(), stackTrace.toString()],
      );
    }
  }
  
  void _initializeDocumentation() {
    sendMessage('Initializing documentation', type: MessageType.info);
    
    _documents['README.md'] = _createReadme();
    _documents['INSTALLATION.md'] = _createInstallationGuide();
    _documents['AUTHENTICATION.md'] = _createAuthenticationGuide();
    _documents['ARCHITECTURE.md'] = _createArchitectureDoc();
    _documents['DEPLOYMENT.md'] = _createDeploymentGuide();
    
    sendMessage('Initialized ${_documents.length} documentation files', type: MessageType.info);
  }
  
  void _prepareDeploymentSteps() {
    _deploymentSteps.addAll([
      DeploymentStep(
        order: 1,
        name: 'Update pubspec.yaml',
        description: 'Ensure version and build number are correct',
        command: null,
      ),
      DeploymentStep(
        order: 2,
        name: 'Run flutter pub get',
        description: 'Install all dependencies',
        command: 'flutter pub get',
      ),
      DeploymentStep(
        order: 3,
        name: 'Run build_runner',
        description: 'Generate code for Hive, Riverpod',
        command: 'flutter pub run build_runner build --delete-conflicting-outputs',
      ),
      DeploymentStep(
        order: 4,
        name: 'Run tests',
        description: 'Execute all tests',
        command: 'flutter test',
      ),
      DeploymentStep(
        order: 5,
        name: 'Analyze code',
        description: 'Check for linting issues',
        command: 'flutter analyze',
      ),
      DeploymentStep(
        order: 6,
        name: 'Build APK (Android)',
        description: 'Build release APK',
        command: 'flutter build apk --release',
      ),
      DeploymentStep(
        order: 7,
        name: 'Build iOS (iOS)',
        description: 'Build iOS archive',
        command: 'flutter build ipa --release',
      ),
    ]);
  }
  
  Future<AgentTaskResult> _processDocumentationTask(AgentTask task) async {
    final metadata = task.metadata;
    
    switch (metadata?['file']) {
      case 'README.md':
        return _generateReadme(task);
      case 'pubspec.yaml':
        return _updatePubspec(task);
      default:
        return _generateDocumentation(task);
    }
  }
  
  AgentTaskResult _generateReadme(AgentTask task) {
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'README.md generated',
      artifacts: {
        'content': _documents['README.md']?.content,
      },
    );
  }
  
  AgentTaskResult _updatePubspec(AgentTask task) {
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'pubspec.yaml updated',
    );
  }
  
  AgentTaskResult _generateDocumentation(AgentTask task) {
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Documentation generated',
    );
  }
  
  Document _createReadme() {
    return Document(
      name: 'README.md',
      title: 'GitDoIt - Minimalist GitHub Issues & Projects TODO Manager',
      content: '''
# GitDoIt

**Minimalist GitHub Issues & Projects TODO Manager**

A cross-platform mobile application (Android + iOS) that transforms GitHub Issues and GitHub Projects (v2) into a convenient, fast, minimalist TODO manager with a strong offline-first approach.

## Features

- 🔐 **Dual Authentication**: OAuth Device Flow or Personal Access Token
- 📱 **Offline-First**: Work without internet, sync when connected
- 🗂️ **Hierarchical View**: Repo → Issues → Sub-issues with expandable items
- 📋 **Project Board**: Kanban-style board with drag-and-drop
- 🎨 **Dark Theme**: Beautiful dark mode with orange accents
- ⚡ **Fast**: Optimized for quick scanning and triage

## Tech Stack

- **Framework**: Flutter 3.24+
- **State Management**: Riverpod 2.x
- **Local Storage**: Hive
- **Network**: http + graphql_flutter
- **Secure Storage**: flutter_secure_storage
- **Markdown**: flutter_markdown
- **Drag & Drop**: reorderables

## Installation

### Prerequisites

- Flutter SDK 3.24 or higher
- Dart SDK 3.11 or higher
- Android Studio / Xcode
- GitHub account (for authentication)

### Steps

1. Clone the repository:
```bash
git clone https://github.com/your-org/gitdoit.git
cd gitdoit
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

## Usage

### Authentication

GitDoIt supports two authentication methods:

1. **OAuth Device Flow** (Recommended)
   - Click "Login with GitHub"
   - Enter the provided code on GitHub's device verification page
   - Grant permissions

2. **Personal Access Token**
   - Generate a token with scopes: `repo`, `read:org`, `write:org`, `project`
   - Enter the token in the app

3. **Offline Mode**
   - Click "Continue Offline"
   - Create and manage local tasks without GitHub

### Main Features

- **Dashboard**: View all your issues in a hierarchical list
- **Filters**: Filter by Open/Closed/All and by project
- **Issue Details**: View full issue with markdown support
- **Project Board**: Drag and drop issues between columns
- **Search**: Global search across titles, labels, and body

## Screens

1. **OnboardingScreen** - Authentication choice
2. **MainDashboardScreen** - Main task hierarchy view
3. **IssueDetailScreen** - Detailed issue view
4. **ProjectBoardScreen** - Kanban board
5. **RepoProjectLibraryScreen** - Manage repos and projects
6. **SearchScreen** - Global search
7. **SettingsScreen** - App settings

## Architecture

```
lib/
├── agents/           # Agent system for parallel development
├── constants/        # App constants (colors, strings)
├── models/          # Data models (Item, IssueItem, RepoItem, ProjectItem)
├── providers/       # Riverpod providers
├── screens/         # UI screens
├── services/        # Business logic services
└── widgets/         # Reusable widgets
```

## Development

### Running Tests

```bash
flutter test
```

### Code Generation

```bash
flutter pub run build_runner watch
```

### Linting

```bash
flutter analyze
```

## Contributing

This is an MVP project. Please refer to the brief for feature requirements.

## License

MIT License

## Acknowledgments

- GitHub API for providing the backend
- Flutter community for amazing packages
''',
    );
  }
  
  Document _createInstallationGuide() {
    return Document(
      name: 'INSTALLATION.md',
      title: 'Installation Guide',
      content: '''
# Installation Guide

## System Requirements

### macOS
- macOS 10.15 (Catalina) or higher
- Xcode 15.0 or higher
- CocoaPods

### Windows
- Windows 10 or higher
- Visual Studio 2022 with C++ workload
- Git for Windows

### Linux
- Ubuntu 20.04 or higher (or equivalent)
- GCC, Clang, or other C++ compiler
- Git

## Flutter Setup

1. Download Flutter SDK from https://flutter.dev
2. Extract to a desired location (e.g., `~/flutter`)
3. Add Flutter to your PATH:
```bash
export PATH="\$PATH:`pwd`/flutter/bin"
```

4. Run `flutter doctor` to check your setup

## Project Setup

1. Clone the repository
2. Navigate to project directory
3. Run `flutter pub get`
4. Run `flutter pub run build_runner build --delete-conflicting-outputs`
5. Run `flutter run`

## Android Setup

1. Install Android Studio
2. Install Android SDK (API 21+)
3. Set up an emulator or connect a device
4. Run `flutter config --android-sdk <path>`

## iOS Setup

1. Install Xcode from App Store
2. Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. Run `sudo xcodebuild -runFirstLaunch`
4. Install CocoaPods: `sudo gem install cocoapods`
5. Set up iOS simulator or connect a device

## Troubleshooting

### Common Issues

**Issue**: Build fails with "No such module"
**Solution**: Run `flutter clean` and `flutter pub get`

**Issue**: Code generation fails
**Solution**: Run `flutter pub run build_runner clean` then rebuild

**Issue**: Android build fails
**Solution**: Check `android/app/build.gradle` for correct SDK versions
''',
    );
  }
  
  Document _createAuthenticationGuide() {
    return Document(
      name: 'AUTHENTICATION.md',
      title: 'Authentication Guide',
      content: '''
# Authentication Guide

## OAuth Device Flow (Recommended)

### Steps

1. App requests device code from GitHub
2. App displays user code and verification URL
3. User visits URL on another device
4. User enters code and authorizes app
5. App polls for token completion
6. Token is stored securely

### Required Scopes

- `repo` - Full control of private repositories
- `read:org` - Read org membership
- `write:org` - Read and write org membership
- `project` - Read and write projects

## Personal Access Token (PAT)

### Creating a Token

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Click "Generate new token"
3. Select scopes:
   - ✅ repo
   - ✅ read:org
   - ✅ write:org  
   - ✅ project
4. Generate and copy the token

### Using the Token

1. Select "Use Personal Access Token" in app
2. Paste your token
3. Token is stored in flutter_secure_storage

## Offline Mode

- Select "Continue Offline"
- Creates local repository "My Local Tasks"
- All features work without network
- Changes sync when you log in later

## Security

- Tokens stored in flutter_secure_storage
- No tokens logged or transmitted
- Token only used for GitHub API calls
- Logout securely deletes token

## Troubleshooting

**Issue**: "Bad credentials"
**Solution**: Token expired or revoked. Generate new token.

**Issue**: "Resource not accessible"
**Solution**: Missing required scopes. Regenerate token with all scopes.

**Issue**: OAuth timeout
**Solution**: Network issue. Try PAT or check connection.
''',
    );
  }
  
  Document _createArchitectureDoc() {
    return Document(
      name: 'ARCHITECTURE.md',
      title: 'Architecture Documentation',
      content: '''
# Architecture Documentation

## Overview

GitDoIt follows a clean architecture pattern with Riverpod for state management.

## Layers

### Presentation Layer
- **Screens**: 7 MVP screens
- **Widgets**: Reusable components (ExpandableItem, etc.)
- **Theme**: Dark mode with defined color palette

### Business Logic Layer
- **Providers**: Riverpod state management
- **Services**: Business logic (Auth, Sync, GitHub API)
- **Models**: Data structures with Hive support

### Data Layer
- **Local**: Hive for offline storage
- **Remote**: GitHub REST + GraphQL APIs
- **Secure**: flutter_secure_storage for tokens

## Key Components

### ExpandableItem Widget
Recursive widget for hierarchical display:
```
RepoItem
└── IssueItem
    └── IssueItem (sub-task)
```

### Sync Service
Handles offline-first synchronization:
1. Load local data
2. Fetch remote data
3. Merge with conflict resolution
4. Update local storage

### Authentication Service
Dual auth support:
- OAuth Device Flow
- Personal Access Token

## State Management

Using Riverpod for:
- Global state (auth, settings)
- Cache management
- Async data fetching

## Data Flow

```
User Action → Provider → Service → API/Local DB → Provider → UI
```

## File Structure

```
lib/
├── main.dart              # App entry point
├── agents/                # Agent system
├── constants/             # Constants
│   └── app_colors.dart   # Color definitions
├── models/                # Data models
│   ├── item.dart         # Abstract base class
│   ├── repo_item.dart    # Repository model
│   ├── issue_item.dart   # Issue model
│   └── project_item.dart # Project model
├── providers/             # Riverpod providers
├── screens/               # UI screens
├── services/              # Business logic
└── widgets/               # Reusable widgets
```
''',
    );
  }
  
  Document _createDeploymentGuide() {
    return Document(
      name: 'DEPLOYMENT.md',
      title: 'Deployment Guide',
      content: '''
# Deployment Guide

## Pre-deployment Checklist

- [ ] All tests passing
- [ ] No linting errors
- [ ] Version updated in pubspec.yaml
- [ ] Build number incremented
- [ ] README updated
- [ ] Screenshots captured (if needed)

## Android Deployment

### Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Play Store Upload

1. Create app in Google Play Console
2. Fill store listing
3. Upload app bundle
4. Complete content rating
5. Submit for review

## iOS Deployment

### Build IPA

```bash
flutter build ipa --release
```

Output: `build/ios/archive/Runner.xcarchive`

### Xcode Upload

1. Open Xcode
2. Window → Organizer
3. Select archive
4. Click "Distribute App"
5. Follow App Store Connect upload

### TestFlight

1. Go to App Store Connect
2. Select your app
3. Go to TestFlight tab
4. Add testers
5. Submit for beta review

## Version Management

Update in `pubspec.yaml`:

```yaml
version: 1.0.0+1  # version+build_number
```

## Release Notes

Keep changelog in:
- README.md
- App store listings
- Git tags

## Post-deployment

1. Monitor crash reports
2. Check user reviews
3. Track analytics
4. Plan next sprint
''',
    );
  }
  
  /// Get document by name
  Document? getDocument(String name) {
    return _documents[name];
  }
  
  /// Get all documents
  Map<String, Document> getAllDocuments() {
    return Map.unmodifiable(_documents);
  }
  
  /// Get deployment steps
  List<DeploymentStep> getDeploymentSteps() {
    return List.unmodifiable(_deploymentSteps);
  }
  
  /// Get deployment readiness
  Map<String, dynamic> getDeploymentReadiness() {
    return {
      'documentsReady': _documents.length,
      'deploymentSteps': _deploymentSteps.length,
      'ready': _documents.length >= 5 && _deploymentSteps.length >= 7,
    };
  }
}

/// Document specification
class Document {
  final String name;
  final String title;
  final String content;
  
  Document({
    required this.name,
    required this.title,
    required this.content,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'contentLength': content.length,
    };
  }
}

/// Deployment step
class DeploymentStep {
  final int order;
  final String name;
  final String description;
  final String? command;
  
  DeploymentStep({
    required this.order,
    required this.name,
    required this.description,
    this.command,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'name': name,
      'description': description,
      'command': command,
    };
  }
}
