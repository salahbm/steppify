class PedometerState {
  final bool isLoading;
  final int totalSteps;
  final int sinceAppLaunch;
  final bool hasPermission;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool isSupported;

  PedometerState({
    required this.isLoading,
    required this.totalSteps,
    required this.sinceAppLaunch,
    required this.hasPermission,
    required this.isSupported,
    this.errorMessage,
    this.lastUpdated,
  });

  factory PedometerState.initial() => PedometerState(
    isLoading: false,
    totalSteps: 0,
    sinceAppLaunch: 0,
    hasPermission: true,
    isSupported: true,
    lastUpdated: null,
    errorMessage: null,
  );

  PedometerState copyWith({
    bool? isLoading,
    int? totalSteps,
    int? sinceAppLaunch,
    bool? hasPermission,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? isSupported,
    bool clearError = false,
  }) {
    return PedometerState(
      isLoading: isLoading ?? this.isLoading,
      totalSteps: totalSteps ?? this.totalSteps,
      sinceAppLaunch: sinceAppLaunch ?? this.sinceAppLaunch,
      hasPermission: hasPermission ?? this.hasPermission,
      isSupported: isSupported ?? this.isSupported,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
