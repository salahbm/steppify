import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // UI HELPERS
  // ---------------------------------------------------------------------------

  Color _statusColor() {
    switch (_status) {
      case 'walking':
        return Colors.green;
      case 'stationary':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon() {
    switch (_status) {
      case 'walking':
        return Icons.directions_walk;
      case 'stationary':
        return Icons.pause_circle_outline;
      case 'active':
        return Icons.check_circle;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
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
      return Scaffold(
        appBar: AppBar(
          title: const Text("Step Tracker"),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Initializing step tracker..."),
              SizedBox(height: 10),
              Text(
                "Connecting to device sensors",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == "error") {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Step Tracker"),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "Sensor Not Available",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _logs.isNotEmpty
                      ? _logs.last.split('] ').last
                      : "Unknown error",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Troubleshooting:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStep("1", "Check device has step counter sensor"),
                        _buildStep(
                          "2",
                          "Settings > Apps > Steppify > Permissions",
                        ),
                        _buildStep(
                          "3",
                          "Enable 'Physical activity' permission",
                        ),
                        _buildStep("4", "Restart the app"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _retryInitialization,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Debug Logs:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _logs.length,
                        itemBuilder: (_, i) => Text(
                          _logs[i],
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Step Tracker"),
        backgroundColor: Colors.deepPurple,
        actions: [
          Icon(_statusIcon(), color: _statusColor()),
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
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Today: $_currentDate | Resets at midnight",
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Main step counter - TODAY'S STEPS
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade600,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Today\'s Steps',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _todaySteps.toString(),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_statusIcon(), color: _statusColor(), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _status.toUpperCase(),
                            style: TextStyle(
                              color: _statusColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary counters row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: Colors.deepPurple,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Since Open',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sinceOpenSteps.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.phone_android,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Since Reboot',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _stepsSinceReboot.toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Controls
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _trackingPaused ? _startTracking : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !_trackingPaused ? _pauseTracking : null,
                      icon: const Icon(Icons.pause),
                      label: const Text("Pause"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Notification controls
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !_notificationActive
                          ? _startNotification
                          : null,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text("Show Notification"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _notificationActive ? _stopNotification : null,
                      icon: const Icon(Icons.notifications_off),
                      label: const Text("Hide Notification"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Reset buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _resetSessionSteps,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(
                        "Reset Session",
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _manualDayReset,
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text(
                        "Reset Day",
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Logs
              const Text(
                "Activity Logs",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _logs.length,
                      itemBuilder: (_, i) {
                        final reversedIndex = _logs.length - 1 - i;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[reversedIndex],
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
