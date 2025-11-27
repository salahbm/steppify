import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steppify/features/step_tracker/data/live_activity_service.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';
import 'package:steppify/features/step_tracker/utils/status_helpers.dart';
import 'package:steppify/features/step_tracker/widgets/widgets.dart';

class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  // Platform-specific services
  static const platform = MethodChannel('com.example.steppify/notification');
  final _liveActivityService = LiveActivityService();

  // Step data
  int _todaySteps = 0;
  int _sinceOpenSteps = 0;
  int _stepsSinceReboot = 0;

  // Android-specific: baseline tracking
  int _midnightBaseline = 0;
  int _sessionBaseline = 0;
  int? _androidFirstStepFrom;

  // iOS-specific: boot baseline
  int _bootSteps = 0;

  // State
  String _status = "ready";
  bool _trackingPaused = false;
  bool _notificationActive = false;
  bool _liveActivityActive = false;
  bool _loading = true;
  String? _error;

  // Streams
  StreamSubscription<int>? _stepStream;
  StreamSubscription<int>? _stepStreamFrom;
  StreamSubscription<PedestrianStatus>? _pedestrianStream;
  Timer? _midnightTimer;

  // Logs
  final List<String> _logs = [];

  // Date
  String _currentDate = "";
  late DateTime _startOfDay;

  @override
  void initState() {
    super.initState();
    _initializeTracker();
  }

  @override
  void dispose() {
    _stepStream?.cancel();
    _stepStreamFrom?.cancel();
    _pedestrianStream?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _log(String msg) {
    final ts = DateTime.now().toString().substring(11, 19);
    if (mounted) {
      setState(() {
        _logs.add('[$ts] $msg');
        if (_logs.length > 100) _logs.removeAt(0);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  Future<void> _initializeTracker() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final now = DateTime.now();
    _startOfDay = DateTime(now.year, now.month, now.day);
    _currentDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    _log("🚀 Initializing step tracker");

    try {
      // Request permissions
      final permGranted = await _requestPermissions();
      if (!permGranted) {
        setState(() {
          _error = "Permissions not granted";
          _loading = false;
        });
        return;
      }

      // Load saved data (Android only)
      if (Platform.isAndroid) {
        await _loadSavedData();
      }

      // Start listening to step streams
      _listenStepCountStream();
      _listenStepCountStreamFrom();
      _listenPedestrianStatusStream();

      // Start midnight timer (Android only)
      if (Platform.isAndroid) {
        _startMidnightTimer();
      }

      setState(() {
        _loading = false;
        _status = "ready";
      });

      _log("✅ Initialization complete");
    } catch (e) {
      _log("❌ Initialization error: $e");
      setState(() {
        _error = "Initialization failed: $e";
        _loading = false;
      });
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      PermissionStatus perm = Platform.isAndroid
          ? await Permission.activityRecognition.request()
          : await Permission.sensors.request();

      if (perm.isDenied || perm.isPermanentlyDenied || perm.isRestricted) {
        _log("❌ Permission denied");
        return false;
      }

      _log("✅ Permissions granted");
      return true;
    } catch (e) {
      _log("❌ Permission error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // DATA PERSISTENCE (Android)
  // ---------------------------------------------------------------------------

  Future<void> _loadSavedData() async {
    if (!Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _midnightBaseline = prefs.getInt('midnightBaseline') ?? 0;
        _sessionBaseline = prefs.getInt('sessionBaseline') ?? 0;
        _currentDate = prefs.getString('currentDate') ?? _currentDate;
      });
      _log("📂 Loaded saved data");
    } catch (e) {
      _log("⚠️ Load data error: $e");
    }
  }

  Future<void> _saveData() async {
    if (!Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('midnightBaseline', _midnightBaseline);
      await prefs.setInt('sessionBaseline', _sessionBaseline);
      await prefs.setString('currentDate', _currentDate);
    } catch (e) {
      _log("⚠️ Save data error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // STEP COUNTING STREAMS
  // ---------------------------------------------------------------------------

  void _listenStepCountStream() {
    try {
      _stepStream = Pedometer().stepCountStream().listen((steps) {
        if (_trackingPaused) return;

        setState(() {
          _stepsSinceReboot = steps;
        });

        if (Platform.isAndroid) {
          _calculateAndroidSteps();
        } else {
          _calculateIOSSteps(steps);
        }

        _updatePlatformWidget();
      });
      _log("📊 Step count stream started");
    } catch (e) {
      _log("❌ Step stream error: $e");
    }
  }

  void _listenStepCountStreamFrom() async {
    try {
      if (Platform.isAndroid) {
        // Android: Mix getStepCount with stepCountStream
        _todaySteps = await Pedometer().getStepCount(
          from: _startOfDay,
          to: DateTime.now(),
        );
        setState(() {});

        _stepStreamFrom = Pedometer().stepCountStream().listen((step) {
          if (_trackingPaused) return;

          if (_androidFirstStepFrom == null) {
            _androidFirstStepFrom = step;
            return;
          }

          setState(() {
            _todaySteps = _todaySteps + step - _androidFirstStepFrom!;
          });
          _updatePlatformWidget();
        });
      } else {
        // iOS: Use stepCountStreamFrom directly
        _stepStreamFrom = Pedometer()
            .stepCountStreamFrom(from: _startOfDay)
            .listen((steps) {
              if (_trackingPaused) return;

              setState(() {
                _todaySteps = steps;
              });
              _updatePlatformWidget();
            });
      }
      _log("📊 Today steps stream started");
    } catch (e) {
      _log("❌ Today steps stream error: $e");
    }
  }

  void _listenPedestrianStatusStream() {
    try {
      _pedestrianStream = Pedometer().pedestrianStatusStream().listen((status) {
        setState(() {
          _status = _pedestrianStatusToString(status);
        });
        _log("🚶 Status: $_status");
        _updatePlatformWidget();
      });
      _log("📊 Pedestrian status stream started");
    } catch (e) {
      _log("❌ Pedestrian status error: $e");
    }
  }

  String _pedestrianStatusToString(PedestrianStatus? status) {
    if (status == null) return "unknown";
    final str = status.toString().split('.').last.toLowerCase();
    if (str == "walking") return "walking";
    if (str == "stopped") return "stationary";
    return str;
  }

  // ---------------------------------------------------------------------------
  // STEP CALCULATIONS
  // ---------------------------------------------------------------------------

  void _calculateAndroidSteps() {
    final newTodaySteps = _stepsSinceReboot - _midnightBaseline;
    final newSinceOpen = _stepsSinceReboot - _sessionBaseline;

    setState(() {
      if (newTodaySteps > 0) _todaySteps = newTodaySteps;
      if (newSinceOpen > 0) _sinceOpenSteps = newSinceOpen;
    });

    _saveData();
  }

  void _calculateIOSSteps(int currentSteps) {
    if (_bootSteps == 0) {
      _bootSteps = currentSteps;
    }

    final stepsSinceOpen = currentSteps - _bootSteps;
    setState(() {
      if (stepsSinceOpen > 0) _sinceOpenSteps = stepsSinceOpen;
    });
  }

  // ---------------------------------------------------------------------------
  // MIDNIGHT TIMER (Android)
  // ---------------------------------------------------------------------------

  void _startMidnightTimer() {
    if (!Platform.isAndroid) return;

    _midnightTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkForNewDay();
    });
  }

  void _checkForNewDay() {
    if (!Platform.isAndroid) return;

    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (todayStr != _currentDate) {
      _log("🌅 New day detected");
      setState(() {
        _currentDate = todayStr;
        _startOfDay = DateTime(now.year, now.month, now.day);
        _midnightBaseline = _stepsSinceReboot;
        _todaySteps = 0;
      });
      _saveData();
      _updatePlatformWidget();
    }
  }

  // ---------------------------------------------------------------------------
  // PLATFORM-SPECIFIC WIDGETS (Notification/Live Activity)
  // ---------------------------------------------------------------------------

  void _updatePlatformWidget() {
    if (Platform.isAndroid && _notificationActive) {
      _updateNotification();
    } else if (Platform.isIOS && _liveActivityActive) {
      _updateLiveActivity();
    }
  }

  // Android Notification
  Future<void> _startNotification() async {
    if (!Platform.isAndroid) return;

    try {
      await platform.invokeMethod('startNotification', {
        'todaySteps': _todaySteps,
        'sinceOpenSteps': _sinceOpenSteps,
        'status': _status,
      });
      setState(() => _notificationActive = true);
      _log("🔔 Notification started");
    } on PlatformException catch (e) {
      _log("❌ Notification error: ${e.message}");
    }
  }

  Future<void> _updateNotification() async {
    if (!Platform.isAndroid || !_notificationActive) return;

    try {
      await platform.invokeMethod('updateNotification', {
        'todaySteps': _todaySteps,
        'sinceOpenSteps': _sinceOpenSteps,
        'status': _status,
      });
    } on PlatformException catch (e) {
      _log("❌ Update notification error: ${e.message}");
    }
  }

  Future<void> _stopNotification() async {
    if (!Platform.isAndroid) return;

    try {
      await platform.invokeMethod('stopNotification');
      setState(() => _notificationActive = false);
      _log("🔕 Notification stopped");
    } on PlatformException catch (e) {
      _log("❌ Stop notification error: ${e.message}");
    }
  }

  // iOS Live Activity
  Future<void> _startLiveActivity() async {
    if (!Platform.isIOS) return;

    try {
      await _liveActivityService.startLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: _todaySteps,
          sinceOpenSteps: _sinceOpenSteps,
          sinceBootSteps: _stepsSinceReboot,
          status: _status,
        ),
      );
      setState(() => _liveActivityActive = true);
      _log("🎯 Live Activity started");
    } catch (e) {
      _log("❌ Live Activity start error: $e");
    }
  }

  Future<void> _updateLiveActivity() async {
    if (!Platform.isIOS || !_liveActivityActive) return;

    try {
      await _liveActivityService.updateLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: _todaySteps,
          sinceOpenSteps: _sinceOpenSteps,
          sinceBootSteps: _stepsSinceReboot,
          status: _status,
        ),
      );
    } catch (e) {
      _log("❌ Live Activity update error: $e");
    }
  }

  Future<void> _endLiveActivity() async {
    if (!Platform.isIOS) return;

    try {
      await _liveActivityService.endLiveActivity();
      setState(() => _liveActivityActive = false);
      _log("🛑 Live Activity ended");
    } catch (e) {
      _log("❌ Live Activity end error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // TRACKING CONTROLS
  // ---------------------------------------------------------------------------

  void _pauseTracking() {
    setState(() => _trackingPaused = true);
    _log("⏸️ Tracking paused");
  }

  void _startTracking() {
    setState(() => _trackingPaused = false);
    _log("▶️ Tracking resumed");
  }

  void _resetSessionSteps() {
    setState(() {
      if (Platform.isAndroid) {
        _sessionBaseline = _stepsSinceReboot;
      } else {
        _bootSteps = _stepsSinceReboot;
      }
      _sinceOpenSteps = 0;
    });
    if (Platform.isAndroid) {
      _saveData();
    }
    _log("🔄 Session reset");
    _updatePlatformWidget();
  }

  void _manualDayReset() {
    if (!Platform.isAndroid) return;

    setState(() {
      _midnightBaseline = _stepsSinceReboot;
      _todaySteps = 0;
    });
    _saveData();
    _log("🔄 Daily counter reset");
    _updatePlatformWidget();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingScreen();
    }

    if (_error != null) {
      return ErrorScreen(
        errorMessage: _error!,
        logs: _logs,
        onRetry: _initializeTracker,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Step Tracker"),
        backgroundColor: Colors.deepPurple,
        actions: [
          Icon(
            StatusHelpers.getStatusIcon(_status),
            color: StatusHelpers.getStatusColor(_status),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date info banner (Android only)
              if (Platform.isAndroid) ...[
                DateInfoBanner(currentDate: _currentDate),
                const SizedBox(height: 16),
              ],

              // Main step counter
              StepCounterCard(
                steps: _todaySteps,
                title: "Today's Steps",
                status: _status,
                statusIcon: StatusHelpers.getStatusIcon(_status),
                statusColor: StatusHelpers.getStatusColor(_status),
              ),

              const SizedBox(height: 16),

              // Secondary counters row
              Row(
                children: [
                  Expanded(
                    child: SecondaryStepCard(
                      label: 'Since Open',
                      steps: _sinceOpenSteps,
                      icon: Icons.timer,
                      iconColor: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryStepCard(
                      label: Platform.isAndroid ? 'Since Reboot' : 'Since Boot',
                      steps: _stepsSinceReboot,
                      icon: Platform.isAndroid
                          ? Icons.phone_android
                          : Icons.phone_iphone,
                      iconColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Status indicator (iOS)
              if (Platform.isIOS) ...[
                StatusIndicator(
                  status: _status,
                  color: StatusHelpers.getStatusColor(_status),
                ),
                const SizedBox(height: 20),
              ],

              // Tracking controls
              TrackingControlButtons(
                isPaused: _trackingPaused,
                onStart: _startTracking,
                onPause: _pauseTracking,
              ),

              const SizedBox(height: 12),

              // Platform-specific controls
              if (Platform.isAndroid) ...[
                NotificationControlButtons(
                  isActive: _notificationActive,
                  onStart: _startNotification,
                  onStop: _stopNotification,
                ),
                const SizedBox(height: 12),
                ResetControlButtons(
                  onResetSession: _resetSessionSteps,
                  onResetDay: _manualDayReset,
                ),
              ] else if (Platform.isIOS) ...[
                LiveActivityControlButtons(
                  isActive: _liveActivityActive,
                  onStart: _startLiveActivity,
                  onUpdate: _updateLiveActivity,
                  onEnd: _endLiveActivity,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _resetSessionSteps,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Logs
              Expanded(child: ActivityLogViewer(logs: _logs)),
            ],
          ),
        ),
      ),
    );
  }
}
