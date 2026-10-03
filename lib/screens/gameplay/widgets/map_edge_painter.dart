import 'package:flutter/material.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/map_position.dart';

/// Одна линия между двумя локациями.
class MapEdge {
  final MapPosition from;
  final MapPosition to;
  final bool isHighlighted;
  final bool isVisited;
  final bool isScouted;
  final int minutes;

  const MapEdge({
    required this.from,
    required this.to,
    this.isHighlighted = false,
    this.isVisited = false,
    this.isScouted = false,
    this.minutes = 20,
  });
}

/// Рисует все рёбра между локациями.
class MapEdgePainter extends CustomPainter {
  final List<MapEdge> edges;

  const MapEdgePainter({required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    // Сначала рисуем обычные рёбра (фон).
    for (final edge in edges.where((e) => !e.isHighlighted)) {
      _drawEdge(canvas, size, edge);
    }
    // Потом highlighted (поверх).
    for (final edge in edges.where((e) => e.isHighlighted)) {
      _drawEdge(canvas, size, edge);
    }
  }

  void _drawEdge(Canvas canvas, Size size, MapEdge edge) {
    final start = Offset(
      edge.from.x * size.width,
      edge.from.y * size.height,
    );
    final end = Offset(
      edge.to.x * size.width,
      edge.to.y * size.height,
    );

    Color color;
    double width;
    bool dashed;

    if (edge.isHighlighted) {
      color = const Color(0xFFC8B464);
      width = 2.5;
      dashed = true;
    } else if (edge.isVisited) {
      color = Colors.white.withValues(alpha: 0.35);
      width = 1.2;
      dashed = false;
    } else if (edge.isScouted) {
      // Разведано, но не посещено — очень тусклая
      color = Colors.white.withValues(alpha: 0.12);
      width = 0.8;
      dashed = true;
    } else {
      // Не разведано — не рисуем.
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    if (dashed) {
      _drawDashedLine(canvas, start, end, paint);
    } else {
      canvas.drawLine(start, end, paint);
    }

    // Бусины на посещённых рёбрах
    if (edge.isVisited || edge.isHighlighted) {
      _drawBeads(canvas, start, end, color);
    }

    // Время перехода — маленький бейдж по центру (только для highlighted)
    if (edge.isHighlighted) {
      _drawTimeBadge(canvas, start, end, edge.minutes);
    }
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
      canvas.drawCircle(pos, 2.0, beadPaint);
    }
  }

  /// Бейдж с временем перехода в центре ребра.
  void _drawTimeBadge(Canvas canvas, Offset start, Offset end, int minutes) {
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final text = minutes < 60
        ? '$minutes м'
        : '${minutes ~/ 60}ч ${minutes % 60}м';

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFC8B464),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Фон бейджа
    final bgRect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF141414).withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFFC8B464).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
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
    return oldDelegate.edges != edges;
  }
}

/// Хелпер: собрать рёбра из списка локаций.
///
/// Правила (Fog of War):
/// - Рисуем ребро только если **обе** локации scouted или visited.
/// - Hidden локации — пропускаем, пока не открыты.
/// - Не дублируем: если A→B и B→A — рисуем один раз.
/// - Highlighted — рёбра текущей локации с её соседями.
List<MapEdge> buildEdges({
  required List<Location> locations,
  required Set<String> visited,
  required Set<String> scouted,
  required Set<String> unlocked,
  required String currentLocationId,
}) {
  final byId = <String, Location>{
    for (final loc in locations) loc.id: loc,
  };

  final currentLoc = byId[currentLocationId];
  final currentNeighbors = <String>{
    if (currentLoc != null) ...currentLoc.connectionIds,
  };

  final edges = <MapEdge>[];
  final seen = <String>{};

  for (final loc in locations) {
    // Не рисуем рёбра от локаций, о которых игрок не знает.
    final locKnown = scouted.contains(loc.id) || visited.contains(loc.id);
    if (!locKnown) continue;

    for (final conn in loc.connections) {
      final target = byId[conn.targetId];
      if (target == null) continue;

      // Скрытая и неоткрытая — пропускаем.
      if (target.hidden && !unlocked.contains(target.id)) continue;
      if (loc.hidden && !unlocked.contains(loc.id)) continue;

      // Обе локации должны быть известны.
      final targetKnown =
          scouted.contains(target.id) || visited.contains(target.id);
      if (!targetKnown) continue;

      // Дедупликация.
      final key = [loc.id, target.id]..sort();
      final keyStr = key.join('|');
      if (seen.contains(keyStr)) continue;
      seen.add(keyStr);

      // Highlighted — если ребро касается текущей.
      final touchesCurrent =
          loc.id == currentLocationId || target.id == currentLocationId;

      final isDirectNeighbor = touchesCurrent &&
          (currentNeighbors.contains(loc.id) ||
              currentNeighbors.contains(target.id));

      edges.add(MapEdge(
        from: loc.mapPosition,
        to: target.mapPosition,
        isHighlighted: isDirectNeighbor,
        isVisited: visited.contains(loc.id) && visited.contains(target.id),
        isScouted: scouted.contains(loc.id) || scouted.contains(target.id),
        minutes: conn.minutes,
      ));
    }
  }

  return edges;
}