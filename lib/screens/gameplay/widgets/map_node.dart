import 'package:flutter/material.dart';

import 'package:dark_hours/models/world/location.dart';

/// Состояние локации на карте.
enum NodeState {
  current,
  neighbor,
  visited,
  hidden,
}

/// Кружок локации на карте с подписью.
class MapNode extends StatelessWidget {
  final Location location;
  final NodeState state;
  final VoidCallback? onTap;

  static const double nodeSize = 56.0;
  static const double labelWidth = 110.0;

  const MapNode({
    super.key,
    required this.location,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTappable = state == NodeState.current ||
        state == NodeState.neighbor ||
        state == NodeState.visited;

    return GestureDetector(
      onTap: isTappable ? onTap : null,
      child: SizedBox(
        width: labelWidth,
        height: nodeSize + 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: nodeSize,
              height: nodeSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (state == NodeState.current) _buildPulse(),
                  _buildCircle(),
                  _buildIcon(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _buildLabel(),
          ],
        ),
      ),
    );
  }

  /// Пульсация текущей локации.
  Widget _buildPulse() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: nodeSize + 20 * value,
          height: nodeSize + 20 * value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFC8B464)
                  .withValues(alpha: (1.0 - value) * 0.5),
              width: 2.0,
            ),
          ),
        );
      },
    );
  }

  /// Основной кружок с обводкой.
  Widget _buildCircle() {
    final fillColor = _getFillColor();
    final borderColor = _getBorderColor();
    final borderWidth = _getBorderWidth();

    return Container(
      width: nodeSize - 10,
      height: nodeSize - 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: state == NodeState.current
            ? [
                BoxShadow(
                  color: const Color(0xFFC8B464).withValues(alpha: 0.5),
                  blurRadius: 14,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
    );
  }

  /// Цвет заливки — по danger_level.
  Color _getFillColor() {
    if (state == NodeState.hidden) return Colors.transparent;
    if (state == NodeState.current) return const Color(0xFF2A2418);
    if (state == NodeState.neighbor) return const Color(0xFF1E1A12);

    // visited — по уровню опасности
    final danger = location.dangerLevel;
    if (location.isFinal) return const Color(0xFF3A2E10); // Северная станция
    if (danger <= 2) return const Color(0xFF142018); // безопасно — зелёный
    if (danger <= 5) return const Color(0xFF201814); // средне — тёплый
    if (danger <= 8) return const Color(0xFF201010); // опасно — красный
    return const Color(0xFF251010); // смертельно — тёмно-красный
  }

  /// Цвет обводки.
  Color _getBorderColor() {
    switch (state) {
      case NodeState.current:
        return const Color(0xFFC8B464); // золотой
      case NodeState.neighbor:
        return const Color(0xFFC8B464).withValues(alpha: 0.75);
      case NodeState.visited:
        if (location.isFinal) {
          return const Color(0xFFC8B464).withValues(alpha: 0.6);
        }
        if (location.hidden) {
          return const Color(0xFF8844FF).withValues(alpha: 0.6); // скрытая
        }
        return Colors.white.withValues(alpha: 0.4);
      case NodeState.hidden:
        return Colors.transparent;
    }
  }

  /// Толщина обводки.
  double _getBorderWidth() {
    switch (state) {
      case NodeState.current:
        return 2.5;
      case NodeState.neighbor:
        return 2.0;
      case NodeState.visited:
        return 1.0;
      case NodeState.hidden:
        return 0.0;
    }
  }

  /// Иконка внутри кружка.
  Widget _buildIcon() {
    final opacity = state == NodeState.visited ? 0.7 : 1.0;

    // Финальная станция — особый значок
    if (location.isFinal) {
      return Opacity(
        opacity: opacity,
        child: const Text(
          '⭐',
          style: TextStyle(fontSize: 26),
        ),
      );
    }

    return Opacity(
      opacity: opacity,
      child: Text(
        location.icon,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  /// Подпись локации под кружком.
  Widget _buildLabel() {
    final Color textColor;
    final FontWeight weight;

    switch (state) {
      case NodeState.current:
        textColor = const Color(0xFFC8B464);
        weight = FontWeight.bold;
        break;
      case NodeState.neighbor:
        textColor = const Color(0xFFC8B464).withValues(alpha: 0.9);
        weight = FontWeight.w600;
        break;
      case NodeState.visited:
        textColor = Colors.white.withValues(alpha: 0.55);
        weight = FontWeight.normal;
        break;
      case NodeState.hidden:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        location.name,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: weight,
          letterSpacing: 0.2,
          height: 1.1,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}