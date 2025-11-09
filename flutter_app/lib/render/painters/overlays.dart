import 'dart:ui';

import '../../sim/sim_isolate.dart';
import '../style.dart';

enum OverlayMode { none, mass, energy, habitability }

class OverlayPainter {
  OverlayPainter();

  final Paint _massPaint = Paint()..color = PRUStyle.overlayMass.withOpacity(0.25);
  final Paint _energyPaint = Paint()..color = PRUStyle.overlayEnergy.withOpacity(0.25);
  final Paint _habitPaint = Paint()..color = PRUStyle.overlayHabitability.withOpacity(0.25);

  void paint(Canvas canvas, Iterable<EntitySnapshot> entities, OverlayMode mode, double zoom) {
    if (mode == OverlayMode.none) {
      return;
    }
    final paint = _paintForMode(mode);
    for (final entity in entities) {
      final radius = 12.0 / zoom;
      canvas.drawCircle(Offset(entity.x, entity.y), radius, paint);
    }
  }

  Paint _paintForMode(OverlayMode mode) {
    switch (mode) {
      case OverlayMode.mass:
        return _massPaint;
      case OverlayMode.energy:
        return _energyPaint;
      case OverlayMode.habitability:
        return _habitPaint;
      case OverlayMode.none:
        return Paint();
    }
  }
}
