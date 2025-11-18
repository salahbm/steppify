abstract class PedometerDataSource {
  Stream<int> get stepStream;
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<bool> requestPermission();
  Future<bool> toggleBackgroundUpdates(bool enable);

  void dispose();
}

class PedometerDataSourceImpl implements PedometerDataSource {
  // TODO: Implement using a plugin such as 'pedometer' or 'health'
  @override
  Stream<int> get stepStream => Stream.periodic(
    const Duration(seconds: 1),
    (count) => count * 5, // Simulated step count
  );

  @override
  Future<void> startTracking() async {
    // Simulate
  }

  @override
  Future<void> stopTracking() async {
    // Simulate
  }

  @override
  Future<bool> requestPermission() async {
    // Simulate permission granted
    return true;
  }

  @override
  Future<bool> toggleBackgroundUpdates(bool enable) async {
    // Simulate toggle success
    return enable;
  }

  @override
  void dispose() {}
}
