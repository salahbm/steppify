import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cm_pedometer/cm_pedometer.dart';
import 'package:live_activities/live_activities.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:steppify/features/step_tracker/data/steps_live_model.dart';

class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  int _todaySteps = 0;
  int _sinceOpenSteps = 0;
  int _sinceBootSteps = 0;

  String _status = 'unknown';

  StreamSubscription<CMPedometerData>? _todaySub;
  StreamSubscription<CMPedometerData>? _openSub;
  StreamSubscription<CMPedometerData>? _bootSub;
  StreamSubscription<CMPedestrianStatus>? _statusSub;

  bool _trackingPaused = false;

  bool _loading = false;
  String? _error;
  final List<String> _logs = [];
  final _live = LiveActivities();

  String? _activityId;
  StepLiveActivityModel? _activityModel;

  late DateTime _startOfDay;
  late DateTime _screenOpenedAt;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final now = DateTime.now();
    _startOfDay = DateTime(now.year, now.month, now.day);
    _screenOpenedAt = now;

    _live.init(appGroupId: 'group.com.steppify', urlScheme: 'steppify');

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
      _status = 'unknown';
    });

    final available = await CMPedometer.isStepCountingAvailable();
    _log("Step counting available: $available");

    if (!available) {
      setState(() {
        _loading = false;
        _error = "Step counting unavailable";
      });
      return;
    }

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
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      _log("iOS uses system Motion & Fitness permission");
      return true;
    }

    var status = await Permission.activityRecognition.status;
    if (status.isGranted) return true;

    status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  // --------------------------------------------------------------------------
  // MANUAL CONTROL – Start & Pause
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

  void pauseTracking() {
    setState(() {
      _trackingPaused = true;
    });

    _stopStreams();
    _log("Tracking paused");
  }

  void startTracking() {
    setState(() {
      _trackingPaused = false;
    });

    _log("Tracking resumed");

    // DO NOT reset sinceOpen time
    // DO NOT reset counters
    // Just resume streams

    _stopStreams();
    _startAllStreams();
  }

  // --------------------------------------------------------------------------
  // EXISTING STREAMS (unchanged logic)
  // --------------------------------------------------------------------------

  void _startTodayStream() {
    _todaySub?.cancel();

    _todaySub = CMPedometer.stepCounterFirstStream(from: _startOfDay).listen((
      data,
    ) {
      _todaySteps = data.numberOfSteps.toInt();
      _updateLiveActivity();
      setState(() {});
    }, onError: (e) => _log("Today stream error: $e"));
  }

  void _startSinceOpenStream() {
    _openSub?.cancel();

    _openSub = CMPedometer.stepCounterSecondStream(from: _screenOpenedAt)
        .listen((data) {
          _sinceOpenSteps = data.numberOfSteps.toInt();
          setState(() {});
        }, onError: (e) => _log("Since-open stream error: $e"));
  }

  void _startSinceBootStream() {
    _bootSub?.cancel();

    _bootSub = CMPedometer.stepCounterThirdStream().listen((data) {
      _sinceBootSteps = data.numberOfSteps.toInt();
      setState(() {});
    }, onError: (e) => _log("Since-boot stream error: $e"));
  }

  void _startStatusStream() {
    _statusSub?.cancel();

    _statusSub = CMPedometer.pedestrianStatusStream.listen(
      (CMPedestrianStatus event) {
        _status = event.status;
        setState(() {});
      },
      onError: (e) {
        _status = 'unknown';
        _log("Status stream error: $e");
        setState(() {});
      },
    );
  }

  // --------------------------------------------------------------------------
  // LIVE ACTIVITY
  // --------------------------------------------------------------------------
  Future<void> _startLiveActivity() async {
    await Permission.notification.request();

    await _live.endAllActivities();

    _activityModel = StepLiveActivityModel(
      todaySteps: _todaySteps,
      sinceOpenSteps: _sinceOpenSteps,
      sinceBootSteps: _sinceBootSteps,
      status: _status,
    );

    _activityId = await _live.createActivity(
      DateTime.now().millisecondsSinceEpoch.toString(),
      _activityModel!.toMap(),
    );

    _log("Live Activity started: $_activityId");
  }

  Future<void> _updateLiveActivity() async {
    if (_activityId == null || _activityModel == null) return;

    _activityModel = _activityModel!.copyWith(
      todaySteps: _todaySteps,
      sinceOpenSteps: _sinceOpenSteps,
      sinceBootSteps: _sinceBootSteps,
      status: _status,
    );

    await _live.updateActivity(_activityId!, _activityModel!.toMap());
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
        appBar: AppBar(title: Text('Step Tracker')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text("Step Tracker")),
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
              children: [
                ElevatedButton(
                  onPressed: _trackingPaused ? startTracking : null,
                  child: const Text("Start"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: !_trackingPaused ? pauseTracking : null,
                  child: const Text("Pause"),
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _startLiveActivity,
                  child: const Text("Start Live"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await _live.endAllActivities();
                    _activityId = null;
                    setState(() {});
                  },
                  child: const Text("Stop Live"),
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
}
