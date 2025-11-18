import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Contract for fetching step information from the native pedometer layers.
abstract class StepsRepo {
  Stream<int> watchSteps();
  Future<int> fetchTodaySteps();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<bool> isSupported();
  void dispose();

  factory StepsRepo.instance() {
    if (Platform.isIOS) {
      return _IOSStepsRepo();
    }
    if (Platform.isAndroid) {
      return _AndroidStepsRepo();
    }
    return _UnsupportedStepsRepo();
  }
}

abstract class _PlatformStepsRepo implements StepsRepo {
  _PlatformStepsRepo({
    required String methodChannelName,
    required String eventChannelName,
  })  : _methodChannel = MethodChannel(methodChannelName),
        _eventChannel = EventChannel(eventChannelName);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final StreamController<int> _stepsController =
      StreamController<int>.broadcast();
  StreamSubscription<dynamic>? _platformSubscription;

  @override
  Stream<int> watchSteps() {
    _platformSubscription ??=
        _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      final parsedSteps = _parseStepPayload(event);
      if (parsedSteps != null) {
        _stepsController.add(parsedSteps);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('Step stream error: $error');
      _stepsController.addError(error, stackTrace);
    });

    return _stepsController.stream;
  }

  @override
  Future<int> fetchTodaySteps() async {
    try {
      final value = await _methodChannel.invokeMethod<int>('fetchTodaySteps');
      return value ?? 0;
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Failed to fetch steps: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final granted = await _methodChannel.invokeMethod<bool>('hasPermission');
      return granted ?? false;
    } on PlatformException catch (error) {
      debugPrint('Unable to determine permission state: $error');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final granted =
          await _methodChannel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } on PlatformException catch (error) {
      debugPrint('Permission request failed: $error');
      return false;
    }
  }

  @override
  Future<bool> isSupported() async {
    try {
      final supported = await _methodChannel.invokeMethod<bool>('isSupported');
      return supported ?? true;
    } on PlatformException catch (error) {
      debugPrint('Support check failed: $error');
      return false;
    }
  }

  @override
  void dispose() {
    _platformSubscription?.cancel();
    _stepsController.close();
  }

  int? _parseStepPayload(dynamic payload) {
    if (payload is int) {
      return payload;
    }
    if (payload is double) {
      return payload.toInt();
    }
    if (payload is Map<String, dynamic>) {
      final steps = payload['steps'];
      if (steps is int) {
        return steps;
      }
      if (steps is double) {
        return steps.toInt();
      }
    }
    return null;
  }
}

class _AndroidStepsRepo extends _PlatformStepsRepo {
  _AndroidStepsRepo()
      : super(
          methodChannelName: 'com.steppify/health_connect',
          eventChannelName: 'com.steppify/health_connect/steps',
        );

  @override
  Future<bool> isSupported() async {
    try {
      final supported = await _methodChannel
          .invokeMethod<bool>('isHealthConnectAvailable');
      return supported ?? false;
    } on PlatformException catch (error) {
      if (error.code == 'health_connect_not_installed') {
        return false;
      }
      debugPrint('Health Connect support check failed: $error');
      return false;
    }
  }
}

class _IOSStepsRepo extends _PlatformStepsRepo {
  _IOSStepsRepo()
      : super(
          methodChannelName: 'com.steppify/core_motion',
          eventChannelName: 'com.steppify/core_motion/steps',
        );

  @override
  Future<bool> isSupported() async {
    try {
      final supported = await _methodChannel
          .invokeMethod<bool>('isCoreMotionAvailable');
      return supported ?? false;
    } on PlatformException catch (error) {
      debugPrint('CoreMotion support check failed: $error');
      return false;
    }
  }
}

class _UnsupportedStepsRepo implements StepsRepo {
  @override
  void dispose() {}

  @override
  Future<int> fetchTodaySteps() async => 0;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Stream<int> watchSteps() => const Stream<int>.empty();
}
