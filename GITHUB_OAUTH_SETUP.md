# 🔐 GitHub OAuth Настройка для Разработчика

## ⚠️ ВАЖНО: Прочитайте ПЕРЕД запуском приложения

Приложение использует **OAuth 2.0 + PKCE** для аутентификации через GitHub.

**Конечный пользователь НЕ должен ничего настраивать!**

Просто нажмите **"Login with GitHub"** → браузер откроется → войдите в GitHub → готово! ✅

---

## 🛠️ Настройка для Разработчика (ВЫ)

### **Шаг 1: Создайте GitHub OAuth App**

1. Откройте: https://github.com/settings/developers
2. Нажмите **"New OAuth App"**
3. Заполните форму:

   ```
   Application name: GitDoIt
   Homepage URL: https://github.com/berlogabob/flutter-github-issues-todo
   Authorization callback URL: gitdoit://oauth2redirect
   Application description: Minimalist GitHub Issues & Projects TODO Manager
   ```

4. Нажмите **"Register application"**
5. **Скопируйте Client ID** (выглядит как: `Iv1.xxxxxxxxxxxx`)

---

### **Шаг 2: Вставьте Client ID в код**

Откройте файл:
```
lib/services/github_auth_service.dart
```

Найдите строку (примерно строка 36):
```dart
static const String _clientId = 'Iv1.YOUR_CLIENT_ID_HERE'; // ← ВСТАВЬТЕ СЮДА ВАШ CLIENT ID
```

Замените на ВАШ Client ID:
```dart
static const String _clientId = 'Iv1.abcdef123456789'; // Ваш реальный Client ID
```

**Сохраните файл.**

---

### **Шаг 3: Пересоберите приложение**

```bash
# Очистите и постройте заново
flutter clean
flutter pub get
flutter run -d 000251565001005
```

---

### **Шаг 4: Тестирование**

1. Запустите приложение
2. Нажмите **"Login with GitHub"**
3. **Браузер откроется автоматически** ✅
4. Войдите в GitHub (если не вошли)
5. Нажмите **"Authorize GitDoIt"**
6. **Приложение откроется автоматически** ✅
7. **Вы вошли!** ✅

---

## 📱 Как это работает для пользователя

```
1. Пользователь нажимает "Login with GitHub"
   ↓
2. Открывается браузер (Chrome/Safari)
   ↓
3. Пользователь входит в GitHub
   ↓
4. Пользователь нажимает "Authorize"
   ↓
5. GitHub перенаправляет обратно в приложение
   ↓
6. Пользователь авторизован! ✅
```

**Никаких Client ID, никаких кодов - просто кнопка и браузер!**

---

## 🔧 Конфигурация

### Android

**Файл:** `android/app/src/main/AndroidManifest.xml`

```xml
<activity
    android:name="net.openid.appauth.RedirectUriReceiverActivity"
    android:exported="true"
    android:launchMode="singleTask">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="gitdoit"
            android:host="oauth2redirect" />
    </intent-filter>
</activity>
```

### iOS

**Файл:** `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>gitdoit</string>
    </array>
  </dict>
</array>
```

---

## 📝 Client ID уже вшит?

Если вы видите ошибку:
```
GitHub OAuth Client ID is not configured.
Developer needs to:
1. Go to https://github.com/settings/developers
2. Create OAuth App for GitDoIt
3. Add Client ID to github_auth_service.dart
4. Rebuild app
```

Это значит, что **Client ID еще не вставлен в код**.

**Откройте:** `lib/services/github_auth_service.dart`  
**Найдите:** строка с `'Iv1.YOUR_CLIENT_ID_HERE'`  
**Замените:** на ваш реальный Client ID  
**Пересоберите:** `flutter clean && flutter pub get && flutter run`

---

## 🎯 Итог

| Кто | Что делает |
|-----|------------|
| **ВЫ (разработчик)** | Создаете OAuth App → вшиваете Client ID → собираете приложение |
| **Пользователь** | Нажимает кнопку → входит в браузере → готово! |

**Пользователь НИКОГДА не видит и не вводит Client ID!**

---

## 📞 Проблемы?

### Браузер не открывается
- Проверьте, что Client ID вставлен в `github_auth_service.dart`
- Проверьте, что AndroidManifest.xml настроен
- Проверьте, что Info.plist настроен (для iOS)

### "Client ID is not configured"
- Откройте `lib/services/github_auth_service.dart`
- Убедитесь, что `_clientId` не равен `'Iv1.YOUR_CLIENT_ID_HERE'`
- Пересоберите приложение

### GitHub показывает ошибку
- Проверьте, что callback URL в GitHub OAuth App: `gitdoit://oauth2redirect`
- Проверьте, что scheme в AndroidManifest.xml: `gitdoit`
- Проверьте, что scheme в Info.plist: `gitdoit`

---

**Готово! Теперь пользователи могут входить через GitHub одной кнопкой!** 🚀
