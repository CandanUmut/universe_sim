import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../simulation/particle.dart';

class UniversePainter extends CustomPainter {
  UniversePainter({
    required this.particles,
    required this.scale,
    required this.panOffset,
    required this.showTrails,
    required this.showBarycenter,
    required this.barycenter,
    required this.starfield,
  });

  final List<Particle> particles;
  final double scale;
  final Offset panOffset;
  final bool showTrails;
  final bool showBarycenter;
  final Vector3 barycenter;
  final List<Offset> starfield;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Paint background = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0xFF0B132B),
          Color(0xFF1C2541),
          Color(0xFF3A506B),
        ],
        radius: 1.2,
        center: Alignment(0, -0.3),
      ).createShader(bounds);
    canvas.drawRect(bounds, background);

    final Paint starPaint = Paint()..color = Colors.white.withOpacity(0.7);
    for (final Offset relative in starfield) {
      final Offset starPosition = Offset(relative.dx * size.width, relative.dy * size.height);
      canvas.drawCircle(starPosition, 0.75 + (relative.dy % 0.7), starPaint);
    }

    canvas.save();
    canvas.translate(size.width / 2 + panOffset.dx, size.height / 2 + panOffset.dy);
    canvas.scale(scale);

    _drawGrid(canvas, size);

    if (showBarycenter) {
      final Paint baryPaint = Paint()
        ..color = Colors.pinkAccent.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / scale;
      canvas.drawCircle(Offset(barycenter.x, barycenter.y), 18 / scale, baryPaint);
    }

    for (final Particle particle in particles) {
      if (showTrails && particle.trail.length > 1) {
        final Path path = Path()
          ..moveTo(particle.trail.first.dx, particle.trail.first.dy);
        for (final Offset point in particle.trail.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        final Paint trailPaint = Paint()
          ..color = particle.color.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5 / scale, 0.4);
        canvas.drawPath(path, trailPaint);
      }
    }

    for (final Particle particle in particles) {
      final Paint bodyPaint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            particle.color.withOpacity(0.2),
            particle.color,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(particle.position.x, particle.position.y),
            radius: particle.radius * 1.5,
          ),
        );
      final double bodyRadius = math.max(particle.radius, 4.0);
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        bodyRadius,
        bodyPaint,
      );

      if (particle.highlight) {
        final Paint glow = Paint()
          ..color = particle.color.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(
          Offset(particle.position.x, particle.position.y),
          bodyRadius * 1.6,
          glow,
        );
      }

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: particle.name,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12 / scale,
            fontWeight: particle.highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(particle.position.x + bodyRadius + 6, particle.position.y - bodyRadius - 4),
      );
    }

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    const double spacing = 1e5;
    const int linesPerSide = 40;
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (int i = -linesPerSide; i <= linesPerSide; i++) {
      final double offset = i * spacing;
      canvas.drawLine(Offset(offset, -linesPerSide * spacing),
          Offset(offset, linesPerSide * spacing), gridPaint);
      canvas.drawLine(Offset(-linesPerSide * spacing, offset),
          Offset(linesPerSide * spacing, offset), gridPaint);
    }

    final Paint axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(-1e7, 0),
      const Offset(1e7, 0),
      axisPaint,
    );
    canvas.drawLine(
      const Offset(0, -1e7),
      const Offset(0, 1e7),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant UniversePainter oldDelegate) {
    return oldDelegate.particles != particles ||
        oldDelegate.scale != scale ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.showTrails != showTrails ||
        oldDelegate.showBarycenter != showBarycenter ||
        oldDelegate.starfield != starfield;
  }
}
