import 'dart:async';
import 'dart:io';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class to handle step tracking logic
class StepTrackerService {
  // Streams
  StreamSubscription<int>? _stepStream;
  StreamSubscription<int>? _stepStreamFrom;
  StreamSubscription<PedestrianStatus>? _pedestrianStream;

  // Callbacks
  final Function(int steps) onStepCount;
  final Function(int todaySteps) onTodaySteps;
  final Function(String status) onStatusChange;
  final Function(String message) onLog;

  // Android-specific tracking
  int? _androidFirstStepFrom;

  StepTrackerService({
    required this.onStepCount,
    required this.onTodaySteps,
    required this.onStatusChange,
    required this.onLog,
  });

  /// Request permissions based on platform
  Future<bool> requestPermissions() async {
    try {
      PermissionStatus perm = Platform.isAndroid
          ? await Permission.activityRecognition.request()
          : await Permission.sensors.request();

      if (perm.isDenied || perm.isPermanentlyDenied || perm.isRestricted) {
        onLog("❌ Permission denied");
        return false;
      }

      onLog("✅ Permissions granted");
      return true;
    } catch (e) {
      onLog("❌ Permission error: $e");
      return false;
    }
  }

  /// Start listening to step count stream
  void startStepCountStream({required bool Function() isPaused}) {
    try {
      _stepStream = Pedometer().stepCountStream().listen((steps) {
        if (isPaused()) return;
        onStepCount(steps);
      });
      onLog("📊 Step count stream started");
    } catch (e) {
      onLog("❌ Step stream error: $e");
    }
  }

  /// Start listening to today's steps
  Future<void> startTodayStepsStream({
    required DateTime startOfDay,
    required bool Function() isPaused,
  }) async {
    try {
      if (Platform.isAndroid) {
        // Android: Mix getStepCount with stepCountStream
        final initialSteps = await Pedometer().getStepCount(
          from: startOfDay,
          to: DateTime.now(),
        );
        onTodaySteps(initialSteps);

        _stepStreamFrom = Pedometer().stepCountStream().listen((step) {
          if (isPaused()) return;

          if (_androidFirstStepFrom == null) {
            _androidFirstStepFrom = step;
            return;
          }

          final todaySteps = initialSteps + step - _androidFirstStepFrom!;
          onTodaySteps(todaySteps);
        });
      } else {
        // iOS: Use stepCountStreamFrom directly
        _stepStreamFrom = Pedometer()
            .stepCountStreamFrom(from: startOfDay)
            .listen((steps) {
          if (isPaused()) return;
          onTodaySteps(steps);
        });
      }
      onLog("📊 Today steps stream started");
    } catch (e) {
      onLog("❌ Today steps stream error: $e");
    }
  }

  /// Start listening to pedestrian status
  void startPedestrianStatusStream() {
    try {
      _pedestrianStream = Pedometer().pedestrianStatusStream().listen((status) {
        final statusStr = _pedestrianStatusToString(status);
        onStatusChange(statusStr);
        onLog("🚶 Status: $statusStr");
      });
      onLog("📊 Pedestrian status stream started");
    } catch (e) {
      onLog("❌ Pedestrian status error: $e");
    }
  }

  String _pedestrianStatusToString(PedestrianStatus? status) {
    if (status == null) return "unknown";
    final str = status.toString().split('.').last.toLowerCase();
    if (str == "walking") return "walking";
    if (str == "stopped") return "stationary";
    return str;
  }

  /// Cancel all streams
  void dispose() {
    _stepStream?.cancel();
    _stepStreamFrom?.cancel();
    _pedestrianStream?.cancel();
  }

  /// Reset Android first step tracking
  void resetAndroidTracking() {
    _androidFirstStepFrom = null;
  }
}

/// Service for Android-specific data persistence
class AndroidDataService {
  static const String _keyMidnightBaseline = 'midnightBaseline';
  static const String _keySessionBaseline = 'sessionBaseline';
  static const String _keyCurrentDate = 'currentDate';

  /// Load saved data from SharedPreferences
  Future<Map<String, dynamic>> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'midnightBaseline': prefs.getInt(_keyMidnightBaseline) ?? 0,
        'sessionBaseline': prefs.getInt(_keySessionBaseline) ?? 0,
        'currentDate': prefs.getString(_keyCurrentDate) ?? '',
      };
    } catch (e) {
      return {
        'midnightBaseline': 0,
        'sessionBaseline': 0,
        'currentDate': '',
      };
    }
  }

  /// Save data to SharedPreferences
  Future<void> saveData({
    required int midnightBaseline,
    required int sessionBaseline,
    required String currentDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMidnightBaseline, midnightBaseline);
      await prefs.setInt(_keySessionBaseline, sessionBaseline);
      await prefs.setString(_keyCurrentDate, currentDate);
    } catch (e) {
      // Silently fail
    }
  }
}
