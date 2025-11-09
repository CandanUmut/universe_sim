import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

class Mathf {
  const Mathf._();

  static const double tau = math.pi * 2;

  static double clamp(double value, double min, double max) => value < min
      ? min
      : (value > max)
          ? max
          : value;

  static double lerp(double a, double b, double t) => a + (b - a) * t;

  static double smoothStep(double edge0, double edge1, double x) {
    final t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static Vector2 vec2Lerp(Vector2 a, Vector2 b, double t) {
    return Vector2(lerp(a.x, b.x, t), lerp(a.y, b.y, t));
  }

  static double length(Vector2 v) => v.length;

  static double angle(Vector2 v) => math.atan2(v.y, v.x);

  static Vector2 fromPolar(double r, double theta) {
    return Vector2(r * math.cos(theta), r * math.sin(theta));
  }

  static double wrapAngle(double angle) {
    var a = angle % tau;
    if (a < -math.pi) {
      a += tau;
    } else if (a > math.pi) {
      a -= tau;
    }
    return a;
  }
}
