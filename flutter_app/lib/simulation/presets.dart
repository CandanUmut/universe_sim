import 'dart:math';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import 'particle.dart';
import 'simulation_engine.dart' show gravitationalConstant;

class PresetSystems {
  static List<Particle> solarSystem() {
    const double au = 149_597_870.7; // kilometres
    const double scale = 1e-6; // convert km to simulation units

    Vector3 positionFromOrbit(double distanceAu) =>
        Vector3(distanceAu * au * scale, 0, 0);

    Vector3 orbitVelocity(double distanceAu, double centralMass) {
      final double distanceKm = distanceAu * au;
      final double velocity =
          math.sqrt(gravitationalConstant * centralMass / math.max(distanceKm * 1000, 1));
      return Vector3(0, velocity * scale, 0);
    }

    const double sunMass = 1.989e30;

    return <Particle>[
      Particle(
        name: 'Sun',
        mass: sunMass,
        radius: 20,
        color: const Color(0xFFFFD700),
        position: Vector3.zero(),
        velocity: Vector3.zero(),
        fixed: true,
        highlight: true,
      ),
      Particle(
        name: 'Mercury',
        mass: 3.285e23,
        radius: 6,
        color: const Color(0xFFC0C0C0),
        position: positionFromOrbit(0.39),
        velocity: orbitVelocity(0.39, sunMass),
      ),
      Particle(
        name: 'Venus',
        mass: 4.867e24,
        radius: 8,
        color: const Color(0xFFFFA500),
        position: positionFromOrbit(0.72),
        velocity: orbitVelocity(0.72, sunMass),
      ),
      Particle(
        name: 'Earth',
        mass: 5.972e24,
        radius: 9,
        color: const Color(0xFF1E90FF),
        position: positionFromOrbit(1.0),
        velocity: orbitVelocity(1.0, sunMass),
        highlight: true,
      ),
      Particle(
        name: 'Mars',
        mass: 6.39e23,
        radius: 7,
        color: const Color(0xFFB22222),
        position: positionFromOrbit(1.52),
        velocity: orbitVelocity(1.52, sunMass),
      ),
      Particle(
        name: 'Jupiter',
        mass: 1.898e27,
        radius: 15,
        color: const Color(0xFFFFF5EE),
        position: positionFromOrbit(5.2),
        velocity: orbitVelocity(5.2, sunMass),
      ),
      Particle(
        name: 'Saturn',
        mass: 5.683e26,
        radius: 14,
        color: const Color(0xFFF5DEB3),
        position: positionFromOrbit(9.58),
        velocity: orbitVelocity(9.58, sunMass),
      ),
      Particle(
        name: 'Uranus',
        mass: 8.681e25,
        radius: 12,
        color: const Color(0xFFAFEEEE),
        position: positionFromOrbit(19.2),
        velocity: orbitVelocity(19.2, sunMass),
      ),
      Particle(
        name: 'Neptune',
        mass: 1.024e26,
        radius: 12,
        color: const Color(0xFF4169E1),
        position: positionFromOrbit(30.05),
        velocity: orbitVelocity(30.05, sunMass),
      ),
    ];
  }

  static List<Particle> binaryDance() {
    final double mass = 4e30;
    final Vector3 offset = Vector3(3e5, 0, 0);
    final Vector3 velocity = Vector3(0, 8e1, 0);

    return <Particle>[
      Particle(
        name: 'Alpha',
        mass: mass,
        radius: 18,
        color: const Color(0xFFFF6B6B),
        position: -offset,
        velocity: velocity.clone(),
        highlight: true,
      ),
      Particle(
        name: 'Beta',
        mass: mass,
        radius: 18,
        color: const Color(0xFF4ECDC4),
        position: offset,
        velocity: -velocity,
        highlight: true,
      ),
      ...List<Particle>.generate(16, (int index) {
        final double angle = (index / 16) * math.pi * 2;
        final double radius = 8e5 + index * 5e4;
        final Vector3 pos = Vector3(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
          0,
        );
        final Vector3 vel = Vector3(-math.sin(angle), math.cos(angle), 0)
          ..scale(60 + index * 2);
        return Particle(
          name: 'Satellite-${index + 1}',
          mass: 5e22 + index * 3e20,
          radius: 5 + index % 3,
          color: Color.lerp(const Color(0xFF9B5DE5), const Color(0xFFFEE440), index / 16)!,
          position: pos,
          velocity: vel,
        );
      }),
    ];
  }

  static List<Particle> proceduralCluster(int seed) {
    final Random random = Random(seed);
    final List<Particle> particles = <Particle>[];
    const int count = 40;
    for (int i = 0; i < count; i++) {
      final double radius = (1 + random.nextDouble() * 9) * 2e5;
      final double angle = random.nextDouble() * math.pi * 2;
      final Vector3 pos = Vector3(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
        (random.nextDouble() - 0.5) * radius * 0.2,
      );
      final Vector3 vel = Vector3(
        -math.sin(angle),
        math.cos(angle),
        (random.nextDouble() - 0.5) * 0.4,
      )..scale(40 + random.nextDouble() * 30);
      particles.add(
        Particle(
          name: 'Cluster-${i + 1}',
          mass: 5e23 + random.nextDouble() * 3e23,
          radius: 5 + random.nextDouble() * 8,
          color: Color.lerp(const Color(0xFF48CAE4), const Color(0xFFCAF0F8), i / count)!,
          position: pos,
          velocity: vel,
        ),
      );
    }

    particles.add(
      Particle(
        name: 'Anchor',
        mass: 4e30,
        radius: 22,
        color: const Color(0xFFFFD166),
        position: Vector3.zero(),
        velocity: Vector3.zero(),
        fixed: true,
        highlight: true,
      ),
    );

    return particles;
  }
}
