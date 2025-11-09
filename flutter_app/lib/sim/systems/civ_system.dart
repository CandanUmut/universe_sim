import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/mathf.dart';
import '../components/civilization.dart';
import '../components/relay.dart';
import '../components/transform.dart';
import '../ecs.dart';

class CivSystem extends SimSystem {
  @override
  void update(double dt, SimState state) {
    for (final entry in state.civilizations.entries) {
      final id = entry.key;
      final civ = entry.value;
      final transform = state.transforms[id];
      if (transform == null) {
        continue;
      }
      final field = state.sampler.sampleMultiScale(transform.position);
      civ.influence += (field.civPressure + field.habitability * 0.5) * dt * 0.05;
      civ.cohesion = Mathf.clamp(civ.cohesion + field.angularBias * dt * 0.01, 0.1, 1.0);
      state.order += civ.cohesion * dt * 0.05;
      if (civ.influence > _thresholdForLevel(civ.level)) {
        civ.influence = 0;
        civ.level = _nextLevel(civ.level);
        _spawnRelay(state, transform.position, civ);
      }
    }

    for (final relayEntry in state.relays.entries) {
      final relay = relayEntry.value;
      relay.cooldown = math.max(0, relay.cooldown - dt);
    }
  }

  double _thresholdForLevel(CivilizationLevel level) {
    switch (level) {
      case CivilizationLevel.nascent:
        return 1.0;
      case CivilizationLevel.planetary:
        return 2.0;
      case CivilizationLevel.interstellar:
        return double.infinity;
    }
  }

  CivilizationLevel _nextLevel(CivilizationLevel level) {
    switch (level) {
      case CivilizationLevel.nascent:
        return CivilizationLevel.planetary;
      case CivilizationLevel.planetary:
        return CivilizationLevel.interstellar;
      case CivilizationLevel.interstellar:
        return CivilizationLevel.interstellar;
    }
  }

  void _spawnRelay(SimState state, Vector2 origin, CivilizationComponent civ) {
    if (civ.level == CivilizationLevel.interstellar) {
      return;
    }
    final relayId = state.createEntity();
    final offset = Vector2(math.cos(state.rng.nextDouble01() * Mathf.tau), math.sin(state.rng.nextDouble01() * Mathf.tau)) *
        (150 + civ.level.index * 60);
    state.transforms[relayId] = TransformComponent(position: origin + offset, velocity: Vector2.zero());
    state.relays[relayId] = RelayComponent(strength: 0.5 + civ.level.index * 0.3);
  }
}
