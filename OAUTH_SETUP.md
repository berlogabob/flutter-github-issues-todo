# GitHub OAuth Setup

GitDoIt uses GitHub OAuth Device Flow. The OAuth client ID is public
configuration and is compiled into the app; client secrets are not used.

## Create the OAuth app

1. Open <https://github.com/settings/developers>.
2. Create or select an OAuth app and enable Device Flow.
3. Copy its client ID.

## Local development

```bash
cp .env.example .env
```

Set the value in `.env`:

```env
GITHUB_CLIENT_ID=Iv1.your_client_id
```

Use the Makefile helper:

```bash
make run-with-env
```

Or pass the value directly:

```bash
flutter run --dart-define=GITHUB_CLIENT_ID=Iv1.your_client_id
```

Release builds through `make build-android` and `make build-web` validate
`.env` and pass the same compile-time value.

## GitHub Pages

Add `GITHUB_CLIENT_ID` as a repository Actions variable. The Pages workflow
passes it to `flutter build web`; it is not a secret.

## Alternatives

Personal-access-token and offline modes remain available when no OAuth client
ID is configured. Tokens are stored with `flutter_secure_storage` and must
never be committed or logged.
