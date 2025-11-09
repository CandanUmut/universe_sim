import 'dart:math' as math;

/// Deterministic seeded RNG (SplitMix64) implemented with BigInt so it
/// works on web (no 64-bit int literals). Public API unchanged.
class SeededRng {
  SeededRng(int seed) : _state = _toU64(BigInt.from(seed)) {
    _state = (_state ^ _C) & _MASK;
    // Warm up to avoid low-entropy first values.
    for (var i = 0; i < 4; i++) {
      nextU32();
    }
  }

  // 64-bit mask and SplitMix64 constants as BigInt
  static final BigInt _MASK = (BigInt.one << 64) - BigInt.one;
  static final BigInt _C    = BigInt.parse('9E3779B97F4A7C15', radix: 16);
  static final BigInt _M1   = BigInt.parse('BF58476D1CE4E5B9', radix: 16);
  static final BigInt _M2   = BigInt.parse('94D049BB133111EB', radix: 16);

  BigInt _state;

  static BigInt _toU64(BigInt x) => x & ((BigInt.one << 64) - BigInt.one);

  BigInt _nextU64Big() {
    // SplitMix64 using BigInt ops (all masked to 64 bits)
    _state = (_state + _C) & _MASK;
    var z = _state;
    z = ((z ^ (z >> 30)) * _M1) & _MASK;
    z = ((z ^ (z >> 27)) * _M2) & _MASK;
    z = z ^ (z >> 31);
    return z & _MASK;
  }

  /// Returns a uniformly distributed unsigned 32-bit integer.
  int nextU32() {
    // Truncate to 32 bits -> safe to convert to JS number
    final v = _nextU64Big() & BigInt.from(0xFFFFFFFF);
    return v.toInt();
  }

  /// Returns a double in the range [0, 1).
  double nextDouble01() {
    // Use top 53 bits to make a JS-safe double fraction
    final v53 = _nextU64Big() >> 11; // 64-11 = 53 bits
    return v53.toInt() / 9007199254740992.0; // 2^53
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

  /// Returns a normally distributed double using Box–Muller.
  double nextGaussian({double mean = 0, double deviation = 1}) {
    final u1 = nextDouble01().clamp(1e-9, 1.0);
    final u2 = nextDouble01();
    final mag = math.sqrt(-2.0 * math.log(u1));
    final theta = 2.0 * math.pi * u2;
    return mean + deviation * mag * math.cos(theta);
  }
}
