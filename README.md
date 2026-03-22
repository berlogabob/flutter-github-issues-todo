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

`0.5.0+129`

## License

See `LICENSE`.
