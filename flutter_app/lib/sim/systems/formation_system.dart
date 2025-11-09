import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/mathf.dart';
import '../components/biosphere.dart';
import '../components/orbit.dart';
import '../components/planet.dart';
import '../components/star.dart';
import '../components/transform.dart';
import '../ecs.dart';
import '../pru_types.dart';

class FormationSystem extends SimSystem {
  @override
  void update(double dt, SimState state) {
    for (final id in state.queryStars()) {
      final star = state.stars[id]!;
      final transform = state.ensureTransform(id);
      star.age += dt;
      state.starlight += star.luminosity * dt * 0.05;
      final field = state.sampler.sampleMultiScale(transform.position);
      _maybeSpawnPlanet(state, id, star, transform, field);
      _updatePlanets(state, id, star, dt, field);
    }
  }

  void _maybeSpawnPlanet(
    SimState state,
    EntityId starId,
    StarComponent star,
    TransformComponent starTransform,
    PRUField field,
  ) {
    if (star.planetIds.length >= 6) {
      return;
    }
    final spawnChance = (field.massDensity + field.energyFlux) * 0.15;
    if (spawnChance <= 0) {
      return;
    }
    if (state.rng.nextDouble01() < spawnChance * 0.01) {
      final planetId = state.createEntity();
      final orbitIndex = star.planetIds.length + 1;
      final baseRadius = 80.0 + orbitIndex * 40.0;
      state.transforms[planetId] = TransformComponent(
        position: Vector2.copy(starTransform.position + Vector2(baseRadius, 0)),
        velocity: Vector2.zero(),
      );
      state.orbits[planetId] = OrbitComponent(
        radius: baseRadius,
        angle: state.rng.nextDouble01() * Mathf.tau,
        angularVelocity: 0.05 + field.angularBias * 0.1,
      );
      final planet = PlanetComponent(orbitIndex: orbitIndex);
      planet.resourceValue = math.max(0.1, field.energyFlux + field.massDensity * 0.5);
      state.planets[planetId] = planet;
      state.biospheres[planetId] = BiosphereComponent(stage: BiosphereStage.sterile);
      star.planetIds.add(planetId);
    }
  }

  void _updatePlanets(
    SimState state,
    EntityId starId,
    StarComponent star,
    double dt,
    PRUField starField,
  ) {
    for (final planetId in star.planetIds) {
      final planet = state.planets[planetId];
      if (planet == null) {
        continue;
      }
      planet.formationProgress = Mathf.clamp(
        planet.formationProgress + (starField.massDensity + starField.energyFlux) * dt * 0.01,
        0,
        1,
      );
    }
  }
}
