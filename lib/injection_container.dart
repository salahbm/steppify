import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'config/environment.dart';

/// Environment Configuration Provider
final environmentProvider = Provider<EnvironmentConfig>(
  (ref) => const EnvironmentConfig(),
);

/// Dynamically derived API base URL Provider
final apiBaseUrlProvider = Provider<String>((ref) {
  final environment = ref.read(environmentProvider);
  return environment.isProduction
      ? 'https://api.steppify.app'
      : 'https://api.dev.steppify.app';
});

/// Theme Mode Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(),
);

/// Locale Provider for i18n
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void updateLocale(Locale locale) => state = locale;
}

/// Location tracking toggle Provider
final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, bool>(
      (ref) => LocationTrackingNotifier(),
    );

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false); // false = light theme

  void toggleTheme() => state = !state;
}

class LocationTrackingNotifier extends StateNotifier<bool> {
  LocationTrackingNotifier() : super(false); // default disabled

  void toggle() => state = !state;
}

/// For future asynchronous initialization
Future<void> configureDependencies() async {
  // Keep this for remote setup or initialization logic
}
