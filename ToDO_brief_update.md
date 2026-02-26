ToDO_brief_update.md
# GitDoIt: Unified Design and Development Brief

## Project Overview

### Project Title
GitDoIt – Minimalist GitHub Issues & Projects TODO Manager.

### Description
GitDoIt is a cross-platform mobile app built with pure Flutter (no platform dependencies), transforming GitHub issues and Projects (v2) into a simple, efficient task manager. It emphasizes offline-first functionality, allowing users to create, manage, and sync tasks without constant internet. The app resolves user pain points: information overload in lists, navigation complexity, unreliable connectivity, and lack of project integration.

Design philosophy: Clean, laconic, visually pure minimalism inspired by Teenage Engineering (raw functional beauty), Nothing (transparent logic with bold accents), Notion (modular, airy structure), and Revolut (confident precision). Strictly monochromatic (dark mode only) with orange accents for actions. Focus on modularity: reusable widgets for hierarchies (repos → issues → sub-tasks → projects).

Key principles:
- Offline-first: Local storage (Hive) for all data; sync on demand/auto when online.
- GitHub integration: REST for issues, GraphQL for Projects v2; auth via PAT or OAuth (browser-based).
- Modularity: Unified `ExpandableItem` widget for repos, issues, projects – recursive, compact/expanded states.
- User research integration: Based on GitHub reviews, social media (X/Twitter, Reddit), forums (Stack Overflow), and best practices – prioritize quick scanning in compact views; detailed info on separate screens.

Target audience: Developers, project managers, individual GitHub users.

Tech stack:
- Flutter/Dart.
- State: Riverpod.
- Storage: Hive.
- API: http (REST), graphql_flutter (GraphQL).
- Auth: flutter_secure_storage, url_launcher (OAuth).
- Other: markdown_widget, reorderables.

Project structure (high-level):
- `lib/main.dart`: App entry.
- `models/`: Item.dart (abstract), RepoItem.dart, IssueItem.dart, ProjectItem.dart.
- `services/`: GitHubRestService.dart, GitHubGraphQLService.dart, AuthService.dart, StorageService.dart, SyncService.dart.
- `widgets/`: ExpandableItem.dart, LabelChip.dart, StatusDot.dart, ConnectorLine.dart, FilterWidget.dart, AppBarWidget.dart.
- `screens/`: OnboardingScreen.dart, MainScreen.dart, IssueDetailScreen.dart, ProjectDetailScreen.dart, RepoManagerScreen.dart, SearchScreen.dart, SettingsScreen.dart.
- `providers/`: reposProvider.dart, issuesProvider.dart, projectsProvider.dart, authProvider.dart, syncProvider.dart.
- `utils/`: relativeTime.dart, conflictResolver.dart.

## Visual Style Guide (Mono Orange Minimalism)

### Philosophy
Clean. Confident. Premium-minimal. The interface breathes with spaciousness, feels expensive and modern – like Teenage Engineering's industrial restraint meets Nothing's bold accents, Notion's clarity, and Revolut's precision.

### Color Palette
- True Black base: #000000 / #0A0A0A / #111111.
- Surfaces/cards: #121212 → #1A1A1A.
- Primary text: #F5F5F5 / #EDEDED.
- Secondary text: #8A8A8F → #A0A0A5.
- Brand accent (orange): #FF5E00 (or #FF6B1A) – used sparingly for CTAs, active states, badges.
- Error: #FF2D55 (rare).
- No gradients, textures, or multi-colors.

### Typography
- Font: Inter / Neue Haas Grotesk (fallback: SF Pro).
- Weights: Regular/Medium (body), SemiBold/Bold (headings).
- Scale: 4pt grid (4, 8, 12, 16, 20, 24, 32, 40, 48 px).
- Line height: 1.32–1.45.
- Alignment: Left (default).

### UI Elements
- Padding: 24–48 px for airiness.
- Borders: 1px #222–#333; corners 12–16 px (cards/buttons), 20–24 px (panels).
- Icons: 1.5–2 px lines, outline (monochrome; orange on active).
- Animations: Short (120–180 ms), smooth (cubic-bezier 0.4 0 0.2 1).
- Accessibility: WCAG AA+, large touch targets (48x48 px min).
- Avoid: Illustrations, neons, excessive motion.

### Research Summary on Issue Display
From user reviews (GitHub discussions, X/Twitter, Reddit r/github, Stack Overflow, Medium articles on GitHub as TODO):
- **Compact View (in lists/widgets)**: Quick scan focus – minimal text, visual indicators. Must show: #number, truncated title (1 line with …), status (● green #238636 open / ✓ gray #6e7781 closed), 1–2 labels (colored, e.g., bug red), relative time (2h/5d), optional @assignee (highlight if @you). Examples: "#187 Fix login… bug high ● open 2h" or minimal "#187 …crash on iOS ● 2h". Users complain about overload; praise visual triage.
- **Expanded/Detail View**: Not inline – tap compact item → full separate screen. Expect: Full title/number/status, markdown description (steps to reproduce), all labels, assignee/watchers/milestone, timeline, comments/reactions, actions (close/assign/label). Output: Compact for scrolling/triage; detail screen to avoid clutter (standard in GitHub Mobile, ZenHub).

## Data Model
Abstract `Item` for unification:
```dart
abstract class Item {
  String id; // repo slug or issue number
  String title;
  String? subtitle; // labels for issues
  ItemStatus status; // open/closed
  DateTime updatedAt;
  String? assignee;
  List<String> labels;
  List<Item> children; // issues for repo, sub-tasks for issue
  bool isExpanded = false;
  String? projectStatus; // for Projects v2
  String? projectItemId;
}

enum ItemStatus { open, closed }

class RepoItem extends Item { /* slug */ }
class IssueItem extends Item { /* number, description, comments */ }
class ProjectItem extends Item { /* fields, columns */ }
```
- Storage: Hive boxes ('repos', 'issues', 'projects').
- Sync: Local priority; resolve conflicts via timestamps.

## Detailed Screens

All screens use dark mode, orange accents, spacious layout. AppBar: Title 'GitDoIt', icons (sync: gray offline/blue syncing/green online, search, bookmark for repos, settings). FAB: + New Issue (orange).

### 1. Onboarding Screen
- **Appearance**: Full-screen black background, centered logo (orange glyph on black), subtitle "Welcome to GitDoIt – GitHub TODO Simplified". Two buttons: "Login with GitHub" (orange, primary), "Continue Offline" (gray). Optional token input field (masked) if PAT selected. How-it-works cards (3–4 minimal text blocks with icons).
- **Elements**: No clutter; large padding (40 px). Animations: Fade-in buttons.
- **Behavior**: First launch only. Skip if data exists.

### 2. Main Dashboard Screen
- **Appearance**: Scaffold with AppBar. Body: Column – FilterWidget (chips: Open/Closed/All + project dropdown), scrollable ListView of ExpandableItem widgets. Top: Default local TODO repo (fixed, non-collapsible). Below: User-selected repos/projects (accordion-style). Empty state: "No repos – add one!" with illustration (minimal line art).
- **Widget Structure**:
  - Collapsed: "owner/repo >" + "o 12 x 43 w 12 p 23" (o=open count; x/w/p=tag placeholders, hide if not implemented).
  - Expanded: Header "^" + list of compact issues: "#187 Fix login… bug high ● open 2h @you".
- **Elements**: Pull-to-refresh for sync. Horizontal scroll if needed. Orange badges for counts.
- **Behavior**: Tap header → expand/collapse. Tap issue → Issue Detail. Infinite pagination.

### 3. Issue Detail Screen
- **Appearance**: Full title/number/status at top (orange status dot). Scrollable column: Markdown description, full labels (chips), assignee (avatar/text), timeline (list of changes), comments (tiles with reactions), attachments (images/logs). Bottom actions: Edit (orange), Close/Reopen, Assign, Label (dropdowns).
- **Elements**: Orange accents on buttons. Timeline: Gray dividers, relative times.
- **Behavior**: Back button returns to Main. Edit → modal form.

### 4. Project Detail Screen
- **Appearance**: Board view: Horizontal scrollable Row of columns (from Status field, e.g., Todo/In Progress/Done). Each column: Vertical ListView of compact issue cards (draggable via ReorderableListView). Top: Project name, filters (by field). Actions: + Add Item (orange FAB).
- **Elements**: Columns as cards (#1A1A1A bg), items with orange drag handles. Custom fields (priority/estimate) as badges.
- **Behavior**: Drag item → update status via GraphQL mutation. Tap item → Issue Detail.

### 5. Repo/Project Manager Screen (Selection Screen)
- **Appearance**: ListView of user's GitHub repos/projects (fetched via API). Each row: Repo name, description (truncated), circle icon: ○ (unchecked), ● (newly selected), ✓ (previously added, bold). Bottom: "Add Selected" button (orange).
- **Elements**: Search bar at top. Checkmarks orange on select.
- **Behavior**: Tap row → toggle selection. "Add" → adds to Main Dashboard below default.

### 6. Search Screen
- **Appearance**: Top search field (full-width, orange cursor). Results: Expandable list of matching items (across repos/projects).
- **Elements**: Instant filtering by title/labels/fields. No results: "Nothing found – try broader terms."
- **Behavior**: Accessed via AppBar icon. Results use same compact format.

### 7. Settings Screen
- **Appearance**: List sections: Account (Login/Logout, Token Manage), Repos/Projects (select default), Appearance (theme toggle – future), Data (Clear Cache, Offline Storage). Danger zone: Logout (red accent).
- **Elements**: Switches/sliders orange. Dividers #333.
- **Behavior**: Direct actions; confirm dialogs for destructive.

## User Journeys

### 1. First Launch (Onboarding)
- Open app → Onboarding: "GitHub Login" (tap) → Browser opens for OAuth (authorize, enter code) → Token saved → Auto-fetch default repo/project → Main Dashboard.
- Alternative: "Offline" (tap) → Create local repo (name input + confirm) → Main Dashboard with default local TODO.

### 2. Daily Use (Task Management)
- Open app → Auto-sync if online (green icon) → Main Dashboard: Filter 'Open' (default) → Scroll repos (expand one) → See compact issues.
- View issue: Tap item → Issue Detail (read desc/comments) → Back.
- Create issue: FAB + (tap) → Modal: Title (required), desc/labels/assignee/project/column → Create → Auto-add to list/sync.
- Edit: In Detail, tap Edit → Update fields → Save/sync.
- Project workflow: From Main, select project filter → Tap project → Project Detail → Drag item to column → Auto-mutation.

### 3. Repo/Project Management
- From Main prompt or AppBar bookmark → Repo Manager: "Fetch My" (tap) → List appears → Tap rows to select (○ → ●/✓) → "Add" → Back to Main (new widgets below default).

### 4. Search and Advanced
- AppBar search (tap) → Search Screen: Type query → Results appear → Tap result → Detail.
- Settings: AppBar gear (tap) → Adjust (e.g., logout: confirm → Onboarding).

### 5. Offline/Sync Scenarios
- Offline: Gray sync icon, use cached data ("Last sync: 15 min ago").
- Online: Tap refresh → Pull/push changes. Conflicts: Prompt user (local vs. remote).

### 6. Advanced (Projects Integration)
- Add token with project scope → Settings: Select project → Main: Filter by project → View board in Project Detail → Add/move items.

This document unifies all provided briefs/research. For wireframes, use Figma; test on devices for adaptability. Next: Implementation roadmap or refinements?