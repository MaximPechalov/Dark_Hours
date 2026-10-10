// lib/screens/gameplay/map/map_region_transition.dart

import 'package:flutter/material.dart';

/// Оверлей перехода между регионами.
///
/// **НЕПРОЗРАЧНЫЙ** — полностью закрывает карту, чтобы игрок
/// не видел старый фон под новыми локациями.
///
/// Появляется/исчезает через [AnimatedOpacity] (400 ms).
///
/// Управление (когда показывать/скрывать) — снаружи,
/// в [MapMovementHandler.onRegionChanged].
class MapRegionTransition extends StatelessWidget {
  /// Показывать ли оверлей.
  final bool visible;

  /// Название региона, который загружается.
  final String regionName;

  /// Длительность анимации появления/исчезновения.
  final Duration animationDuration;

  const MapRegionTransition({
    super.key,
    required this.visible,
    required this.regionName,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: animationDuration,
        child: Container(
          // ⚡ НЕПРОЗРАЧНЫЙ фон — гарантирует, что старый регион не виден.
          color: const Color(0xFF08080A),
          alignment: Alignment.center,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC8B464).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '◉ ПЕРЕХОД ◉',
            style: TextStyle(
              color: Color(0xFFC8B464),
              fontSize: 11,
              letterSpacing: 4.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            regionName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFC8B464),
              ),
            ),
          ),
        ],
      ),
    );
  }
}