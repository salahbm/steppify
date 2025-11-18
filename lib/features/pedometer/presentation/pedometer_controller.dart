import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pedometer_data_source.dart';
import '../data/pedometer_repository.dart';
import '../domain/pedometer_entity.dart';
import '../domain/pedometer_usecase.dart';

class PedometerState {
  const PedometerState({
    required this.entity,
    required this.permissionGranted,
    required this.isLoading,
    required this.hasError,
    required this.isInitialized,
    this.errorMessage,
  });

  final PedometerEntity entity;
  final bool permissionGranted;
  final bool isLoading;
  final bool hasError;
  final bool isInitialized;
  final String? errorMessage;

  double get progress => entity.progress;

  PedometerState copyWith({
    PedometerEntity? entity,
    bool? permissionGranted,
    bool? isLoading,
    bool? hasError,
    bool? isInitialized,
    String? errorMessage,
    bool resetErrorMessage = false,
  }) {
    return PedometerState(
      entity: entity ?? this.entity,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage:
          resetErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory PedometerState.initial() {
    return PedometerState(
      entity: PedometerEntity.initial(),
      permissionGranted: false,
      isLoading: false,
      hasError: false,
      isInitialized: false,
      errorMessage: null,
    );
  }
}

class PedometerController extends StateNotifier<PedometerState> {
  PedometerController(this._useCase) : super(PedometerState.initial());

  final PedometerUseCase _useCase;
  StreamSubscription<int>? _subscription;

  Future<void> initialize() async {
    if (state.isInitialized) {
      return;
    }
    state = state.copyWith(isLoading: true, isInitialized: true);
    final permissionGranted = await _useCase.requestPermission();
    state = state.copyWith(permissionGranted: permissionGranted);
    if (!permissionGranted) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Permission is required to start counting steps.',
      );
      return;
    }
    await startTracking();
  }

  Future<void> startTracking() async {
    if (state.entity.isTracking) {
      return;
    }
    await _useCase.startTracking();
    _subscription ??= _useCase.stepStream.listen(
      _handleStepEvent,
      onError: (error) {
        state = state.copyWith(
          hasError: true,
          errorMessage: error.toString(),
          isLoading: false,
        );
      },
    );
    state = state.copyWith(
      entity: state.entity.copyWith(isTracking: true),
      isLoading: false,
      hasError: false,
      resetErrorMessage: true,
    );
  }

  Future<void> stopTracking() async {
    await _useCase.stopTracking();
    await _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(
      entity: state.entity.copyWith(isTracking: false),
    );
  }

  void _handleStepEvent(int steps) {
    final quote = _useCase.motivationalQuote(steps);
    state = state.copyWith(
      entity: state.entity.copyWith(
        totalSteps: steps,
        isTracking: true,
        motivationalQuote: quote,
        lastUpdated: DateTime.now(),
      ),
      hasError: false,
      resetErrorMessage: true,
    );
  }

  Future<void> toggleBackgroundTracking(bool enable) async {
    final isEnabled = await _useCase.toggleBackgroundTracking(enable);
    state = state.copyWith(
      entity: state.entity.copyWith(
        backgroundTrackingEnabled: isEnabled,
      ),
    );
  }

  // TODO(dev): Trigger push notifications or streak reminders when milestones
  // are hit once notification services are wired up.
  Future<void> refreshQuote() async {
    _handleStepEvent(state.entity.totalSteps);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final pedometerDataSourceProvider = Provider<PedometerDataSource>((ref) {
  final dataSource = PedometerDataSourceImpl();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final pedometerRepositoryProvider = Provider<PedometerRepository>((ref) {
  final dataSource = ref.watch(pedometerDataSourceProvider);
  return PedometerRepositoryImpl(dataSource: dataSource);
});

final pedometerUseCaseProvider = Provider<PedometerUseCase>((ref) {
  final repository = ref.watch(pedometerRepositoryProvider);
  return PedometerUseCase(repository: repository);
});

final pedometerControllerProvider =
    StateNotifierProvider<PedometerController, PedometerState>((ref) {
  final controller = PedometerController(ref.watch(pedometerUseCaseProvider));
  Future<void>.microtask(controller.initialize);
  ref.onDispose(controller.dispose);
  return controller;
});
