Вот **финальная версия объединённого, полностью самодостаточного брифа** на разработку приложения GitDoIt.

Документ составлен так, чтобы в нём содержалась вся необходимая информация для реализации MVP без необходимости обращаться к любым другим файлам, макетам, прототипам, старым версиям брифа или внешним источникам.

**GitDoIt — Техническое задание (самодостаточный бриф)**  
Дата: 24 февраля 2026  
Версия: 1.0 (финальная объединённая, самодостаточная)

### 1. Название и суть проекта

**Название:** GitDoIt  
**Слоган:** Minimalist GitHub Issues & Projects TODO Manager  
**Платформа:** кросс-платформенное мобильное приложение (Android + iOS)  
**Язык / фреймворк:** Flutter (pure Dart)  
**Основная идея:** превращать GitHub Issues и GitHub Projects (v2) в удобный, быстрый, минималистичный TODO-менеджер с сильным offline-first подходом.

### 2. Целевая аудитория и решаемые боли

- Разработчики, тимлиды, продакт-менеджеры, open-source контрибьюторы  
- Основные боли, которые решает приложение:
  - Перегруженные списки задач в GitHub → нужен быстрый скан и triage
  - Плохая навигация по репозиториям и проектам → нужна иерархия и быстрая фильтрация
  - Нет нормальной оффлайн-работы → важные задачи должны редактироваться в самолёте / метро
  - Слишком много кликов для перемещения задачи по колонке → минимум действий
  - Нет приятного минималистичного мобильного опыта именно под задачи

### 3. Визуальный стиль (строго)

- Основная тема: **тёмная** (dark mode по умолчанию, светлая тема не планируется в MVP)
- Фон: тёмно-серый (#121212 → #1E1E1E градиенты)
- Акценты:
  - Основные действия (кнопки Create, Sync, Move) → **оранжевый** (#FF6200, #FF8A33)
  - Коннекторы, линии иерархии, стрелки раскрытия → **красный** (#FF3B30 или близкий)
  - Ссылки и выделение имени assignee (если это ты) → **синий** (#0A84FF)
  - Опасные действия (Close, Delete, Logout) → **красный** (#FF3B30)
- Шрифты: system sans-serif (Roboto на Android, SF Pro на iOS)
  - Заголовки / названия репозиториев / issues → medium/bold
  - Второстепенный текст (время, автор, лейблы) → regular/light, opacity 0.7–0.85
- Иконки: Material Icons + минимальные кастомные (стрелки, коннекторы — линии с толщиной 1.5–2 px)

### 4. Ключевые принципы UX

- Минимум кликов
- Контекстные действия (долгое нажатие, свайп где логично)
- Быстрый скан → компактные карточки
- Полные детали → отдельный экран, а не раскрывашка
- Иерархия через рекурсивный виджет ExpandableItem
- Автоматическая синхронизация при появлении сети (но с ручной кнопкой)

### 5. Аутентификация (два варианта, пользователь выбирает)

Вариант А — **OAuth Device Flow** (рекомендуемый)  
Вариант Б — **Personal Access Token** (PAT) — для тех, кто хочет быстро

Scopes, которые нужны (минимум):
- repo (чтение/запись issues)
- read:org, write:org (для проектов на уровне организации)
- project (чтение/запись Projects v2)

### 6. Основные сущности и модель данных (абстрактная)

```dart
abstract class Item {
  String id;                        // github id или локальный uuid
  String title;
  ItemStatus status;                // open / closed
  DateTime? updatedAt;
  String? assigneeLogin;
  List<String> labels;              // имена лейблов
  List<Item> children;              // подзадачи / issues в репозитории
  bool isExpanded = false;
  bool isLocalOnly = false;         // не было синхронизировано
  DateTime? localUpdatedAt;
}

enum ItemStatus { open, closed }

class RepoItem extends Item {
  String fullName;                  // "owner/repo"
  String? description;
}

class IssueItem extends Item {
  int? number;                      // github номер
  String? bodyMarkdown;
  String? projectColumnName;        // если задача в проекте
  String? projectItemNodeId;        // для GraphQL мутаций
}

class ProjectItem extends Item {
  // пока минимально — в MVP только название и статус
  String? projectNodeId;
}
```

### 7. Экраны MVP (строго 7 экранов)

1. OnboardingScreen  
2. MainDashboardScreen  
3. IssueDetailScreen  
4. ProjectBoardScreen  
5. RepoProjectLibraryScreen  
6. SearchScreen  
7. SettingsScreen

### 8. Краткое описание каждого экрана

**OnboardingScreen**  
- Логотип + название + подзаголовок  
- Две большие кнопки:  
  • Login with GitHub (OAuth Device Flow)  
  • Use Personal Access Token  
- Под PAT — поле ввода (masked) + кнопка Continue  
- Кнопка «Continue Offline» → создаёт пустой локальный репозиторий «My Local Tasks»

**MainDashboardScreen**  
- AppBar: GitDoIt | sync status icon | search | settings  
- Фильтры: чипы Open / Closed / All + дропдаун «All Projects» / «Project X»  
- Список: иерархия через ExpandableItem (Repo → Issues → sub-issues)  
- FAB: + New Issue  
- Если пусто → крупный текст «Add repository or project» + кнопка

**IssueDetailScreen**  
- Большой заголовок #123 Title  
- Markdown body  
- Метаданные: labels (chips), assignee, status dot, relative time  
- Если в проекте → текущая колонка + дропдаун для смены  
- Кнопки: Edit / Close / Reopen / Add comment (пока заглушка)

**ProjectBoardScreen**  
- Горизонтальный скролл колонок (по значению поля Status)  
- В каждой колонке — вертикальный ReorderableListView карточек  
- Карточка: #num Title + 1–2 label + assignee + relative time  
- Drag & drop между колонками → мгновенное обновление через GraphQL

**RepoProjectLibraryScreen**  
- Список подключённых репозиториев и проектов  
- Кнопки: Add by URL / Fetch my repositories / Fetch my projects  
- Для каждого элемента: set as default / remove

**SearchScreen**  
- Поле поиска (глобальное по title, labels, body)  
- Результаты — тот же ExpandableItem стиль

**SettingsScreen**  
- Account: logout, текущий пользователь  
- Default repository / project  
- Sync: auto-sync on wifi / on any network  
- Danger zone: clear local cache

### 9. Технический стек (жестко зафиксирован)

- Flutter 3.24+ (на февраль 2026)  
- State management: Riverpod 2.x  
- Локальное хранилище: Hive  
- Сеть: http + graphql_flutter  
- Secure storage: flutter_secure_storage  
- Markdown: flutter_markdown  
- Drag & drop: reorderables  
- Запуск браузера: url_launcher  
- Нет других зависимостей в MVP

### 10. Запреты и ограничения (обязательные для всех разработчиков)

- Запрещено добавлять любые фичи, которых нет в этом документе  
- Запрещено добавлять светлую тему в MVP  
- Запрещено добавлять уведомления, виджеты, share sheet, интеграции с другими сервисами  
- Запрещено добавлять любые иконки / иллюстрации / Lottie / кастомные шейпы, если об этом не сказано явно выше  
- Запрещено менять цвета акцентов без явного согласования  
- Запрещено делать inline-редактирование в списке (только через IssueDetailScreen)

### 11. MVP — критерии готовности

- Можно авторизоваться (OAuth или PAT)  
- Можно работать полностью оффлайн (создавать, редактировать, перемещать локальные задачи)  
- Синхронизация issues (REST) работает в обе стороны  
- Синхронизация Projects v2 (GraphQL): просмотр доски, перемещение по колонкам  
- Нет критических багов в user journeys из раздела 12

### 12. Основные user journeys (MVP)

1. Первый запуск → OAuth за 3–4 клика → MainDashboard с хотя бы одним репозиторием  
2. Оффлайн-режим → Continue Offline → создать задачу → выйти → зайти снова → задача на месте  
3. Создать issue → указать проект и колонку → увидеть в ProjectBoardScreen  
4. Перетащить задачу между колонками → статус изменился  
5. Открыть issue → прочитать markdown → закрыть issue → увидеть в списке closed

---


