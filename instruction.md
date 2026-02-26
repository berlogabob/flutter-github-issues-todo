# Project Brief: Development of GitDoIt - GitHub Issues & Projects TODO Manager App

## 1. Project Overview

### 1.1 Project Title
GitDoIt: A Minimalist GitHub Issues & Projects TODO Tool.

### 1.2 Project Description
GitDoIt - это кросс-платформенное мобильное приложение на Flutter, которое превращает GitHub issues и Projects (v2) в простой и эффективный менеджер задач. Приложение фокусируется на offline-first подходе, позволяя создавать, управлять и синхронизировать задачи без постоянного интернета. Оно сочетает мощь GitHub с минималистичным интерфейсом TODO, решая проблемы пользователей: перегрузку информацией, сложную навигацию, ненадежную связь и отсутствие интеграции с проектами.

Дизайн вдохновлен Notion (блочная структура, expandable элементы) и Teenage Engineering (функциональный минимализм, тактильные акценты как стрелки и коннекторы). Тема: темная с оранжевыми акцентами для действий. Поддержка локального хранения для оффлайн, синхронизация с GitHub через персональный токен (PAT) или современный OAuth (Device Flow или Web Auth via браузер).

Бриф основан на предоставленных макетах, отзывах пользователей, лучших практиках GitHub как TODO, минималистичном дизайне Flutter и интеграции с GitHub API (REST для issues, GraphQL для Projects). Дата брифа: 24 февраля 2026 года (учитывая актуальные стандарты API на эту дату, такие как GraphQL для Projects v2).

### 1.3 Objectives
- Обеспечить seamless TODO с GitHub issues и Projects, с оффлайн-поддержкой.
- Реализовать модульный код с переиспользованием (унифицированные виджеты для иерархии).
- Решить "боли": быстрый triage, интеграция с досками Projects, минималистичный UX с минимумом кликов.
- Поддержка аутентификации: PAT для простоты, OAuth для безопасности и удобства (без ввода токена вручную).
- Целевая аудитория: разработчики, менеджеры проектов, индивидуальные пользователи GitHub.

### 1.4 Key Features Summary
- Оффлайн-first: Локальное создание/редактирование задач.
- GitHub Sync: Issues и Projects via REST/GraphQL.
- Модульные виджеты: Expandable для repos/issues/sub-tasks/projects.
- Фильтры, поиск, управление: Open/closed/all, библиотека репозиториев/projects.
- Аутентификация: PAT или OAuth (browser-based).
- Projects: Просмотр/управление досками, перемещение задач по колонкам.

## 2. Functional Requirements

### 2.1 Authentication
- **Персональный токен (PAT)**: Ввод в поле (маскированный), хранение в secure storage (Flutter Secure Storage). Scopes: repo, issues, project (read/write).
- **OAuth (современный подход)**: Использовать Device Flow (рекомендовано GitHub для мобильных apps без web-сервера). Процесс:
  - Пользователь нажимает "Login with GitHub".
  - App запрашивает device code via GitHub API (/login/device/code).
  - Открывает браузер (url_launcher) с verification URI.
  - Пользователь авторизуется в браузере, вводит user code.
  - App поллингит /login/device/poll для access token.
  - Token хранится securely, refresh automatically.
- Логика: Если токен истек, auto-refresh или re-auth. Logout: Удалить токен, очистить кэш.

### 2.2 Core Functionality
- **Offline Mode**: Полная работа без сети; данные в Hive. Sync при подключении.
- **GitHub Integration**:
  - REST для issues: List/create/update/close/assign/labels.
  - GraphQL для Projects v2: List projects, items, fields (Status, custom), mutations (add item, update field like column move).
- **Local TODO**: "Локальные репозитории/projects" для оффлайн; моделировать как GitHub entities.
- **Sync**: Manual (кнопка refresh), auto (on start/online). Handle conflicts (local priority).
- **Issue Management**:
  - Create: Title, desc, labels, assignee, sub-tasks (checklists or child issues).
  - View: Compact (#num Title... labels status time @assignee); tap → detail screen.
  - Edit: Title/body/state/labels/assignees.
- **Projects Management**:
  - List projects (user/org/repo level).
  - View board: Columns (from Status field), items in columns.
  - Add issue to project/column.
  - Move item: Update Status field via mutation.
  - Custom fields: Display/edit (e.g., Priority, Estimate).
- **Repo/Projects Library**: Add by URL/ID, set default, remove.
- **Filters**: Open/Closed/All + by Project/Column/Custom Field.
- **Search**: Global по title/labels/fields.

### 2.3 Screens
- **Onboarding Screen**:
  - Logo, name, subtitle.
  - Buttons: "GitHub Login" (OAuth/PAT toggle), "Continue Offline".
  - How It Works cards.
  - Token input if PAT chosen.

- **Main Dashboard**:
  - AppBar: Title, sync icon (green/gray/red), + Add (issue/project), Search, Refresh, Settings.
  - Filters: Chips for status + dropdown for Projects.
  - List: Expandable repos/projects → issues/items.
  - If empty: "No Repo/Project", prompt add.
  - FAB: + New Issue.

- **Create/Edit Issue Modal**:
  - Fields: Title, Desc, Labels, Assignee, Add to Project/Column.
  - Buttons: Cancel/Create.

- **Issue Detail Screen**:
  - Full details: Title, desc (Markdown), labels, assignee, timeline, comments.
  - Actions: Edit, Close, Assign, Move Column (if in project).

- **Project Detail Screen** (new):
  - Board view: Horizontal scrollable columns (ListViews in Row).
  - Items: Compact cards, draggable (ReorderableListView) for move.
  - Actions: Add Item, Edit Fields.

- **Repo/Project Manager Screen**:
  - List connected entities.
  - Add by URL/ID, Fetch My (API), Set Default.

- **Search Screen**:
  - Input, results as expandable list.

- **Settings Screen**:
  - Account: Login/Logout, Token Manage.
  - Repository/Projects: Default select.
  - Appearance: Theme (coming soon).
  - Data: Offline Storage, Clear Cache.
  - Danger: Logout.

### 2.4 Data Model
- `Item` (abstract): id, title, status, updatedAt, assignee, labels, children, projectStatus, projectItemId.
- `RepoItem`, `IssueItem`, `ProjectItem` (extends Item: fields, columns).

## 3. Non-Functional Requirements

### 3.1 Performance
- Оффлайн: Instant from Hive.
- Sync: Background, batch queries.
- UI: Smooth drag-and-drop, no lag on 1000+ items.

### 3.2 Security
- Tokens: Secure Storage.
- Data: Encrypted local, no unnecessary API calls.

### 3.3 Usability
- Минимализм: Dark theme, orange actions.
- Accessibility: ARIA labels, contrast.
- Cross-Platform: Android/iOS.

## 4. Design and UI/UX Guidelines

### 4.1 Visual Style
- Colors: Dark gray, orange accents, red danger.
- Typography: Sans-serif, light secondary.
- Icons: Material with custom.

### 4.2 UX Principles
- Минимум кликов: Auto-sync, contextual actions (e.g., swipe to move column), predictive search.

## 5. Technical Architecture

### 5.1 Tech Stack
- Flutter: Pure Dart.
- State: Riverpod.
- Storage: Hive.
- API: http for REST, graphql_flutter for GraphQL.
- Auth: url_launcher for OAuth, flutter_secure_storage.
- Markdown: markdown_widget.
- Drag: reorderables.

### 5.2 Project Structure
- **lib/**
  - **main.dart**: Entry point, app init (Hive, Riverpod).
  - **models/**: Item.dart, RepoItem.dart, IssueItem.dart, ProjectItem.dart.
  - **services/**: GitHubRestService.dart (issues), GitHubGraphQLService.dart (projects), AuthService.dart (PAT/OAuth), StorageService.dart (Hive), SyncService.dart.
  - **widgets/**: ExpandableItem.dart (reusable), LabelChip.dart, StatusDot.dart, ConnectorLine.dart, FilterWidget.dart, AppBarWidget.dart.
  - **screens/**: OnboardingScreen.dart, MainScreen.dart, IssueDetailScreen.dart, ProjectDetailScreen.dart, RepoManagerScreen.dart, SettingsScreen.dart, SearchScreen.dart.
  - **providers/**: reposProvider.dart, issuesProvider.dart, projectsProvider.dart, authProvider.dart, syncProvider.dart.
  - **utils/**: relativeTime.dart, conflictResolver.dart.
- **assets/**: Icons, logo.
- **test/**: Unit (widgets), Integration (journeys).
- **pubspec.yaml**: Dependencies (flutter_secure_storage, graphql_flutter, url_launcher, hive, riverpod, etc.).

## 6. User Journeys (с минимумом лишних кликов)

### 6.1 First Launch
1. Open app → Onboarding: "GitHub Login" (1 клик) → Browser opens for OAuth (авторизация в 2-3 шага) → Back to app, token saved → Auto-fetch default repo/project → Dashboard.
   - Альтернатива: "Offline" (1 клик) → Create local repo (1 input + confirm).

### 6.2 Daily Use
1. Open app → Auto-sync if online → Dashboard: Filtered list (default Open).
2. View issue: Tap item (1 клик) → Detail screen.
3. Create issue: FAB + (1 клик) → Modal, fill title (required), optional desc/project/column → Create (1 клик) → Auto-add to list/sync.
4. Move in project: In detail, select column from dropdown (1 клик) → Auto-mutation/sync.
5. Add repo/project: From dashboard prompt or settings (1 клик) → Manager screen, "Fetch My" (1 клик) → Select/add (1 клик).

### 6.3 Advanced
1. Search: AppBar search icon (1 клик) → Input → Instant results.
2. Settings: Gear (1 клик) → Direct actions (e.g., Logout 1 confirm).
3. Sync: Refresh icon (1 клик) or auto.

## 7. Scope and Deliverables
- MVP: Auth, Issues, Basic Projects (view/move).
- Future: Custom fields full edit, notifications.
- Testing: Full coverage.
- Deployment: Stores, open-source.

Этот бриф - полный blueprint. Для уточнений - feedback.
