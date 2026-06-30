# GitDoIt Engineering Guide

GitDoIt is an offline-first Flutter application for GitHub Issues and
Projects V2. There is no runtime agent subsystem; automation belongs in CI or
development tooling, not in the shipped app.

## Required checks

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Run the relevant Flutter build after changing dependencies, platform code, or
startup configuration.

## Project rules

- Follow Dart naming conventions, single quotes, and trailing commas.
- Preserve offline-first behavior: mutations must persist locally before sync.
- Keep tokens in `flutter_secure_storage`; never log or commit credentials.
- Never commit `.env`, build output, `docs/`, or `graphify-out/`.
- Handle async failures where recovery or data preservation is required.
- Keep the dark theme and responsive layouts accessible.
- Reuse existing models, services, and widgets before adding abstractions.
- Do not add speculative factories, interfaces, providers, or dependencies.
- Keep serialized model shapes, Hive keys, and pending-operation formats
  backward compatible unless a migration is part of the task.

## Architecture

- `lib/models/`: persisted and API-facing data models.
- `lib/services/`: GitHub, storage, cache, sync, and platform integration.
- `lib/providers/`: Riverpod state that has active UI consumers.
- `lib/screens/`: reachable application screens.
- `lib/widgets/`: shared presentation components.

Authentication configuration is supplied at compile time:

```bash
flutter run --dart-define=GITHUB_CLIENT_ID=your_client_id
```
