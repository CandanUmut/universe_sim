import 'package:flame/extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

class CameraController {
  double zoom = 1.0;
  Vector2 position = Vector2.zero();
  Vector2? _lastPan;

  Vector2 screenToWorld(Vector2 screenPosition, Vector2 screenSize) {
    final centered = screenPosition - screenSize / 2;
    final world = centered / zoom + position;
    return world;
  }

  void onPanStart(DragStartDetails details, Vector2 screenSize) {
    _lastPan = details.localPosition.toVector2();
  }

  void onPanUpdate(DragUpdateDetails details, Vector2 screenSize) {
    final current = details.localPosition.toVector2();
    final last = _lastPan;
    if (last != null) {
      final delta = current - last;
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

  void focus(Vector2 target) {
    position = target.clone();
  }
}
