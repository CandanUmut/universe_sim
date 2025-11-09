import 'dart:math';

/// Generates deterministic hashed identifiers for grid cells and entities.
class IdHasher {
  IdHasher(this.seed);

  final int seed;

  int cellKey(int level, int x, int y) {
    var h = seed + level * 0x9E3779B9;
    h ^= x * 0x51ED2701;
    h ^= y * 0xDA442D24;
    h = (h ^ (h >> 16)) * 0x45d9f3b;
    h = (h ^ (h >> 16)) * 0x45d9f3b;
    h ^= h >> 16;
    return h & 0x7FFFFFFF;
  }

  int entityId(int index) {
    return (seed ^ (index * 0x632BE5AB)) & 0x7FFFFFFF;
  }

  int hashPosition(double x, double y, double cellSize) {
    final cx = (x / cellSize).floor();
    final cy = (y / cellSize).floor();
    return cellKey(cellSize.toInt(), cx, cy);
  }
}

/// Deterministic stable mapping from hash to color gradient 0..1.
double hashUnit(int hash) {
  final value = (hash ^ (hash >> 15)) & 0xFFFFFFFF;
  return value / 0xFFFFFFFF;
}

/// Maps an index to a pseudo-random angle.
double hashAngle(int hash) => (hashUnit(hash) * pi * 2.0) % (pi * 2.0);
