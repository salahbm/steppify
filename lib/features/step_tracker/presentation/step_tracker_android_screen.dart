import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steppify/features/step_tracker/utils/status_helpers.dart';
import 'package:steppify/features/step_tracker/widgets/widgets.dart';

class StepTrackerAndroidScreen extends StatefulWidget {
  const StepTrackerAndroidScreen({super.key});

  @override
  State<StepTrackerAndroidScreen> createState() =>
      _StepTrackerAndroidScreenState();
}

class _StepTrackerAndroidScreenState extends State<StepTrackerAndroidScreen>
    with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.steppify/notification');

  int _todaySteps = 0;
  int _sinceOpenSteps = 0;
  int _stepsSinceReboot = 0;
  int _midnightBaseline = 0;
  int _sessionBaseline = 0;

  String _status = "initializing";
  String _pedestrianStatus = "unknown";

  bool _loading = false;
  bool _initialized = false;
  bool _notificationActive = false;
  bool _trackingPaused = false;
  bool _sensorAvailable = false;

  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  Timer? _midnightCheckTimer;

  final List<String> _logs = [];

  String _currentDate = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final now = DateTime.now();

    _currentDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    _initialized = true;
    _initialize();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    _midnightCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_trackingPaused) {
      _log("App resumed");
      _checkForNewDay();
      if (_notificationActive) {
        _updateNotification();
      }
    }
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

  Future<void> _initialize() async {
    setState(() => _loading = true);
    _log("🚀 Initialization started");

    try {
      // Load saved data
      await _loadSavedData();

      // Request activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();
      _log("Activity permission: $activityStatus");

      if (!activityStatus.isGranted) {
        _endLoadingWithError(
          "Activity recognition permission required.\n\n"
          "Please grant permission to access step sensor.",
        );
        return;
      }

      // Request notification permission
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      _log("Starting pedometer sensor...");

      // Initialize step count stream
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      // Initialize pedestrian status stream
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _log("✅ Sensor listeners initialized");

      // Start midnight check timer
      _startMidnightCheckTimer();

      // Wait for first data
      await Future.delayed(const Duration(seconds: 2));

      if (!_sensorAvailable) {
        _endLoadingWithError(
          "Step counter sensor not available.\n\n"
          "Your device may not have a step counter sensor.",
        );
        return;
      }

      // Auto-start notification
      await _startNotification();

      setState(() {
        _loading = false;
        _status = "active";
      });
      _log("✅ Initialization complete");
    } catch (e, stackTrace) {
      _log("❌ Init error: $e");
      _log("Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}");
      _endLoadingWithError("Initialization error: $e");
    }
  }

  void _endLoadingWithError(String error) {
    _log("❌ $error");
    if (mounted) {
      setState(() {
        _loading = false;
        _status = "error";
      });
    }
  }

  // ---------------------------------------------------------------------------
  // DATA PERSISTENCE
  // ---------------------------------------------------------------------------

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString('last_date') ?? "";
    final savedBaseline = prefs.getInt('midnight_baseline') ?? 0;
    final savedSessionBaseline = prefs.getInt('session_baseline') ?? 0;

    _log("Loaded: date=$savedDate, baseline=$savedBaseline");

    // Check if it's a new day
    if (savedDate != _currentDate) {
      _log("New day detected! Resetting baseline");
      _midnightBaseline = 0;
      _sessionBaseline = 0;
      await _saveData();
    } else {
      _midnightBaseline = savedBaseline;
      _sessionBaseline = savedSessionBaseline;
      _log("Using saved baseline: $_midnightBaseline");
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_date', _currentDate);
    await prefs.setInt('midnight_baseline', _midnightBaseline);
    await prefs.setInt('session_baseline', _sessionBaseline);
    _log("Data saved: baseline=$_midnightBaseline");
  }

  // ---------------------------------------------------------------------------
  // MIDNIGHT RESET
  // ---------------------------------------------------------------------------

  void _startMidnightCheckTimer() {
    // Check every minute for midnight
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForNewDay();
    });
  }

  Future<void> _checkForNewDay() async {
    final now = DateTime.now();
    final todayDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (todayDate != _currentDate) {
      _log("🌅 New day detected at ${now.toString().substring(11, 19)}");

      // Update midnight baseline to current steps
      _midnightBaseline = _stepsSinceReboot;
      _sessionBaseline = _stepsSinceReboot;
      _currentDate = todayDate;

      await _saveData();

      // Recalculate today's steps
      _calculateSteps();

      _log("✅ New day baseline set: $_midnightBaseline");
    }
  }

  // ---------------------------------------------------------------------------
  // PEDOMETER CALLBACKS
  // ---------------------------------------------------------------------------

  void _onStepCount(StepCount event) {
    if (!mounted) return;

    _sensorAvailable = true;
    _stepsSinceReboot = event.steps;

    // Set baselines on first reading
    if (_midnightBaseline == 0 && _stepsSinceReboot > 0) {
      _midnightBaseline = _stepsSinceReboot;
      _sessionBaseline = _stepsSinceReboot;
      _saveData();
      _log("📍 Initial baseline set: $_midnightBaseline");
    }

    // Calculate steps
    _calculateSteps();

    // Update notification in real-time
    if (_notificationActive) {
      _updateNotification();
    }
  }

  void _calculateSteps() {
    // Today's steps = current steps - midnight baseline
    final todaySteps = _stepsSinceReboot - _midnightBaseline;

    // Since open steps = current steps - session baseline
    final sinceOpen = _stepsSinceReboot - _sessionBaseline;

    _log(
      "📊 Reboot: $_stepsSinceReboot | Today: $todaySteps | Session: $sinceOpen",
    );

    if (mounted) {
      setState(() {
        _todaySteps = todaySteps >= 0 ? todaySteps : 0;
        _sinceOpenSteps = sinceOpen >= 0 ? sinceOpen : 0;
        _status = _pedestrianStatus == "walking" ? "walking" : "stationary";
      });
    }
  }

  void _onStepCountError(dynamic error) {
    _log("⚠️ Step count error: $error");
    if (!_sensorAvailable) {
      _log("Step counter sensor not available");
    }
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    if (!mounted) return;

    final status = event.status.toLowerCase();
    _log("🚶 Status: $status");

    setState(() {
      _pedestrianStatus = status;
      if (_pedestrianStatus == "walking") {
        _status = "walking";
      } else if (_pedestrianStatus == "stopped") {
        _status = "stationary";
      }
    });

    if (_notificationActive) {
      _updateNotification();
    }
  }

  void _onPedestrianStatusError(dynamic error) {
    _log("⚠️ Pedestrian status error: $error");
  }

  // ---------------------------------------------------------------------------
  // ANDROID NOTIFICATION
  // ---------------------------------------------------------------------------

  Future<void> _startNotification() async {
    if (_notificationActive) return;

    try {
      await platform.invokeMethod('startNotification', {
        'todaySteps': _todaySteps,
        'sinceOpenSteps': _sinceOpenSteps,
        'status': _status,
      });
      if (mounted) {
        setState(() => _notificationActive = true);
      }
      _log("🔔 Notification started");
    } catch (e) {
      _log("⚠️ Notification unavailable: $e");
    }
  }

  Future<void> _updateNotification() async {
    if (!_notificationActive) return;

    try {
      await platform.invokeMethod('updateNotification', {
        'todaySteps': _todaySteps,
        'sinceOpenSteps': _sinceOpenSteps,
        'status': _status,
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _stopNotification() async {
    if (!_notificationActive) return;

    try {
      await platform.invokeMethod('stopNotification');
      if (mounted) {
        setState(() => _notificationActive = false);
      }
      _log("🔕 Notification stopped");
    } catch (e) {
      _log("⚠️ Stop notification error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // CONTROLS
  // ---------------------------------------------------------------------------

  void _pauseTracking() {
    setState(() => _trackingPaused = true);
    _stepCountStream?.pause();
    _pedestrianStatusStream?.pause();
    _log("⏸️ Tracking paused");
  }

  void _startTracking() {
    setState(() => _trackingPaused = false);
    _stepCountStream?.resume();
    _pedestrianStatusStream?.resume();
    _log("▶️ Tracking resumed");
  }

  Future<void> _resetSessionSteps() async {
    setState(() {
      _sessionBaseline = _stepsSinceReboot;
      _sinceOpenSteps = 0;
    });
    await _saveData();
    _log("🔄 Session counter reset");
    if (_notificationActive) {
      _updateNotification();
    }
  }

  Future<void> _manualDayReset() async {
    setState(() {
      _midnightBaseline = _stepsSinceReboot;
      _sessionBaseline = _stepsSinceReboot;
      _todaySteps = 0;
      _sinceOpenSteps = 0;
    });
    await _saveData();
    _log("🔄 Daily counter manually reset");
    if (_notificationActive) {
      _updateNotification();
    }
  }

  Future<void> _retryInitialization() async {
    _log("🔄 Retrying initialization...");
    setState(() {
      _initialized = false;
      _logs.clear();
      _todaySteps = 0;
      _sinceOpenSteps = 0;
      _sensorAvailable = false;
    });
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    _midnightCheckTimer?.cancel();
    await _initialize();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingScreen();
    }

    if (_status == "error") {
      return ErrorScreen(
        errorMessage: _logs.isNotEmpty
            ? _logs.last.split('] ').last
            : "Unknown error",
        logs: _logs,
        onRetry: _retryInitialization,
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
              // Date info banner
              DateInfoBanner(currentDate: _currentDate),

              const SizedBox(height: 16),

              // Main step counter - TODAY'S STEPS
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
                      label: 'Since Reboot',
                      steps: _stepsSinceReboot,
                      icon: Icons.phone_android,
                      iconColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Controls
              TrackingControlButtons(
                isPaused: _trackingPaused,
                onStart: _startTracking,
                onPause: _pauseTracking,
              ),

              const SizedBox(height: 12),

              // Notification controls
              NotificationControlButtons(
                isActive: _notificationActive,
                onStart: _startNotification,
                onStop: _stopNotification,
              ),

              const SizedBox(height: 12),

              // Reset buttons
              ResetControlButtons(
                onResetSession: _resetSessionSteps,
                onResetDay: _manualDayReset,
              ),

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
