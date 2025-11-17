import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/environment.dart';

final environmentProvider = Provider<EnvironmentConfig>(
  (ref) => const EnvironmentConfig(),
);

final apiBaseUrlProvider = Provider<String>((ref) {
  final environment = ref.read(environmentProvider);
  return environment.isProduction
      ? 'https://api.steppify.app'
      : 'https://api.dev.steppify.app';
});

Future<void> configureDependencies() async {
  // Add asynchronous initialization logic here when needed.
}
