# Universe Simulation Suite

This repository now contains two complementary takes on the Precomputed Relational Universe (PRU):

* **`sim.py` / `universe_sim.py`** – the original pygame prototypes.
* **`flutter_app/`** – a Flutter-powered, mobile and web-ready experience that gamifies the simulation while keeping the PRU physics intact.

## Flutter experience

The Flutter client was handcrafted to mirror the relational physics of the prototype while introducing a modern UI, mobile gestures, procedural scenarios, and a playful comet-spawning mechanic. It runs on iOS, Android, and the web.

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.19 or newer
* Dart 3.3 or newer

### Getting started

```bash
cd flutter_app
flutter pub get
flutter run -d chrome   # or ios, android, etc.
```

Available presets can be switched from the control panel (bottom-right). Pinch to zoom, drag to pan, and double-tap to recenter the camera. Use the floating action button to spawn comets that interact with the existing systems using precomputed accelerations.

## Python prototypes

The original pygame sandboxes remain untouched for reference.

```bash
python sim.py
# or
python universe_sim.py
```

Feel free to compare both implementations or extend either path further.
