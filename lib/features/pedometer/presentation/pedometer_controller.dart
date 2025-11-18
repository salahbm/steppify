import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:steppify/features/pedometer/data/pedometer_provider.dart';
import '../domain/pedometer_usecase.dart';
import 'pedometer_state.dart';
import '../pedometer.dart';

class PedometerController extends Notifier<PedometerState> {
  late final PedometerUseCase _useCase;
  StreamSubscription<int>? _subscription;

  @override
  PedometerState build() {
    _useCase = ref.read(pedometerUseCaseProvider);
    ref.onDispose(() => _subscription?.cancel());
    Future.microtask(initialize);
    return PedometerState.initial();
  }

  Future<void> initialize() async {
    if (state.isInitialized) return;
    state = state.copyWith(isInitialized: true, isLoading: true);

    final permission = await _useCase.requestPermission();
    if (!permission) {
      state = state.copyWith(
        hasError: true,
        permissionGranted: false,
        isLoading: false,
        errorMessage: 'Permission not granted.',
      );
      return;
    }

    state = state.copyWith(permissionGranted: true);
    await startTracking();
  }

  Future<void> startTracking() async {
    await _useCase.startTracking();
    _subscription = _useCase.stepStream.listen((steps) {
      final quote = _useCase.motivationalQuote(steps);
      state = state.copyWith(
        entity: state.entity.copyWith(
          totalSteps: steps,
          motivationalQuote: quote,
          lastUpdated: DateTime.now(),
          isTracking: true,
        ),
        hasError: false,
        isLoading: false,
      );
    });
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    await _useCase.stopTracking();
    state = state.copyWith(entity: state.entity.copyWith(isTracking: false));
  }

  Future<void> toggleBackgroundTracking(bool enable) async {
    final enabled = await _useCase.toggleBackgroundTracking(enable);
    state = state.copyWith(
      entity: state.entity.copyWith(backgroundTrackingEnabled: enabled),
    );
  }

  Future<void> refreshQuote() async {
    final steps = state.entity.totalSteps;
    final quote = _useCase.motivationalQuote(steps);
    state = state.copyWith(
      entity: state.entity.copyWith(motivationalQuote: quote),
    );
  }
}

final pedometerControllerProvider =
    NotifierProvider<PedometerController, PedometerState>(
      () => PedometerController(),
    );
