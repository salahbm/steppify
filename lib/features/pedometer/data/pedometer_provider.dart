import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'steps_repo.dart';

final stepsRepoProvider = Provider<StepsRepo>((ref) {
  final repo = StepsRepo.instance();
  ref.onDispose(repo.dispose);
  return repo;
});
