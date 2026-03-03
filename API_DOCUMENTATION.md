# API Documentation - Sprint 15

This document provides API documentation for new features and methods added in Sprint 15.

---

## Table of Contents

1. [GitHubApiService - New Methods](#githubapiservice---new-methods)
2. [IssueDetailScreen - New Methods](#issuedetailscreen---new-methods)
3. [SearchScreen - New Methods](#searchscreen---new-methods)
4. [SettingsScreen - New Methods](#settingsscreen---new-methods)
5. [IssueCard - Haptic Feedback](#issuecard---haptic-feedback)
6. [Data Models](#data-models)

---

## GitHubApiService - New Methods

### `fetchRepoCollaborators`

Fetches collaborators (assignees) for a repository.

**Signature:**
```dart
Future<List<Map<String, dynamic>>> fetchRepoCollaborators(
  String owner,
  String repo,
)
```

**Parameters:**
- `owner` (String): The repository owner's login
- `repo` (String): The repository name

**Returns:** `List<Map<String, dynamic>>` - List of collaborator objects containing:
  - `login`: User login name
  - `id`: User ID
  - `avatar_url`: Avatar image URL
  - `html_url`: GitHub profile URL
  - `type`: User type (e.g., "User")

**API Endpoint:** `GET /repos/{owner}/{repo}/collaborators`

**Example:**
```dart
final collaborators = await githubApi.fetchRepoCollaborators('flutter', 'flutter');
for (final collaborator in collaborators) {
  print('${collaborator['login']}: ${collaborator['avatar_url']}');
}
```

**Throws:** `Exception` if the request fails or returns a non-200 status code.

---

### `fetchRepoLabels`

Fetches available labels for a repository.

**Signature:**
```dart
Future<List<Map<String, dynamic>>> fetchRepoLabels(
  String owner,
  String repo,
)
```

**Parameters:**
- `owner` (String): The repository owner's login
- `repo` (String): The repository name

**Returns:** `List<Map<String, dynamic>>` - List of label objects containing:
  - `id`: Label ID
  - `name`: Label name
  - `color`: Hex color code (6 characters, e.g., "0075ca")
  - `description`: Label description (optional)
  - `url`: API URL for the label

**API Endpoint:** `GET /repos/{owner}/{repo}/labels`

**Example:**
```dart
final labels = await githubApi.fetchRepoLabels('flutter', 'flutter');
for (final label in labels) {
  print('${label['name']}: #${label['color']}');
}
```

**Throws:** `Exception` if the request fails or returns a non-200 status code.

---

### `getCurrentUser`

Fetches current authenticated user's information.

**Signature:**
```dart
Future<Map<String, dynamic>?> getCurrentUser()
```

**Returns:** `Map<String, dynamic>?` - User data map containing:
  - `login`: GitHub username
  - `id`: User ID
  - `name`: Display name (optional)
  - `avatar_url`: Avatar image URL
  - `email`: Email address (if public)
  - `html_url`: GitHub profile URL

**API Endpoint:** `GET /user`

**Example:**
```dart
final user = await githubApi.getCurrentUser();
if (user != null) {
  print('Logged in as: ${user['login']}');
}
```

**Returns:** `null` if the request fails or user data cannot be retrieved.

---

### `fetchProjects`

Fetches current user's Projects V2 using GraphQL.

**Signature:**
```dart
Future<List<Map<String, dynamic>>> fetchProjects({int first = 30})
```

**Parameters:**
- `first` (int): Maximum number of projects to fetch (default: 30)

**Returns:** `List<Map<String, dynamic>>` - List of project objects containing:
  - `id`: Project node ID (for GraphQL operations)
  - `title`: Project title
  - `shortDescription`: Project description
  - `url`: GitHub URL for the project
  - `closed`: Whether the project is closed
  - `createdAt`: Project creation timestamp
  - `updatedAt`: Last update timestamp

**API Endpoint:** `POST /graphql` (GraphQL query)

**GraphQL Query:**
```graphql
query GetUserProjects($first: Int!) {
  viewer {
    projectsV2(first: $first) {
      nodes {
        id
        title
        shortDescription
        url
        closed
        createdAt
        updatedAt
      }
    }
  }
}
```

**Example:**
```dart
final projects = await githubApi.fetchProjects(first: 30);
for (final project in projects) {
  print('${project['title']}: ${project['url']}');
}
```

**Returns:** Empty list if the request fails or GraphQL errors occur.

**Caching:** Results cached for 5 minutes.

---

### `updateIssue`

Updates an issue's properties (close/reopen/edit/assignee/labels).

**Signature:**
```dart
Future<IssueItem> updateIssue(
  String owner,
  String repo,
  int number, {
  String? title,
  String? body,
  String? state,
  List<String>? labels,
  List<String>? assignees,
})
```

**Parameters:**
- `owner` (String): Repository owner's login
- `repo` (String): Repository name
- `number` (int): Issue number
- `title` (String?, optional): New title
- `body` (String?, optional): New description
- `state` (String?, optional): New state ('open' or 'closed')
- `labels` (List<String>?, optional): New labels list (replaces existing)
- `assignees` (List<String>?, optional): New assignees list (replaces existing)

**Returns:** `IssueItem` - The updated issue

**API Endpoint:** `PATCH /repos/{owner}/{repo}/issues/{issue_number}`

**Example:**
```dart
// Update assignee
final updated = await githubApi.updateIssue(
  'flutter',
  'flutter',
  123,
  assignees: ['user1', 'user2'],
);
```

**Throws:** `Exception` if the request fails.

---

### `addIssueLabel`

Adds a label to an issue.

**Signature:**
```dart
Future<IssueItem> addIssueLabel(
  String owner,
  String repo,
  int issueNumber,
  String label,
)
```

**Parameters:**
- `owner` (String): Repository owner's login
- `repo` (String): Repository name
- `issueNumber` (int): Issue number
- `label` (String): Label name to add

**Returns:** `IssueItem` - The updated issue with the label added

**API Endpoints:**
- `POST /repos/{owner}/{repo}/issues/{issue_number}/labels`
- `GET /repos/{owner}/{repo}/issues/{issue_number}` (to fetch updated issue)

**Example:**
```dart
final updatedIssue = await githubApi.addIssueLabel(
  'flutter',
  'flutter',
  123,
  'enhancement',
);
```

**Throws:** `Exception` if the request fails.

---

### `removeIssueLabel`

Removes a label from an issue.

**Signature:**
```dart
Future<IssueItem> removeIssueLabel(
  String owner,
  String repo,
  int issueNumber,
  String label,
)
```

**Parameters:**
- `owner` (String): Repository owner's login
- `repo` (String): Repository name
- `issueNumber` (int): Issue number
- `label` (String): Label name to remove

**Returns:** `IssueItem` - The updated issue with the label removed

**API Endpoints:**
- `DELETE /repos/{owner}/{repo}/issues/{issue_number}/labels/{name}`
- `GET /repos/{owner}/{repo}/issues/{issue_number}` (to fetch updated issue)

**Example:**
```dart
final updatedIssue = await githubApi.removeIssueLabel(
  'flutter',
  'flutter',
  123,
  'bug',
);
```

**Throws:** `Exception` if the request fails.

---

## IssueDetailScreen - New Methods

### `_loadAssignees`

Loads and caches assignees for the current repository.

**Signature:**
```dart
Future<void> _loadAssignees()
```

**Behavior:**
1. Checks cache first (5-minute TTL)
2. Falls back to network request if cache miss
3. Handles offline mode gracefully
4. Caches results for 5 minutes

**State Updates:**
- `_assignees`: List of collaborator objects
- `_isLoadingAssignees`: Loading state flag

---

### `_showAssigneeDialog`

Displays the assignee picker dialog.

**Signature:**
```dart
Future<void> _showAssigneeDialog()
```

**Features:**
- Fetches assignees from GitHub API via `fetchRepoCollaborators()`
- Shows list of assignees with avatars in a DraggableScrollableSheet
- Displays checkmark for currently assigned user
- Added haptic feedback with `HapticFeedback.selectionClick()`

---

### `_setAssignee`

Sets the assignee for the current issue.

**Signature:**
```dart
Future<void> _setAssignee(String login)
```

**Parameters:**
- `login` (String): The assignee's login name

**Behavior:**
- Handles local issues (state update only)
- Queues operations when offline via `PendingOperationsService`
- Updates immediately when online via `GitHubApiService.updateIssue()`
- Shows appropriate snackbars for feedback

---

### `_loadLabels`

Loads and caches labels for the current repository.

**Signature:**
```dart
Future<void> _loadLabels()
```

**Behavior:**
1. Checks cache first (5-minute TTL)
2. Falls back to network request if cache miss
3. Handles offline mode gracefully
4. Caches results for 5 minutes

**State Updates:**
- `_labels`: List of label objects
- `_isLoadingLabels`: Loading state flag

---

### `_showLabelsDialog`

Displays the label picker dialog.

**Signature:**
```dart
Future<void> _showLabelsDialog()
```

**Features:**
- Fetches labels from GitHub API via `fetchRepoLabels()`
- Shows current labels in a "Current Labels" section with remove capability
- Shows available repo labels in "Available Labels" section with checkboxes
- Displays label colors using hex color parsing
- Added haptic feedback with `HapticFeedback.selectionClick()`

---

### `_addLabel`

Adds a label to the current issue.

**Signature:**
```dart
Future<void> _addLabel(String labelName)
```

**Parameters:**
- `labelName` (String): The label name to add

**Behavior:**
- Handles local issues (state update only)
- Queues operations when offline via `PendingOperationsService`
- Updates immediately when online via `GitHubApiService.addIssueLabel()`

---

## SearchScreen - New Methods

### `_loadUserLogin`

Loads current user login from cache or GitHub API.

**Signature:**
```dart
Future<void> _loadUserLogin()
```

**Behavior:**
1. Checks cache first (1-hour TTL)
2. Tries local storage first (faster)
3. Fetches from GitHub API if not cached
4. Saves to both local storage and cache

**State Updates:**
- `_cachedUserLogin`: Cached user login string
- `_isLoadingUserLogin`: Loading state flag

**Usage in Filter:**
```dart
if (_filterMyIssues) {
  final currentLogin = _cachedUserLogin;
  if (currentLogin == null) {
    return true; // Skip filter if not loaded
  }
  if (issue.assigneeLogin != currentLogin) return false;
}
```

---

## SettingsScreen - New Methods

### `_loadDefaultProject`

Loads saved default project from local storage.

**Signature:**
```dart
Future<void> _loadDefaultProject()
```

**Behavior:**
- Loads from `LocalStorageService.getDefaultProject()`
- Updates `_defaultProject` state variable

---

### `_loadProjects`

Loads projects from GitHub API.

**Signature:**
```dart
Future<void> _loadProjects()
```

**Behavior:**
- Fetches projects from GitHub API via `fetchProjects()`
- Handles loading state
- Error handling with `AppErrorHandler`

**State Updates:**
- `_projects`: List of project objects
- `_isLoadingProjects`: Loading state flag

---

### `_changeDefaultProject`

Shows project picker dialog and saves selection.

**Signature:**
```dart
Future<void> _changeDefaultProject()
```

**Features:**
- Shows project picker dialog
- Displays projects in selectable ListView
- Shows checkmark for selected project
- Displays closed projects with strikethrough and disabled appearance
- Saves selection to `LocalStorageService.saveDefaultProject()`
- Shows confirmation snackbar

---

## IssueCard - Haptic Feedback

### Swipe Actions

Haptic feedback added to `confirmDismiss`:

```dart
confirmDismiss: (direction) async {
  // Trigger haptic feedback on swipe
  HapticFeedback.lightImpact();
  // ... rest of logic
}
```

### Card Tap

Haptic feedback added to `onTap`:

```dart
onTap: () {
  // Trigger haptic feedback on tap
  HapticFeedback.lightImpact();
  onTap?.call(issue);
}
```

---

## MainDashboardScreen - Haptic Feedback

Haptic feedback added to navigation and action methods:

```dart
// Navigation
HapticFeedback.selectionClick(); // _navigateToSearch()
HapticFeedback.selectionClick(); // _navigateToRepoLibrary()
HapticFeedback.selectionClick(); // _navigateToSettings()

// Actions
HapticFeedback.selectionClick(); // _createNewIssue()
HapticFeedback.lightImpact();    // _togglePinRepo()
HapticFeedback.selectionClick(); // _openIssueDetail()
```

---

## Data Models

### Assignee Object

```dart
{
  'login': String,      // GitHub username
  'id': int,            // User ID
  'avatar_url': String, // Avatar URL
  'html_url': String,   // Profile URL
  'type': String,       // "User" or "Organization"
}
```

### Label Object

```dart
{
  'id': int,            // Label ID
  'name': String,       // Label name
  'color': String,      // Hex color (6 chars, no #)
  'description': String?, // Optional description
  'url': String,        // API URL
}
```

### Project Object

```dart
{
  'id': String,              // GraphQL node ID
  'title': String,           // Project title
  'shortDescription': String?, // Description
  'url': String,             // GitHub URL
  'closed': bool,            // Closed status
  'createdAt': DateTime,     // Creation timestamp
  'updatedAt': DateTime,     // Last update timestamp
}
```

---

## Caching Strategy

| Data Type | Cache Key | TTL | Storage |
|-----------|-----------|-----|---------|
| Assignees | `collaborators_{owner}_{repo}` | 5 min | Memory |
| Labels | `labels_{owner}_{repo}` | 5 min | Memory |
| User Login | `current_user_login` | 1 hour | Memory + Local |
| Projects | `projects_{first}` | 5 min | Memory |

---

## Error Handling

All API methods use `AppErrorHandler` for consistent error handling:

```dart
try {
  // API call
} catch (e, stackTrace) {
  AppErrorHandler.handle(e, stackTrace: stackTrace);
  rethrow;
}
```

Network errors are caught and return user-friendly messages.

---

**Document Version:** 1.0
**Last Updated:** March 2, 2026
**Sprint:** 15
