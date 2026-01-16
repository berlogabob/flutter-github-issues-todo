### Неделя 1: Базовый Setup и Аутентификация  
**Цель недели**: сделать первый рабочий экран ввода токена и понять, как вообще запускается Flutter-проект  
**Инструменты**: VS Code (основной) + Zed (если хочется скорости на просмотр/редактирование файлов)  
**Время на неделю**: ~7–8 часов (по 60–90 минут в день)  
**Совет по редакторам**:
- VS Code — используй для запуска, отладки, Flutter-команд (он лучше интегрирован)
- Zed — для быстрого просмотра/редактирования файлов, если нравится скорость и минимализм

| День | Шаг | Что именно сделать | Где / Как | Время | Что должно получиться / зачем это |
|------|-----|---------------------|-----------|-------|------------------------------------|
| **1** | 1.1 | Открой терминал в VS Code (Ctrl+`) и выполни `flutter doctor` | VS Code → Terminal → New Terminal | 5 мин | Увидишь, всё ли готово. Зелёные галочки — отлично. Красные — читаешь и исправляешь по инструкции |
| 1 | 1.2 | Создай проект командой: `flutter create gitdoit` | В терминале VS Code | 3 мин | Появится папка gitdoit с готовым шаблоном |
| 1 | 1.3 | Перейди в папку: `cd gitdoit` | Терминал | 10 сек | Теперь ты внутри проекта |
| 1 | 1.4 | Запусти приложение: `flutter run` | Терминал | 2–4 мин | Должен открыться эмулятор с дефолтным счётчиком (кнопка +1) |
| 1 | 1.5 | Если нет эмулятора — запусти Android-эмулятор из VS Code | VS Code → правый нижний угол → No Devices → Create Android Emulator | 5–10 мин | Появится виртуальный телефон |
| 1 | 1.6 | Нажми Ctrl+C в терминале → останови приложение | Терминал | 10 сек | Просто остановка |
| 1 | 1.7 | Открой проект в VS Code: File → Open Folder → выбери папку gitdoit | VS Code | 1 мин | Теперь видишь всю структуру слева |
| 1 | 1.8 | Сделай первый коммит: `git init` → `git add .` → `git commit -m "Initial Flutter project"` | Терминал | 2 мин | Проект под версионным контролем |
| **2** | 2.1 | Открой файл pubspec.yaml (в корне проекта) | VS Code → Explorer слева | 1 мин | Это главный конфиг-файл проекта |
| 2 | 2.2 | Найди раздел dependencies: и под ним добавь (сохрани отступы 2 пробела!):<br>http: ^1.2.0<br>flutter_secure_storage: ^9.2.0<br>provider: ^6.1.2<br>json_annotation: ^4.9.0<br>intl: ^0.19.0 | VS Code | 4 мин | Добавили нужные пакеты |
| 2 | 2.3 | Под dev_dependencies добавь:<br>json_serializable: ^6.8.0<br>build_runner: ^2.4.0 | VS Code | 2 мин | Для генерации моделей позже |
| 2 | 2.4 | Сохрани файл (Ctrl+S) | — | — | — |
| 2 | 2.5 | В терминале выполни: `flutter pub get` | Терминал VS Code | 1–3 мин | Пакеты скачались, pubspec.lock обновился |
| 2 | 2.6 | Запусти `flutter run` ещё раз — убедись, что ничего не сломалось | Терминал | 2 мин | Должен работать тот же счётчик |
| 2 | 2.7 | Коммит: `git add pubspec.yaml pubspec.lock` → `git commit -m "Add core dependencies"` | Терминал | 1 мин | Зафиксировали пакеты |
| **3** | 3.1 | В VS Code создай папки внутри lib/: models, services, screens, providers | Правой кнопкой на lib → New Folder | 2 мин | Организуем структуру |
| 3 | 3.2 | Открой main.dart → найди строку title: 'Flutter Demo Home Page' → замени на 'GitDoIt' | VS Code | 1 мин | Персонализируем заголовок |
| 3 | 3.3 | В body: замени весь Center(child: Column(...)) на:<br>Center(child: Text('Hello GitDoIt!')) | VS Code | 2 мин | Упрощаем экран для теста |
| 3 | 3.4 | Сохрани → нажми **r** в терминале (если app запущен) → hot reload | Терминал | 5 сек | Увидишь новый текст без перезапуска |
| 3 | 3.5 | Коммит: `git add lib/main.dart` → `git commit -m "Day 3: Basic UI change"` | Терминал | 1 мин | — |
| **4** | 4.1 | Создай файл: lib/screens/auth_screen.dart | Правой кнопкой на screens → New File | 30 сек | Новый экран |
| 4 | 4.2 | Вставь в файл минимальный код:<br>```dart:disable-run
| 4 | 4.3 | В main.dart добавь import: `import 'screens/auth_screen.dart';` | VS Code | 30 сек | Связываем файлы |
| 4 | 4.4 | В main.dart замени home: MyHomePage(...) на home: const AuthScreen(), | VS Code | 30 сек | Теперь приложение стартует с твоего экрана |
| 4 | 4.5 | Запусти `flutter run` или нажми r (hot reload) | Терминал | 2 мин | Видишь новый экран с текстом |
| 4 | 4.6 | Коммит: `git add .` → `git commit -m "Day 4: Created AuthScreen"` | Терминал | 1 мин | — |
| **5** | 5.1 | В auth_screen.dart добавь import: `import 'package:flutter_secure_storage/flutter_secure_storage.dart';` | VS Code | 30 сек | Подключили хранилище токена |
| 5 | 5.2 | Добавь поле ввода: замени body на:<br>```dart<br>body: Padding(<br>  padding: const EdgeInsets.all(16.0),<br>  child: TextField(<br>    decoration: const InputDecoration(labelText: 'GitHub PAT'),<br>  ),<br>),<br>``` | VS Code | 3 мин | Появилось поле ввода |
| 5 | 5.3 | Добавь контроллер сверху класса:<br>final _controller = TextEditingController(); | VS Code | 1 мин | Чтобы читать текст |
| 5 | 5.4 | В TextField добавь: controller: _controller, | VS Code | 30 сек | Связали поле с контроллером |
| 5 | 5.5 | Добавь кнопку под TextField (в Column):<br>ElevatedButton(<br>  onPressed: () {},<br>  child: const Text('Save'),<br>) | VS Code | 2 мин | Пока кнопка ничего не делает |
| 5 | 5.6 | Запусти / hot reload — проверь внешний вид | Терминал | 2 мин | Должно быть поле + кнопка |
| **6** | 6.1 | Сделай кнопку рабочей: onPressed: () async {<br>  final storage = FlutterSecureStorage();<br>  await storage.write(key: 'github_token', value: _controller.text);<br>  print('Token saved!');<br>}, | VS Code | 4 мин | Сохраняет токен |
| 6 | 6.2 | Добавь всплывашку после сохранения:<br>ScaffoldMessenger.of(context).showSnackBar(<br>  const SnackBar(content: Text('Token saved!')),<br>); | VS Code | 2 мин | Появится уведомление внизу экрана |
| 6 | 6.3 | Добавь вторую кнопку "Check":<br>ElevatedButton(<br>  onPressed: () async {<br>    final storage = FlutterSecureStorage();<br>    String? token = await storage.read(key: 'github_token');<br>    print('Saved token: $token');<br>  },<br>  child: const Text('Check'),<br>) | VS Code | 4 мин | Проверяет, что сохранилось |
| 6 | 6.4 | Запусти → введи любой текст → Save → перезапусти app → нажми Check → посмотри в терминале VS Code вывод | Терминал | 5 мин | Увидишь сохранённый текст |
| **7** | 7.1 | Протестируй: ввод, сохранение, перезапуск, проверка | VS Code + эмулятор | 10 мин | Убедись, что токен держится |
| 7 | 7.2 | Добавь обработку пустого ввода:<br>if (_controller.text.isEmpty) {<br>  ScaffoldMessenger.of(context).showSnackBar(<br>    const SnackBar(content: Text('Please enter token')),<br>  );<br>  return;<br>} | VS Code | 5 мин | Не даём сохранить пустоту |
| 7 | 7.3 | Коммит всего: `git add .` → `git commit -m "Week 1 complete: Auth screen with token storage"` | Терминал | 2 мин | Неделя закончена |
| 7 | 7.4 | Сделай релизный APK: `flutter build apk --release` | Терминал | 3–5 мин | Файл появится в build/app/outputs/flutter-apk/app-release.apk |
| 7 | 7.5 | Установи APK на телефон и проверь | Телефон | 5 мин | Первая версия на реальном устройстве! |

Теперь всё разбито на очень мелкие шаги (по 1–5 минут), чтобы не сбиваться.  
Если что-то не получается — просто пиши точную ошибку или на каком шаге застрял.  
Готов начать День 1 прямо сейчас? Просто скажи «поехали» или «день 1».
