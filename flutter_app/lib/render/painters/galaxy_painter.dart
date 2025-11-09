import 'dart:ui';

import 'package:flutter/painting.dart' show RadialGradient;

import '../../sim/sim_isolate.dart';
import '../style.dart';

class GalaxyPainter {
  GalaxyPainter();

  final Paint _backgroundPaint = Paint()
    ..shader = const RadialGradient(
      colors: [Color(0xFF0B1024), PRUStyle.background],
      radius: 0.9,
    ).createShader(const Rect.fromLTWH(-2000, -2000, 4000, 4000));

  final Paint _starPaint = Paint()
    ..color = PRUStyle.starWarm
    ..style = PaintingStyle.fill;

  void paint(Canvas canvas, Iterable<EntitySnapshot> entities, double zoom) {
    canvas.save();
    canvas.drawRect(const Rect.fromLTWH(-5000, -5000, 10000, 10000), _backgroundPaint);
    for (final entity in entities) {
      if (entity.type == 'star') {
        final radius = 4.0 / zoom;
        canvas.drawCircle(Offset(entity.x, entity.y), radius, _starPaint);
      }
    }
    canvas.restore();
  }
}
