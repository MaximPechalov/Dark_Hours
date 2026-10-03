import 'package:flutter/material.dart';
import 'package:dark_hours/models/world/region_layout.dart';

/// Layout для региона **underground**.
///
/// Подземелье — тоннели, платформы метро, бункер.
/// Нет зданий — вместо них «технические зоны».
class UndergroundLayout {
  UndergroundLayout._();

  static const String regionId = 'underground';
  static const Size logicalSize = Size(800, 1200);

  static final RegionLayout layout = RegionLayout(
    regionId: regionId,
    logicalSize: logicalSize,
    backgroundColor: const Color(0xFF050508),
    quarterColor: const Color(0xFF0E0E14),
    quarters: _quarters,
    parks: const [],
    river: null,
    roads: _tunnels,
  );

  // ═══════════════════════════════════════════════════════════
  // «КВАРТАЛЫ» — технические зоны (визуально — это платформы)
  // ═══════════════════════════════════════════════════════════

  static final List<Quarter> _quarters = [
    // Платформа метро (запад, центр).
    Quarter(
      id: 'metro_platform_zone',
      polygon: const [
        Offset(0.05, 0.35),
        Offset(0.35, 0.35),
        Offset(0.38, 0.50),
        Offset(0.32, 0.62),
        Offset(0.05, 0.62),
      ],
      type: QuarterType.industrial,
      buildingsCount: 4,
      seed: 3000,
    ),

    // Бункер (восток, центр).
    Quarter(
      id: 'bunker_zone',
      polygon: const [
        Offset(0.62, 0.30),
        Offset(0.95, 0.30),
        Offset(0.95, 0.55),
        Offset(0.60, 0.55),
      ],
      type: QuarterType.military,
      buildingsCount: 3,
      seed: 3100,
    ),

    // Тоннельный узел (центр).
    Quarter(
      id: 'tunnel_hub_zone',
      polygon: const [
        Offset(0.40, 0.35),
        Offset(0.58, 0.35),
        Offset(0.60, 0.55),
        Offset(0.40, 0.55),
      ],
      type: QuarterType.industrial,
      buildingsCount: 2,
      seed: 3200,
    ),

    // Канализация (юг).
    Quarter(
      id: 'sewer_zone',
      polygon: const [
        Offset(0.10, 0.65),
        Offset(0.90, 0.65),
        Offset(0.90, 0.92),
        Offset(0.10, 0.92),
      ],
      type: QuarterType.industrial,
      buildingsCount: 3,
      seed: 3300,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // «ДОРОГИ» — тоннели (изогнутые)
  // ═══════════════════════════════════════════════════════════

  static const List<Road> _tunnels = [
    // Главная горизонтальная линия (метро).
    Road(
      path: [
        Offset(0.00, 0.50),
        Offset(0.20, 0.48),
        Offset(0.40, 0.50),
        Offset(0.65, 0.48),
        Offset(1.00, 0.50),
      ],
      isMain: true,
    ),

    // Вертикальная линия (вентиляция).
    Road(
      path: [
        Offset(0.50, 0.00),
        Offset(0.48, 0.25),
        Offset(0.50, 0.50),
        Offset(0.52, 0.75),
        Offset(0.50, 1.00),
      ],
      isMain: true,
    ),

    // Ответвление к бункеру.
    Road(
      path: [
        Offset(0.50, 0.50),
        Offset(0.75, 0.42),
        Offset(0.85, 0.45),
      ],
      isMain: false,
    ),

    // Ответвление к канализации.
    Road(
      path: [
        Offset(0.50, 0.50),
        Offset(0.35, 0.70),
        Offset(0.30, 0.85),
      ],
      isMain: false,
    ),

    // Ответвление к заброшенному тоннелю.
    Road(
      path: [
        Offset(0.00, 0.75),
        Offset(0.15, 0.80),
        Offset(0.30, 0.85),
      ],
      isMain: false,
    ),
  ];
}