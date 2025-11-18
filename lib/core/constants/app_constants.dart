class AppConstants {
  const AppConstants._();

  static const String appName = 'Steppify';
  static const String apiBaseUrl = 'https://api.example.com';
  static const Duration defaultTimeout = Duration(seconds: 30);
}

class StorageKeys {
  const StorageKeys._();

  static const String authToken = 'auth_token';
  static const String onboardingCompleted = 'onboarding_completed';
}
