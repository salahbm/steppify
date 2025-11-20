import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cm_pedometer/cm_pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:steppify/features/step_tracker/data/live_activity_service.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';

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

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  Color _statusColor() {
    switch (_status) {
      case 'walking':
        return Colors.green;
      case 'stopped':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Step Tracker')),
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
              'Today: $_todaySteps steps',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text('Since open: $_sinceOpenSteps'),
            Text('Since boot: $_sinceBootSteps'),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Status: $_status'),
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

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: !_liveActivityActive ? _startLiveActivity : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Start Live Activity"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _liveActivityActive ? _updateLiveActivity : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Update Live Activity (Manual)"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _liveActivityActive ? _endLiveActivity : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Stop Live Activity"),
                ),
              ],
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
