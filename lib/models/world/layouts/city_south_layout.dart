import 'package:flutter/material.dart';
import 'package:dark_hours/models/world/region_layout.dart';

/// Layout для региона **city_south**.
///
/// Южная часть города — стартовый регион.
/// Промзона, торговые улицы, жилые кварталы, парк у реки.
class CitySouthLayout {
  CitySouthLayout._();

  static const String regionId = 'city_south';
  static const Size logicalSize = Size(800, 1200);

  /// Регион целиком.
  static final RegionLayout layout = RegionLayout(
    regionId: regionId,
    logicalSize: logicalSize,
    backgroundColor: const Color(0xFF0A0A0A),
    quarterColor: const Color(0xFF1A1A1A),
    quarters: _quarters,
    parks: _parks,
    river: _river,
    roads: _roads,
  );

  // ═══════════════════════════════════════════════════════════
  // КВАРТАЛЫ
  // ═══════════════════════════════════════════════════════════

  static final List<Quarter> _quarters = [
    // ─── Жилой квартал (запад, север) ───
    Quarter(
      id: 'residential_west',
      polygon: const [
        Offset(0.02, 0.05),
        Offset(0.30, 0.05),
        Offset(0.32, 0.18),
        Offset(0.28, 0.32),
        Offset(0.02, 0.30),
      ],
      type: QuarterType.residential,
      buildingsCount: 8,
      seed: 100,
    ),

    // ─── Жилой квартал (центр-север) ───
    Quarter(
      id: 'residential_center',
      polygon: const [
        Offset(0.36, 0.04),
        Offset(0.62, 0.04),
        Offset(0.64, 0.20),
        Offset(0.60, 0.32),
        Offset(0.34, 0.30),
        Offset(0.34, 0.10),
      ],
      type: QuarterType.residential,
      buildingsCount: 7,
      seed: 200,
    ),

    // ─── Коммерческий квартал (восток, север) ───
    Quarter(
      id: 'commercial_east',
      polygon: const [
        Offset(0.68, 0.04),
        Offset(0.97, 0.06),
        Offset(0.96, 0.28),
        Offset(0.70, 0.30),
        Offset(0.68, 0.18),
      ],
      type: QuarterType.commercial,
      buildingsCount: 6,
      seed: 300,
    ),

    // ─── Промзона (восток, центр) ───
    Quarter(
      id: 'industrial_east',
      polygon: const [
        Offset(0.66, 0.36),
        Offset(0.98, 0.36),
        Offset(0.98, 0.60),
        Offset(0.72, 0.62),
        Offset(0.68, 0.48),
      ],
      type: QuarterType.industrial,
      buildingsCount: 5,
      seed: 400,
    ),

    // ─── Коммерческий квартал (центр) ───
    Quarter(
      id: 'commercial_center',
      polygon: const [
        Offset(0.36, 0.36),
        Offset(0.60, 0.36),
        Offset(0.62, 0.48),
        Offset(0.58, 0.62),
        Offset(0.34, 0.60),
        Offset(0.34, 0.44),
      ],
      type: QuarterType.commercial,
      buildingsCount: 6,
      seed: 500,
    ),

    // ─── Смешанный квартал (запад, центр) ───
    Quarter(
      id: 'mixed_west',
      polygon: const [
        Offset(0.02, 0.36),
        Offset(0.28, 0.36),
        Offset(0.30, 0.52),
        Offset(0.26, 0.62),
        Offset(0.02, 0.60),
      ],
      type: QuarterType.mixed,
      buildingsCount: 6,
      seed: 600,
    ),

    // ─── Смешанный квартал (центр-юг) ───
    Quarter(
      id: 'mixed_south',
      polygon: const [
        Offset(0.34, 0.66),
        Offset(0.60, 0.66),
        Offset(0.62, 0.80),
        Offset(0.58, 0.86),
        Offset(0.34, 0.86),
        Offset(0.32, 0.78),
      ],
      type: QuarterType.mixed,
      buildingsCount: 6,
      seed: 700,
    ),

    // ─── Промзона (запад, юг) ───
    Quarter(
      id: 'industrial_west',
      polygon: const [
        Offset(0.02, 0.66),
        Offset(0.28, 0.66),
        Offset(0.30, 0.80),
        Offset(0.24, 0.92),
        Offset(0.02, 0.92),
      ],
      type: QuarterType.industrial,
      buildingsCount: 5,
      seed: 800,
    ),

    // ─── Коммерческий квартал (восток, юг) ───
    Quarter(
      id: 'commercial_south',
      polygon: const [
        Offset(0.66, 0.66),
        Offset(0.98, 0.68),
        Offset(0.96, 0.88),
        Offset(0.66, 0.88),
        Offset(0.64, 0.76),
      ],
      type: QuarterType.commercial,
      buildingsCount: 6,
      seed: 900,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // ПАРКИ
  // ═══════════════════════════════════════════════════════════

  static final List<Park> _parks = [
    // Южный парк — центрально-западный.
    Park(
      id: 'park_south',
      polygon: const [
        Offset(0.10, 0.40),
        Offset(0.28, 0.38),
        Offset(0.30, 0.50),
        Offset(0.26, 0.60),
        Offset(0.08, 0.58),
      ],
      treesCount: 25,
      seed: 1000,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // РЕКА
  // ═══════════════════════════════════════════════════════════

  static const River _river = River(
    path: [
      Offset(-0.05, 0.94),
      Offset(0.15, 0.92),
      Offset(0.30, 0.95),
      Offset(0.48, 0.93),
      Offset(0.65, 0.96),
      Offset(0.85, 0.94),
      Offset(1.05, 0.95),
    ],
    width: 0.03,
  );

  // ═══════════════════════════════════════════════════════════
  // ДОРОГИ
  // ═══════════════════════════════════════════════════════════

  static const List<Road> _roads = [
    // Главная горизонтальная — Южная улица.
    Road(
      path: [
        Offset(0.00, 0.33),
        Offset(0.34, 0.33),
        Offset(0.64, 0.33),
        Offset(1.00, 0.33),
      ],
      isMain: true,
    ),

    // Вторая горизонтальная — Центральная.
    Road(
      path: [
        Offset(0.00, 0.64),
        Offset(0.32, 0.64),
        Offset(0.62, 0.64),
        Offset(1.00, 0.65),
      ],
      isMain: true,
    ),

    // Главная вертикальная — через весь регион.
    Road(
      path: [
        Offset(0.32, 0.00),
        Offset(0.34, 0.33),
        Offset(0.35, 0.64),
        Offset(0.33, 1.00),
      ],
      isMain: true,
    ),

    // Вертикальная — восточнее центра.
    Road(
      path: [
        Offset(0.64, 0.00),
        Offset(0.65, 0.33),
        Offset(0.64, 0.64),
        Offset(0.65, 1.00),
      ],
      isMain: false,
    ),

    // Вертикальная — западная.
    Road(
      path: [
        Offset(0.00, 0.30),
        Offset(0.10, 0.45),
        Offset(0.00, 0.62),
      ],
      isMain: false,
    ),
  ];
}