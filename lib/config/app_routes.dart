import 'package:flutter/material.dart';
import 'package:steppify/features/pedometer/pedometer.dart';
import 'package:steppify/features/home/home.dart';
import 'package:steppify/features/settings/settings.dart';
import 'package:steppify/features/not_found/not_found.dart';
import 'package:steppify/features/step_tracker/step_tracker.dart';

class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const notFound = '/not-found';
  static const pedometer = '/pedometer';
  static const stepTracker = '/step-tracker';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.notFound:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
      case AppRoutes.pedometer:
        return MaterialPageRoute(builder: (_) => const PedometerScreen());
      case AppRoutes.stepTracker:
        return MaterialPageRoute(builder: (_) => const StepTrackerScreen());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }
}
