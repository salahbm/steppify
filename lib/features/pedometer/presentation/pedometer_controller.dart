import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pedometer_provider.dart';
import '../data/steps_repo.dart';
import 'pedometer_state.dart';

class PedometerController extends Notifier<PedometerState> {
  PedometerController();

  late final StepsRepo _repo;
  StreamSubscription<int>? _stepsSubscription;

  @override
  PedometerState build() {
    _repo = ref.read(stepsRepoProvider);
    ref.onDispose(_dispose);
    Future<void>.microtask(_initialize);
    return PedometerState.initial();
  }

  Future<void> _initialize() async {
    await _ensureSupport();
  }

  Future<void> _ensureSupport() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final supported = await _repo.isSupported();
    if (!supported) {
      state = state.copyWith(
        isSupported: false,
        isLoading: false,
        errorMessage: 'Step tracking is not supported on this device.',
      );
      return;
    }

    await _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    var hasPermission = await _repo.hasPermission();
    if (!hasPermission) {
      hasPermission = await _repo.requestPermission();
    }

    if (!hasPermission) {
      state = state.copyWith(
        hasPermission: false,
        isLoading: false,
        errorMessage: 'We need permission to read today\'s steps.',
      );
      return;
    }

    state = state.copyWith(hasPermission: true, clearError: true);
    await _hydrateSteps();
    _listenToSteps();
  }

  Future<void> requestPermission() => _ensurePermission();

  Future<void> refreshSteps() async {
    if (!state.hasPermission) {
      state = state.copyWith(
        errorMessage: 'Grant permissions to refresh today\'s steps.',
      );
      return;
    }

    await _hydrateSteps();
  }

  Future<void> _hydrateSteps() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final steps = await _repo.fetchTodaySteps();
      state = state.copyWith(
        totalSteps: steps,
        isLoading: false,
        lastUpdated: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void _listenToSteps() {
    _stepsSubscription?.cancel();
    _stepsSubscription = _repo.watchSteps().listen((steps) {
      state = state.copyWith(
        totalSteps: steps,
        lastUpdated: DateTime.now(),
        clearError: true,
        isLoading: false,
      );
    }, onError: (Object error, StackTrace stackTrace) {
      state = state.copyWith(
        errorMessage: error.toString(),
        isLoading: false,
      );
    });
  }

  void _dispose() {
    _stepsSubscription?.cancel();
  }
}

final pedometerControllerProvider =
    NotifierProvider<PedometerController, PedometerState>(
  PedometerController.new,
);
