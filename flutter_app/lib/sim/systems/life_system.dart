import '../components/biosphere.dart';
import '../components/civilization.dart';
import '../ecs.dart';

class LifeSystem extends SimSystem {
  @override
  void update(double dt, SimState state) {
    for (final entry in state.biospheres.entries) {
      final id = entry.key;
      final biosphere = entry.value;
      final transform = state.transforms[id];
      if (transform == null) {
        continue;
      }
      final field = state.sampler.sampleMultiScale(transform.position);
      final growth = (field.habitability + field.energyFlux * 0.5) * dt * 0.05;
      biosphere.progress += growth;
      if (biosphere.progress >= 1) {
        biosphere.progress = 0;
        biosphere.stage = _nextStage(biosphere.stage);
        if (biosphere.stage == BiosphereStage.intelligent && !state.civilizations.containsKey(id)) {
          state.civilizations[id] = CivilizationComponent(level: CivilizationLevel.nascent);
        }
      }
    }
  }

  BiosphereStage _nextStage(BiosphereStage stage) {
    switch (stage) {
      case BiosphereStage.sterile:
        return BiosphereStage.proto;
      case BiosphereStage.proto:
        return BiosphereStage.simple;
      case BiosphereStage.simple:
        return BiosphereStage.complex;
      case BiosphereStage.complex:
        return BiosphereStage.intelligent;
      case BiosphereStage.intelligent:
        return BiosphereStage.intelligent;
    }
  }
}
