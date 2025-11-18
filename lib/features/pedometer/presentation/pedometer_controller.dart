import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pedometer_provider.dart';
import '../data/steps_repo.dart';
import '../data/pedometer_state.dart';

class PedometerController extends Notifier<PedometerState> {
  late final StepsRepo _repo;
  StreamSubscription<int>? _subscription;
  bool _initialCheckDone = false;

  @override
  PedometerState build() {
    _repo = ref.read(stepsRepoProvider);
    ref.onDispose(dispose);
    Future.microtask(_initialize);
    return PedometerState.initial();
  }

  Future<void> _initialize() async {
    if (!_initialCheckDone) {
      _initialCheckDone = true;
      await _checkPermissionAndStart();
    }
  }

  Future<void> _checkPermissionAndStart() async {
    state = state.copyWith(isLoading: true);

    final granted = await _repo.requestPermission();
    if (!granted) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Permission required to track steps.',
      );
      return;
    }

    await _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      final steps = await _repo.fetchTodaySteps();
      state = state.copyWith(
        totalSteps: steps,
        isLoading: false,
        errorMessage: null,
      );

      _subscription = _repo.watchSteps().listen((value) {
        state = state.copyWith(totalSteps: value);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch steps: $e',
      );
    }
  }

  Future<void> retry() => _checkPermissionAndStart();

  void dispose() {
    _subscription?.cancel();
    _repo.dispose();
  }
}

final pedometerControllerProvider =
    NotifierProvider<PedometerController, PedometerState>(
      PedometerController.new,
    );
