import 'dart:collection';

import 'package:vector_math/vector_math_64.dart';

import '../core/ids.dart';
import '../core/rng.dart';
import 'components/biosphere.dart';
import 'components/civilization.dart';
import 'components/orbit.dart';
import 'components/planet.dart';
import 'components/relay.dart';
import 'components/star.dart';
import 'components/transform.dart';
import 'pru_grid.dart';
import 'pru_sampling.dart';
import 'pru_types.dart';
import 'systems/civ_system.dart';
import 'systems/formation_system.dart';
import 'systems/life_system.dart';
import 'systems/orbit_system.dart';
import 'systems/cleanup_system.dart';
import 'world_seed.dart';

typedef EntityId = int;

typedef ComponentMap<T> = LinkedHashMap<EntityId, T>;

class SimState {
  SimState({required this.seed, required this.grid})
      : entities = <EntityId>{},
        rng = SeededRng(seed.entitySeed),
        sampler = PRUSampler(grid),
        transforms = ComponentMap<TransformComponent>(),
        orbits = ComponentMap<OrbitComponent>(),
        stars = ComponentMap<StarComponent>(),
        planets = ComponentMap<PlanetComponent>(),
        biospheres = ComponentMap<BiosphereComponent>(),
        civilizations = ComponentMap<CivilizationComponent>(),
        relays = ComponentMap<RelayComponent>(),
        _idHasher = IdHasher(seed.entitySeed),
        systems = [] {
    systems.addAll([
      OrbitSystem(),
      FormationSystem(),
      LifeSystem(),
      CivSystem(),
      CleanupSystem(),
    ]);
  }

  final UniverseSeed seed;
  final UniverseGrid grid;
  final Set<EntityId> entities;
  final SeededRng rng;
  final PRUSampler sampler;
  final ComponentMap<TransformComponent> transforms;
  final ComponentMap<OrbitComponent> orbits;
  final ComponentMap<StarComponent> stars;
  final ComponentMap<PlanetComponent> planets;
  final ComponentMap<BiosphereComponent> biospheres;
  final ComponentMap<CivilizationComponent> civilizations;
  final ComponentMap<RelayComponent> relays;
  final List<SimSystem> systems;
  final IdHasher _idHasher;
  int _entityIndex = 0;
  double starlight = 0;
  double order = 0;
  double elapsedTime = 0;

  EntityId createEntity() {
    final id = _idHasher.entityId(_entityIndex++);
    entities.add(id);
    return id;
  }

  void removeEntity(EntityId id) {
    entities.remove(id);
    transforms.remove(id);
    orbits.remove(id);
    stars.remove(id);
    planets.remove(id);
    biospheres.remove(id);
    civilizations.remove(id);
    relays.remove(id);
  }

  void update(double dt) {
    grid.clearLocalSources();
    for (final entry in relays.entries) {
      final id = entry.key;
      final relay = entry.value;
      final transform = transforms[id];
      if (transform == null) {
        continue;
      }
      for (final level in GridLevel.values) {
        final cellSize = level.cellSize;
        final cellX = (transform.position.x / cellSize).floor();
        final cellY = (transform.position.y / cellSize).floor();
        grid.addLocalSource(level, cellX, cellY, grid.rules.influenceForRelay(relay.strength));
      }
    }
    for (final system in systems) {
      system.update(dt, this);
    }
    elapsedTime += dt;
  }

  Iterable<EntityId> queryStars() => stars.keys;
  Iterable<EntityId> queryPlanets() => planets.keys;
  Iterable<EntityId> queryBiospheres() => biospheres.keys;
  Iterable<EntityId> queryCivilizations() => civilizations.keys;
  Iterable<EntityId> queryRelays() => relays.keys;

  TransformComponent ensureTransform(EntityId id) {
    return transforms.putIfAbsent(id, () => TransformComponent(position: Vector2.zero(), velocity: Vector2.zero()));
  }
}

abstract class SimSystem {
  void update(double dt, SimState state);
}
