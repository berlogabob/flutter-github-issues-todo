# Environment Configuration Setup

## Proper Way to Configure GitHub OAuth

GitDoIt now uses **flutter_dotenv** for proper environment variable management.

---

## How It Works

The app loads environment variables in this order:

1. **`.env`** (in project root) - Your personal configuration
2. **`.env.default`** (bundled with app) - Fallback with placeholder values

---

## Setup Instructions

### Step 1: Create Your .env File

```bash
# Copy the default file
cp .env.default .env
```

### Step 2: Get Your GitHub OAuth Client ID

1. Go to https://github.com/settings/developers
2. Click **"New OAuth App"**
3. Fill in:
   ```
   Application name: GitDoIt
   Homepage URL: https://github.com/berlogabob/flutter-github-issues-todo
   Authorization callback URL: https://github.com/login/oauth/access_token
   ```
4. Click **"Register application"**
5. Copy your **Client ID** (starts with `Iv1.`)

### Step 3: Configure .env

Edit `.env` file:

```bash
nano .env
```

Replace:
```
GITHUB_CLIENT_ID=your_client_id_here
```

With your actual Client ID:
```
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
```

Save and exit (Ctrl+O, Enter, Ctrl+X).

### Step 4: Run the App

```bash
flutter run
```

That's it! The app automatically loads `.env` on startup.

---

## How It Works (Technical Details)

### In Development

```
Project Root/
├── .env              ← Your personal config (NOT committed to git)
├── .env.default      ← Template with placeholders (committed to git)
└── lib/
    └── main.dart     ← Loads .env automatically
```

**Loading Order:**
1. Try to load `.env` from root directory
2. If not found, load `.env.default` (bundled in assets)
3. OAuth service reads from `dotenv.env['GITHUB_CLIENT_ID']`

### In Production (Release Build)

The `.env.default` file is bundled with the app as a fallback.

**For Release Builds:**

You have two options:

#### Option A: Bundle .env with Release

```bash
# Copy your .env to build assets
cp .env build/flutter_assets/.env
```

#### Option B: Use Build-Time Variables

```bash
# Android
flutter build apk --dart-define=GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx

# iOS
flutter build ios --dart-define=GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
```

---

## File Structure

### .env (Your Personal File)

```env
# GitHub OAuth Configuration
# This file is NOT committed to version control

GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
```

### .env.default (Template)

```env
# GitHub OAuth Configuration
# This is a TEMPLATE - replace with your actual values

GITHUB_CLIENT_ID=your_client_id_here
```

### .gitignore

```gitignore
# Environment variables - NEVER commit these
.env
```

---

## Troubleshooting

### App says "GITHUB_CLIENT_ID is not configured"

**Check if .env exists:**
```bash
ls -la .env
```

**Check if GITHUB_CLIENT_ID is set:**
```bash
cat .env | grep GITHUB_CLIENT_ID
```

**Should show:**
```
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
```

**If it shows `your_client_id_here`:**
- Edit `.env` and add your real Client ID
- Restart the app

### OAuth Still Doesn't Work

**Check logs:**
```bash
flutter run --verbose 2>&1 | grep "Loaded .env"
```

**Should show:**
```
✅ Loaded .env from root directory
```

**If it shows:**
```
⚠️ .env not found in root, trying bundled default...
✅ Loaded .env.default (bundled)
```

This means your `.env` file is missing or in the wrong location.

---

## Security Notes

### ✅ DO:
- Keep `.env` in your project root
- Add your real Client ID
- Restart app after changes
- Use different Client IDs for dev/prod

### ❌ DON'T:
- Commit `.env` to version control
- Share your Client ID publicly
- Use the same Client ID for multiple apps
- Hardcode Client ID in source code

---

## Summary

**Development:**
1. Create `.env` with your Client ID
2. Run `flutter run`
3. App loads `.env` automatically

**Production:**
1. Bundle `.env` with release build
2. Or use `--dart-define` at build time
3. App uses bundled config

**That's the proper, production-ready way!** ✅

---

For detailed OAuth setup instructions, see `OAUTH_SETUP.md`.
