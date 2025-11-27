import 'package:flutter/services.dart';

/// Service for Android notification management
class NotificationService {
  static const platform = MethodChannel('com.example.steppify/notification');

  /// Start the notification
  Future<bool> startNotification({
    required int todaySteps,
    required int sinceOpenSteps,
    required String status,
  }) async {
    try {
      await platform.invokeMethod('startNotification', {
        'todaySteps': todaySteps,
        'sinceOpenSteps': sinceOpenSteps,
        'status': status,
      });
      return true;
    } on PlatformException catch (e) {
      throw Exception("Notification error: ${e.message}");
    }
  }

  /// Update the notification
  Future<void> updateNotification({
    required int todaySteps,
    required int sinceOpenSteps,
    required String status,
  }) async {
    try {
      await platform.invokeMethod('updateNotification', {
        'todaySteps': todaySteps,
        'sinceOpenSteps': sinceOpenSteps,
        'status': status,
      });
    } on PlatformException catch (e) {
      throw Exception("Update notification error: ${e.message}");
    }
  }

  /// Stop the notification
  Future<void> stopNotification() async {
    try {
      await platform.invokeMethod('stopNotification');
    } on PlatformException catch (e) {
      throw Exception("Stop notification error: ${e.message}");
    }
  }
}
