import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../core/mathf.dart';
import '../core/rng.dart';
import 'components/star.dart';
import 'components/transform.dart';
import 'ecs.dart';
import 'scenarios.dart';

class UniverseSeed {
  UniverseSeed({required this.masterSeed, required this.scenario});

  final int masterSeed;
  final ScenarioDefinition scenario;

  int get rulesSeed => masterSeed ^ 0xA5A5A5A5;
  int get entitySeed => masterSeed ^ 0x5A5A5A5A;
  int get noiseSeed => masterSeed ^ 0x13579BDF;
}

class WorldBuilder {
  WorldBuilder(this.state);

  final SimState state;

  void populateInitial() {
    final scenario = state.seed.scenario;
    final rng = SeededRng(state.seed.masterSeed);
    final baseRadius = scenario.initialRadius;
    for (var i = 0; i < scenario.initialStars; i++) {
      final angle = i / math.max(1, scenario.initialStars - 1) * Mathf.tau + rng.nextDouble01() * 0.2;
      final radius = baseRadius * (0.5 + rng.nextDouble01() * 0.5);
      final position = Vector2(math.cos(angle), math.sin(angle)) * radius;
      _spawnStar(position, rng);
    }
  }

  void _spawnStar(Vector2 position, SeededRng rng) {
    final id = state.createEntity();
    state.transforms[id] = TransformComponent(position: position, velocity: Vector2.zero());
    state.stars[id] = StarComponent(
      luminosity: 1.0 + rng.nextDouble01() * 1.5,
      temperature: 4500 + rng.nextRange(0, 2000),
    );
  }
}
