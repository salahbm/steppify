import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cm_pedometer/cm_pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:steppify/features/step_tracker/data/live_activity_service.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';
import 'package:steppify/features/step_tracker/presentation/utils/status_helpers.dart';
import 'package:steppify/features/step_tracker/presentation/widgets/widgets.dart';

class StepTrackerIOSScreen extends StatefulWidget {
  const StepTrackerIOSScreen({super.key});

  @override
  State<StepTrackerIOSScreen> createState() => _StepTrackerIOSScreenState();
}

class _StepTrackerIOSScreenState extends State<StepTrackerIOSScreen> {
  final _liveActivityService = LiveActivityService();

  int _todaySteps = 0;
  int _sinceOpenSteps = 0;
  int _sinceBootSteps = 0;
  String _status = 'stationary';

  StreamSubscription<CMPedometerData>? _todaySub;
  StreamSubscription<CMPedometerData>? _openSub;
  StreamSubscription<CMPedometerData>? _bootSub;
  StreamSubscription<CMPedestrianStatus>? _statusSub;

  bool _trackingPaused = false;
  bool _loading = false;
  String? _error;
  final List<String> _logs = [];
  bool _liveActivityActive = false;

  late DateTime _startOfDay;
  late DateTime _screenOpenedAt;
  bool _initialized = false;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final now = DateTime.now();
    _startOfDay = DateTime(now.year, now.month, now.day);
    _screenOpenedAt = now;

    _initialized = true;
    _initialize();
  }

  @override
  void dispose() {
    _stopStreams();
    // Don't end Live Activity on dispose - let it persist
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Logs
  // --------------------------------------------------------------------------

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String();
    setState(() => _logs.add('$ts - $msg'));
  }

  // --------------------------------------------------------------------------
  // INITIALIZE
  // --------------------------------------------------------------------------

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
      _logs.clear();
      _todaySteps = 0;
      _sinceOpenSteps = 0;
      _sinceBootSteps = 0;
      _status = 'stationary';
    });

    final granted = await _requestPermission();
    if (!granted) {
      setState(() {
        _loading = false;
        _error = "Permission not granted";
      });
      return;
    }

    final available = await CMPedometer.isStepCountingAvailable();

    if (!available) {
      setState(() {
        _loading = false;
        _error = "Step counting unavailable";
      });
    }

    _startAllStreams();

    setState(() => _loading = false);
  }

  Future<bool> _requestPermission() async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return true;
    }
    bool granted = await Permission.activityRecognition.isGranted;

    if (!granted) {
      granted =
          await Permission.activityRecognition.request() ==
          PermissionStatus.granted;
    }

    return granted;
  }

  // --------------------------------------------------------------------------
  // STREAM CONTROL
  // --------------------------------------------------------------------------

  void _startAllStreams() {
    if (_trackingPaused) return;
    _startTodayStream();
    _startSinceOpenStream();
    _startSinceBootStream();
    _startStatusStream();
    _log("Streams started");
  }

  void _stopStreams() {
    _todaySub?.cancel();
    _openSub?.cancel();
    _bootSub?.cancel();
    _statusSub?.cancel();
    _log("Streams stopped");
  }

  // --------------------------------------------------------------------------
  // Live Activity update
  // --------------------------------------------------------------------------
  Future<void> _updateLiveActivity() async {
    if (!_liveActivityActive) return;

    try {
      await _liveActivityService.updateLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: _todaySteps,
          sinceOpenSteps: _sinceOpenSteps,
          sinceBootSteps: _sinceBootSteps,
          status: 'manual',
        ),
      );
      _log("Live Activity updated");
    } catch (e) {
      _log("Live Activity update error: $e");
    }
  }

  Future<void> _startLiveActivity() async {
    if (_liveActivityActive) {
      _log("Live Activity already active");
      return;
    }

    try {
      await _liveActivityService.startLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: _todaySteps,
          sinceOpenSteps: _sinceOpenSteps,
          sinceBootSteps: _sinceBootSteps,
          status: 'start',
        ),
      );
      setState(() => _liveActivityActive = true);
      _log("Live Activity started");
    } catch (e) {
      _log("Failed to start Live Activity: $e");
    }
  }

  Future<void> _endLiveActivity() async {
    if (!_liveActivityActive) {
      _log("Live Activity not active");
      return;
    }

    try {
      await _liveActivityService.endLiveActivity();
      setState(() => _liveActivityActive = false);
      _log("Live Activity stopped");
    } catch (e) {
      _log("Failed to stop Live Activity: $e");
    }
  }

  // --------------------------------------------------------------------------
  // STREAMS
  // --------------------------------------------------------------------------

  void _startTodayStream() {
    _todaySub?.cancel();
    _todaySub = CMPedometer.stepCounterFirstStream(from: _startOfDay).listen((
      data,
    ) {
      _todaySteps = data.numberOfSteps.toInt();
      setState(() {});
      _updateLiveActivity();
    }, onError: (e) => _log("Today stream error: $e"));
  }

  void _startSinceOpenStream() {
    _openSub?.cancel();
    _openSub = CMPedometer.stepCounterSecondStream(from: _screenOpenedAt)
        .listen((data) {
          _sinceOpenSteps = data.numberOfSteps.toInt();
          setState(() {});
          _updateLiveActivity();
        }, onError: (e) => _log("Since-open stream error: $e"));
  }

  void _startSinceBootStream() {
    _bootSub?.cancel();
    _bootSub = CMPedometer.stepCounterThirdStream().listen((data) {
      _sinceBootSteps = data.numberOfSteps.toInt();
      setState(() {});
      _updateLiveActivity();
    }, onError: (e) => _log("Since-boot stream error: $e"));
  }

  void _startStatusStream() {
    _statusSub?.cancel();
    _statusSub = CMPedometer.pedestrianStatusStream.listen(
      (event) {
        _status = event.status;
        setState(() {});
        _updateLiveActivity();
      },
      onError: (e) {
        _status = 'unknown';
        _log("Status stream error: $e");
        setState(() {});
        _updateLiveActivity();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingScreen();
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Step Tracker")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initialize,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Step Tracker"),
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
                      label: 'Since Boot',
                      steps: _sinceBootSteps,
                      icon: Icons.phone_iphone,
                      iconColor: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Status indicator
              StatusIndicator(
                status: _status,
                color: StatusHelpers.getStatusColor(_status),
              ),

              const SizedBox(height: 20),

              // Tracking controls
              TrackingControlButtons(
                isPaused: _trackingPaused,
                onStart: startTracking,
                onPause: pauseTracking,
              ),

              const SizedBox(height: 12),

              // Live Activity controls
              LiveActivityControlButtons(
                isActive: _liveActivityActive,
                onStart: _startLiveActivity,
                onUpdate: _updateLiveActivity,
                onEnd: _endLiveActivity,
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

  void pauseTracking() {
    setState(() => _trackingPaused = true);
    _stopStreams();
    _log("Tracking paused");
  }

  void startTracking() {
    setState(() => _trackingPaused = false);
    _log("Tracking resumed");
    _stopStreams();
    _startAllStreams();
  }
}
