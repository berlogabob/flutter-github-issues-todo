# GitDoIt

Offline-first Flutter app for managing GitHub Issues as TODOs, with Projects V2 support.

## What it does

- Browse repositories and issues
- Create/edit/update issues with Markdown
- Manage labels, assignees, and project defaults
- Work offline with local queue + later sync
- Background sync via `workmanager`
- Search/filter across repositories and issues

## Modernized architecture

- Navigation: `go_router` (`lib/app_router.dart`)
- State: `flutter_riverpod`
- Network: `dio` (+ existing integrations)
- Storage: `hive_ce` / `hive_ce_flutter`
- Secure token storage: `flutter_secure_storage`
- Offline pipeline: cache + pending operations + sync service

## Setup

### Prerequisites

- Flutter SDK `>=3.11.0`
- GitHub Personal Access Token with repo access

### Install

```bash
flutter pub get
```

### Environment

The app tries `.env` first, then `.env.default`.

Example:

```env
GITHUB_CLIENT_ID=your_client_id
```

## Run

```bash
flutter run
```

## Test & analyze

```bash
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
```

## Release

GitDoIt v1.0.0 targets Android and Web. iOS/TestFlight is not part of
the v1.0.0 release gate.

### Build locally

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release
flutter build appbundle --release
flutter build web --release --base-href=/flutter-github-issues-todo/
```

Android artifacts are written to:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

### Publish v1.0.0

1. Ensure `pubspec.yaml` is set to `version: 1.0.0+135`.
2. Merge the release branch into `main`.
3. Create an annotated tag from the merged `main` commit:

   ```bash
   git tag -a v1.0.0 -m "GitDoIt v1.0.0"
   git push origin main
   git push origin v1.0.0
   ```

4. The tag push triggers the release artifact CI job.
5. Create the GitHub Release `v1.0.0` using
   `RELEASE_NOTES_v1.0.0.md` and attach the release APK/AAB.

The Makefile keeps version changes separate from builds. Use
`make version-increment` only when intentionally bumping the build number;
`make build-android`, `make build-web`, and `make release-artifacts` do not
modify tracked release metadata.

## Key folders

```text
lib/
  app_router.dart
  models/
  providers/
  screens/
  services/
  widgets/
test/
```

## Version

`1.0.0+135`

## License

See `LICENSE`.
