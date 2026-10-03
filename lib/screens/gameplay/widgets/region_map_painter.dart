import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dark_hours/models/world/region_layout.dart';

/// Рисует схематичную карту региона.
///
/// **ВАЖНО:** этот painter теперь используется ТОЛЬКО для генерации
/// `ui.Image` через `RegionBackgroundCache`. В UI он больше не
/// вызывается на каждый кадр — вместо него `RawImage`.
///
/// Слои (снизу вверх):
/// 1. Фон (градиент).
/// 2. Река.
/// 3. Кварталы (полигоны).
/// 4. Здания (процедурно внутри кварталов).
/// 5. Парки (зелёные зоны + деревья).
/// 6. Дороги.
class RegionMapPainter extends CustomPainter {
  final RegionLayout layout;

  /// Кеш зданий — **static**, чтобы переживать пересоздание painter'а.
  ///
  /// Ключ: `regionId_quarterId`. Значение: список зданий.
  /// Первая генерация ~50-100 мс, дальше — мгновенно из кеша.
  static final Map<String, List<Building>> _buildingCache = {};

  RegionMapPainter({required this.layout});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawRiver(canvas, size);
    _drawQuarters(canvas, size);
    _drawBuildings(canvas, size);
    _drawParks(canvas, size);
    _drawRoads(canvas, size);
    _drawRegionStamp(canvas, size);
  }

  // ═══════════════════════════════════════════════════════════
  // ФОН
  // ═══════════════════════════════════════════════════════════

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Каждый регион имеет свой базовый фон.
    // Добавляем лёгкий оттенок, чтобы регионы визуально отличались.
    final (topColor, midColor, bottomColor) = _regionGradient();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, midColor, bottomColor],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  /// Тройка цветов градиента для текущего региона.
  (Color, Color, Color) _regionGradient() {
    switch (layout.regionId) {
      case 'city_south':
        return (
          const Color(0xFF14100C), // тёплый верх
          const Color(0xFF0E0A08), // тёмная середина
          const Color(0xFF181008), // тёплый низ (река)
        );
      case 'city_center':
        return (
          const Color(0xFF0C0C14), // холодный верх
          const Color(0xFF08080E), // холодная середина
          const Color(0xFF0A0A12), // холодный низ
        );
      case 'forest':
        return (
          const Color(0xFF0C1410), // зеленоватый верх
          const Color(0xFF080C0A), // тёмная середина
          const Color(0xFF0C1410), // зеленоватый низ
        );
      case 'highway':
        return (
          const Color(0xFF14120C), // желтоватый верх
          const Color(0xFF0E0C08), // тёмная середина
          const Color(0xFF14120C), // желтоватый низ
        );
      case 'underground':
        return (
          const Color(0xFF0C0810), // фиолетовый верх
          const Color(0xFF060408), // очень тёмная середина
          const Color(0xFF0C0810), // фиолетовый низ
        );
      case 'north':
        return (
          const Color(0xFF0A0E14), // синеватый верх
          const Color(0xFF060810), // тёмная середина
          const Color(0xFF0A0E14), // синеватый низ
        );
      default:
        return (
          layout.backgroundColor,
          const Color(0xFF0E0E12),
          layout.backgroundColor,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // РЕКА
  // ═══════════════════════════════════════════════════════════

  void _drawRiver(Canvas canvas, Size size) {
    final river = layout.river;
    if (river == null || river.path.length < 2) return;

    final path = _smoothPath(river.path, size);

    // Основная вода — синий полупрозрачный.
    final waterPaint = Paint()
      ..color = const Color(0x5F1E4A6E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = river.width * size.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, waterPaint);

    // Светлая линия сверху — блик.
    final highlightPaint = Paint()
      ..color = const Color(0x3A5F8FBF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = river.width * size.width * 0.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, highlightPaint);
  }

  // ═══════════════════════════════════════════════════════════
  // КВАРТАЛЫ
  // ═══════════════════════════════════════════════════════════

  void _drawQuarters(Canvas canvas, Size size) {
    for (final quarter in layout.quarters) {
      final path = _polygonPath(quarter.polygon, size);

      // Заливка — цвет квартала зависит от его типа.
      final fillColor = _quarterFillColor(quarter.type);
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);

      // Обводка.
      final borderPaint = Paint()
        ..color = _quarterBorderColor(quarter.type)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, borderPaint);
    }
  }

  /// Цвет заливки квартала по типу.
  Color _quarterFillColor(QuarterType type) {
    // Добавляем оттенок региона к базовому цвету квартала.
    final base = layout.quarterColor;

    switch (type) {
      case QuarterType.residential:
        return _blend(base, const Color(0xFF2A2418), 0.3);
      case QuarterType.commercial:
        return _blend(base, const Color(0xFF1A2030), 0.3);
      case QuarterType.industrial:
        return _blend(base, const Color(0xFF2A1810), 0.3);
      case QuarterType.mixed:
        return _blend(base, const Color(0xFF221A1A), 0.3);
      case QuarterType.military:
        return _blend(base, const Color(0xFF101820), 0.3);
    }
  }

  /// Цвет обводки квартала.
  Color _quarterBorderColor(QuarterType type) {
    switch (type) {
      case QuarterType.residential:
        return const Color(0x33FFE0B0);
      case QuarterType.commercial:
        return const Color(0x3360A0FF);
      case QuarterType.industrial:
        return const Color(0x33FF8060);
      case QuarterType.mixed:
        return const Color(0x33FFFFFF);
      case QuarterType.military:
        return const Color(0x3360FFC0);
    }
  }

  /// Смешать два цвета с заданной силой `t` (0..1).
  Color _blend(Color a, Color b, double t) {
    return Color.fromARGB(
      (a.alpha + (b.alpha - a.alpha) * t).round(),
      (a.red + (b.red - a.red) * t).round(),
      (a.green + (b.green - a.green) * t).round(),
      (a.blue + (b.blue - a.blue) * t).round(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ЗДАНИЯ
  // ═══════════════════════════════════════════════════════════

  void _drawBuildings(Canvas canvas, Size size) {
    for (final quarter in layout.quarters) {
      // Ключ кеша — регион + квартал. Кеш static.
      final cacheKey = '${layout.regionId}_${quarter.id}';

      if (!_buildingCache.containsKey(cacheKey)) {
        _buildingCache[cacheKey] = layout.generateBuildings(quarter);
      }

      final buildings = _buildingCache[cacheKey]!;

      for (final building in buildings) {
        _drawBuilding(canvas, size, building);
      }
    }
  }

  void _drawBuilding(Canvas canvas, Size size, Building building) {
    final rect = Rect.fromLTWH(
      building.rect.left * size.width,
      building.rect.top * size.height,
      building.rect.width * size.width,
      building.rect.height * size.height,
    );

    // Тень (сдвиг вниз-вправо).
    final shadowRect = rect.translate(2, 2);
    final shadowPaint = Paint()..color = const Color(0x99000000);
    canvas.drawRect(shadowRect, shadowPaint);

    // Основной корпус.
    final bodyPaint = Paint()..color = building.color;
    canvas.drawRect(rect, bodyPaint);

    // Крыша (треугольник сверху).
    final roofHeight = building.height * size.height;
    final roofPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.center.dx, rect.top - roofHeight)
      ..lineTo(rect.right, rect.top)
      ..close();

    final roofPaint = Paint()..color = const Color(0xFF505058);
    canvas.drawPath(roofPath, roofPaint);

    // Обводка корпуса.
    final borderPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    // Окна — 2 маленькие точки.
    if (rect.width > 15 && rect.height > 15) {
      final windowPaint = Paint()..color = const Color(0x88FFD070);
      const windowSize = 2.5;

      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + rect.width * 0.25 - windowSize / 2,
          rect.top + rect.height * 0.4 - windowSize / 2,
          windowSize,
          windowSize,
        ),
        windowPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + rect.width * 0.75 - windowSize / 2,
          rect.top + rect.height * 0.4 - windowSize / 2,
          windowSize,
          windowSize,
        ),
        windowPaint,
      );
    }

    // Труба.
    if (building.hasChimney) {
      final chimneyRect = Rect.fromLTWH(
        rect.right - 4,
        rect.top - roofHeight - 3,
        2.5,
        5,
      );
      final chimneyPaint = Paint()..color = const Color(0xFF707070);
      canvas.drawRect(chimneyRect, chimneyPaint);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ПАРКИ
  // ═══════════════════════════════════════════════════════════

  void _drawParks(Canvas canvas, Size size) {
    for (final park in layout.parks) {
      final path = _polygonPath(park.polygon, size);

      // Зелёная заливка — сильнее, чем раньше.
      final fillPaint = Paint()
        ..color = const Color(0x3522AA44)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Обводка.
      final borderPaint = Paint()
        ..color = const Color(0x6622AA44)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);

      _drawParkTrees(canvas, size, park);
    }
  }

  void _drawParkTrees(Canvas canvas, Size size, Park park) {
    final rng = math.Random(park.seed);

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final p in park.polygon) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final treePaint = Paint()
      ..color = const Color(0x6622AA44)
      ..style = PaintingStyle.fill;

    int placed = 0;
    int attempts = 0;

    while (placed < park.treesCount && attempts < 200) {
      attempts++;

      final x = minX + rng.nextDouble() * (maxX - minX);
      final y = minY + rng.nextDouble() * (maxY - minY);

      if (!park.contains(Offset(x, y))) continue;

      _drawTree(
        canvas,
        Offset(x * size.width, y * size.height),
        6 + rng.nextDouble() * 4,
        treePaint,
      );
      placed++;
    }
  }

  void _drawTree(Canvas canvas, Offset center, double h, Paint paint) {
    // Ёлка — треугольник.
    final path = Path()
      ..moveTo(center.dx, center.dy - h)
      ..lineTo(center.dx - h * 0.6, center.dy + h * 0.5)
      ..lineTo(center.dx + h * 0.6, center.dy + h * 0.5)
      ..close();
    canvas.drawPath(path, paint);

    // Ствол.
    final trunkPaint = Paint()..color = const Color(0x661A1A1A);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 1, center.dy + h * 0.4, 2, 3),
      trunkPaint,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ДОРОГИ
  // ═══════════════════════════════════════════════════════════

  void _drawRoads(Canvas canvas, Size size) {
    for (final road in layout.roads) {
      final path = _smoothPath(road.path, size);

      // Асфальт — толстая серая линия.
      final roadPaint = Paint()
        ..color = road.isMain
            ? const Color(0x4AFFFFFF)
            : const Color(0x2AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = road.isMain ? 6.0 : 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, roadPaint);

      // Разметка для главных — пунктир.
      if (road.isMain) {
        final dashPaint = Paint()
          ..color = const Color(0x88888844)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;

        _drawDashedPath(canvas, path, dashPaint,
            dashLength: 8, gapLength: 8);
      }
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final extract = metric.extractPath(distance, end);
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // МЕТКА РЕГИОНА (прямо на картинке)
  // ═══════════════════════════════════════════════════════════

  /// Рисует название региона в углу картинки.
  ///
  /// Полупрозрачный, чтобы не мешать. Виден и на фоне, и после
  /// масштабирования.
  void _drawRegionStamp(Canvas canvas, Size size) {
    final label = _regionStampText();
    if (label.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0x2AC8B464), // очень прозрачный золотой
          fontSize: 64,
          fontWeight: FontWeight.bold,
          letterSpacing: 12.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 80);

    textPainter.paint(
      canvas,
      Offset(40, size.height - textPainter.height - 40),
    );
  }

  String _regionStampText() {
    switch (layout.regionId) {
      case 'city_south':
        return 'ЮГ';
      case 'city_center':
        return 'ЦЕНТР';
      case 'forest':
        return 'ЛЕС';
      case 'highway':
        return 'ТРАССА';
      case 'underground':
        return 'ТОННЕЛИ';
      case 'north':
        return 'СЕВЕР';
      default:
        return '';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ХЕЛПЕРЫ
  // ═══════════════════════════════════════════════════════════

  Path _polygonPath(List<Offset> polygon, Size size) {
    final path = Path();
    if (polygon.isEmpty) return path;

    path.moveTo(
      polygon[0].dx * size.width,
      polygon[0].dy * size.height,
    );

    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(
        polygon[i].dx * size.width,
        polygon[i].dy * size.height,
      );
    }

    path.close();
    return path;
  }

  Path _smoothPath(List<Offset> points, Size size) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(
      points[0].dx * size.width,
      points[0].dy * size.height,
    );

    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      final prev = points[i - 1];

      final mid = Offset(
        (p.dx + prev.dx) / 2 * size.width,
        (p.dy + prev.dy) / 2 * size.height,
      );

      path.quadraticBezierTo(
        prev.dx * size.width,
        prev.dy * size.height,
        mid.dx,
        mid.dy,
      );
    }

    final last = points.last;
    path.lineTo(last.dx * size.width, last.dy * size.height);

    return path;
  }

  // ═══════════════════════════════════════════════════════════
  // КЕШ
  // ═══════════════════════════════════════════════════════════

  /// Очистить кеш зданий для конкретного региона.
  static void clearRegionCache(String regionId) {
    final keysToRemove = _buildingCache.keys
        .where((k) => k.startsWith('${regionId}_'))
        .toList();
    for (final key in keysToRemove) {
      _buildingCache.remove(key);
    }
  }

  /// Очистить весь кеш.
  static void clearAllCache() {
    _buildingCache.clear();
  }

  /// Размер кеша (для диагностики).
  static int get cacheSize => _buildingCache.length;

  @override
  bool shouldRepaint(covariant RegionMapPainter oldDelegate) {
    // Painter используется только для генерации.
    // Перерисовка нужна только при смене региона.
    return oldDelegate.layout.regionId != layout.regionId;
  }
}