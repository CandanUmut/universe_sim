import 'package:vector_math/vector_math_64.dart';

import '../ecs.dart';

class CleanupSystem extends SimSystem {
  @override
  void update(double dt, SimState state) {
    final removals = <EntityId>[];
    for (final entry in state.transforms.entries) {
      final id = entry.key;
      final transform = entry.value;
      if (transform.position.length2 > 250000000) {
        removals.add(id);
      }
    }
    for (final id in removals) {
      state.removeEntity(id);
    }
  }
}
