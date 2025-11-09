import 'package:flame/extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class CameraController {
  double zoom = 1.0;
  vm.Vector2 position = vm.Vector2.zero();
  vm.Vector2? _lastPan;

  vm.Vector2 screenToWorld(vm.Vector2 screenPosition, vm.Vector2 screenSize) {
    final centered = screenPosition - screenSize / 2;
    final world = centered / zoom + position;
    return world;
  }

  void onPanStart(DragStartDetails details, vm.Vector2 screenSize) {
    _lastPan = details.localPosition.toVector2();
  }

  void onPanUpdate(DragUpdateDetails details, vm.Vector2 screenSize) {
    final vm.Vector2 current = details.localPosition.toVector2();
    final vm.Vector2? last = _lastPan;
    if (last != null) {
      final vm.Vector2 delta = current - last;
      position -= delta / zoom;
    }
    _lastPan = current;
  }

  void onPanEnd(DragEndDetails details) {
    _lastPan = null;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    zoom = (zoom * details.scale).clamp(0.2, 6.0);
  }

  void focus(vm.Vector2 target) {
    position = target.clone();
  }
}
