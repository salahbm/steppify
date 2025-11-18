# Steppify

Steppify is a Flutter-based mobile application designed to monitor steps and provide user-centered settings such as theming, localization, and permissions (e.g. location tracking). The app supports dark mode, multi-language UI (currently English and Korean), and reactive state management using Riverpod.

---

## Features

- Light and Dark Mode
- English and Korean Localization (`intl_en.arb`, `intl_ko.arb`)
- Dynamic Theme Switching
- Location Tracking Toggle
- Structured Routing
- Dependency Injection with `riverpod` and `get_it`

---

## Tech Stack

- Flutter 3.x
- Riverpod (State Management)
- GetIt (Dependency Injection)
- Flutter Localizations
- Kotlin/Swift (platform-specific code)

---

## Project Structure Overview

```text
lib
├── config                  # Global configuration
│   ├── app_localizations.dart  # Localization setup
│   ├── app_routes.dart         # App-wide route definitions
│   ├── app_theme.dart          # Light/Dark theme definitions
│   ├── config.dart             # Barrel file exporting config modules
│   └── environment.dart        # Environment-specific variables
├── core                    # Core/shared functionalities
│   ├── constants               # App-wide constants
│   ├── error                   # Custom error classes/helpers
│   ├── network                 # API/network handling
│   ├── usecases                # Reusable domain logic
│   ├── utils                   # Utility functions/classes
│   └── widgets                 # Common/shared UI components
├── features                # Feature-based modules
│   ├── home                    # Home screen feature
│   ├── not_found               # 404/route not found feature
│   └── settings                # Settings screen feature
├── injection_container.dart # Dependency Injection setup (with Riverpod & GetIt)
├── l10n                    # Localization files (.arb format)
└── main.dart               # Application entry point

```

---

## Getting Started

### Prerequisites

- Flutter SDK installed: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- Dart extension enabled
- Supported platforms enabled (Android, iOS, Web, etc.)

### Install Dependencies

```sh
flutter pub get
```

### Run the App

#### For Android:

```sh
flutter run -d android
```

#### For iOS:

Make sure CocoaPods is installed:

```sh
sudo gem install cocoapods
```

Then:

```sh
flutter run -d ios
```

#### For Web:

```sh
flutter run -d chrome
```

#### For Desktop:

Enable desktop targets: [https://docs.flutter.dev/desktop](https://docs.flutter.dev/desktop)

---

## Real Step Tracking Integration

Steppify now ships with a production-ready pedometer stack powered by the
[`pedometer`](https://pub.dev/packages/pedometer),
[`permission_handler`](https://pub.dev/packages/permission_handler), and
[`flutter_background`](https://pub.dev/packages/flutter_background) plugins.

### Dependencies

`pubspec.yaml`

```yaml
dependencies:
  pedometer: ^4.0.1
  permission_handler: ^11.3.1
  flutter_background: ^1.2.0
```

Fetch the packages with `flutter pub get`.

### Android configuration

`android/app/src/main/AndroidManifest.xml`

```xml
<manifest ...>
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <application ...>
        ...
    </application>
</manifest>
```

These permissions allow the app to access the motion sensors and keep the
background service alive while step tracking.

### iOS configuration

`ios/Runner/Info.plist`

```xml
<key>NSMotionUsageDescription</key>
<string>Steppify uses your motion data to count steps and update goals.</string>
```

Background step updates are handled by CoreMotion, so no extra switches are
required beyond the privacy description.

### Data layer wiring

- `PedometerDataSourceImpl` (in `lib/features/pedometer/data`) connects to the
  native pedometer stream, manages permissions, and optionally enables Android
  foreground services for background tracking.
- `PedometerRepositoryImpl` exposes this stream to the domain layer.
- The `pedometerProvider` file registers the data source and repository with
  Riverpod so the existing controller/UI continue to function without changes.

### Bonus ideas

- Persist the step totals to a backend (e.g., Supabase/Firebase) on interval by
  listening to the same stream in a background isolate.
- Use `flutter_local_notifications` with Riverpod listeners to schedule a
  congratulatory notification whenever `PedometerEntity.totalSteps` meets or
  exceeds the user’s daily goal.

---

## Folder Descriptions

- **android**, **ios**, **macos**, **linux**, **windows**: Platform-specific code required to run the Flutter app on different platforms.
- **web**: For running the app on web browsers.
- **test**: Contains automated widget test templates.
- **build**: Generated artifacts by the Flutter compiler.
- **l10n**: Contains localization files (`.arb`). Used to provide translations for UI text.
- **analysis_options.yaml**: Flutter lint configuration.
- **pubspec.yaml**: Project dependencies and Flutter settings.

---

## Localization Info

Localization files are found in `lib/l10n/`:

- `intl_en.arb`: English translations
- `intl_ko.arb`: Korean translations

### Adding a New Language

Add a new `.arb` file in `lib/l10n/` and include it in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - lib/l10n/intl_es.arb
```

Run:

```sh
flutter gen-l10n
```

---

## Development Commands

- Format Code:

```sh
flutter format .
```

- Check for Errors:

```sh
flutter analyze
```

- Clear the build:

```sh
flutter clean
```

---

## License

MIT License. See `LICENSE` file for details.
