import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:vector_math/vector_math_64.dart';

import '../sim/pru_rules.dart';
import '../sim/scenarios.dart';
import '../sim/sim_isolate.dart';
import '../sim/world_seed.dart';
import 'camera_controller.dart';
import 'painters/galaxy_painter.dart';
import 'painters/overlays.dart';
import 'painters/system_painter.dart';

class GameRoot extends FlameGame with PanDetector, ScaleDetector, TapDetector {
  GameRoot();

  late final CameraController cameraController;
  late final GalaxyPainter galaxyPainter;
  late final SystemPainter systemPainter;
  late final OverlayPainter overlayPainter;

  SimController? _sim;
  StreamSubscription<SimSnapshot>? _subscription;
  List<EntitySnapshot> _entities = const [];
  OverlayMode overlayMode = OverlayMode.none;
  EntitySnapshot? selected;
  double starlight = 0;
  double order = 0;
  UniverseSeed? seed;
  final ValueNotifier<SimSnapshot?> snapshotNotifier = ValueNotifier(null);
  final ValueNotifier<EntitySnapshot?> selectedNotifier = ValueNotifier(null);
  final ValueNotifier<OverlayMode> overlayNotifier = ValueNotifier(OverlayMode.none);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    cameraController = CameraController();
    galaxyPainter = GalaxyPainter();
    systemPainter = SystemPainter();
    overlayPainter = OverlayPainter();

    final scenarioLibrary = await ScenarioLibrary.load();
    final scenario = scenarioLibrary.scenarios.first;
    seed = UniverseSeed(masterSeed: 90210, scenario: scenario);
    final ruleSet = await PRURuleSet.load(seed!);
    cameraController.position = Vector2(
      scenario.cameraStart[0],
      scenario.cameraStart[1],
    );
    cameraController.zoom = scenario.cameraStart.length > 2 ? scenario.cameraStart[2] : 1.0;

    _sim = SimController(seed!, ruleSet);
    await _sim!.start();
    _subscription = _sim!.snapshots.listen((snapshot) {
      _entities = snapshot.entities;
      starlight = snapshot.starlight;
      order = snapshot.order;
      snapshotNotifier.value = snapshot;
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    final center = Offset(size.x / 2, size.y / 2);
    canvas.translate(center.dx, center.dy);
    canvas.scale(cameraController.zoom, cameraController.zoom);
    canvas.translate(-cameraController.position.x, -cameraController.position.y);
    galaxyPainter.paint(canvas, _entities, cameraController.zoom);
    systemPainter.paint(canvas, _entities, cameraController.zoom);
    overlayPainter.paint(canvas, _entities, overlayMode, cameraController.zoom);
    canvas.restore();
  }

  @override
  void onPanStart(DragStartInfo info) {
    cameraController.onPanStart(info.raw, Vector2(size.x, size.y));
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    cameraController.onPanUpdate(info.raw, Vector2(size.x, size.y));
  }

  @override
  void onPanEnd(DragEndInfo info) {
    cameraController.onPanEnd(info.raw);
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    cameraController.onScaleUpdate(info.raw);
  }

  @override
  void onTapUp(TapUpInfo info) {
    final screenSize = Vector2(size.x, size.y);
    final world = cameraController.screenToWorld(info.eventPosition.global.toVector2(), screenSize);
    selected = _nearestEntity(world);
    selectedNotifier.value = selected;
  }

  EntitySnapshot? _nearestEntity(Vector2 position) {
    EntitySnapshot? nearest;
    var bestDist = double.infinity;
    for (final entity in _entities) {
      final dx = entity.x - position.x;
      final dy = entity.y - position.y;
      final dist = dx * dx + dy * dy;
      if (dist < bestDist) {
        bestDist = dist;
        nearest = entity;
      }
    }
    return nearest;
  }

  void setOverlay(OverlayMode mode) {
    overlayMode = mode;
    overlayNotifier.value = mode;
  }

  void placeStar(Vector2 position) {
    _sim?.sendCommand('placeStar', {'x': position.x, 'y': position.y});
  }

  void seedLife(int entityId) {
    _sim?.sendCommand('seedLife', entityId);
  }

  void buildRelay(int entityId) {
    _sim?.sendCommand('buildRelay', entityId);
  }

  @override
  Future<void> onDetach() async {
    await _subscription?.cancel();
    await _sim?.dispose();
    super.onDetach();
  }

  @override
  void onRemove() {
    snapshotNotifier.dispose();
    selectedNotifier.dispose();
    overlayNotifier.dispose();
    super.onRemove();
  }
}
