Вот **Неделя 2** — максимально мелко разбитая, под VS Code (основной редактор) + Zed (для быстрого просмотра/редактирования), для полного новичка. Всё по шагам 3–10 минут, с объяснениями «что», «где», «зачем» и «что должно получиться».

**Неделя 2: Модель данных и базовый API-сервис**  
**Цель**:  
- Понять, как Flutter работает с данными из интернета (API)  
- Создать модель Issue (как шаблон для задач из GitHub)  
- Написать сервис, который получает список issues по токену  

**Общее время**: ~7–8 часов (60–90 мин/день)  
**Что понадобится**:  
- Уже работающий проект из Недели 1  
- Fine-grained Personal Access Token с правами на Issues (read) — создай его заранее на https://github.com/settings/tokens → Fine-grained tokens → Repository access → только твой репозиторий → Issues: Read-only на старте  

| День | Шаг | Что именно сделать | Где / Как | Время | Что должно получиться / зачем |
|------|-----|---------------------|-----------|-------|--------------------------------|
| **1** | 1.1 | Открой проект в VS Code: File → Open Folder → папка gitdoit | VS Code | 1 мин | Готов к работе |
| 1 | 1.2 | Создай файл lib/models/issue.dart | Правой кнопкой на models → New File → issue.dart | 30 сек | Здесь будет шаблон задачи |
| 1 | 1.3 | Вставь в issue.dart этот код (пока без @JsonSerializable):<br>```dart:disable-run
| 1 | 1.4 | Сохрани и запусти `flutter run` — проверь, что ничего не сломалось | Терминал VS Code | 2 мин | App должен работать как раньше |
| 1 | 1.5 | Коммит: `git add lib/models/issue.dart` → `git commit -m "Day 1 Week 2: Created basic Issue model"` | Терминал | 1 мин | Зафиксировали первую модель |
| **2** | 2.1 | Открой pubspec.yaml → проверь, что json_annotation и json_serializable уже добавлены | VS Code | 1 мин | Если нет — добавь их сейчас |
| 2 | 2.2 | Добавь в dev_dependencies (если ещё нет): build_runner: ^2.4.0 | VS Code | 1 мин | Это инструмент для генерации кода |
| 2 | 2.3 | Сохрани → выполни `flutter pub get` | Терминал | 1–2 мин | Обновили пакеты |
| 2 | 2.4 | Вернись в issue.dart → добавь сверху:<br>```dart<br>import 'package:json_annotation/json_annotation.dart';<br>part 'issue.g.dart';<br>``` | VS Code | 1 мин | Подготовка к автогенерации |
| 2 | 2.5 | Добавь аннотацию над классом:<br>@JsonSerializable()<br>class Issue { ... } | VS Code | 30 сек | Это говорит: "сгенерируй мне код для JSON" |
| 2 | 2.6 | Добавь фабричный конструктор и toJson:<br>factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);<br>Map<String, dynamic> toJson() => _$IssueToJson(this); | VS Code | 2 мин | Это методы для преобразования JSON ↔ объект |
| 2 | 2.7 | Сохрани файл | — | — | — |
| **3** | 3.1 | В терминале выполни команду генерации:<br>`flutter pub run build_runner build --delete-conflicting-outputs` | Терминал VS Code | 1–3 мин | Создаст файл issue.g.dart автоматически |
| 3 | 3.2 | Проверь: в папке models появился файл issue.g.dart | VS Code Explorer | 30 сек | Если нет — повтори команду |
| 3 | 3.3 | Открой issue.g.dart и убедись, что там есть функции _$IssueFromJson и _$IssueToJson | VS Code / Zed | 1 мин | Это сгенерированный код — не редактируй вручную |
| 3 | 3.4 | Коммит: `git add lib/models/` → `git commit -m "Week 2 Day 3: Added JSON serialization to Issue model"` | Терминал | 1 мин | Зафиксировали модель |
| **4** | 4.1 | Создай файл lib/services/github_service.dart | Правой кнопкой на services → New File | 30 сек | Здесь будет вся логика общения с GitHub |
| 4 | 4.2 | Вставь базовый код сервиса:<br>```dart<br>import 'dart:convert';<br>import 'package:http/http.dart' as http;<br>import 'package:flutter_secure_storage/flutter_secure_storage.dart';<br>import '../models/issue.dart';<br><br>class GitHubService {<br>  final _storage = const FlutterSecureStorage();<br><br>  Future<String> _getToken() async {<br>    final token = await _storage.read(key: 'github_token');<br>    if (token == null) throw Exception('No token found');<br>    return token;<br>  }<br>}<br>``` | VS Code | 4 мин | Сервис — это класс, который умеет работать с API |
| 4 | 4.3 | Добавь метод fetchIssues (пока пустой):<br>Future<List<Issue>> fetchIssues(String owner, String repo) async {<br>  // здесь будет код<br>  return [];<br>} | VS Code | 2 мин | Пока возвращаем пустой список — чтобы не ломать |
| 4 | 4.4 | Сохрани и запусти `flutter run` — убедись, что app запускается | Терминал | 2 мин | Ничего не должно сломаться |
| **5** | 5.1 | В метод fetchIssues добавь получение токена:<br>final token = await _getToken(); | VS Code | 1 мин | Теперь сервис знает твой PAT |
| 5 | 5.2 | Добавь URL и запрос:<br>final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/issues?state=open');<br>final response = await http.get(<br>  uri,<br>  headers: {<br>    'Authorization': 'Bearer $token',<br>    'Accept': 'application/vnd.github.v3+json',<br>  },<br>); | VS Code | 4 мин | Это GET-запрос к GitHub |
| 5 | 5.3 | Добавь проверку ответа:<br>if (response.statusCode == 200) {<br>  // всё ок<br>} else {<br>  throw Exception('Failed to load issues: ${response.statusCode}');<br>} | VS Code | 2 мин | Если ошибка — выбросим исключение |
| 5 | 5.4 | Распарсим JSON:<br>final List<dynamic> jsonList = json.decode(response.body);<br>return jsonList.map((json) => Issue.fromJson(json)).toList(); | VS Code | 3 мин | Превращаем JSON в список объектов Issue |
| 5 | 5.5 | Коммит: `git add lib/services/` → `git commit -m "Week 2 Day 5: Added fetchIssues method to GitHubService"` | Терминал | 1 мин | — |
| **6** | 6.1 | Создай файл lib/providers/issues_provider.dart | Правой кнопкой на providers → New File | 30 сек | Здесь будет состояние списка задач |
| 6 | 6.2 | Вставь базовый код:<br>```dart<br>import 'package:flutter/material.dart';<br>import '../models/issue.dart';<br>import '../services/github_service.dart';<br><br>class IssuesProvider extends ChangeNotifier {<br>  List<Issue> _issues = [];<br>  List<Issue> get issues => _issues;<br><br>  Future<void> loadIssues(String owner, String repo) async {<br>    final service = GitHubService();<br>    _issues = await service.fetchIssues(owner, repo);<br>    notifyListeners();<br>  }<br>}<br>``` | VS Code | 5 мин | Provider — это как глобальная переменная для UI |
| 6 | 6.3 | Сохрани файл | — | — | — |
| **7** | 7.1 | Открой main.dart → добавь import:<br>import 'providers/issues_provider.dart';<br>import 'package:provider/provider.dart'; | VS Code | 1 мин | Подключаем Provider |
| 7 | 7.2 | Оберни MaterialApp в MultiProvider:<br>```dart<br>return MultiProvider(<br>  providers: [<br>    ChangeNotifierProvider(create: (_) => IssuesProvider()),<br>  ],<br>  child: MaterialApp(<br>    title: 'GitDoIt',<br>    home: const AuthScreen(),<br>  ),<br>);<br>``` | VS Code | 4 мин | Теперь данные доступны из любого экрана |
| 7 | 7.3 | Создай временный экран для теста: в auth_screen.dart после кнопки Save добавь:<br>ElevatedButton(<br>  onPressed: () {<br>    Navigator.push(<br>      context,<br>      MaterialPageRoute(builder: (_) => const HomeScreen()),<br>    );<br>  },<br>  child: const Text('Go to Issues'),<br>) | VS Code | 4 мин | Кнопка перехода |
| 7 | 7.4 | Создай lib/screens/home_screen.dart:<br>```dart<br>import 'package:flutter/material.dart';<br>import 'package:provider/provider.dart';<br>import '../providers/issues_provider.dart';<br><br>class HomeScreen extends StatelessWidget {<br>  const HomeScreen({super.key});<br><br>  @override<br>  Widget build(BuildContext context) {<br>    return Scaffold(<br>      appBar: AppBar(title: const Text('My Issues')),<br>      body: const Center(child: Text('Loading issues...')),<br>    );<br>  }<br>}<br>``` | VS Code | 4 мин | Простой экран |
| 7 | 7.5 | Коммит всей недели: `git add .` → `git commit -m "Week 2 complete: Issue model + GitHubService + Provider setup"` | Терминал | 2 мин | Неделя закончена |
| 7 | 7.6 | Запусти app → сохрани токен → нажми кнопку перехода → увидишь экран "Loading issues..." | Эмулятор/телефон | 5 мин | Первое доказательство, что API-подготовка идёт |

Теперь всё разбито ещё мельче — каждый шаг 1–5 минут максимум.  
Если на каком-то шаге застрянешь — просто напиши номер шага и ошибку (скопируй текст из терминала).  

Готов начать День 1 Недели 2? Просто скажи «поехали» или «день 1 недели 2». 😊
```
