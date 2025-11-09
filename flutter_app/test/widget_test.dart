import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pru_universe/sim/ecs.dart';
import 'package:pru_universe/sim/pru_grid.dart';
import 'package:pru_universe/sim/pru_rules.dart';
import 'package:pru_universe/sim/scenarios.dart';
import 'package:pru_universe/sim/world_seed.dart';

Future<Map<String, int>> _runSimulation(UniverseSeed seed, int steps) async {
  final ruleSet = await PRURuleSet.load(seed);
  final grid = UniverseGrid(rules: ruleSet);
  final state = SimState(seed: seed, grid: grid);
  WorldBuilder(state).populateInitial();
  for (var i = 0; i < steps; i++) {
    state.update(1 / 30);
  }
  return {
    'stars': state.stars.length,
    'planets': state.planets.length,
    'biospheres': state.biospheres.length,
    'civilizations': state.civilizations.length,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('simulation remains deterministic for identical seeds', () async {
    final scenario = ScenarioDefinition(
      id: 'test',
      name: 'Test Scenario',
      description: 'Deterministic test scenario',
      initialStars: 5,
      initialRadius: 400,
      cameraStart: const [0.0, 0.0, 1.0],
    );
    final seed = UniverseSeed(masterSeed: 4242, scenario: scenario);
    // Ensure assets are available.
    await rootBundle.loadString('lib/data/tech_tree.json');

    final first = await _runSimulation(seed, 240);
    final second = await _runSimulation(seed, 240);
    expect(first, second);
  });
}
