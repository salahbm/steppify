import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:steppify/features/step_tracker/data/live_activity_service.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';

class StepTrackerAndroidScreen extends StatefulWidget {
  const StepTrackerAndroidScreen({super.key});

  @override
  State<StepTrackerAndroidScreen> createState() =>
      _StepTrackerAndroidScreenState();
}

class _StepTrackerAndroidScreenState extends State<StepTrackerAndroidScreen> {
  final _liveActivityService = LiveActivityService();

  int _todaySteps = 0;
  int _sinceOpenSteps = 0;
  int _sinceBootSteps = 0;
  String _status = "stationary";

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  bool _trackingPaused = false;
  bool _loading = false;
  String? _error;
  final List<String> _logs = [];
  bool _liveActivityActive = false;

  late DateTime _startOfDay;
  bool _initialized = false;

  /// Offset values for computing:
  /// - today steps
  /// - since open steps
  /// - since boot (raw pedometer)
  int? _bootOffset;
  int? _todayOffset;
  int? _openOffset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final now = DateTime.now();

    _startOfDay = DateTime(now.year, now.month, now.day);
    _initialized = true;

    _initialize();
  }

  @override
  void dispose() {
    _stopStreams();
    super.dispose();
  }

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String();
    setState(() => _logs.add("$ts - $msg"));
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
      _todaySteps = 0;
      _sinceOpenSteps = 0;
      _sinceBootSteps = 0;
      _status = "stationary";
    });

    final granted = await _requestPermission();

    if (!granted) {
      setState(() {
        _loading = false;
        _error = "Permission not granted";
      });
      return;
    }

    _startAllStreams();

    setState(() => _loading = false);
  }

  Future<bool> _requestPermission() async {
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
    _startStepStream();
    _startStatusStream();
    _log("Streams started");
  }

  void _stopStreams() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _log("Streams stopped");
  }

  // --------------------------------------------------------------------------
  // STEP STREAM (Android pedometer)
  // --------------------------------------------------------------------------

  void _startStepStream() {
    _stepSub?.cancel();

    _stepSub = Pedometer.stepCountStream.listen(
      (StepCount ev) {
        final steps = ev.steps;

        // First reading becomes baseline
        if (_bootOffset == null) {
          _bootOffset = steps;
          _todayOffset = steps;
          _openOffset = steps;
        }

        // Raw pedometer → since boot
        _sinceBootSteps = steps - (_bootOffset ?? 0);

        // Steps since the screen was opened
        _sinceOpenSteps = steps - (_openOffset ?? 0);

        // Handle a new day
        final now = DateTime.now();
        if (now.day != _startOfDay.day ||
            now.month != _startOfDay.month ||
            now.year != _startOfDay.year) {
          _startOfDay = DateTime(now.year, now.month, now.day);
          _todayOffset = steps; // reset baseline
        }

        // Steps since midnight
        _todaySteps = steps - (_todayOffset ?? 0);

        setState(() {});
        _updateLiveActivity();
      },
      onError: (err) {
        _log("Step stream error: $err");
      },
    );
  }

  // --------------------------------------------------------------------------
  // STATUS STREAM
  // --------------------------------------------------------------------------

  void _startStatusStream() {
    _statusSub?.cancel();

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) {
        _status = event.status;
        setState(() {});
        _updateLiveActivity();
      },
      onError: (err) {
        _status = "unknown";
        setState(() {});
        _log("Status stream error: $err");
      },
    );
  }

  // --------------------------------------------------------------------------
  // LIVE ACTIVITY
  // --------------------------------------------------------------------------

  Future<void> _updateLiveActivity() async {
    if (!_liveActivityActive) return;

    try {
      await _liveActivityService.updateLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: _todaySteps,
          sinceOpenSteps: _sinceOpenSteps,
          sinceBootSteps: _sinceBootSteps,
          status: "manual",
        ),
      );
    } catch (e) {
      _log("Live activity update error: $e");
    }
  }

  Future<void> _startLiveActivity() async {
    if (_liveActivityActive) return;

    try {
      await _liveActivityService.startLiveActivity(
        data: StepLiveActivityModel(
          todaySteps: _todaySteps,
          sinceOpenSteps: _sinceOpenSteps,
          sinceBootSteps: _sinceBootSteps,
          status: "start",
        ),
      );
      setState(() => _liveActivityActive = true);
    } catch (e) {
      _log("Failed to start live activity: $e");
    }
  }

  Future<void> _endLiveActivity() async {
    if (!_liveActivityActive) return;

    try {
      await _liveActivityService.endLiveActivity();
      setState(() => _liveActivityActive = false);
    } catch (e) {
      _log("Failed to stop live activity: $e");
    }
  }

  // --------------------------------------------------------------------------
  // UI HELPERS
  // --------------------------------------------------------------------------

  Color _statusColor() {
    switch (_status) {
      case "walking":
        return Colors.green;
      case "stopped":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Step Tracker")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Step Tracker")),
        body: Center(
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Step Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today: $_todaySteps steps",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text("Since open: $_sinceOpenSteps"),
            Text("Since boot: $_sinceBootSteps"),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text("Status: $_status"),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _trackingPaused ? startTracking : null,
                  child: const Text("Start Tracking"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: !_trackingPaused ? pauseTracking : null,
                  child: const Text("Pause Tracking"),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: !_liveActivityActive ? _startLiveActivity : null,
              child: const Text("Start Live Activity"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _liveActivityActive ? _updateLiveActivity : null,
              child: const Text("Update Live Activity (Manual)"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _liveActivityActive ? _endLiveActivity : null,
              child: const Text("Stop Live Activity"),
            ),

            const SizedBox(height: 20),
            const Text("Logs:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) =>
                    Text(_logs[i], style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
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
