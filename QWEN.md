# GitDoIt - Flutter GitHub Issues TODO App: Comprehensive Context

## Project Overview

GitDoIt is a minimalist Flutter mobile application designed to manage GitHub Issues as a simple TODO list. The app enables users to create, view, edit, and close GitHub issues directly from their mobile device, providing a streamlined interface for developers who use GitHub Issues as their primary task management system.

**Core Philosophy**: Industrial Minimalism Redesign - Material Design is used as a base but heavily customized beyond recognition with a monochrome palette and Signal Orange accent color.

**Key Differentiators**:
- Offline-first architecture with local caching using Hive
- Secure storage for GitHub Personal Access Tokens (PAT)
- Minimalist UI focused on functionality over features
- Z-axis spatial depth and spring physics animations
- Designed for developers who find other productivity apps too bloated

## Project Structure

```
gitdoit/
├── android/          # Android platform code
├── ios/              # iOS platform code
├── lib/
│   ├── design_tokens/    # Design system (colors, typography, spacing, etc.)
│   ├── models/           # Data models (Issue, Label, Milestone, User)
│   ├── providers/        # State management (AuthProvider, IssuesProvider)
│   ├── screens/          # UI screens (AuthScreen, HomeScreen, CreateIssueScreen)
│   ├── services/         # GitHub API integration (GitHubService)
│   ├── theme/            # Custom theme system (IndustrialAppTheme)
│   ├── utils/            # Utilities (Logger, helpers)
│   ├── widgets/          # Custom atomic widgets
│   └── main.dart         # Application entry point
├── test/             # Unit tests
├── pubspec.yaml      # Dependencies and package configuration
└── README.md         # Project documentation
```

## Technologies & Dependencies

### Core Stack
- **Flutter**: 3.16+ (Dart 3.2+)
- **GitHub REST API v3**: For issue management
- **Hive**: Local database for offline caching and state persistence
- **Provider**: State management pattern

### Key Dependencies
- `http`: HTTP client for GitHub API requests
- `flutter_secure_storage`: Secure storage for GitHub PAT tokens
- `provider`: State management
- `json_annotation` + `json_serializable`: JSON serialization
- `intl`: Internationalization and date formatting
- `connectivity_plus`: Network connectivity detection
- `flutter_markdown`: Markdown rendering for issue bodies
- `url_launcher`: Opening GitHub links externally

## Architecture Deep Dive

### Authentication System
The app implements a robust authentication flow:
- **AuthProvider**: Manages GitHub PAT token state
- Token stored securely in `flutter_secure_storage`
- Offline-first approach: app works without authentication
- Token validation happens when online
- Automatic retry validation when connection is restored

### GitHub Service Layer
- **GitHubService**: Centralized API client handling all GitHub interactions
- Methods for: fetching issues, creating issues, updating issues, closing/reopening issues
- Error handling with network resilience
- Token permission checking
- Built-in logging for debugging

### State Management
- **IssuesProvider**: Manages issue data state with Hive caching
- Local caching ensures offline functionality
- Filtering and sorting capabilities
- Pull-to-refresh synchronization
- Repository configuration management

### Data Models
- **Issue**: Core model with number, title, body, state, labels, milestone, assignees, timestamps
- **Label**: GitHub label model with name, color, description
- **Milestone**: GitHub milestone model with number, title, state, dates
- **User**: GitHub user model with login, avatar, metadata

### Theme System
- **IndustrialAppTheme**: Custom ThemeData configuration
- Monochrome palette with Signal Orange (#FF5500) as primary accent
- Inter + JetBrains Mono typography pairing
- 8px grid-based spacing system
- Z-axis spatial depth for visual hierarchy
- Spring physics animations for interactive elements

### Design Tokens
Centralized design system with:
- **Colors**: Pure black/white, light/dark grays, Signal Orange family, status colors
- **Typography**: Hierarchical text styles (headline, title, body, label, caption)
- **Spacing**: Consistent padding/margin system based on 8px increments
- **Elevation**: Shadow system for depth perception
- **Animations**: Spring-based transitions for buttons and interactions

## Building and Running

### Prerequisites
- Flutter SDK (3.16+)
- Dart SDK (3.2+)
- Git

### Setup Commands
```bash
# Clone the repository
git clone https://github.com/berlogabob/flutter-github-issues-todo.git
cd flutter-github-issues-todo/gitdoit

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Development Workflow
- **Hot reload**: `flutter run` with hot reload enabled
- **Build APK**: `flutter build apk`
- **Build iOS**: `flutter build ios`
- **Test**: `flutter test`

## Development Conventions

### Code Style
- **Naming**: PascalCase for classes, camelCase for variables/methods
- **Organization**: Feature-based directory structure (models, services, providers, screens)
- **Immutability**: Models use copyWith() methods for immutability
- **Logging**: Comprehensive Logger system with debug/info/warning/error levels
- **Error Handling**: Graceful degradation with offline fallbacks

### Testing Strategy
- Unit tests in `/test` directory
- Mocking for GitHub API calls in tests
- Hive database testing for local caching
- Provider state management tests

### Contribution Guidelines
- Star the repository for visibility
- Report bugs via GitHub issues
- Feature suggestions welcome in discussions
- Pull requests with improvements are encouraged
- Follow the Industrial Minimalism design principles

## Key Features Implemented

1. **Authentication**: Secure PAT token management with offline support
2. **Issue Management**: View, create, edit, close/reopen GitHub issues
3. **Filtering & Sorting**: By status (open/closed), creation/update time
4. **Local Caching**: Hive database for offline operation
5. **Responsive Design**: Works on multiple screen sizes
6. **Custom Theme**: Industrial Minimalism with Signal Orange accent
7. **Markdown Rendering**: For issue body content
8. **Connectivity Awareness**: Auto-detects online/offline states

## Planned Features (from README)
- Kanban board by labels
- Calendar sync
- Notifications
- Enhanced offline capabilities

## Offline-First Architecture

The app is designed with offline-first principles:
- **Local Storage**: Hive database caches issues locally
- **Token Persistence**: PAT tokens stored securely even when offline
- **Graceful Degradation**: App remains functional without internet
- **Sync Strategy**: Changes queued and synchronized when connection restored
- **State Management**: Clear distinction between online/offline states

## Security Considerations

- **Token Storage**: GitHub PAT tokens stored in `flutter_secure_storage`
- **Network Security**: HTTPS for all GitHub API calls
- **Data Validation**: Input validation for issue creation/editing
- **Error Handling**: Prevents sensitive information leakage in error messages

## Project Status

The project appears to be in active development with a clear roadmap focused on minimalism and offline functionality. The architecture is well-structured with separation of concerns across layers (models, services, providers, UI).

The app targets developers who use GitHub Issues as their primary TODO system and want a lightweight, mobile-friendly alternative to more feature-rich productivity applications.