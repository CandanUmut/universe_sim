import 'dart:math' as math;
import 'dart:typed_data';

/// Deterministic seeded random number generator based on SplitMix64.
class SeededRng {
  SeededRng(int seed)
      : _state = Uint64List(1) {
    _state[0] = (seed.toUnsigned(64) ^ 0x9E3779B97F4A7C15) & _mask;
    // Warm up to avoid low-entropy first values.
    for (var i = 0; i < 4; i++) {
      nextU32();
    }
  }

  static const int _mask = 0xFFFFFFFFFFFFFFFF;
  final Uint64List _state;

  int _nextU64() {
    var z = (_state[0] + 0x9E3779B97F4A7C15) & _mask;
    _state[0] = z;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 & _mask;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB & _mask;
    return z ^ (z >> 31);
  }

  /// Returns a uniformly distributed unsigned 32-bit integer.
  int nextU32() => _nextU64() & 0xFFFFFFFF;

  /// Returns a double in the range [0, 1).
  double nextDouble01() {
    final value = _nextU64() >> 11;
    return value / (1 << 53);
  }

  /// Returns an integer in [min, max).
  int nextRange(int min, int max) {
    assert(max > min);
    final span = max - min;
    return min + (nextU32() % span);
  }

  /// Shuffles a list deterministically.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextRange(0, i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  /// Returns a normally distributed double using Box-Muller.
  double nextGaussian({double mean = 0, double deviation = 1}) {
    final u1 = nextDouble01().clamp(1e-9, 1.0);
    final u2 = nextDouble01();
    final mag = math.sqrt(-2.0 * math.log(u1));
    final theta = 2.0 * math.pi * u2;
    return mean + deviation * mag * math.cos(theta);
  }
}
