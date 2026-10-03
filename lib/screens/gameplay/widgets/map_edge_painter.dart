import 'package:flutter/material.dart';

import 'package:dark_hours/models/world/map_position.dart';

/// Одно ребро для отрисовки — к выбранной локации.
class MapEdge {
  final MapPosition from;
  final MapPosition to;
  final int minutes;

  const MapEdge({
    required this.from,
    required this.to,
    required this.minutes,
  });
}

/// Рисует **одно** ребро между текущей и выбранной локацией.
///
/// Если `edge == null` — ничего не рисуется.
/// Это убирает визуальный шум от множества рёбер.
class MapEdgePainter extends CustomPainter {
  final MapEdge? edge;

  const MapEdgePainter({this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    if (edge == null) return;

    final start = Offset(
      edge!.from.x * size.width,
      edge!.from.y * size.height,
    );
    final end = Offset(
      edge!.to.x * size.width,
      edge!.to.y * size.height,
    );

    // Пунктирная золотая линия.
    final paint = Paint()
      ..color = const Color(0xFFC8B464)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(canvas, start, end, paint);

    // Точки-бусины.
    _drawBeads(canvas, start, end, const Color(0xFFC8B464));

    // Бейдж с временем в середине.
    _drawTimeBadge(canvas, start, end, edge!.minutes);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 5.0;

    final total = (end - start).distance;
    if (total <= 0) return;

    final direction = (end - start) / total;
    double drawn = 0;
    while (drawn < total) {
      final dashEnd = (drawn + dashLength).clamp(0.0, total);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * dashEnd,
        paint,
      );
      drawn += dashLength + gapLength;
    }
  }

  void _drawBeads(Canvas canvas, Offset start, Offset end, Color color) {
    final total = (end - start).distance;
    if (total < 30) return;

    final direction = (end - start) / total;
    final beadPaint = Paint()..color = color;

    for (final t in [0.25, 0.5, 0.75]) {
      final pos = start + direction * (total * t);
      canvas.drawCircle(pos, 2.5, beadPaint);
    }
  }

  void _drawTimeBadge(Canvas canvas, Offset start, Offset end, int minutes) {
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final text = minutes < 60
        ? '$minutes мин'
        : '${minutes ~/ 60}ч ${minutes % 60}м';

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFC8B464),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 12,
      height: textPainter.height + 6,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF141414).withValues(alpha: 0.95);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFFC8B464).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      borderPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant MapEdgePainter oldDelegate) {
    return oldDelegate.edge != edge;
  }
}