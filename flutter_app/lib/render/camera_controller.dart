import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'vector2_compat.dart'; // <— use the adapters
import 'package:flame/extensions.dart'; // for .toVector2() only

class CameraController {
  double zoom = 1.0;
  vm.Vector2 position = vm.Vector2.zero();
  vm.Vector2? _lastPan;

  vm.Vector2 screenToWorld(vm.Vector2 screenPosition, vm.Vector2 screenSize) {
    // Be explicit with doubles to avoid int division ambiguity
    final centered = screenPosition - (screenSize / 2.0);
    return (centered / zoom) + position;
  }

  void onPanStart(DragStartDetails details, vm.Vector2 screenSize) {
    // details.localPosition.toVector2() -> Flame Vector2; convert to vm
    _lastPan = details.localPosition.toVector2().asVm;
  }

  void onPanUpdate(DragUpdateDetails details, vm.Vector2 screenSize) {
    final vm.Vector2 current = details.localPosition.toVector2().asVm;
    final vm.Vector2? last = _lastPan;
    if (last != null) {
      final vm.Vector2 delta = current - last;
      position -= (delta / zoom);
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
    // keep object identity, but copy coordinates
    position.setFrom(target);
  }
}
