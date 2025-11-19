import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';

class LiveActivityService {
  static const platform = MethodChannel('step_activity_channel');

  //only if you will test via API
  static const listenerChannel = EventChannel('step_activity_channel');
  //only if you will test via API
  StreamSubscription? eventSubscription;
  //only if you will test via API
  Future<void> listener() async {
    eventSubscription = listenerChannel.receiveBroadcastStream().listen((
      event,
    ) async {
      switch (event['eventType']) {
        case 'pushToStartToken':
          dynamic tokenValue = event['value'];
          log("pushToStartToken -> $tokenValue");
          break;
        case 'pushToUpdateToken':
          dynamic tokenValue = event['value'];

          log("pushToUpdateToken -> $tokenValue");
          break;
      }
    });
  }

  //only if you will test via API
  static Future<void> requestPushNotificationPermission() async {
    try {
      await platform.invokeMethod("requestForNotificationPermission");
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  //only if you will test via API
  static Future<void> registerDevice() async {
    try {
      await platform.invokeMethod("registerDevice");
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  /// Start a new Live Activity with the given data
  Future<void> startLiveActivity({required StepLiveActivityModel data}) async {
    try {
      await platform.invokeMethod('startActivity', data);
      log('Live Activity started successfully');
    } on PlatformException catch (e) {
      log("Failed to start live activity: '${e.message}'.");
    }
  }

  /// Update the existing Live Activity with new data
  Future<void> updateLiveActivity({required StepLiveActivityModel data}) async {
    try {
      await platform.invokeMethod('updateActivity', data);
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
