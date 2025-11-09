import 'dart:ui';

import '../../sim/sim_isolate.dart';
import '../style.dart';

class SystemPainter {
  final Paint _planetPaint = Paint()
    ..color = PRUStyle.planet
    ..style = PaintingStyle.fill;

  final Paint _relayPaint = Paint()
    ..color = PRUStyle.relay
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  void paint(Canvas canvas, Iterable<EntitySnapshot> entities, double zoom) {
    for (final entity in entities) {
      switch (entity.type) {
        case 'planet':
          final radius = 3.0 / zoom;
          canvas.drawCircle(Offset(entity.x, entity.y), radius, _planetPaint);
          break;
        case 'relay':
          final radius = 8.0 / zoom;
          canvas.drawCircle(Offset(entity.x, entity.y), radius, _relayPaint);
          break;
      }
    }
  }

  void paintOrbit(Canvas canvas, Offset origin, double radius) {
    final orbitPaint = Paint()
      ..color = PRUStyle.planet.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(origin, radius, orbitPaint);
  }
}
