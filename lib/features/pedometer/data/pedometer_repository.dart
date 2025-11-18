import 'pedometer_data_source.dart';

abstract class PedometerRepository {
  Stream<int> get stepCountStream;
  Future<void> startListening();
  Future<void> stopListening();
  Future<bool> requestPermission();
  Future<bool> enableBackgroundUpdates(bool enable);
}

class PedometerRepositoryImpl implements PedometerRepository {
  PedometerRepositoryImpl({required this.dataSource});
  final PedometerDataSource dataSource;

  @override
  Stream<int> get stepCountStream => dataSource.stepStream;

  @override
  Future<void> startListening() => dataSource.startTracking();

  @override
  Future<void> stopListening() => dataSource.stopTracking();

  @override
  Future<bool> requestPermission() => dataSource.requestPermission();

  @override
  Future<bool> enableBackgroundUpdates(bool enable) =>
      dataSource.toggleBackgroundUpdates(enable);
}
