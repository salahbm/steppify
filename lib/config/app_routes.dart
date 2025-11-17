import 'package:flutter/material.dart';
import '../features/home/home.dart';
import '../features/settings/settings.dart';
import '../features/not_found/not_found.dart';

class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const notFound = '/not-found';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.notFound:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }
}
