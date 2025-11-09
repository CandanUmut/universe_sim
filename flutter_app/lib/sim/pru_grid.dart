import 'dart:collection';

import '../core/ids.dart';
import 'pru_rules.dart';
import 'pru_types.dart';

class UniverseGrid {
  UniverseGrid({required this.rules, this.maxCacheSize = 2048})
      : _cache = LinkedHashMap<int, PRUField>(),
        _localSources = <GridLevel, Map<int, List<PRUField>>>{},
        _hasher = IdHasher(rules.seed);

  final PRURuleSet rules;
  final int maxCacheSize;
  final LinkedHashMap<int, PRUField> _cache;
  final Map<GridLevel, Map<int, List<PRUField>>> _localSources;
  final IdHasher _hasher;

  void clearLocalSources() {
    for (final level in GridLevel.values) {
      _localSources[level] = {};
    }
  }

  void addLocalSource(GridLevel level, int cellX, int cellY, PRUField field) {
    final key = _cellKey(level, cellX, cellY);
    final map = _localSources.putIfAbsent(level, () => {});
    final list = map.putIfAbsent(key, () => []);
    list.add(field);
    _cache.remove(_cacheKey(level, key));
  }

  PRUField sample(double x, double y, GridLevel level) {
    final cellSize = level.cellSize;
    final cellX = (x / cellSize).floor();
    final cellY = (y / cellSize).floor();
    final cellKey = _cellKey(level, cellX, cellY);
    final cacheKey = _cacheKey(level, cellKey);
    final local = _localSources[level]?[cellKey] ?? const <PRUField>[];
    final cached = _cache[cacheKey];
    if (cached != null) {
      _touch(cacheKey, cached);
      return cached;
    }
    final field = rules.composeCell(
      level: level,
      cellX: cellX,
      cellY: cellY,
      localSources: local,
    );
    _insert(cacheKey, field);
    return field;
  }

  int _cellKey(GridLevel level, int cellX, int cellY) {
    return _hasher.cellKey(level.index, cellX, cellY);
  }

  int _cacheKey(GridLevel level, int cellKey) => (level.index << 28) ^ cellKey;

  void _insert(int key, PRUField field) {
    _cache[key] = field;
    if (_cache.length > maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  void _touch(int key, PRUField field) {
    _cache.remove(key);
    _cache[key] = field;
  }
}
