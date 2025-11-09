import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

class Particle {
  Particle({
    required this.name,
    required this.mass,
    required this.radius,
    required this.color,
    required Vector3 position,
    required Vector3 velocity,
    this.fixed = false,
    this.spin = 0,
    this.highlight = false,
  })  : position = position.clone(),
        velocity = velocity.clone();

  final String name;
  final double mass;
  final double radius;
  final Color color;
  final bool fixed;
  final bool highlight;
  final List<Offset> trail = <Offset>[];
  Vector3 position;
  Vector3 velocity;
  double spin;

  Particle clone() => Particle(
        name: name,
        mass: mass,
        radius: radius,
        color: color,
        position: position.clone(),
        velocity: velocity.clone(),
        fixed: fixed,
        spin: spin,
        highlight: highlight,
      );

  void resetTrail() => trail.clear();
}
