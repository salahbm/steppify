import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';

class LiveActivityService {
  static const platform = MethodChannel('step_activity_channel');

  // only for API testing
  static Future<void> registerDevice() async {
    try {
      await platform.invokeMethod("registerDevice");
    } on PlatformException catch (e) {
      throw PlatformException(code: e.code, message: e.message);
    }
  }

  /// Request permissions needed for step counting + Live Activities
  Future<bool> requestPermissions() async {
    try {
      // On iOS, we only need notification permission for Live Activities
      // Activity recognition is handled separately by CoreMotion
      final notification = await Permission.notification.request();
      log('Notification permission status: $notification');

      // For iOS, notification permission is sufficient for Live Activities
      if (notification.isGranted || notification.isLimited) {
        log('✅ Permissions granted');
        return true;
      }

      log('❌ Notification permission denied: $notification');
      return false;
    } catch (e) {
      log('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Start a new Live Activity with the given data
  Future<void> startLiveActivity({required StepLiveActivityModel data}) async {
    try {
      log(
        '🔵 startLiveActivity called with: today=${data.todaySteps}, open=${data.sinceOpenSteps}, boot=${data.sinceBootSteps}, status=${data.status}',
      );

      final args = {
        'today': data.todaySteps,
        'open': data.sinceOpenSteps,
        'boot': data.sinceBootSteps,
        'status': data.status,
      };

      log('🚀 Calling native startActivity with args: $args');
      await platform.invokeMethod('startActivity', args);
      log('✅ Live Activity started successfully');
    } on PlatformException catch (e) {
      log("❌ Failed to start live activity: '${e.code}' - '${e.message}'");
      rethrow;
    } catch (e) {
      log("❌ Unexpected error starting live activity: $e");
      rethrow;
    }
  }

  /// Update the existing Live Activity
  Future<void> updateLiveActivity({required StepLiveActivityModel data}) async {
    try {
      final args = {
        'today': data.todaySteps,
        'open': data.sinceOpenSteps,
        'boot': data.sinceBootSteps,
        'status': data.status,
      };
      await platform.invokeMethod('updateActivity', args);
    } on PlatformException catch (e) {
      log("Failed to update live activity: '${e.message}'.");
    }
  }

  /// End the current Live Activity
  Future<void> endLiveActivity() async {
    try {
      await platform.invokeMethod('endActivity');
      log('Live Activity ended successfully');
    } on PlatformException catch (e) {
      log("Failed to end live activity: '${e.message}'.");
    }
  }
}
