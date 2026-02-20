### Подробный план разработки проекта GitDoIt: Flutter-приложение для управления задачами (ToDo) через интеграцию с GitHub Issues

Привет, Андрей! Я ещё раз всё обдумал, учёл твои пожелания и перестроил план полностью в текстовом формате — без таблиц, с чёткой разбивкой по дням. План максимально полный: каждый день описан с подзадачами, конкретными шагами, примерами кода (взятыми и адаптированными из наших предыдущих обсуждений и вложений), рекомендациями, возможными рисками и чекпоинтами прогресса. 

Я сохранил гибкий подход, вдохновлённый статьёй на Habr (альтернативы диаграмме Ганта): основа — **Now-Next-Later** (Теперь-Затем-Потом: Now — ближайшие 1–3 дня, Next — следующие 4–10 дней, Later — финализация 11–14 дней) + **Goal-Oriented** (ориентация на цели через OKR — Objectives and Key Results, то есть Цели и Ключевые Результаты). 

**Общие параметры проекта** (расшифровка ключевых аббревиатур при первом упоминании):
- **MVP** (Minimum Viable Product — Минимально Жизнеспособный Продукт): базовая версия приложения, которая запускается, синхронизирует задачи (issues) с GitHub, позволяет создавать/просматривать/редактировать/закрывать их.
- **PAT** (Personal Access Token — Персональный Токен Доступа): безопасный ключ для аутентификации в GitHub API.
- **OKR** (Objectives and Key Results — Цели и Ключевые Результаты): главная цель — изучить Flutter и Dart через работающий MVP; ключевые результаты — приложение синхронизирует задачи, UI (User Interface — Пользовательский Интерфейс) отзывчивый, код чистый.
- **CRUD** (Create, Read, Update, Delete — Создание, Чтение, Обновление, Удаление): базовые операции с задачами.
- **Riverpod** — современный пакет для управления состоянием (state management) в Flutter (альтернатива Provider, BLoC и т.д.).
- Общее время: 14 дней (с 28 января по 10 февраля 2026 года включительно), примерно 4–6 часов в день (итого 60–80 часов). Буфер 20% на эксперименты и обучение.
- Инструменты: Flutter SDK (Software Development Kit — Набор для Разработки), VS Code или Android Studio, GitHub (репозиторий "andrey-todo-2026"), эмулятор/реальное устройство.
- Трекинг: используй GitHub Issues самого репозитория (иронично и удобно) или Notion для заметок.

#### День 1: 28 января 2026 (Now — Setup среды и базовой структуры, ~4–6 часов)
Сегодня фокус на подготовке окружения — это фундамент, без которого ничего не запустится. Это высокоприоритетные задачи с низкими усилиями (High Impact / Low Effort по матрице приоритизации).

1. **Проверка и установка Flutter окружения**  
   Запусти команду `flutter doctor` в терминале — она проверит всё необходимое (Android SDK, Xcode если для iOS, и т.д.). Если чего-то не хватает, установи по инструкциям на flutter.dev (актуальная версия на 2026 год — 3.19 или выше).  
   Создай новый проект: `flutter create gitdoit`. Перейди в папку: `cd gitdoit`. Инициализируй Git: `git init`, добавь remote: `git remote add origin https://github.com/твой-username/andrey-todo-2026.git` (сначала создай пустой репозиторий на GitHub — private для безопасности). Сделай первый коммит и push.

2. **Создание репозитория для задач на GitHub**  
   На GitHub создай новый репозиторий "andrey-todo-2026" (или любое имя). Это будет "бэкенд" для твоих ToDo-задач — все issues будут храниться там.

3. **Добавление зависимостей в pubspec.yaml**  
   Открой файл pubspec.yaml и добавь (это из наших вложений, актуальные версии проверь на pub.dev):  
   ```
   dependencies:
     flutter:
       sdk: flutter
     github: ^9.4.0          # пакет для работы с GitHub API
     flutter_secure_storage: ^9.0.0   # безопасное хранение PAT
     riverpod: ^2.5.0        # управление состоянием (рекомендую для обучения — просто и современно)
     intl: ^0.19.0           # форматирование дат
   ```
   Запусти `flutter pub get`.

4. **Базовая структура папок и файлов**  
   Создай структуру (как в гиде из вложений):  
   - lib/models/issue.dart — модель задачи.  
   - lib/services/github_service.dart — сервис для API.  
   - lib/providers/todo_provider.dart — провайдер состояния.  
   - lib/screens/home_screen.dart, add_edit_issue.dart, issue_detail.dart — экраны.  
   В main.dart пока просто базовый MaterialApp.

**Чекпоинт конца дня**: Проект создаётся, компилируется (`flutter run` на эмуляторе показывает пустой экран), зависимости установлены, репозиторий на GitHub готов. Прогресс по OKR: ~10–15% (основа готова).  
**Риск**: Проблемы с установкой Flutter. Решение: почитай ошибки в `flutter doctor` или спроси меня.

#### День 2: 29 января 2026 (Now — Модели данных и начало GitHub-сервиса, ~5–7 часов)
Продолжаем Now — работаем с данными.

1. **Создание модели Issue**  
   В lib/models/issue.dart напиши класс (расширенный из вложений):  
   ```
   class Issue {
     final int number;
     final String title;
     final String? body;
     final bool isOpen;  // true если open, false если closed
     final List<String> labels;
     // Конструктор и fromJson/toJson для сериализации
     Issue.fromJson(Map<String, dynamic> json)
         : number = json['number'],
           title = json['title'],
           body = json['body'],
           isOpen = json['state'] == 'open',
           labels = List<String>.from(json['labels'].map((l) => l['name']));
   }
   ```

2. **Создание PAT и начало GitHubService**  
   Перейди на github.com/settings/tokens → New token → Fine-grained → Выбери только репозиторий "andrey-todo-2026" → Permissions: Issues → Read & Write. Скопируй токен (он показывается только раз!).  
   В lib/services/github_service.dart начни класс (полный код из вложений):  
   ```
   import 'package:github/github.dart';
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';

   class GitHubService {
     static const _storage = FlutterSecureStorage();
     static const _tokenKey = 'github_pat';
     GitHub? _client;

     Future<GitHub> get client async {
       if (_client != null) return _client!;
       String? token = await _storage.read(key: _tokenKey);
       if (token == null) {
         // В реальном приложении покажи диалог для ввода токена
         // Пока для теста захардкодь или сохрани вручную
       }
       _client = GitHub(auth: Authentication.withToken(token));
       return _client!;
     }

     Future<List<Issue>> getIssues(String owner, String repo) async {
       final gitHub = await client;
       final issues = await gitHub.issues.listByRepo(owner, repo).toList();
       return issues.map((i) => Issue.fromJson(i.toJson())).toList();
     }
   }
   ```

3. **Тест сервиса в main.dart**  
   Добавь временный код для проверки:  
   ```
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     final service = GitHubService();
     // Сохрани токен вручную для теста
     await service._storage.write(key: service._tokenKey, value: 'твой_PAT');
     final issues = await service.getIssues('твой_username', 'andrey-todo-2026');
     print('Найдено задач: ${issues.length}');
     runApp(MyApp());
   }
   ```
   Создай пару тестовых issues вручную на GitHub и проверь вывод в консоли.

**Чекпоинт конца дня**: Модель Issue готова, сервис получает список задач из GitHub. Прогресс по OKR: ~25–30%.  
**Риск**: Ошибки аутентификации. Решение: проверь scopes токена.

#### День 3: 30 января 2026 (Now — Завершение GitHubService, ~6–8 часов)
Финализируем core-логику.

1. **Дополнение GitHubService методами CRUD**  
   Добавь create, update, close:  
   ```
   Future<Issue> createIssue(String owner, String repo, String title, String? body) async {
     final gitHub = await client;
     final request = IssueRequest(title: title, body: body);
     final created = await gitHub.issues.create(owner, repo, request);
     return Issue.fromJson(created.toJson());
   }

   // Аналогично для edit и close (используй gitHub.issues.edit)
   ```

2. **Настройка Riverpod-провайдера**  
   В todo_provider.dart:  
   ```
   final gitHubServiceProvider = Provider((ref) => GitHubService());

   final todosProvider = StateNotifierProvider<TodoNotifier, AsyncValue<List<Issue>>>((ref) {
     return TodoNotifier(ref.watch(gitHubServiceProvider));
   });

   class TodoNotifier extends StateNotifier<AsyncValue<List<Issue>>> {
     final GitHubService service;
     TodoNotifier(this.service) : super(const AsyncLoading()) {
       fetchIssues();
     }

     Future<void> fetchIssues() async {
       state = const AsyncLoading();
       try {
         final issues = await service.getIssues('owner', 'repo');
         state = AsyncData(issues);
       } catch (e) {
         state = AsyncError(e);
       }
     }
     // Методы addIssue, updateIssue и т.д.
   }
   ```

**Чекпоинт конца дня**: Полный CRUD в сервисе работает (протестируй вручную). Прогресс по OKR: ~40%. Переход к Next.

#### День 4–5: 31 января – 1 февраля 2026 (Next — Главный экран со списком задач, ~8–10 часов всего)
Переходим к UI.

1. **Home Screen**  
   Реализуй список задач с Pull-to-Refresh: используй ConsumerWidget, ref.watch(todosProvider), ListView.builder с ListTile (title, checkbox для open/closed). Добавь FloatingActionButton для перехода на экран создания.

2. **Интеграция с провайдером**  
   В onRefresh вызывай ref.read(todosProvider.notifier).fetchIssues().

**Чекпоинт к концу Дня 5**: Экран показывает список задач из GitHub, обновляется. Прогресс по OKR: ~60%.

#### День 6–7: 2–3 февраля 2026 (Next — Экран создания/редактирования задачи, ~6–8 часов)
1. **Add/Edit Screen**  
   Form с TextField для title/body. По сохранению — вызов createIssue, затем refresh списка.

**Чекпоинт к концу Дня 7**: Можно создавать и редактировать задачи, они появляются в списке и на GitHub. Прогресс: ~70–75%.

#### День 8: 4 февраля 2026 (Next — Детальный экран задачи, ~4–5 часов)
1. **Issue Detail**  
   Просмотр body, labels, кнопки close/open.

**Чекпоинт**: Полный цикл просмотра/изменения. Прогресс: ~80%.

#### День 9–10: 5–6 февраля 2026 (Next — Финализация интеграции и обработка ошибок, ~8–10 часов)
1. Автозагрузка при старте, обработка ошибок (SnackBar), ввод PAT через диалог на первом запуске.

**Чекпоинт к концу Дня 10**: Приложение стабильно работает end-to-end. Прогресс: ~90%.

#### День 11–12: 7–8 февраля 2026 (Later — Тестирование и полировка UI, ~6–8 часов)
1. Unit-тесты (flutter test) для моделей и сервиса. Widget-тесты для экранов. Добавь красивые даты (intl), responsive дизайн.

**Чекпоинт**: Тесты проходят, UI выглядит хорошо. Прогресс: ~95%.

#### День 13–14: 9–10 февраля 2026 (Later — Сборка и ревью MVP, ~4–6 часов)
1. `flutter build apk` / iOS. Тестирование на реальном устройстве. Финальный ревью по OKR.

**Чекпоинт к концу Дня 14**: MVP готов и работает! Прогресс: 100%. Отпразднуй и поделись скриншотами, если захочешь.

После этого — пост-MVP идеи (labels, уведомления и т.д.), но только если останется энергия. Если где-то застрянешь — пиши, помогу с кодом или дебагом. Удачи, Андрей — это будет крутой проект для изучения Flutter! 🚀