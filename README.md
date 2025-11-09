# PRUverse — Flutter Universe Simulation

PRUverse is a deterministic, multi-platform universe sandbox powered by Flutter and the Flame game engine. The simulation models a Precomputed Relational Universe (PRU) where stars, planets, biospheres, and civilizations respond to aggregated relational fields instead of expensive pairwise forces. The experience runs on Android, iOS, and the web from a single code base.

The repository also retains the earlier Python prototypes (`sim.py`, `universe_sim.py`) for historical comparison, but the Flutter client is the authoritative, feature-rich implementation.

## Project layout

```
flutter_app/
  lib/
    core/             # math helpers, seeded RNG, deterministic noise
    render/           # Flame game, painters, camera helpers
    sim/              # PRU grid, ECS, isolate, systems, scenarios
    ui/               # HUD, build menu, dialogs, tech tree widgets
    data/             # deterministic tech tree & scenario definitions
  assets/rules.yaml   # PRU relational rule table (loaded at runtime)
  test/widget_test.dart
```

## Requirements

* Flutter 3.19+ (stable channel recommended)
* Dart 3.3+

Install Flutter by following the [official instructions](https://docs.flutter.dev/get-started/install) for your platform. The project has no binary assets and can be built with either the default web renderer or CanvasKit.

## Running the simulation

```bash
cd flutter_app
flutter pub get
flutter run -d chrome           # Web
# or
flutter run -d ios               # iOS
flutter run -d android           # Android
```

### Controls & HUD

* **Pan** – drag/touch and drag
* **Zoom** – scroll or pinch
* **Tap** – select the nearest entity and open the inspector
* **Build panel** – bottom-left card to place stars, seed life, or deploy relays
* **Overlays** – bottom-right panel toggles mass, energy, and habitability visualizations
* **Minimap** – top-left; tap to refocus the main camera
* **Tech tree** – top bar button showing deterministic unlocks and resource totals

### Gameplay loop (MVP)

1. Pick a scenario (e.g., Tiny Spiral or Star Nursery) and explore the emergent PRU fields.
2. Place stars to increase **Starlight**, the energy throughput resource.
3. Watch the formation system spawn planets and biospheres driven by local field samples.
4. Seed life to accelerate evolution and unlock civilizations.
5. Deploy relays to reinforce regional PRU fields, visible through the overlay toggles.

All randomness originates from a single `UniverseSeed`, ensuring deterministic outcomes across desktop, mobile, and web builds.

## Architecture highlights

* **PRU Fields** – `lib/sim/pru_rules.dart` and `assets/rules.yaml` describe multi-scale relational fields. The `UniverseGrid` lazily composes cells on demand and caches the results with an LRU policy.
* **Deterministic RNG** – `lib/core/rng.dart` implements a SplitMix64 generator feeding all procedural systems.
* **O(N) Simulation** – entities are updated by systems in `lib/sim/systems/`, each sampling PRU fields instead of performing pairwise interactions.
* **Simulation isolate** – `lib/sim/sim_isolate.dart` runs the fixed-timestep loop (30 Hz) in a background isolate and streams snapshots to the render thread.
* **Rendering** – `lib/render/game_root.dart` hosts the Flame `Game` that applies camera transforms, paints galaxy backgrounds, system details, and analytical overlays.
* **UI Layer** – Flutter overlays provide HUD, minimap, inspector, build menu, tech tree, and configuration dialogs.

## Testing

The project contains a deterministic regression test:

```bash
cd flutter_app
flutter test
```

`test/widget_test.dart` spins up the PRU simulation twice with the same seed and verifies identical entity counts, guarding against accidental non-determinism.

## Building for production

```bash
flutter build web --web-renderer canvaskit --release
flutter build apk --release
flutter build ios --release
```

All builds are asset-light and generate their visuals procedurally.

## Python prototypes

For archival purposes the original pygame sandboxes remain available:

```bash
python sim.py
python universe_sim.py
```

These prototypes are no longer feature-complete but are useful for understanding the evolution of the PRU approach.
