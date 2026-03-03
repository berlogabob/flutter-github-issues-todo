# GitDoIt

Minimalist GitHub Issues & Projects TODO Manager with offline-first support.

## Features

- **Issue Management**: Create, edit, and manage GitHub issues with full Markdown support
- **Project Integration**: Manage GitHub Projects V2 with drag-and-drop functionality
- **Offline-First**: Work offline with automatic sync when connection is restored
- **Real-time Sync**: Pending operations queue for seamless offline-to-online transition
- **Search**: Global search across all repositories with advanced filtering
- **Repository Management**: Browse and manage multiple GitHub repositories
- **Pagination**: Load repos/issues in batches (30 items per page) for better performance
- **Image Caching**: Avatars cached locally with 10MB disk cache for offline viewing
- **Background Sync**: Automatic sync every 15 minutes on WiFi connection
- **Optimized Lists**: 60 FPS scrolling even with 1000+ items using ListView.builder and RepaintBoundary
- **Loading Skeletons**: Smooth loading experience with shimmer skeleton screens
- **Comments**: View and delete your issue comments with Markdown rendering
- **Empty States**: Beautiful custom illustrations for empty states (5 designs)
- **Tutorial**: First-time user onboarding with 5-step interactive guide
- **🧪 Comprehensive Tests** - 290+ automated tests
- **🔒 Error Recovery** - Graceful error handling with retry
- **📊 Performance Benchmarks** - Documented performance baselines
- **📝 Error Logging** - Local error logging for debugging

### Pickers & Filters

- **Assignee Picker**: Real GitHub API integration for selecting issue assignees with avatar display and 5-minute caching
- **Label Picker**: Repository labels with color coding, showing current and available labels
- **Project Picker**: Select default project from your GitHub Projects V2 in settings
- **My Issues Filter**: Filter issues assigned to you using actual GitHub authentication

### User Experience

- **Haptic Feedback**: Tactile feedback for swipe actions, button taps, and navigation
- **Responsive Design**: Adapts to different screen sizes using ScreenUtil
- **Dark Theme**: Optimized dark mode UI with custom color palette
- **Loading States**: Braille loader animations for smooth loading indicators

## Getting Started

### Prerequisites

- Flutter SDK >= 3.11.0
- GitHub Personal Access Token with `repo` scope

### Installation

1. Clone the repository
2. Run `flutter pub get`
3. Configure your GitHub token in settings

### Configuration

1. Open the app
2. Navigate to Settings
3. Enter your GitHub Personal Access Token
4. Set default repository and project

## Project Structure

```
lib/
├── constants/       # App-wide constants (colors, styles)
├── models/          # Data models (IssueItem, RepoItem, etc.)
├── screens/         # UI screens
├── services/        # Business logic and API services
├── utils/           # Utility functions and helpers
└── widgets/         # Reusable UI components
```

## Key Services

- **GitHubApiService**: REST and GraphQL API integration with retry logic
- **CacheService**: In-memory caching with TTL support
- **LocalStorageService**: Persistent local storage for settings and user data
- **PendingOperationsService**: Offline operation queuing
- **NetworkService**: Connectivity monitoring

## Dependencies

- **State Management**: flutter_riverpod, riverpod
- **Local Storage**: hive, hive_flutter
- **Network**: http, graphql_flutter
- **Secure Storage**: flutter_secure_storage
- **Markdown**: flutter_markdown_plus
- **UI**: flutter_screenutil, flutter_svg

## Version

Current version: 0.5.0+70

## License

See LICENSE file for details.

---

Built with ❤️ using Flutter and the GitHub API
