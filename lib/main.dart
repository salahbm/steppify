import 'package:steppify/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:steppify/features/step_tracker/data/live_activity_permission.dart';
import 'package:steppify/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  runApp(const ProviderScope(child: SteppifyApp()));

  // Call permission functions after the UI is ready
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await LiveActivityService.requestPushNotificationPermission();
    await LiveActivityService.registerDevice();
    await LiveActivityService().listener();
  });
}
