# Environment configuration

Backend configuration is centralized in `AppEnvironment`.

The application can run with the current Firebase defaults, while reviewers or future deployments can override them without editing feature code.

## Supported Dart defines

```bash
flutter run \
  --dart-define=FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com \
  --dart-define=FIREBASE_WEB_API_KEY=your-web-api-key
```

Production CI/release builds should provide environment-specific values rather than scattering endpoints through source files.

## Security note

A Firebase Web API key identifies the Firebase project but is not a server secret. Access control must come from Firebase Authentication and Realtime Database Security Rules.

Actual secrets such as payment-gateway secret keys must never be bundled in the Flutter app. Those belong in a trusted server-side environment such as Firebase Cloud Functions or a separate backend.

## HTTP logging

Debug networking logs intentionally include only:

- HTTP method
- request URL with sensitive query values redacted
- response status code

Request bodies and response bodies are not logged, which avoids exposing customer addresses, phone numbers, passwords, tokens, order payloads, or payment-related data.

Networking logs are disabled in release mode.
