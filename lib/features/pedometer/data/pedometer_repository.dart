import 'package:steppify/features/pedometer/data/pedometer_data_source.dart';

abstract class PedometerRepository {
  Stream<int> get stepCountStream;
  Future<void> startListening();
  Future<void> stopListening();
  Future<bool> requestPermission();
  Future<bool> enableBackgroundUpdates(bool enable);
}

class PedometerRepositoryImpl implements PedometerRepository {
  final PedometerDataSource _dataSource;

  PedometerRepositoryImpl(this._dataSource);

  @override
  Stream<int> get stepCountStream => _dataSource.stepStream;

  @override
  Future<void> startListening() => _dataSource.startTracking();

  @override
  Future<void> stopListening() => _dataSource.stopTracking();

  @override
  Future<bool> requestPermission() => _dataSource.requestPermission();

  @override
  Future<bool> enableBackgroundUpdates(bool enable) =>
      _dataSource.toggleBackgroundUpdates(enable);
}
