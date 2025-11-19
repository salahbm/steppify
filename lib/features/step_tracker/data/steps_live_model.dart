class StepLiveActivityModel {
  final int todaySteps;
  final int sinceOpenSteps;
  final int sinceBootSteps;
  final String status;

  StepLiveActivityModel({
    required this.todaySteps,
    required this.sinceOpenSteps,
    required this.sinceBootSteps,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'todaySteps': todaySteps,
      'sinceOpenSteps': sinceOpenSteps,
      'sinceBootSteps': sinceBootSteps,
      'status': status,
    };
  }

  StepLiveActivityModel copyWith({
    int? todaySteps,
    int? sinceOpenSteps,
    int? sinceBootSteps,
    String? status,
  }) {
    return StepLiveActivityModel(
      todaySteps: todaySteps ?? this.todaySteps,
      sinceOpenSteps: sinceOpenSteps ?? this.sinceOpenSteps,
      sinceBootSteps: sinceBootSteps ?? this.sinceBootSteps,
      status: status ?? this.status,
    );
  }
}
