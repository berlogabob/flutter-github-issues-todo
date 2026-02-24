# 🚀 БЛОК 2: АРХИТЕКТУРА — ПЛАН

**Срок:** 2026-02-22 — 2026-02-25 (4 дня)  
**Цель:** Устранить God Classes

---

## 📋 СПРИНТЫ

### Спринт 7: IssuesProvider → 3 модуля (8 часов)

**Текущее состояние:**
- Файл: `lib/providers/issues_provider.dart`
- Строк: 1448
- Методов: 45+

**Целевое состояние:**
```
lib/providers/
├── issues_provider.dart (State only) — ~300 строк
├── issues_repository.dart (Business logic) — ~400 строк
└── issues_cache.dart (Hive caching) — ~200 строк
```

**Задачи:**
1. Выделить IssuesCache (Hive operations)
2. Выделить IssuesRepository (GitHub API calls)
3. Оставить IssuesProvider (State management)
4. Обновить импорты в screens
5. Тесты: 520/520 ✅

---

### Спринт 8: SettingsScreen → 4 экрана (6 часов)

**Текущее состояние:**
- Файл: `lib/screens/settings_screen.dart`
- Строк: 2063
- Виджетов: 30+

**Целевое состояние:**
```
lib/screens/settings/
├── settings_screen.dart (Main menu) — ~400 строк
├── account_settings_screen.dart — ~300 строк
├── repository_settings_screen.dart — ~300 строк
├── appearance_settings_screen.dart — ~300 строк
└── data_settings_screen.dart — ~300 строк
```

**Задачи:**
1. Создать 4 под-экрана
2. Вынести диалоги в отдельные виджеты
3. Обновить навигацию
4. Тесты: widget tests ✅

---

### Спринт 9: GitHubService → 3 сервиса (4 часа)

**Текущее состояние:**
- Файл: `lib/services/github_service.dart`
- Строк: 824
- Методов: 20+

**Целевое состояние:**
```
lib/services/
├── github_service.dart (Base) — ~200 строк
├── github_issues_api.dart — ~300 строк
├── github_repos_api.dart — ~200 строк
└── github_users_api.dart — ~150 строк
```

**Задачи:**
1. Выделить Issues API
2. Выделить Repositories API
3. Выделить Users API
4. Обновить импорты
5. Тесты: integration tests ✅

---

### Спринт 10: Архитектурная валидация (2 часа)

**Задачи:**
1. Проверить зависимости между модулями
2. Убедиться в отсутствии циклических зависимостей
3. Обновить архитектурную документацию
4. Тесты: 520/520 ✅

---

## 🎯 КРИТЕРИИ ЗАВЕРШЕНИЯ

| Метрика | До | После |
|---------|-----|-------|
| God Classes | 2 | 0 |
| Max строк в файле | 2063 | <600 |
| Средняя сложность | Высокая | Средняя |
| Тесты | 487/520 | 520/520 |

---

**Готовы к Спринту 7?**
