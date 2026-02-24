### Концепция приложения

**Название приложения:** GitDoIt (как в вашем прототипе). Это играет на "Get It Done" с отсылкой к GitHub, подчеркивая простоту и фокус на задачах.

**Общая идея:** Приложение сочетает минималистичный todo-менеджер с GitHub issues, решая "боли" пользователей: перегрузку информацией в списках, сложность навигации, оффлайн-работу и синхронизацию. Дизайн вдохновлен Notion (блочная структура, expandable элементы, чистые линии) и Teenage Engineering (функциональный минимализм, тактильные акценты вроде стрелочек и линий, как в hardware). Цвета: серые тона для фона, красные акценты для коннекторов/стрелочек, синие для ссылок/статусов. Шрифты: sans-serif (e.g., Roboto), light weight для второстепенного текста (user), bold для ключевого (repo/title).

**Ключевые принципы модульности и переиспользования кода:**
- **Унифицированный виджет:** Один базовый виджет `ExpandableItem` для репозиториев, issues и sub-tasks. Он рекурсивно отображает иерархию (repos → issues → sub-tasks), переиспользуя код для компактного/развернутого состояний.
- **Переиспользование:** Общие компоненты для лейблов (Chip), статусов (DotIndicator), времени (RelativeTimeText). Логика расширения/сворачивания в одном месте (используем `ExpansionTile` или custom анимацию для плавности).
- **Данные:** Абстрактная модель `Item` (для Repo или Issue), хранится локально (Hive для оффлайн), синхронизируется с GitHub (via GraphQL или REST с personal token).
- **Оффлайн-first:** Все данные в local storage. Синхронизация по запросу или авто (когда онлайн). Без токена — чисто локальный todo (создаем "локальный repo").
- **Нет платформо-зависимостей:** Только pure Dart/Flutter (http для API, markdown_widget для описаний).

**Решение пользовательских "болей" из отзывов:**
- Компактный вид: Быстрый скан (number + title + status + 1-2 labels + time + assignee).
- Развернутый: Не inline — тап по item открывает полный экран с деталями (description, comments, actions).
- Иерархия: Expand для показа children (issues/sub-tasks), без перегрузки списка.
- Фильтры/поиск: Легкий triage.
- Оффлайн: Работает без сети, sync решает проблему доступности.

### Модель данных (для модульности)

Используем абстрактный класс `Item` для унификации:
```dart
abstract class Item {
  String id; // repo slug or issue number
  String title;
  String? subtitle; // для repo: null, для issue: labels
  ItemStatus status; // open/closed
  DateTime updatedAt;
  String? assignee;
  List<String> labels;
  List<Item> children; // issues для repo, sub-tasks для issue
  bool isExpanded = false; // состояние
}

enum ItemStatus { open, closed }

class RepoItem extends Item { /* специфично: slug = 'user/repo' */ }
class IssueItem extends Item { /* специфично: number, description, comments */ }
```
- Sub-tasks: Моделируем как child-IssueItem (via checklists в GitHub или linked issues).
- Хранение: Hive boxes (e.g., 'repos', 'issues'). Provider/Riverpod для state.

### Виджеты (модульная структура)

Все в `lib/widgets/` для переиспользования.

1. **ExpandableItem (унифицированный базовый виджет):**
   - StatefulWidget, принимает `Item` (Repo или Issue).
   - **Компактное состояние (collapsed):** Row с:
     - Для repo: Container (rounded, gray bg) с Text(user, light font) + Text(repo, bold) + ArrowIcon (right if collapsed, down if expanded).
     - Для issue: Text('#num Title...', ellipsis) + LabelsChips (1-2, colored) + StatusDot (green for open) + RelativeTime ('2h') + AssigneeText ('@assignee').
     - GestureDetector: Тап по item → открывает DetailScreen. Тап по arrow → toggle expand (если has children).
   - **Развернутое состояние (expanded):** Column с компактным header + ListView(children.map((child) => ExpandableItem(child))).
   - Стили: Rounded borders, red connector line (CustomPaint для линии как в прототипе). Анимация: AnimatedContainer для expand.
   - Переиспользование: Рекурсивен — работает для любой иерархии (repo → issue → sub-task).
   - Пример использования: `ExpandableItem(item: repoItem)`.

2. **Общие компоненты (для переиспользования):**
   - `LabelChip`: Small colored Chip (e.g., red for 'bug', green for 'enhancement').
   - `StatusDot`: CircleAvatar (color by status).
   - `RelativeTimeText`: Text(calculateRelativeTime(updatedAt)).
   - `AssigneeText`: Text('@assignee', blue if @you).
   - `ConnectorLine`: CustomPaint для красной линии 연결ки (как в вашем прототипе).

3. **FilterWidget:**
   - Row с ChoiceChips: 'Open', 'Closed', 'All'. Фильтрует items в Provider.

4. **AppBarWidget (переиспользуемый):**
   - Title 'GitDoIt'.
   - Actions: SyncIcon (color: gray offline, blue syncing, green online), SearchIcon, BookmarkIcon (для repo manager), SettingsIcon.

5. **Ваш существующий виджет:** Интегрируем как базовый для ExpandableItem (адаптируем под унификацию, добавим рекурсию и тап-логику).

### Экраны

1. **OnboardingScreen:**
   - Простая форма: Input для GitHub token (опционально). Кнопка 'Create Local Repo' или 'Add GitHub Repo' (by URL).
   - Переход к MainScreen после setup.

2. **MainScreen:**
   - Scaffold с AppBarWidget.
   - Body: Column(FilterWidget + ListView(repos.map(ExpandableItem))).
   - Главный repo сверху, остальные ниже (из local storage).
   - Sync: FloatingActionButton для manual sync.

3. **IssueDetailScreen (или RepoDetailScreen для унификации):**
   - Принимает Item.
   - Для issue: Full title + MarkdownBody(description) + Labels list + Assignee + Timeline (ListView изменений) + Comments section (ListTile с reactions) + Actions (buttons: close, assign, etc.).
   - Для repo: Overview (stats: open issues, etc.) + Full list issues.
   - Минималистичный: Scrollable column, no overload.

4. **RepoManagerScreen:**
   - ListView подключенных repos.
   - Add by URL (parse 'user/repo'), remove, set default.
   - Кнопка 'Create Local' для оффлайн-repos.

5. **SearchScreen:**
   - TextField для поиска по title/labels.
   - Результаты: List of ExpandableItem (filtered).

6. **SettingsScreen:**
   - Token edit, theme toggle, sync settings.

### User Journey

1. **Первый запуск (Onboarding):**
   - Открыть app → Если нет данных: "Welcome! Work offline or connect GitHub?" → Input token (skip for local) → Add default repo (local или GitHub URL) → Save → MainScreen.

2. **Ежедневное использование (MainScreen):**
   - Просмотр: Filter 'Open' → Список repos (collapsed). Expand repo → Видит compact issues.
   - Детали: Tap issue → IssueDetailScreen (edit description, add comment, close).
   - Иерархия: Если issue has sub-tasks → Expand issue для children.
   - Поиск: Tap search → SearchScreen, результаты across all repos.
   - Управление repos: Tap bookmark → RepoManagerScreen → Add/remove.

3. **Оффлайн/Синхронизация:**
   - Оффлайн: Все локально, иконка gray.
   - С токеном: Tap sync → Pull issues from GitHub, push local changes → Иконка green.
   - Авто-sync: При запуске/фоне (если онлайн).

4. **Редактирование:**
   - В DetailScreen: Actions для GitHub API (close issue, assign) или local (для оффлайн).

**Реализация в коде (high-level):**
- State management: Riverpod (providers для repos, filter, syncStatus).
- API: http package для GitHub (e.g., GET /repos/:owner/:repo/issues).
- Local: Hive.initFlutter() → boxes для Item.
- Тестирование: Unit для ExpandableItem, integration для journeys.

Эта структура обеспечивает модульность (один виджет для всего), переиспользование (компоненты + рекурсия) и фокус на user pains (быстрый скан, оффлайн, минимализм). Если нужно код-сниппеты или уточнения, дайте знать!
