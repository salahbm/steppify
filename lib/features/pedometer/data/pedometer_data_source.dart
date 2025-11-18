import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class PedometerDataSource {
  Stream<int> get stepStream;
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<bool> requestPermission();
  Future<bool> toggleBackgroundUpdates(bool enable);

  void dispose();
}

class PedometerDataSourceImpl implements PedometerDataSource {
  PedometerDataSourceImpl();

  final StreamController<int> _stepController =
      StreamController<int>.broadcast();
  StreamSubscription<StepCount>? _stepSubscription;
  bool _isTracking = false;
  bool _backgroundEnabled = false;

  @override
  Stream<int> get stepStream => _stepController.stream;

  @override
  Future<void> startTracking() async {
    if (_isTracking) return;

    final granted = await requestPermission();
    if (!granted) {
      _stepController.addError('Permission not granted');
      return;
    }

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) {
          _stepController.add(event.steps);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Pedometer error: $error');
          _stepController.addError(error);
        },
        cancelOnError: false,
      );
      _isTracking = true;
    } catch (error, stackTrace) {
      debugPrint('Failed to start tracking: $error');
      _stepController.addError(error);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> stopTracking() async {
    await _stepSubscription?.cancel();
    _stepSubscription = null;
    _isTracking = false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    final Permission permission = Platform.isAndroid
        ? Permission.activityRecognition
        : Permission.sensors;

    final status = await permission.status;
    if (status.isGranted) return true;

    final result = await permission.request();
    return result.isGranted;
  }

  @override
  Future<bool> toggleBackgroundUpdates(bool enable) async {
    if (enable == _backgroundEnabled) return _backgroundEnabled;

    if (!Platform.isAndroid) {
      _backgroundEnabled = enable;
      return _backgroundEnabled;
    }

    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Steppify is tracking your steps',
      notificationText: 'Tap to return to the app.',
      notificationImportance: AndroidNotificationImportance.low,
      enableWifiLock: false,
    );

    if (enable) {
      final initialized =
          await FlutterBackground.initialize(androidConfig: androidConfig);
      if (!initialized) return false;

      final success = await FlutterBackground.enableBackgroundExecution();
      _backgroundEnabled = success;
      return success;
    } else {
      await FlutterBackground.disableBackgroundExecution();
      _backgroundEnabled = false;
      return true;
    }
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _stepController.close();
  }
}
