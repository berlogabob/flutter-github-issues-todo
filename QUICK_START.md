# 🚀 Quick Start - Fix GitHub Login

## Problem
```
OAuth failed: Exception: GITHUB_CLIENT_ID environment variable is not set
```

## Solution (2 Steps)

### Step 1: Get Your GitHub OAuth Client ID

1. **Go to:** https://github.com/settings/developers
2. **Click:** "New OAuth App"
3. **Fill in:**
   ```
   Application name: GitDoIt
   Homepage URL: https://github.com/berlogabob/flutter-github-issues-todo
   Authorization callback URL: https://github.com/login/oauth/access_token
   ```
4. **Click:** "Register application"
5. **Copy** your Client ID (looks like: `Iv1.xxxxxxxxxxxx`)

### Step 2: Configure GitDoIt

**Edit `.env` file:**
```bash
# Open .env file
nano .env

# Replace this line:
GITHUB_CLIENT_ID=your_client_id_here

# With your actual Client ID:
GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
```

**Save and run:**
```bash
make run-with-env
```

Or manually:
```bash
flutter run --dart-define=GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx
```

---

## ✅ That's It!

Now when you click "Login with GitHub":
1. Dialog appears with code
2. Click "Open in Browser"
3. GitHub opens in browser
4. Enter code on GitHub
5. Authorize GitDoIt
6. You're logged in!

---

## 🆘 Alternative: Use Personal Access Token

Don't want to setup OAuth? Use a PAT instead:

1. **Go to:** https://github.com/settings/tokens
2. **Click:** "Generate new token (classic)"
3. **Name:** `GitDoIt`
4. **Scopes:** 
   - ✅ `repo`
   - ✅ `read:org`
   - ✅ `write:org`
   - ✅ `project`
5. **Generate** and copy token
6. **In app:** Click "Use Personal Access Token" and paste token

---

## 📝 Commands Reference

```bash
# Run with OAuth from .env file
make run-with-env

# Or manually
flutter run --dart-define=GITHUB_CLIENT_ID=Iv1.xxxxxxxxxxxx

# Validate .env file
make validate-env
```

---

## 🔍 Troubleshooting

**Still getting error?**

1. Check .env file exists:
   ```bash
   cat .env
   ```

2. Verify Client ID is set (not `your_client_id_here`)

3. Run validation:
   ```bash
   make validate-env
   ```

**Need help?** See `OAUTH_SETUP.md` for detailed guide.
