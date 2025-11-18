import 'dart:async';
import 'dart:io';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepsRepo {
  StreamSubscription<StepCount>? _stepSubscription;
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();
  int? _baseSteps; // Steps at day start

  Future<void> _loadBaseSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    final lastSavedDate = prefs.getString('baseDate');
    final lastSavedSteps = prefs.getInt('baseSteps');

    if (lastSavedDate != today.toIso8601String().substring(0, 10)) {
      // New day, reset base
      await prefs.setString(
        'baseDate',
        today.toIso8601String().substring(0, 10),
      );
      await prefs.setInt('baseSteps', 0);
      _baseSteps = null;
    } else {
      _baseSteps = lastSavedSteps;
    }
  }

  Stream<int> watchSteps() {
    _loadBaseSteps().then((_) {
      _stepSubscription = Pedometer.stepCountStream.listen((event) async {
        if (_baseSteps == null) {
          _baseSteps = event.steps;
          final prefs = await SharedPreferences.getInstance();
          prefs.setInt('baseSteps', _baseSteps!);
        }
        _stepController.add(event.steps - _baseSteps!);
      }, onError: (error) => _stepController.addError(error));
    });

    return _stepController.stream;
  }

  Future<int> fetchTodaySteps() async {
    final completer = Completer<int>();
    late final StreamSubscription<int> sub;

    sub = watchSteps().listen((steps) {
      completer.complete(steps);
      sub.cancel();
    });
    return completer.future;
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.isGranted) return true;
      final status = await Permission.activityRecognition.request();
      return status == PermissionStatus.granted;
    }
    // iOS grants implicitly
    return true;
  }

  void dispose() {
    _stepSubscription?.cancel();
    _stepController.close();
  }
}
