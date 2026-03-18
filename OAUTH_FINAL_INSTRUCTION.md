# 🔐 GitHub OAuth - Финальная Инструкция

## Проблема

Приложение **почти работает**! GitHub показывает страницу авторизации, но не может автоматически вернуть вас в приложение.

**Причина:** Android/iOS требует дополнительной настройки для обработки redirect URL `gitdoit://oauth2redirect`.

---

## ✅ Решение №1: Использовать Personal Access Token (СЕЙЧАС)

Это **работает сразу** без настройки OAuth redirect.

### Шаг 1: Создайте Personal Access Token

1. Откройте: https://github.com/settings/tokens
2. Нажмите **"Generate new token (classic)"**
3. Заполните:
   - **Note:** `GitDoIt App`
   - **Expiration:** `No expiration` (или выберите срок)
4. Выберите **scopes**:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `read:user` (Read user profile data)
   - ✅ `user:email` (Access user email addresses)
   - ✅ `read:org` (Read org membership)
5. Нажмите **"Generate token"**
6. **Скопируйте токен** (начинается с `ghp_...`)

### Шаг 2: Войдите в приложение

1. Откройте GitDoIt app
2. Нажмите **"Use Personal Access Token"**
3. Вставьте токен
4. Нажмите **"Login"**
5. **Готово!** ✅

---

## 🔧 Решение №2: Настроить OAuth Redirect (ДЛЯ РАЗРАБОТЧИКА)

Если хотите настроить правильный OAuth flow:

### Android: Настройка App Links

**Файл:** `android/app/src/main/AndroidManifest.xml`

Добавьте intent filter для обработки redirect:

```xml
<activity android:name=".MainActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- OAuth Redirect Handler -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="gitdoit" android:host="oauth2redirect" />
    </intent-filter>
</activity>
```

### iOS: Настройка URL Schemes

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

### Пересоберите приложение

```bash
flutter clean
flutter pub get
flutter run -d 000251565001005
```

---

## 📝 Что Работает Сейчас

✅ Приложение строится  
✅ Кнопка "Login with GitHub" работает  
✅ Браузер открывается  
✅ GitHub показывает страницу авторизации  
❌ Redirect обратно в приложение не работает (нужна настройка)

---

## 🎯 Рекомендация

**Используйте Personal Access Token** - это:
- ✅ Работает сразу
- ✅ Безопасно (токен хранится в secure storage)
- ✅ Не требует настройки OAuth redirect
- ✅ GitHub рекомендует для личных приложений

**OAuth redirect** настраивайте когда приложение будет готово к production.

---

## 📞 Проблемы?

### "Invalid token"
- Убедитесь что токен начинается с `ghp_`
- Проверьте что выбраны все required scopes
- Попробуйте создать новый токен

### "Access denied"
- Проверьте scopes у токена
- Убедитесь что токен не истек

### Браузер не открывается
- Проверьте что интернет работает
- Попробуйте на физическом устройстве (не эмулятор)

---

**Используйте Personal Access Token для быстрой работы!** 🚀
