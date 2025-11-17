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
