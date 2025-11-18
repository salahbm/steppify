import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:steppify/features/pedometer/domain/pedometer_usecase.dart';
import 'pedometer_data_source.dart';
import 'pedometer_repository.dart';

// Data source provider
final pedometerDataSourceProvider = Provider<PedometerDataSource>((ref) {
  final dataSource = PedometerDataSourceImpl();
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

// Repository provider
final pedometerRepositoryProvider = Provider<PedometerRepository>((ref) {
  final dataSource = ref.watch(pedometerDataSourceProvider);
  return PedometerRepositoryImpl(dataSource: dataSource);
});

// Use case provider
final pedometerUseCaseProvider = Provider<PedometerUseCase>((ref) {
  final repository = ref.watch(pedometerRepositoryProvider);
  return PedometerUseCase(repository: repository);
});
