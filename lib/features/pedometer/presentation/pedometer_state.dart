import '../domain/pedometer_entity.dart';

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
      errorMessage: resetErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
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
