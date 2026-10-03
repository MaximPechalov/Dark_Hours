import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Тип квартала — влияет на стиль зданий.
enum QuarterType {
  /// Жилой — дома, пятиэтажки.
  residential,

  /// Коммерческий — магазины, офисы, кафе.
  commercial,

  /// Промышленный — ангары, склады, заводы.
  industrial,

  /// Смешанный — всё подряд.
  mixed,

  /// Военный — бункеры, КПП (для underground).
  military,
}

/// Квартал — полигон с зданиями внутри.
class Quarter {
  final String id;
  final List<Offset> polygon;
  final QuarterType type;

  /// Сколько зданий внутри квартала.
  final int buildingsCount;

  /// Seed для генерации зданий (детерминированный).
  final int seed;

  const Quarter({
    required this.id,
    required this.polygon,
    this.type = QuarterType.residential,
    this.buildingsCount = 6,
    this.seed = 0,
  });

  /// Проверка: точка внутри полигона (ray casting).
  bool contains(Offset point) {
    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];

      if (((a.dy > point.dy) != (b.dy > point.dy)) &&
          (point.dx <
              (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx)) {
        crossings++;
      }
    }
    return crossings % 2 == 1;
  }
}

/// Парк — зелёная зона с деревьями.
class Park {
  final String id;
  final List<Offset> polygon;
  final int treesCount;
  final int seed;

  const Park({
    required this.id,
    required this.polygon,
    this.treesCount = 20,
    this.seed = 0,
  });

  bool contains(Offset point) {
    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];

      if (((a.dy > point.dy) != (b.dy > point.dy)) &&
          (point.dx <
              (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx)) {
        crossings++;
      }
    }
    return crossings % 2 == 1;
  }
}

/// Река — извилистая линия с шириной.
class River {
  /// Точки кривой (по ним рисуем Безье).
  final List<Offset> path;

  /// Ширина в логических единицах.
  final double width;

  const River({
    required this.path,
    this.width = 0.04,
  });
}

/// Дорога — линия между кварталами.
class Road {
  final List<Offset> path;

  /// Главная дорога (толще, светлее).
  final bool isMain;

  const Road({
    required this.path,
    this.isMain = false,
  });
}

/// Сгенерированное здание внутри квартала.
class Building {
  final Rect rect;
  final double height; // «высота» = размер крыши
  final bool hasChimney;
  final Color color;

  const Building({
    required this.rect,
    required this.height,
    this.hasChimney = false,
    this.color = const Color(0xFFFFFFFF),
  });
}

/// Весь layout одного региона.
class RegionLayout {
  final String regionId;
  final Size logicalSize;
  final List<Quarter> quarters;
  final List<Park> parks;
  final River? river;
  final List<Road> roads;

  /// Цвет фона региона.
  final Color backgroundColor;

  /// Цвет кварталов (базовый).
  final Color quarterColor;

  const RegionLayout({
    required this.regionId,
    this.logicalSize = const Size(800, 1200),
    required this.quarters,
    this.parks = const [],
    this.river,
    this.roads = const [],
    this.backgroundColor = const Color(0xFF0A0A0A),
    this.quarterColor = const Color(0xFF1A1A1A),
  });

  /// Сгенерировать здания внутри квартала (детерминированно по seed).
  List<Building> generateBuildings(Quarter quarter) {
    final rng = math.Random(quarter.seed);

    // Bounding box квартала.
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final p in quarter.polygon) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    final buildings = <Building>[];
    int attempts = 0;

    // Стиль зданий — по типу квартала.
    double minSize;
    double maxSize;
    double maxHeight;
    Color baseColor;

    switch (quarter.type) {
      case QuarterType.residential:
        minSize = 0.015;
        maxSize = 0.035;
        maxHeight = 0.02;
        baseColor = const Color(0xFF2A2A2A);
        break;
      case QuarterType.commercial:
        minSize = 0.02;
        maxSize = 0.05;
        maxHeight = 0.04;
        baseColor = const Color(0xFF303030);
        break;
      case QuarterType.industrial:
        minSize = 0.03;
        maxSize = 0.07;
        maxHeight = 0.03;
        baseColor = const Color(0xFF282828);
        break;
      case QuarterType.mixed:
        minSize = 0.015;
        maxSize = 0.05;
        maxHeight = 0.035;
        baseColor = const Color(0xFF2E2E2E);
        break;
      case QuarterType.military:
        minSize = 0.04;
        maxSize = 0.08;
        maxHeight = 0.025;
        baseColor = const Color(0xFF202028);
        break;
    }

    while (buildings.length < quarter.buildingsCount && attempts < 200) {
      attempts++;

      final w = minSize + rng.nextDouble() * (maxSize - minSize);
      final h = minSize + rng.nextDouble() * (maxSize - minSize);
      final x = minX + rng.nextDouble() * (maxX - minX - w);
      final y = minY + rng.nextDouble() * (maxY - minY - h);

      final rect = Rect.fromLTWH(x, y, w, h);

      // Центр здания должен быть внутри квартала.
      if (!quarter.contains(rect.center)) continue;

      // Не пересекаться с существующими.
      bool overlaps = false;
      for (final b in buildings) {
        if (b.rect.overlaps(rect.inflate(0.005))) {
          overlaps = true;
          break;
        }
      }
      if (overlaps) continue;

      buildings.add(Building(
        rect: rect,
        height: maxHeight * (0.4 + rng.nextDouble() * 0.6),
        hasChimney: rng.nextDouble() < 0.15,
        color: baseColor,
      ));
    }

    return buildings;
  }
}