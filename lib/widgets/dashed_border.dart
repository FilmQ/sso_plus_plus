import 'dart:ui';

import 'package:flutter/material.dart';

/// A rounded border, dashed or solid (U1-2: an empty upload box is dashed).
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, required this.color, this.radius = 12, this.dashed = true});

  final Widget child;
  final Color color;
  final double radius;
  final bool dashed;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(foregroundPainter: _Painter(color, radius, dashed), child: child);
}

class _Painter extends CustomPainter {
  _Painter(this.color, this.radius, this.dashed);

  final Color color;
  final double radius;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Path outline = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.5));
    if (!dashed) {
      canvas.drawPath(outline, paint);
      return;
    }
    for (final PathMetric metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.color != color || old.dashed != dashed || old.radius != radius;
}
