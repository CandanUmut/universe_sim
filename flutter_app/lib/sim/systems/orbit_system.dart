import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/mathf.dart';
import '../ecs.dart';
import '../pru_types.dart';

class OrbitSystem extends SimSystem {
  @override
  void update(double dt, SimState state) {
    for (final entry in state.orbits.entries) {
      final id = entry.key;
      final orbit = entry.value;
      final transform = state.ensureTransform(id);
      final position = transform.position;
      final field = state.sampler.sampleMultiScale(position);
      final targetAngular = field.angularBias * 0.5 + 0.05;
      orbit.angularVelocity += (targetAngular - orbit.angularVelocity) * dt * 0.5;
      orbit.angle = Mathf.wrapAngle(orbit.angle + orbit.angularVelocity * dt * Mathf.tau);
      final stableRadius = math.max(32.0, orbit.radius * (1.0 + field.massDensity * 0.02 - field.energyFlux * 0.01));
      transform.position = Vector2(math.cos(orbit.angle), math.sin(orbit.angle)) * stableRadius;
      transform.velocity = Vector2(-math.sin(orbit.angle), math.cos(orbit.angle)) * (stableRadius * orbit.angularVelocity);
    }
  }
}
