import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';

/// Contract for providing step-count updates from the platform.
abstract class PedometerDataSource {
  Stream<int> get stepCountStream;

  Future<void> startListening();

  Future<void> stopListening();

  Future<bool> requestPermission();

  Future<bool> enableBackgroundUpdates(bool enable);
}

/// Default implementation that relies on the `pedometer` plugin.
class PedometerDataSourceImpl implements PedometerDataSource {
  PedometerDataSourceImpl();

  StreamSubscription<StepCount>? _subscription;
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();

  @override
  Stream<int> get stepCountStream => _stepController.stream;

  @override
  Future<void> startListening() async {
    await _subscription?.cancel();
    _subscription = Pedometer.stepCountStream.listen(
      (event) => _stepController.add(event.steps),
      onError: (error) => _stepController.addError(error),
      cancelOnError: false,
    );
  }

  @override
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<bool> requestPermission() async {
    // TODO(dev): Integrate permission_handler or a custom channel to request
    // ACTIVITY_RECOGNITION on Android and Motion & Fitness / HealthKit on iOS.
    if (Platform.isIOS) {
      // Placeholder for HealthKit/Motion Fitness request.
      return true;
    }
    if (Platform.isAndroid) {
      // Placeholder for ACTIVITY_RECOGNITION request.
      return true;
    }
    return true;
  }

  @override
  Future<bool> enableBackgroundUpdates(bool enable) async {
    // TODO(dev): Wire up background services/isolates to keep listening even
    // when the application is terminated.
    return enable;
  }

  void dispose() {
    _subscription?.cancel();
    _stepController.close();
  }
}
