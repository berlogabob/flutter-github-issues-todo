# GitDoIt

Offline-first Flutter app for managing GitHub Issues as TODOs, with Projects
V2 support.

## Features

- Browse, search, create, edit, close, and reopen GitHub issues.
- Manage labels, assignees, comments, repositories, and project defaults.
- Queue mutations locally and synchronize them when connectivity returns.
- Run background sync and inspect pending operations or sync failures.
- Use GitHub OAuth Device Flow, a personal access token, or offline mode.

## Architecture

- Navigation: native Flutter named routes.
- State: Riverpod for shared UI state; local state for screen-only concerns.
- Network: Dio.
- Storage: Hive CE and `flutter_secure_storage`.
- Offline pipeline: local cache, pending-operation queue, and sync service.

## Setup

Install Flutter 3.44 or newer, then:

```bash
flutter pub get
cp .env.example .env
```

Set `GITHUB_CLIENT_ID` in `.env`. The Makefile passes it to Flutter as a
compile-time value; direct commands must do the same:

```bash
flutter run --dart-define=GITHUB_CLIENT_ID=your_client_id
```

Personal-access-token and offline modes do not require an OAuth client ID.
See `OAUTH_SETUP.md` for authentication setup.

## Quality checks

```bash
flutter analyze
flutter test
```

## Builds

Local release targets validate `.env` and pass the OAuth client ID:

```bash
make build-android
make build-web
```

Artifacts are written under `build/`. Web output is deployed from
`build/web` by GitHub Actions; generated Web files are not committed.

GitHub repository setup:

1. Set Pages source to **GitHub Actions**.
2. Add repository Actions variable `GITHUB_CLIENT_ID`.
3. Push to `main`; CI tests, builds, and deploys the Web app.

Tags matching `v*` continue to build Android release artifacts.

## Release

The current release is `1.0.0+136`. See `RELEASE_NOTES_v1.0.0.md` and
`CHANGELOG.md`.

## License

See `LICENSE`.
