import 'package:vector_math/vector_math_64.dart';

import 'pru_grid.dart';
import 'pru_types.dart';

class PRUSampler {
  PRUSampler(this.grid);

  final UniverseGrid grid;

  PRUField sample(Vector2 position, GridLevel level) {
    return grid.sample(position.x, position.y, level);
  }

  PRUField sampleMultiScale(Vector2 position) {
    var combined = PRUField.zero;
    for (final level in GridLevel.values) {
      final field = sample(position, level);
      final weight = 1.0 / (level.index + 1);
      combined = combined.addWeighted(field, weight);
    }
    return combined;
  }
}
