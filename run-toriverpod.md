**Полная миграция проекта GitDoIt на Riverpod 3 + Реализация свайпов «пин/unpin» для библиотеки репозиториев**

Это **один самодостаточный документ**. Следуй инструкциям строго по порядку — после выполнения у тебя будет полностью Riverpod-приложение + рабочие жесты в библиотеке репозиториев (свайп влево — закрепить, свайп вправо — открепить, один «main/default» репозиторий всегда отображается и не открепляется).

### 1. Почему это нужно сделать именно сейчас
- Твой проект уже использует `flutter_riverpod: ^3.0.3` и `riverpod_annotation: ^3.0.3`.
- Папка `lib/providers/` существует, но пуста — значит миграция будет чистой.
- Экран библиотеки (`lib/screens/repo_project_library_screen.dart`) до сих пор на `setState` — это единственное место, где состояние разрознено.
- После миграции весь код станет предсказуемым, тестируемым и масштабируемым.

### 2. Подготовка проекта (5 минут)
Открой терминал в корне проекта и выполни:

```bash
flutter pub add riverpod_annotation
flutter pub add dev:riverpod_generator
flutter pub add dev:build_runner
flutter pub get
```

В `pubspec.yaml` убедись, что есть:
```yaml
dependencies:
  flutter_riverpod: ^3.0.3
  riverpod_annotation: ^3.0.3

dev_dependencies:
  riverpod_generator: ^3.0.3
  build_runner: ^2.4.0
```

В `lib/main.dart` замени весь `runApp` на:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart'; // или твой стартовый экран

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitDoIt',
      theme: ThemeData.dark(useMaterial3: true),
      home: const OnboardingScreen(), // или MainDashboardScreen
    );
  }
}
```

### 3. Обновление модели `lib/models/repo_item.dart`
Открой файл и добавь два новых поля + обнови методы (добавь в конец класса):

```dart
class RepoItem extends Item {
  final String fullName;
  final String? description;

  bool isPinned;
  bool isMain;                    // ← главный репозиторий

  RepoItem({
    required super.id,
    required super.title,
    required this.fullName,
    this.description,
    this.isPinned = false,
    this.isMain = false,
    // все твои старые параметры...
  }) : super(/* ... */);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['fullName'] = fullName;
    json['description'] = description;
    json['isPinned'] = isPinned;
    json['isMain'] = isMain;
    return json;
  }

  factory RepoItem.fromJson(Map<String, dynamic> json) {
    // твой существующий fromJson
    return RepoItem(
      // старые поля...
      fullName: json['fullName'] ?? '',
      description: json['description'],
      isPinned: json['isPinned'] as bool? ?? false,
      isMain: json['isMain'] as bool? ?? false,
    );
  }
}
```

### 4. Обновление сервиса хранения `lib/services/local_storage_service.dart`
В конец класса `LocalStorageService` добавь эти методы (используем уже существующий `default_repo` как main):

```dart
  // ==================== PINNED + MAIN REPO ====================
  static const String _pinnedReposKey = 'pinned_repos';

  Future<void> savePinnedRepos(List<String> fullNames) async {
    try {
      await _storage.write(key: _pinnedReposKey, value: json.encode(fullNames));
      debugPrint('✅ Сохранено ${fullNames.length} закреплённых репозиториев');
    } catch (e) {
      debugPrint('Ошибка сохранения pinned: $e');
    }
  }

  Future<List<String>> getPinnedRepos() async {
    try {
      final jsonStr = await _storage.read(key: _pinnedReposKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      return List<String>.from(json.decode(jsonStr));
    } catch (e) {
      debugPrint('Ошибка загрузки pinned: $e');
      return [];
    }
  }

  // Уже есть в твоём файле:
  // Future<void> saveDefaultRepo(String repoFullName)
  // Future<String?> getDefaultRepo()
```

### 5. Создание провайдеров (новые файлы в `lib/providers/`)
Создай три файла:

**`lib/providers/pinned_repos_provider.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app_name/services/local_storage_service.dart'; // замени на свой пакет
import '../models/repo_item.dart';

final pinnedReposProvider = StateNotifierProvider<PinnedReposNotifier, List<String>>((ref) {
  return PinnedReposNotifier(ref);
});

class PinnedReposNotifier extends StateNotifier<List<String>> {
  final Ref ref;
  PinnedReposNotifier(this.ref) : super([]);

  Future<void> load() async {
    final storage = LocalStorageService();
    state = await storage.getPinnedRepos();
  }

  Future<void> pin(String fullName) async {
    if (state.contains(fullName)) return;
    state = [...state, fullName];
    await _save();
  }

  Future<void> unpin(String fullName) async {
    state = state.where((n) => n != fullName).toList();
    await _save();
  }

  Future<void> _save() async {
    final storage = LocalStorageService();
    await storage.savePinnedRepos(state);
  }
}

final mainRepoProvider = StateProvider<String?>((ref) => null);

final displayedReposProvider = Provider<List<RepoItem>>((ref) {
  final allRepos = ref.watch(repositoriesProvider); // твой провайдер репозиториев (если нет — создай ниже)
  final pinned = ref.watch(pinnedReposProvider);
  final main = ref.watch(mainRepoProvider);

  return allRepos.where((r) => r.fullName == main || pinned.contains(r.fullName)).toList();
});
```

**`lib/providers/repositories_provider.dart`** (если у тебя ещё нет глобального провайдера репозиториев — создай):

```dart
final repositoriesProvider = StateProvider<List<RepoItem>>((ref) => []);
```

### 6. Полная переписка экрана библиотеки `lib/screens/repo_project_library_screen.dart`
Замени **весь** файл на этот (он теперь полностью на Riverpod + Dismissible):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repo_item.dart';
import '../providers/pinned_repos_provider.dart';
import '../providers/repositories_provider.dart';
import '../services/local_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RepoProjectLibraryScreen extends ConsumerStatefulWidget {
  const RepoProjectLibraryScreen({super.key});

  @override
  ConsumerState<RepoProjectLibraryScreen> createState() => _RepoProjectLibraryScreenState();
}

class _RepoProjectLibraryScreenState extends ConsumerState<RepoProjectLibraryScreen> {
  @override
  void initState() {
    super.initState();
    _loadPinnedAndMain();
  }

  Future<void> _loadPinnedAndMain() async {
    final notifier = ref.read(pinnedReposProvider.notifier);
    await notifier.load();

    final storage = LocalStorageService();
    final main = await storage.getDefaultRepo();
    ref.read(mainRepoProvider.notifier).state = main;
  }

  @override
  Widget build(BuildContext context) {
    final repos = ref.watch(repositoriesProvider);
    final pinned = ref.watch(pinnedReposProvider);
    final mainRepo = ref.watch(mainRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека репозиториев')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: repos.length,
        itemBuilder: (context, index) {
          final repo = repos[index];
          final isPinnedHere = pinned.contains(repo.fullName);
          final isMainHere = repo.fullName == mainRepo;

          return Dismissible(
            key: ValueKey(repo.fullName),
            direction: DismissDirection.horizontal,

            background: Container(
              color: Colors.green.shade600,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: const Row(children: [Icon(Icons.push_pin, color: Colors.white), SizedBox(width: 12), Text('Закрепить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            ),
            secondaryBackground: Container(
              color: Colors.red.shade600,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Открепить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 12), Icon(Icons.push_pin_off, color: Colors.white)]),
            ),

            confirmDismiss: (direction) async {
              final notifier = ref.read(pinnedReposProvider.notifier);

              if (direction == DismissDirection.startToEnd) {
                await notifier.pin(repo.fullName);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${repo.fullName} закреплён')));
              } else if (direction == DismissDirection.endToStart) {
                if (isMainHere) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Основной репозиторий нельзя открепить')));
                  return false;
                }
                await notifier.unpin(repo.fullName);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${repo.fullName} откреплён')));
              }
              return false; // карточка остаётся на месте
            },

            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.folder, size: 40, color: Colors.orange),
                title: Text(repo.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: repo.description != null ? Text(repo.description!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMainHere)
                      const Chip(label: Text('main'), backgroundColor: Colors.amber)
                    else if (isPinnedHere)
                      const Chip(label: Text('пин'), backgroundColor: Colors.blue, labelStyle: TextStyle(color: Colors.white)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => launchUrl(Uri.parse('https://github.com/${repo.fullName}'), mode: LaunchMode.externalApplication),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### 7. Главный экран (`lib/screens/main_dashboard_screen.dart`)
В месте, где отображается список репозиториев, замени на:

```dart
final displayedRepos = ref.watch(displayedReposProvider);

ListView.builder(
  itemCount: displayedRepos.length,
  itemBuilder: (context, i) => YourRepoCard(repo: displayedRepos[i]),
)
```

### 8. Первый запуск и выбор основного репозитория
В `onboarding_screen.dart` после успешного логина добавь:

```dart
final firstRepo = repos.first; // или из диалога выбора
await LocalStorageService().saveDefaultRepo(firstRepo.fullName);
ref.read(mainRepoProvider.notifier).state = firstRepo.fullName;
firstRepo.isMain = true;
firstRepo.isPinned = true;
```

### 9. Запуск миграции
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### 10. Что ты получишь после выполнения
- Полностью Riverpod-приложение (библиотека больше не использует `setState`).
- Свайп влево → чип «пин» + репозиторий на главном экране.
- Свайп вправо → открепление (кроме main).
- Один основной репозиторий всегда виден.
- Всё сохраняется между запусками.

Готово! Теперь проект соответствует современным стандартам Flutter + Riverpod 3.
