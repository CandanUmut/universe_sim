import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../render/style.dart';
import '../sim/sim_isolate.dart';

class Minimap extends StatelessWidget {
  const Minimap({super.key, required this.snapshot, required this.onFocus});

  final SimSnapshot? snapshot;
  final ValueChanged<Vector2> onFocus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Card(
        color: Colors.black45,
        child: GestureDetector(
          onTapUp: (details) {
            if (snapshot == null) {
              return;
            }
            final local = details.localPosition;
            final center = const Offset(90, 90);
            final world = Vector2(
              (local.dx - center.dx) * 20,
              (local.dy - center.dy) * 20,
            );
            onFocus(world);
          },
          child: CustomPaint(
            painter: _MinimapPainter(snapshot),
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.snapshot);

  final SimSnapshot? snapshot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PRUStyle.background
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
    if (snapshot == null) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    for (final entity in snapshot!.entities) {
      final offset = Offset(entity.x / 20 + center.dx, entity.y / 20 + center.dy);
      final color = switch (entity.type) {
        'star' => PRUStyle.starWarm,
        'planet' => PRUStyle.planet,
        'relay' => PRUStyle.relay,
        _ => Colors.white54,
      };
      canvas.drawCircle(offset, 2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => oldDelegate.snapshot != snapshot;
}
