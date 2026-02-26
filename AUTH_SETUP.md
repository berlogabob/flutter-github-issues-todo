# 🔐 НАСТРОЙКА АУТЕНТИФИКАЦИИ

## Проблемы и решения

### ✅ ИСПРАВЛЕНО: Authorization Header

**Проблема:** Login показывал "network error" и username = null

**Причина:** Неправильный заголовок авторизации

**Было:**
```dart
'Authorization': 'Bearer $token'  // ❌ Не работает для GitHub PAT
```

**Стало:**
```dart
'Authorization': 'token $token'  // ✅ Правильно для GitHub PAT
```

**Файл:** `lib/providers/auth_provider.dart` (строка 182)

---

## ⚠️ ТРЕБУЕТ НАСТРОЙКИ: OAuth Client ID

### GitHub OAuth Application Setup

1. **Создайте OAuth приложение на GitHub:**
   - Перейдите в https://github.com/settings/developers
   - Нажмите "New OAuth App"
   - Заполните форму:
     - **Application name:** `GitDoIt`
     - **Homepage URL:** `https://github.com/berlogabob/flutter-github-issues-todo`
     - **Authorization callback URL:** `gitdoit://auth/callback`

2. **Получите Client ID и Client Secret:**
   - После создания скопируйте **Client ID**
   - Нажмите "Generate a new client secret" и скопируйте **Client Secret**

3. **Обновите `lib/services/github_service.dart`:**

```dart
// Строки 30-31
static const String oauthClientId = 'YOUR_ACTUAL_CLIENT_ID';  // Вставьте Client ID
static const String oauthClientSecret = 'YOUR_ACTUAL_CLIENT_SECRET';  // Вставьте Client Secret
```

4. **Пересоберите приложение:**
```bash
cd gitdoit
flutter clean
flutter pub get
flutter run
```

---

## 🔧 Personal Access Token (PAT) Setup

### Создание токена на GitHub

1. Перейдите в https://github.com/settings/tokens
2. Нажмите "Generate new token (classic)"
3. Выберите scope'ы:
   - ✅ `repo` — Полный доступ к репозиториям
   - ✅ `user` — Доступ к информации о пользователе
4. Нажмите "Generate token"
5. **Скопируйте токен** (начинается с `ghp_`)

### Использование в приложении

1. Откройте приложение
2. Перейдите в **Settings** → **GitHub Account**
3. Нажмите **Login**
4. Введите токен в формате: `ghp_xxxxxxxxxxxx`
5. Нажмите **LOGIN**

---

## 🐛 ОТЛАДКА

### Логирование

Приложения использует подробное логирование:

```bash
# Запуск с логами
flutter run --verbose

# Фильтрация логов аутентификации
flutter logs | grep -i auth
```

### Частые ошибки

#### 1. "Invalid token"
**Причина:** Неправильный PAT  
**Решение:** Пересоздайте токен с правильными scope'ами

#### 2. "Network error"
**Причина:** Нет подключения к интернету  
**Решение:** Проверьте подключение

#### 3. "401 Unauthorized"
**Причина:** Токен отозван или истёк  
**Решение:** Создайте новый токен

#### 4. OAuth не работает
**Причина:** Не настроен OAuth Client ID  
**Решение:** Следуйте инструкции выше

---

## 📊 ТЕКУЩИЙ СТАТУС

| Компонент | Статус |
|-----------|--------|
| PAT Authentication | ✅ Работает |
| OAuth Authentication | ⚠️ Требует настройки Client ID |
| Token Storage | ✅ Secure Storage |
| Offline Mode | ✅ Работает |
| Username Display | ✅ Работает после фикса |

---

## 📝 CHANGELOG

### 2026-02-24
- ✅ Исправлен Authorization header для PAT
- ✅ Username теперь отображается после login
- ⚠️ OAuth требует настройки Client ID/Secret

---

**После настройки OAuth приложение готово к production!** 🚀
