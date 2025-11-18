/// Entity used across the presentation and domain layers.
class PedometerEntity {
  const PedometerEntity({
    required this.totalSteps,
    required this.goal,
    required this.isTracking,
    required this.backgroundTrackingEnabled,
    required this.motivationalQuote,
    required this.lastUpdated,
  });

  final int totalSteps;
  final double goal;
  final bool isTracking;
  final bool backgroundTrackingEnabled;
  final String motivationalQuote;
  final DateTime? lastUpdated;

  double get progress => (totalSteps / goal).clamp(0, 1);

  PedometerEntity copyWith({
    int? totalSteps,
    double? goal,
    bool? isTracking,
    bool? backgroundTrackingEnabled,
    String? motivationalQuote,
    DateTime? lastUpdated,
  }) {
    return PedometerEntity(
      totalSteps: totalSteps ?? this.totalSteps,
      goal: goal ?? this.goal,
      isTracking: isTracking ?? this.isTracking,
      backgroundTrackingEnabled:
          backgroundTrackingEnabled ?? this.backgroundTrackingEnabled,
      motivationalQuote: motivationalQuote ?? this.motivationalQuote,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory PedometerEntity.initial({double goal = 10000}) {
    return PedometerEntity(
      totalSteps: 0,
      goal: goal,
      isTracking: false,
      backgroundTrackingEnabled: false,
      motivationalQuote: 'Let\'s get those steps in! 💪',
      lastUpdated: null,
    );
  }
}
