# Rokto Dorkar Flutter app

The Flutter client for the [Rokto Dorkar](../README.md) blood donor network. It targets Android, iOS, and web and connects to the deployed Django REST API by default.

## Run

```bash
flutter pub get
flutter run -d chrome
```

Use a different API during development with `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1/
```

Android emulators must use `http://10.0.2.2:8000/api/v1/` to reach a backend running on the host computer.

## Check quality

```bash
flutter analyze
flutter test
```

## Build

```bash
flutter build apk --release --build-name=1.0.0 --build-number=1
flutter build web --release
```

See the root README for features, architecture, security, deployment, and environment configuration.
