import 'package:flutter/material.dart';
import 'package:dark_hours/models/world/region_layout.dart';

/// Layout для региона **city_center**.
///
/// Центр города — плотная застройка, офисы, площадь, мало зелени.
class CityCenterLayout {
  CityCenterLayout._();

  static const String regionId = 'city_center';
  static const Size logicalSize = Size(800, 1200);

  static final RegionLayout layout = RegionLayout(
    regionId: regionId,
    logicalSize: logicalSize,
    backgroundColor: const Color(0xFF0C0C10),
    quarterColor: const Color(0xFF1A1A1A),
    quarters: _quarters,
    parks: _parks,
    river: null, // в центре нет реки
    roads: _roads,
  );

  // ═══════════════════════════════════════════════════════════
  // КВАРТАЛЫ
  // ═══════════════════════════════════════════════════════════

  static final List<Quarter> _quarters = [
    // ─── Больница (запад, север) ───
    Quarter(
      id: 'hospital_block',
      polygon: const [
        Offset(0.02, 0.04),
        Offset(0.28, 0.04),
        Offset(0.30, 0.18),
        Offset(0.26, 0.28),
        Offset(0.02, 0.28),
      ],
      type: QuarterType.commercial,
      buildingsCount: 5,
      seed: 1100,
    ),

    // ─── Административный квартал (центр, север) ───
    Quarter(
      id: 'gov_block',
      polygon: const [
        Offset(0.36, 0.04),
        Offset(0.62, 0.04),
        Offset(0.64, 0.18),
        Offset(0.60, 0.28),
        Offset(0.34, 0.28),
      ],
      type: QuarterType.commercial,
      buildingsCount: 6,
      seed: 1200,
    ),

    // ─── Полиция + мэрия (восток, север) ───
    Quarter(
      id: 'police_block',
      polygon: const [
        Offset(0.68, 0.04),
        Offset(0.98, 0.04),
        Offset(0.98, 0.28),
        Offset(0.70, 0.28),
      ],
      type: QuarterType.industrial,
      buildingsCount: 5,
      seed: 1300,
    ),

    // ─── Библиотека + театр (запад, центр) ───
    Quarter(
      id: 'culture_block',
      polygon: const [
        Offset(0.02, 0.32),
        Offset(0.30, 0.32),
        Offset(0.32, 0.46),
        Offset(0.28, 0.60),
        Offset(0.02, 0.60),
      ],
      type: QuarterType.commercial,
      buildingsCount: 6,
      seed: 1400,
    ),

    // ─── Центральный квартал — офисы, кафе (центр) ───
    Quarter(
      id: 'center_block',
      polygon: const [
        Offset(0.36, 0.32),
        Offset(0.64, 0.32),
        Offset(0.66, 0.46),
        Offset(0.62, 0.60),
        Offset(0.34, 0.60),
        Offset(0.34, 0.44),
      ],
      type: QuarterType.commercial,
      buildingsCount: 7,
      seed: 1500,
    ),

    // ─── Университет + планетарий (восток, центр) ───
    Quarter(
      id: 'university_block',
      polygon: const [
        Offset(0.70, 0.32),
        Offset(0.98, 0.32),
        Offset(0.98, 0.60),
        Offset(0.68, 0.60),
        Offset(0.68, 0.46),
      ],
      type: QuarterType.commercial,
      buildingsCount: 6,
      seed: 1600,
    ),

    // ─── Церковь + офисы (запад, юг) ───
    Quarter(
      id: 'south_west_block',
      polygon: const [
        Offset(0.02, 0.64),
        Offset(0.30, 0.64),
        Offset(0.32, 0.80),
        Offset(0.26, 0.92),
        Offset(0.02, 0.92),
      ],
      type: QuarterType.mixed,
      buildingsCount: 6,
      seed: 1700,
    ),

    // ─── Банк + метро (центр, юг) ───
    Quarter(
      id: 'bank_block',
      polygon: const [
        Offset(0.36, 0.64),
        Offset(0.64, 0.64),
        Offset(0.66, 0.78),
        Offset(0.60, 0.92),
        Offset(0.34, 0.92),
      ],
      type: QuarterType.commercial,
      buildingsCount: 6,
      seed: 1800,
    ),

    // ─── Крыши + спортзал (восток, юг) ───
    Quarter(
      id: 'rooftops_block',
      polygon: const [
        Offset(0.70, 0.64),
        Offset(0.98, 0.64),
        Offset(0.98, 0.92),
        Offset(0.68, 0.92),
      ],
      type: QuarterType.industrial,
      buildingsCount: 5,
      seed: 1900,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // ПАРКИ
  // ═══════════════════════════════════════════════════════════

  static final List<Park> _parks = [
    // Центральный парк — на юго-западе.
    Park(
      id: 'park_center',
      polygon: const [
        Offset(0.05, 0.42),
        Offset(0.25, 0.42),
        Offset(0.27, 0.52),
        Offset(0.22, 0.60),
        Offset(0.05, 0.58),
      ],
      treesCount: 18,
      seed: 2000,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // ДОРОГИ
  // ═══════════════════════════════════════════════════════════

  static const List<Road> _roads = [
    // Главный горизонтальный бульвар (север).
    Road(
      path: [
        Offset(0.00, 0.30),
        Offset(0.34, 0.30),
        Offset(0.66, 0.30),
        Offset(1.00, 0.30),
      ],
      isMain: true,
    ),

    // Второй горизонтальный (центр).
    Road(
      path: [
        Offset(0.00, 0.62),
        Offset(0.34, 0.62),
        Offset(0.66, 0.62),
        Offset(1.00, 0.62),
      ],
      isMain: true,
    ),

    // Главный вертикальный проспект.
    Road(
      path: [
        Offset(0.34, 0.00),
        Offset(0.34, 0.30),
        Offset(0.34, 0.62),
        Offset(0.34, 1.00),
      ],
      isMain: true,
    ),

    // Второй вертикальный (восточнее).
    Road(
      path: [
        Offset(0.66, 0.00),
        Offset(0.66, 0.30),
        Offset(0.66, 0.62),
        Offset(0.66, 1.00),
      ],
      isMain: false,
    ),

    // Диагональная дорога (юго-восток).
    Road(
      path: [
        Offset(0.66, 0.62),
        Offset(0.80, 0.70),
        Offset(0.98, 0.82),
      ],
      isMain: false,
    ),
  ];
}