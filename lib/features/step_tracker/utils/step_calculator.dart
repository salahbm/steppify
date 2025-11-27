/// Utility class for step calculations
class StepCalculator {
  /// Calculate today's steps for Android
  static int calculateAndroidTodaySteps({
    required int stepsSinceReboot,
    required int midnightBaseline,
  }) {
    final steps = stepsSinceReboot - midnightBaseline;
    return steps > 0 ? steps : 0;
  }

  /// Calculate steps since open for iOS
  static int calculateIOSSinceOpenSteps({
    required int currentSteps,
    required int bootSteps,
  }) {
    final steps = currentSteps - bootSteps;
    return steps > 0 ? steps : 0;
  }

  /// Format date as YYYY-MM-DD
  static String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Check if it's a new day
  static bool isNewDay(String currentDate, DateTime now) {
    final todayStr = formatDate(now);
    return todayStr != currentDate;
  }
}
