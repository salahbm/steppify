import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer_2/pedometer_2.dart';
import 'package:permission_handler/permission_handler.dart';

class PedometerScreen extends StatefulWidget {
  const PedometerScreen({super.key});
  @override
  State<PedometerScreen> createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> {
  StreamSubscription<int>? _stepSub;
  int _bootSteps = 0;
  int _currentBootSteps = 0;
  int _todaySteps = 0;

  @override
  void initState() {
    super.initState();
    _initPermissionsAndStart();
  }

  Future<void> _initPermissionsAndStart() async {
    // Request permission (Android)
    if (await Permission.activityRecognition.isDenied) {
      await Permission.activityRecognition.request();
    }
    if (!mounted) return;

    _stepSub = Pedometer().stepCountStream().listen(
      (int steps) {
        setState(() {
          _currentBootSteps = steps;
          if (_bootSteps == 0) {
            _bootSteps = steps; // record start-boot baseline
          }
        });
      },
      onError: (e) {
        debugPrint('Step stream error: $e');
      },
    );

    _fetchTodaySteps();
  }

  Future<void> _fetchTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final count = await Pedometer().getStepCount(from: startOfDay, to: now);
      setState(() {
        _todaySteps = count;
      });
    } catch (e) {
      debugPrint('Error fetching today steps: $e');
    }
  }

  int get stepsSinceOpen => _currentBootSteps - _bootSteps;

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Steps since boot: $_currentBootSteps'),
            const SizedBox(height: 12),
            Text('Steps since app opened: $stepsSinceOpen'),
            const SizedBox(height: 12),
            Text('Steps today: $_todaySteps'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTodaySteps,
              child: const Text('Refresh today count'),
            ),
          ],
        ),
      ),
    );
  }
}
