import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pedometer_data_source.dart';
import 'pedometer_repository.dart';
import '../domain/pedometer_usecase.dart';

final pedometerDataSourceProvider = Provider<PedometerDataSource>((ref) {
  final dataSource = PedometerDataSourceImpl();
  ref.onDispose(() => dataSource.dispose());
  return dataSource;
});

final pedometerRepositoryProvider = Provider<PedometerRepository>((ref) {
  final dataSource = ref.read(pedometerDataSourceProvider);
  return PedometerRepositoryImpl(dataSource);
});

final pedometerUseCaseProvider = Provider<PedometerUseCase>((ref) {
  final repo = ref.read(pedometerRepositoryProvider);
  return PedometerUseCase(repository: repo);
});
