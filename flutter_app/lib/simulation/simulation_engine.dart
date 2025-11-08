import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import 'particle.dart';

const double gravitationalConstant = 6.67430e-11;
const double softening = 1e-3;

class SimulationEngine {
  SimulationEngine({
    required List<Particle> particles,
    this.maxTrailLength = 200,
  })  : _particles = particles.map((p) => p.clone()).toList() {
    _precomputeAccelerations();
  }

  final List<Particle> _particles;
  final int maxTrailLength;

  late List<Vector3> _accelerations;
  bool _needsRecompute = false;

  List<Particle> get particles => _particles;

  void markDirty() => _needsRecompute = true;

  void resetParticles(List<Particle> particles) {
    _particles
      ..clear()
      ..addAll(particles.map((p) => p.clone()));
    for (final particle in _particles) {
      particle.resetTrail();
    }
    _precomputeAccelerations();
  }

  void addParticle(Particle particle) {
    _particles.add(particle.clone());
    _needsRecompute = true;
  }

  void removeParticle(String name) {
    _particles.removeWhere((p) => p.name == name);
    _needsRecompute = true;
  }

  Vector3 get barycenter {
    double totalMass = 0;
    final Vector3 accumulator = Vector3.zero();
    for (final particle in _particles) {
      totalMass += particle.mass;
      accumulator.add(particle.position * particle.mass);
    }
    if (totalMass == 0) {
      return Vector3.zero();
    }
    return accumulator / totalMass;
  }

  void step(double deltaSeconds) {
    if (_needsRecompute) {
      _precomputeAccelerations();
    }

    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      final Vector3 acceleration = _accelerations[i];
      if (!particle.fixed) {
        particle.velocity += acceleration * deltaSeconds;
        particle.position += particle.velocity * deltaSeconds;
      }

      particle.trail.add(Offset(particle.position.x, particle.position.y));
      if (particle.trail.length > maxTrailLength) {
        particle.trail.removeRange(0, particle.trail.length - maxTrailLength);
      }
    }
  }

  void _precomputeAccelerations() {
    _accelerations = List<Vector3>.generate(
      _particles.length,
      (_) => Vector3.zero(),
    );

    for (var i = 0; i < _particles.length; i++) {
      final particleI = _particles[i];
      final Vector3 acc = _accelerations[i];

      for (var j = 0; j < _particles.length; j++) {
        if (i == j) continue;
        final particleJ = _particles[j];
        final Vector3 diff = particleJ.position - particleI.position;
        final double distanceSquared = math.max(diff.length2, softening);
        final double distance = math.sqrt(distanceSquared);
        final Vector3 direction = diff / distance;
        final double accelerationMagnitude =
            gravitationalConstant * particleJ.mass / distanceSquared;
        acc.add(direction * accelerationMagnitude);
      }
    }

    _needsRecompute = false;
  }
}
