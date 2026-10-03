import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Цвета зон.
const Map<String, Color> kZoneColors = {
  'city_south': Color(0x1AFFA500),
  'city_center': Color(0x1AFF4444),
  'forest': Color(0x1A22AA22),
  'highway': Color(0x1ACCCC44),
  'north': Color(0x1A4488FF),
  'underground': Color(0x158844FF),
};

/// Названия зон.
const Map<String, String> kZoneNames = {
  'city_south': 'ЮГ ГОРОДА',
  'city_center': 'ЦЕНТР',
  'forest': 'ЛЕС',
  'highway': 'ТРАССА',
  'north': 'СЕВЕР',
  'underground': 'ТОННЕЛИ',
};

/// Прямоугольники зон (логические координаты).
const Map<String, Rect> kZoneRects = {
  'north': Rect.fromLTWH(0.0, 0.0, 1.0, 0.15),
  'highway': Rect.fromLTWH(0.0, 0.15, 1.0, 0.20),
  'forest': Rect.fromLTWH(0.0, 0.35, 0.45, 0.35),
  'city_center': Rect.fromLTWH(0.45, 0.35, 0.55, 0.35),
  'city_south': Rect.fromLTWH(0.0, 0.70, 1.0, 0.30),
  'underground': Rect.fromLTWH(0.0, 0.85, 1.0, 0.15),
};

/// Рисует зоны, сетку и силуэты.
///
/// Отображает **только открытые регионы**.
class MapZonePainter extends CustomPainter {
  final Size logicalSize;

  /// Открытые регионы (из MapController.discoveredRegions).
  final Set<String> discoveredRegions;

  const MapZonePainter({
    required this.logicalSize,
    required this.discoveredRegions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas, size);

    // Рисуем только открытые регионы.
    for (final zoneId in discoveredRegions) {
      final rect = kZoneRects[zoneId];
      if (rect == null) continue;

      _drawZone(canvas, size, zoneId, rect);
      _drawZoneSilhouettes(canvas, size, zoneId, rect);
    }
  }

  /// Градиентный фон.
  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0E0E14),
          Color(0xFF0A0A0A),
          Color(0xFF100C08),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  /// Сетка.
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Цветная зона с подписью.
  void _drawZone(Canvas canvas, Size size, String zoneId, Rect rect) {
    final color = kZoneColors[zoneId] ?? Colors.transparent;

    final pxRect = Rect.fromLTWH(
      rect.left * size.width,
      rect.top * size.height,
      rect.width * size.width,
      rect.height * size.height,
    );

    final fillPaint = Paint()..color = color;
    canvas.drawRect(pxRect, fillPaint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(pxRect, borderPaint);

    _drawZoneLabel(
      canvas,
      pxRect.topLeft + const Offset(10, 10),
      kZoneNames[zoneId] ?? zoneId.toUpperCase(),
      color.withValues(alpha: 0.9),
    );
  }

  void _drawZoneLabel(Canvas canvas, Offset offset, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          letterSpacing: 4.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, offset);
  }

  /// Силуэты для каждого открытого региона.
  void _drawZoneSilhouettes(
    Canvas canvas,
    Size size,
    String zoneId,
    Rect zone,
  ) {
    switch (zoneId) {
      case 'city_south':
        _drawCitySilhouettes(canvas, size, zone, baseAlpha: 0.08, seed: 100);
        break;
      case 'city_center':
        _drawCitySilhouettes(
          canvas,
          size,
          zone,
          baseAlpha: 0.10,
          seed: 200,
          heightFactor: 1.6,
        );
        break;
      case 'forest':
        _drawForestSilhouettes(canvas, size, zone);
        break;
      case 'highway':
        _drawHighwaySilhouettes(canvas, size, zone);
        break;
      case 'north':
        _drawNorthSilhouettes(canvas, size, zone);
        break;
      case 'underground':
        _drawUndergroundSilhouettes(canvas, size);
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // СИЛУЭТЫ
  // ═══════════════════════════════════════════════════════════

  void _drawCitySilhouettes(
    Canvas canvas,
    Size size,
    Rect zone, {
    required double baseAlpha,
    required int seed,
    double heightFactor = 1.0,
  }) {
    final rng = math.Random(seed);
    final zoneRect = Rect.fromLTWH(
      zone.left * size.width,
      zone.top * size.height,
      zone.width * size.width,
      zone.height * size.height,
    );

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: baseAlpha);

    const buildingCount = 8;
    final buildingWidth = zoneRect.width / buildingCount;

    for (int i = 0; i < buildingCount; i++) {
      final h = (rng.nextDouble() * 30 + 15) * heightFactor;
      final bx = zoneRect.left + i * buildingWidth + 4;
      final by = zoneRect.bottom - h;
      final bw = buildingWidth - 8;

      canvas.drawRect(Rect.fromLTWH(bx, by, bw, h), paint);

      final windowPaint = Paint()
        ..color = Colors.white.withValues(alpha: baseAlpha * 1.5);
      final windowRows = (h / 8).floor();
      final windowCols = (bw / 6).floor().clamp(1, 4);

      for (int wr = 0; wr < windowRows; wr++) {
        for (int wc = 0; wc < windowCols; wc++) {
          if (rng.nextDouble() > 0.4) continue;
          canvas.drawRect(
            Rect.fromLTWH(bx + 4 + wc * 6, by + 4 + wr * 8, 2, 3),
            windowPaint,
          );
        }
      }
    }
  }

  void _drawForestSilhouettes(Canvas canvas, Size size, Rect zone) {
    final rng = math.Random(300);
    final zoneRect = Rect.fromLTWH(
      zone.left * size.width,
      zone.top * size.height,
      zone.width * size.width,
      zone.height * size.height,
    );

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final x = zoneRect.left + rng.nextDouble() * zoneRect.width;
      final y = zoneRect.top + rng.nextDouble() * zoneRect.height;
      final h = 12 + rng.nextDouble() * 12;
      _drawTree(canvas, Offset(x, y), h, paint);
    }
  }

  void _drawTree(Canvas canvas, Offset center, double h, Paint paint) {
    final path1 = Path()
      ..moveTo(center.dx, center.dy - h)
      ..lineTo(center.dx - h * 0.4, center.dy - h * 0.4)
      ..lineTo(center.dx + h * 0.4, center.dy - h * 0.4)
      ..close();
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(center.dx, center.dy - h * 0.7)
      ..lineTo(center.dx - h * 0.5, center.dy - h * 0.1)
      ..lineTo(center.dx + h * 0.5, center.dy - h * 0.1)
      ..close();
    canvas.drawPath(path2, paint);

    final path3 = Path()
      ..moveTo(center.dx, center.dy - h * 0.4)
      ..lineTo(center.dx - h * 0.6, center.dy + h * 0.3)
      ..lineTo(center.dx + h * 0.6, center.dy + h * 0.3)
      ..close();
    canvas.drawPath(path3, paint);
  }

  void _drawHighwaySilhouettes(Canvas canvas, Size size, Rect zone) {
    final zoneRect = Rect.fromLTWH(
      zone.left * size.width,
      zone.top * size.height,
      zone.width * size.width,
      zone.height * size.height,
    );

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawRect(
      Rect.fromLTWH(
        zoneRect.left,
        zoneRect.center.dy - 20,
        zoneRect.width,
        40,
      ),
      roadPaint,
    );

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    for (double x = zoneRect.left; x < zoneRect.right; x += 30) {
      canvas.drawLine(
        Offset(x, zoneRect.center.dy),
        Offset(x + 15, zoneRect.center.dy),
        dashPaint,
      );
    }

    final rng = math.Random(400);
    final carPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08);
    for (int i = 0; i < 6; i++) {
      final cx = zoneRect.left + rng.nextDouble() * zoneRect.width;
      final cy = zoneRect.center.dy - 25 + rng.nextDouble() * 50;
      canvas.drawRect(Rect.fromLTWH(cx, cy, 14, 6), carPaint);
    }
  }

  void _drawNorthSilhouettes(Canvas canvas, Size size, Rect zone) {
    final zoneRect = Rect.fromLTWH(
      zone.left * size.width,
      zone.top * size.height,
      zone.width * size.width,
      zone.height * size.height,
    );

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cx = zoneRect.center.dx;
    final baseY = zoneRect.bottom - 10;
    final topY = zoneRect.top + 20;

    canvas.drawLine(Offset(cx - 20, baseY), Offset(cx - 5, topY), paint);
    canvas.drawLine(Offset(cx + 20, baseY), Offset(cx + 5, topY), paint);

    for (int i = 0; i < 5; i++) {
      final t = i / 5.0;
      final y = baseY - (baseY - topY) * t;
      final width = 20 - t * 15;
      canvas.drawLine(Offset(cx - width, y), Offset(cx + width, y), paint);
    }

    canvas.drawLine(Offset(cx, topY), Offset(cx, topY - 15), paint);

    final signalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(Offset(cx, topY - 15), 8.0 * i, signalPaint);
    }
  }

  void _drawUndergroundSilhouettes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paths = [
      Path()
        ..moveTo(0, size.height * 0.92)
        ..lineTo(size.width * 0.3, size.height * 0.92)
        ..lineTo(size.width * 0.3, size.height * 0.98),
      Path()
        ..moveTo(size.width * 0.05, size.height * 0.95)
        ..lineTo(size.width * 0.15, size.height * 0.98),
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.88)
        ..lineTo(size.width * 0.6, size.height * 0.95),
    ];

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MapZonePainter oldDelegate) {
    return oldDelegate.logicalSize != logicalSize ||
        oldDelegate.discoveredRegions != discoveredRegions;
  }
}