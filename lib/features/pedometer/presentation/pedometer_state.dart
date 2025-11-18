class PedometerState {
  const PedometerState({
    required this.totalSteps,
    required this.isLoading,
    required this.hasPermission,
    required this.isSupported,
    this.errorMessage,
    this.lastUpdated,
  });

  final int totalSteps;
  final bool isLoading;
  final bool hasPermission;
  final bool isSupported;
  final String? errorMessage;
  final DateTime? lastUpdated;

  bool get canTrack => isSupported && hasPermission;

  PedometerState copyWith({
    int? totalSteps,
    bool? isLoading,
    bool? hasPermission,
    bool? isSupported,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return PedometerState(
      totalSteps: totalSteps ?? this.totalSteps,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      isSupported: isSupported ?? this.isSupported,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory PedometerState.initial() {
    return const PedometerState(
      totalSteps: 0,
      isLoading: true,
      hasPermission: false,
      isSupported: true,
      errorMessage: null,
      lastUpdated: null,
    );
  }
}
