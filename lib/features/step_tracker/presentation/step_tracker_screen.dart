import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:steppify/features/step_tracker/data/live_activity_service.dart';
import 'package:steppify/features/step_tracker/data/notification_service.dart';
import 'package:steppify/features/step_tracker/data/step_tracker_service.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';
import 'package:steppify/features/step_tracker/utils/status_helpers.dart';
import 'package:steppify/features/step_tracker/utils/step_calculator.dart';
import 'package:steppify/features/step_tracker/widgets/widgets.dart';

class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  // Services
  late final StepTrackerService _stepTrackerService;
  final _liveActivityService = LiveActivityService();
  final _notificationService = NotificationService();
  final _androidDataService = AndroidDataService();

  // Step data
  int _todaySteps = 0;
  int _sinceOpenSteps = 0;
  int _stepsSinceReboot = 0;

  // Android-specific: baseline tracking
  int _midnightBaseline = 0;
  int _sessionBaseline = 0;

  // iOS-specific: boot baseline
  int _bootSteps = 0;

  // State
  String _status = "ready";
  bool _trackingPaused = false;
  bool _notificationActive = false;
  bool _liveActivityActive = false;
  bool _loading = true;
  String? _error;

  // Timer
  Timer? _midnightTimer;

  // Logs
  final List<String> _logs = [];

  // Date
  String _currentDate = "";
  late DateTime _startOfDay;

  @override
  void initState() {
    super.initState();
    _stepTrackerService = StepTrackerService(
      onStepCount: _handleStepCount,
      onTodaySteps: _handleTodaySteps,
      onStatusChange: _handleStatusChange,
      onLog: _log,
    );
    _initializeTracker();
  }

  @override
  void dispose() {
    _stepTrackerService.dispose();
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
  // CALLBACKS FROM SERVICE
  // ---------------------------------------------------------------------------

  void _handleStepCount(int steps) {
    setState(() {
      _stepsSinceReboot = steps;
    });

    if (Platform.isAndroid) {
      _calculateAndroidSteps();
    } else {
      _calculateIOSSteps(steps);
    }

    _updatePlatformWidget();
  }

  void _handleTodaySteps(int steps) {
    setState(() {
      _todaySteps = steps;
    });
    _updatePlatformWidget();
  }

  void _handleStatusChange(String status) {
    setState(() {
      _status = status;
    });
    _updatePlatformWidget();
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
    _currentDate = StepCalculator.formatDate(now);

    _log("🚀 Initializing step tracker");

    try {
      // Request permissions
      final permGranted = await _stepTrackerService.requestPermissions();
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
      _stepTrackerService.startStepCountStream(isPaused: () => _trackingPaused);
      await _stepTrackerService.startTodayStepsStream(
        startOfDay: _startOfDay,
        isPaused: () => _trackingPaused,
      );
      _stepTrackerService.startPedestrianStatusStream();

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

  // ---------------------------------------------------------------------------
  // DATA PERSISTENCE (Android)
  // ---------------------------------------------------------------------------

  Future<void> _loadSavedData() async {
    if (!Platform.isAndroid) return;

    try {
      final data = await _androidDataService.loadData();
      setState(() {
        _midnightBaseline = data['midnightBaseline'] as int;
        _sessionBaseline = data['sessionBaseline'] as int;
        final savedDate = data['currentDate'] as String;
        if (savedDate.isNotEmpty) {
          _currentDate = savedDate;
        }
      });
      _log("📂 Loaded saved data");
    } catch (e) {
      _log("⚠️ Load data error: $e");
    }
  }

  Future<void> _saveData() async {
    if (!Platform.isAndroid) return;

    try {
      await _androidDataService.saveData(
        midnightBaseline: _midnightBaseline,
        sessionBaseline: _sessionBaseline,
        currentDate: _currentDate,
      );
    } catch (e) {
      _log("⚠️ Save data error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // STEP CALCULATIONS
  // ---------------------------------------------------------------------------

  void _calculateAndroidSteps() {
    setState(() {
      _todaySteps = StepCalculator.calculateAndroidTodaySteps(
        stepsSinceReboot: _stepsSinceReboot,
        midnightBaseline: _midnightBaseline,
      );
    });
    _saveData();
  }

  void _calculateIOSSteps(int currentSteps) {
    if (_bootSteps == 0) {
      _bootSteps = currentSteps;
    }

    setState(() {
      _sinceOpenSteps = StepCalculator.calculateIOSSinceOpenSteps(
        currentSteps: currentSteps,
        bootSteps: _bootSteps,
      );
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
    if (StepCalculator.isNewDay(_currentDate, now)) {
      _log("🌅 New day detected");
      setState(() {
        _currentDate = StepCalculator.formatDate(now);
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
      await _notificationService.startNotification(
        todaySteps: _todaySteps,
        sinceOpenSteps: _sinceOpenSteps,
        status: _status,
      );
      setState(() => _notificationActive = true);
      _log("🔔 Notification started");
    } catch (e) {
      _log("❌ $e");
    }
  }

  Future<void> _updateNotification() async {
    if (!Platform.isAndroid || !_notificationActive) return;

    try {
      await _notificationService.updateNotification(
        todaySteps: _todaySteps,
        sinceOpenSteps: _sinceOpenSteps,
        status: _status,
      );
    } catch (e) {
      _log("❌ $e");
    }
  }

  Future<void> _stopNotification() async {
    if (!Platform.isAndroid) return;

    try {
      await _notificationService.stopNotification();
      setState(() => _notificationActive = false);
      _log("🔕 Notification stopped");
    } catch (e) {
      _log("❌ $e");
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
