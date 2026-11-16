import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// The liquid-glass vessel.
class Vessel extends StatelessWidget {
  final double fill; // 0.0 to 1.0 (can go higher)
  final double reserve; // what is fenced off: 0.0 to 1.0
  final Size size;

  const Vessel({
    super.key,
    required this.fill,
    required this.reserve,
    this.size = const Size(252, 252),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _VesselPainter(
          fill: fill,
          reserve: reserve,
        ),
      ),
    );
  }
}

class _VesselPainter extends CustomPainter {
  final double fill;
  final double reserve;

  _VesselPainter({required this.fill, required this.reserve});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = size.width / 2;
    final center = Offset(r, r);

    // 1. Clip to the circular shape
    final path = Path()..addOval(rect);
    canvas.clipPath(path);

    // 2. Liquid fill
    final liquidH = size.height * fill.clamp(0.0, 1.1);
    final liquidTop = size.height - liquidH;
    final liquidPath = Path()
      ..addRect(Rect.fromLTWH(0, liquidTop, size.width, liquidH));

    final paint = Paint()
      ..color = Hue.liquidAt(fill)
      ..style = PaintingStyle.fill;
    canvas.drawPath(liquidPath, paint);

    // 3. Reserve band (hatched line riding on top)
    if (reserve > 0) {
      final reserveH = size.height * (reserve * fill).clamp(0.0, 1.0);
      final reserveTop = liquidTop;
      final reserveRect = Rect.fromLTWH(0, reserveTop, size.width, reserveH);

      final reservePaint = Paint()
        ..color = Hue.text3.withAlpha(50)
        ..style = PaintingStyle.fill;
      canvas.drawRect(reserveRect, reservePaint);

      // Hatch pattern
      final hatchPaint = Paint()
        ..color = Hue.text3.withAlpha(120)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (double i = 0; i < size.width + size.height; i += 8) {
        canvas.drawLine(
          Offset(i, reserveTop),
          Offset(i - size.height, reserveTop + size.height),
          hatchPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_VesselPainter old) =>
      old.fill != fill || old.reserve != reserve;
}
