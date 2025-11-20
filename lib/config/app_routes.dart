import 'package:flutter/material.dart';
import 'package:steppify/features/home/home.dart';
import 'package:steppify/features/settings/settings.dart';
import 'package:steppify/features/not_found/not_found.dart';
import 'package:steppify/features/step_tracker/step_tracker.dart';

class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const notFound = '/not-found';
  static const stepTrackerIOS = '/step-tracker-ios';
  static const stepTrackerAndroid = '/step-tracker-android';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.notFound:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
      case AppRoutes.stepTrackerAndroid:
        return MaterialPageRoute(
          builder: (_) => const StepTrackerAndroidScreen(),
        );
      case AppRoutes.stepTrackerIOS:
        return MaterialPageRoute(builder: (_) => const StepTrackerIOSScreen());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }
}
