# GitHub OAuth Setup Guide

**Problem:** "Login with GitHub" button doesn't work

**Cause:** GitHub OAuth Client ID is not configured

---

## Quick Fix (2 Options)

### Option 1: Setup GitHub OAuth (Recommended)

#### Step 1: Create GitHub OAuth App

1. Go to https://github.com/settings/developers
2. Click **"New OAuth App"** (or use an existing one)
3. Fill in the details:
   - **Application name:** `GitDoIt` (or your choice)
   - **Homepage URL:** `https://github.com/berlogabob/flutter-github-issues-todo`
   - **Authorization callback URL:** `https://github.com/login/oauth/access_token`
   - **Application description:** `Minimalist GitHub Issues & Projects TODO Manager`
4. Click **"Register application"**

#### Step 2: Copy Client ID

1. After registration, you'll see your **Client ID**
2. Copy it (looks like: `Iv1.a1b2c3d4e5f6g7h8`)

#### Step 3: Configure GitDoIt

**Method A: Using .env file (Development)**

```bash
# 1. Copy example file
cp .env.example .env

# 2. Edit .env file
nano .env  # or use your favorite editor

# 3. Add your Client ID
GITHUB_CLIENT_ID=Iv1.a1b2c3d4e5f6g7h8

# 4. Run with environment variable
flutter run --dart-define=GITHUB_CLIENT_ID=Iv1.a1b2c3d4e5f6g7h8
```

**Method B: Command line (Quick test)**

```bash
flutter run --dart-define=GITHUB_CLIENT_ID=YOUR_CLIENT_ID_HERE
```

Replace `YOUR_CLIENT_ID_HERE` with your actual Client ID.

#### Step 4: Test Login

1. Run the app
2. Click "Login with GitHub"
3. A dialog appears with a code
4. Click "Open GitHub" or visit the URL manually
5. Enter the code on GitHub
6. Authorize GitDoIt
7. App will automatically log you in

---

### Option 2: Use Personal Access Token (Alternative)

If you don't want to setup OAuth, you can use a Personal Access Token instead.

#### Step 1: Generate PAT

1. Go to https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Give it a name: `GitDoIt`
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `read:org` (Read org membership)
   - ✅ `write:org` (Read and write org membership)
   - ✅ `project` (Read and write projects)
5. Click **"Generate token"**
6. **Copy the token immediately** (you won't see it again!)

#### Step 2: Use PAT in App

1. Open GitDoIt app
2. Click **"Use Personal Access Token"** (or "Use PAT")
3. Paste your token
4. Click **"Login"**
5. Done!

---

## Common Issues

### "GITHUB_CLIENT_ID environment variable is not set"

**Solution:** You need to pass the Client ID when running the app:

```bash
flutter run --dart-define=GITHUB_CLIENT_ID=your_actual_client_id
```

Or create `.env` file with your Client ID.

### "Invalid client_id"

**Possible causes:**
1. Client ID is incorrect (check for typos)
2. Client ID has extra spaces
3. OAuth App is deleted/disabled

**Solution:**
- Go to https://github.com/settings/developers
- Find your OAuth App
- Copy the Client ID again
- Update `.env` or command line

### "Redirect URI mismatch"

**Cause:** Callback URL doesn't match

**Solution:**
- In GitHub OAuth App settings, set:
  - **Authorization callback URL:** `https://github.com/login/oauth/access_token`

### "Access denied" or "403 Forbidden"

**Cause:** Token permissions are insufficient

**Solution:**
- Regenerate PAT with correct scopes:
  - `repo` (required)
  - `read:org` (recommended)
  - `write:org` (recommended)
  - `project` (for project boards)

---

## Android Release Build

For release builds, you need to configure Client ID in build files:

### Android

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        manifestPlaceholders = [
            GITHUB_CLIENT_ID: "Iv1.a1b2c3d4e5f6g7h8"
        ]
    }
}
```

### iOS

Edit `ios/Runner/xcconfigs/Release.xcconfig`:

```
GITHUB_CLIENT_ID = Iv1.a1b2c3d4e5f6g7h8
```

---

## Security Notes

⚠️ **NEVER commit `.env` file to version control!**

The `.env` file is in `.gitignore` by default.

For production:
- Use environment variables
- Use secure configuration management
- Don't hardcode credentials in source code

---

## Need Help?

1. Check `.env.example` for format
2. Verify OAuth App is active
3. Test with a simple curl request:

```bash
curl -X POST https://github.com/login/device/code \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=YOUR_CLIENT_ID&scope=repo"
```

Should return JSON with `device_code`, `user_code`, etc.

---

## Quick Reference

| Item | Value |
|------|-------|
| OAuth App URL | https://github.com/settings/developers |
| PAT URL | https://github.com/settings/tokens |
| Callback URL | `https://github.com/login/oauth/access_token` |
| Required Scopes | `repo`, `user` |
| Run Command | `flutter run --dart-define=GITHUB_CLIENT_ID=xxx` |

---

**Still having issues?** Create an issue on GitHub with error details.
