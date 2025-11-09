import 'dart:math' as math;

/// Lightweight deterministic 2D noise used for PRU field perturbations.
class ValueNoise2D {
  const ValueNoise2D({required this.seed});

  final int seed;

  double noise(double x, double y) {
    final xi = x.floor();
    final yi = y.floor();
    final xf = x - xi;
    final yf = y - yi;

    double dot(int ix, int iy) {
      final hash = _hash(ix, iy);
      final angle = (hash & 0xFFFF) / 0xFFFF * math.pi * 2.0;
      final gradX = math.cos(angle);
      final gradY = math.sin(angle);
      final dx = x - ix;
      final dy = y - iy;
      return gradX * dx + gradY * dy;
    }

    final n00 = dot(xi, yi);
    final n10 = dot(xi + 1, yi);
    final n01 = dot(xi, yi + 1);
    final n11 = dot(xi + 1, yi + 1);

    final u = fade(xf);
    final v = fade(yf);

    return lerp(lerp(n00, n10, u), lerp(n01, n11, u), v);
  }

  double fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);

  double lerp(double a, double b, double t) => a + (b - a) * t;

  int _hash(int x, int y) {
    var h = seed;
    h ^= x * 0x27d4eb2d;
    h ^= y * 0x165667b1;
    h = (h ^ (h >> 15)) * 0x85ebca6b;
    h = (h ^ (h >> 13)) * 0xc2b2ae35;
    h ^= h >> 16;
    return h & 0xFFFFFFFF;
  }
}
