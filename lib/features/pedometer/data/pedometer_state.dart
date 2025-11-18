class PedometerState {
  final bool isLoading;
  final int totalSteps;
  final bool hasPermission;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool isSupported;

  PedometerState({
    required this.isLoading,
    required this.totalSteps,
    required this.hasPermission,
    required this.isSupported,
    this.errorMessage,
    this.lastUpdated,
  });

  factory PedometerState.initial() => PedometerState(
    isLoading: false,
    totalSteps: 0,
    hasPermission: true,
    isSupported: true,
    lastUpdated: null,
    errorMessage: null,
  );

  PedometerState copyWith({
    bool? isLoading,
    int? totalSteps,
    bool? hasPermission,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? isSupported,
    bool clearError = false,
  }) {
    return PedometerState(
      isLoading: isLoading ?? this.isLoading,
      totalSteps: totalSteps ?? this.totalSteps,
      hasPermission: hasPermission ?? this.hasPermission,
      isSupported: isSupported ?? this.isSupported,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
