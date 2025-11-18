import '../data/pedometer_repository.dart';

class PedometerUseCase {
  PedometerUseCase({required PedometerRepository repository})
    : _repository = repository;

  final PedometerRepository _repository;

  Stream<int> get stepStream => _repository.stepCountStream;

  Future<void> startTracking() => _repository.startListening();

  Future<void> stopTracking() => _repository.stopListening();

  Future<bool> requestPermission() => _repository.requestPermission();

  Future<bool> toggleBackgroundTracking(bool enable) =>
      _repository.enableBackgroundUpdates(enable);

  String motivationalQuote(int steps) {
    const quotes = <int, String>{
      0: 'The first step is the hardest – you already did it! 🚶',
      2000: 'Nice groove! Keep pushing toward your goal. 🎧',
      5000: 'Halfway hero – stay unstoppable. ⚡',
      8000: 'Almost there! Feel the energy rise. 🔥',
      10000: 'Goal crusher! Celebrate the wins. 🏆',
    };

    String selected = quotes.entries.first.value;
    for (final entry in quotes.entries) {
      if (steps >= entry.key) {
        selected = entry.value;
      }
    }
    return selected;
  }
}
