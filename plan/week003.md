Вот **Неделя 3** — также максимально мелко разбитая, под VS Code + Zed, для полного новичка. Всё по шагам 2–10 минут, с объяснениями «что», «где», «зачем» и «что должно получиться».

**Неделя 3: UI для списка задач и pull-to-refresh**  
**Цель**:  
- Показать список issues на экране HomeScreen  
- Добавить pull-to-refresh (обновление по свайпу вниз)  
- Добавить простой фильтр по статусу (open/closed/all)  
- Сделать красивый ListTile для каждой задачи  

**Общее время**: ~7–8 часов (60–90 мин/день)  
**Что понадобится**:  
- Завершённая Неделя 2 (модель Issue, GitHubService с fetchIssues, IssuesProvider, HomeScreen)  
- Реальный токен, сохранённый в приложении (из Недели 1)  
- Тестовый репозиторий на GitHub с хотя бы 2–3 открытыми issues (создай их вручную заранее, если нужно)

| День | Шаг | Что именно сделать | Где / Как | Время | Что должно получиться / зачем |
|------|-----|---------------------|-----------|-------|--------------------------------|
| **1** | 1.1 | Открой проект в VS Code | File → Open Folder → gitdoit | 1 мин | Готов к работе |
| 1 | 1.2 | Открой lib/screens/home_screen.dart | Explorer слева | 30 сек | Это наш главный экран со списком |
| 1 | 1.3 | Добавь импорт Provider и модели:<br>import 'package:provider/provider.dart';<br>import '../providers/issues_provider.dart';<br>import '../models/issue.dart'; | Верх файла | 1 мин | Чтобы использовать глобальное состояние |
| 1 | 1.4 | В build добавь Consumer:<br>body: Consumer<IssuesProvider>(<br>  builder: (context, provider, child) {<br>    return Center(child: Text('Issues count: ${provider.issues.length}'));<br>  },<br>), | Внутри Scaffold | 3 мин | Покажет количество задач — тест Provider |
| 1 | 1.5 | Запусти app → сохрани токен → перейди на HomeScreen → увидишь число (пока 0) | Эмулятор | 2 мин | Provider работает |
| 1 | 1.6 | Коммит: `git add lib/screens/home_screen.dart` → `git commit -m "Week 3 Day 1: Added Consumer to HomeScreen"` | Терминал | 1 мин | — |
| **2** | 2.1 | В HomeScreen добавь кнопку загрузки (временно):<br>floatingActionButton: FloatingActionButton(<br>  onPressed: () async {<br>    final provider = Provider.of<IssuesProvider>(context, listen: false);<br>    await provider.loadIssues('berlogabob', 'flutter-github-issues-todo');<br>  },<br>  child: const Icon(Icons.refresh),<br>), | В Scaffold | 4 мин | Кнопка для теста загрузки |
| 2 | 2.2 | Запусти → перейди на HomeScreen → нажми кнопку → подожди 2–5 сек → увидишь число >0 (если есть issues в твоём репо) | Эмулятор | 3 мин | Первая загрузка данных из GitHub! |
| 2 | 2.3 | Если число всё ещё 0 — проверь: print в loadIssues или в консоли GitHub ошибки (401 = токен неверный) | Терминал VS Code | 5 мин | Диагностика |
| 2 | 2.4 | Коммит: `git add lib/screens/home_screen.dart` → `git commit -m "Week 3 Day 2: Added test load button"` | Терминал | 1 мин | — |
| **3** | 3.1 | Замени Center на ListView.builder:<br>if (provider.issues.isEmpty) {<br>  return const Center(child: Text('No issues yet'));<br>}<br>return ListView.builder(<br>  itemCount: provider.issues.length,<br>  itemBuilder: (context, index) {<br>    final issue = provider.issues[index];<br>    return ListTile(<br>      title: Text(issue.title),<br>      subtitle: Text('Issue #${issue.number} - ${issue.state}'),<br>    );<br>  },<br>); | В builder Consumer | 5 мин | Появится список задач |
| 3 | 3.2 | Добавь иконку слева:<br>leading: Icon(<br>  issue.state == 'open' ? Icons.circle_outlined : Icons.check_circle,<br>  color: issue.state == 'open' ? Colors.orange : Colors.green,<br>), | В ListTile | 2 мин | Визуально видно open/closed |
| 3 | 3.3 | Запусти → нажми кнопку загрузки → увидишь реальные issues из твоего репо | Эмулятор | 3 мин | Первый настоящий список! |
| 3 | 3.4 | Коммит: `git add lib/screens/home_screen.dart` → `git commit -m "Week 3 Day 3: Added ListView with issues"` | Терминал | 1 мин | — |
| **4** | 4.1 | Добавь RefreshIndicator вокруг ListView:<br>return RefreshIndicator(<br>  onRefresh: () async {<br>    final provider = Provider.of<IssuesProvider>(context, listen: false);<br>    await provider.loadIssues('berlogabob', 'flutter-github-issues-todo');<br>  },<br>  child: ListView.builder(...),<br>); | В builder | 4 мин | Pull-to-refresh (свайп вниз) |
| 4 | 4.2 | Запусти → потяни список вниз → увидишь индикатор обновления → список перезагрузится | Эмулятор | 3 мин | Удобно обновлять данные |
| 4 | 4.3 | Коммит: `git add lib/screens/home_screen.dart` → `git commit -m "Week 3 Day 4: Added pull-to-refresh"` | Терминал | 1 мин | — |
| **5** | 5.1 | Добавь переменную для фильтра в HomeScreen:<br>String _filterState = 'open'; | В класс HomeScreen (перед build) | 1 мин | Для будущего фильтра |
| 5 | 2.2 | Добавь DropdownButton сверху списка:<br>Padding(<br>  padding: const EdgeInsets.all(16),<br>  child: DropdownButton<String>(<br>    value: _filterState,<br>    items: const [<br>      DropdownMenuItem(value: 'open', child: Text('Open')),<br>      DropdownMenuItem(value: 'closed', child: Text('Closed')),<br>      DropdownMenuItem(value: 'all', child: Text('All')),<br>    ],<br>    onChanged: (value) {<br>      setState(() { _filterState = value!; });<br>    },<br>  ),<br>), | Перед ListView | 5 мин | Выпадающий список фильтров |
| 5 | 5.3 | В onRefresh измени вызов на:<br>await provider.loadIssues('berlogabob', 'flutter-github-issues-todo', state: _filterState); | В RefreshIndicator | 2 мин | Передаём фильтр |
| 5 | 5.4 | В GitHubService измени fetchIssues на:<br>Future<List<Issue>> fetchIssues(String owner, String repo, {String state = 'open'}) async { ... }<br>и в Uri: ?state=$state (если state == 'all' — можно убрать параметр) | lib/services/github_service.dart | 4 мин | API теперь поддерживает фильтр |
| 5 | 5.5 | Запусти → измени фильтр → обнови список → увидишь только open или closed | Эмулятор | 4 мин | Фильтр работает |
| 5 | 5.6 | Коммит: `git add .` → `git commit -m "Week 3 Day 5: Added status filter and updated service"` | Терминал | 1 мин | — |
| **6** | 6.1 | Улучши ListTile: добавь trailing: IconButton(icon: Icon(Icons.more_vert), onPressed: () {}), | В itemBuilder | 2 мин | Будущие действия (edit, close) |
| 6 | 6.2 | Добавь дату создания:<br>subtitle: Text('Issue #${issue.number} • ${issue.state} • ${issue.createdAt.toString().substring(0,10)}'), | В ListTile | 2 мин | Красивее и информативнее |
| 6 | 6.3 | Запусти и проверь внешний вид | Эмулятор | 3 мин | Список стал красивее |
| 6 | 6.4 | Коммит: `git add lib/screens/home_screen.dart` → `git commit -m "Week 3 Day 6: Improved ListTile UI"` | Терминал | 1 мин | — |
| **7** | 7.1 | Протестируй полностью: токен → загрузка → фильтр → pull-to-refresh → разные состояния | Эмулятор/телефон | 10 мин | Всё работает вместе |
| 7 | 7.2 | Сделай кнопку загрузки необязательной: вызови loadIssues автоматически при открытии экрана | В initState HomeScreen (сделай StatefulWidget) | 5 мин | Список загружается сам |
| 7 | 7.3 | Коммит всей недели: `git add .` → `git commit -m "Week 3 complete: Issue list UI, refresh, filter"` | Терминал | 2 мин | Неделя закончена |
| 7 | 7.4 | Сделай релиз APK: `flutter build apk --release` → установи на телефон | Терминал | 5 мин | Версия v0.3 на устройстве |

Теперь всё ещё мельче, чем раньше. Каждый шаг — отдельное действие, которое можно сделать за 2–5 минут и сразу проверить.

Готов начать **День 1 Недели 3**?  
Просто скажи «поехали» или «день 1 недели 3» — и начнём. 😊
