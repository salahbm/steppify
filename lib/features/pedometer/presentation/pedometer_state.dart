class PedometerState {
  const PedometerState({
    required this.totalSteps,
    required this.goal,
    required this.isLoading,
    required this.hasPermission,
    required this.isSupported,
    this.errorMessage,
    this.lastUpdated,
  });

  final int totalSteps;
  final int goal;
  final bool isLoading;
  final bool hasPermission;
  final bool isSupported;
  final String? errorMessage;
  final DateTime? lastUpdated;

  double get progress => goal == 0 ? 0 : (totalSteps / goal).clamp(0, 1).toDouble();

  PedometerState copyWith({
    int? totalSteps,
    int? goal,
    bool? isLoading,
    bool? hasPermission,
    bool? isSupported,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return PedometerState(
      totalSteps: totalSteps ?? this.totalSteps,
      goal: goal ?? this.goal,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      isSupported: isSupported ?? this.isSupported,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory PedometerState.initial() {
    return const PedometerState(
      totalSteps: 0,
      goal: 10000,
      isLoading: true,
      hasPermission: false,
      isSupported: true,
      errorMessage: null,
      lastUpdated: null,
    );
  }
}
