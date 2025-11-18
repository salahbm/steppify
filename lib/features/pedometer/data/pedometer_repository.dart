import 'pedometer_data_source.dart';

/// Abstraction over the pedometer data layer.
abstract class PedometerRepository {
  Stream<int> get stepCountStream;

  Future<void> startListening();

  Future<void> stopListening();

  Future<bool> requestPermission();

  Future<bool> enableBackgroundUpdates(bool enable);
}

class PedometerRepositoryImpl implements PedometerRepository {
  PedometerRepositoryImpl({required PedometerDataSource dataSource})
      : _dataSource = dataSource;

  final PedometerDataSource _dataSource;

  @override
  Stream<int> get stepCountStream => _dataSource.stepCountStream;

  @override
  Future<bool> enableBackgroundUpdates(bool enable) {
    return _dataSource.enableBackgroundUpdates(enable);
  }

  @override
  Future<bool> requestPermission() {
    return _dataSource.requestPermission();
  }

  @override
  Future<void> startListening() {
    return _dataSource.startListening();
  }

  @override
  Future<void> stopListening() {
    return _dataSource.stopListening();
  }
}
