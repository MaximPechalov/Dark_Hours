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
  final bool isSelected;

  /// Разведано ли состояние локации (детальная разведка).
  final bool hasDetails;

  final VoidCallback? onTap;

  static const double nodeSize = 56.0;
  static const double labelWidth = 110.0;

  const MapNode({
    super.key,
    required this.location,
    required this.state,
    this.isSelected = false,
    this.hasDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTappable = state != NodeState.hidden;

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
                  if (isSelected && state != NodeState.current)
                    _buildSelectedPulse(),
                  _buildCircle(),
                  _buildIcon(),
                  if (hasDetails && state != NodeState.current)
                    _buildDetailsBadge(),
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

  /// Пульсация выбранной локации.
  Widget _buildSelectedPulse() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: nodeSize + 14 * value,
          height: nodeSize + 14 * value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFD070)
                  .withValues(alpha: (1.0 - value) * 0.6),
              width: 1.5,
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
        boxShadow: _getBoxShadows(),
      ),
    );
  }

  /// Тени (для текущей / выбранной).
  List<BoxShadow>? _getBoxShadows() {
    if (state == NodeState.current) {
      return [
        BoxShadow(
          color: const Color(0xFFC8B464).withValues(alpha: 0.5),
          blurRadius: 14,
          spreadRadius: 3,
        ),
      ];
    }
    if (isSelected) {
      return [
        BoxShadow(
          color: const Color(0xFFFFD070).withValues(alpha: 0.6),
          blurRadius: 16,
          spreadRadius: 4,
        ),
      ];
    }
    if (state == NodeState.neighbor) {
      return [
        BoxShadow(
          color: const Color(0xFFC8B464).withValues(alpha: 0.2),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    }
    return null;
  }

  /// Цвет заливки — по danger_level.
  Color _getFillColor() {
    if (state == NodeState.hidden) return Colors.transparent;
    if (state == NodeState.current) return const Color(0xFF2A2418);
    if (state == NodeState.neighbor) return const Color(0xFF1E1A12);

    // visited — по уровню опасности
    final danger = location.dangerLevel;
    if (location.isFinal) return const Color(0xFF3A2E10);
    if (danger <= 2) return const Color(0xFF142018);
    if (danger <= 5) return const Color(0xFF201814);
    if (danger <= 8) return const Color(0xFF201010);
    return const Color(0xFF251010);
  }

  /// Цвет обводки.
  ///
  /// Для visited с деталями — синеватый оттенок (разведано).
  Color _getBorderColor() {
    if (isSelected && state != NodeState.current) {
      return const Color(0xFFFFD070);
    }

    switch (state) {
      case NodeState.current:
        return const Color(0xFFC8B464);
      case NodeState.neighbor:
        return const Color(0xFFC8B464).withValues(alpha: 0.75);
      case NodeState.visited:
        // Разведанные детально — синеватая обводка.
        if (hasDetails) {
          return const Color(0xFF5F8FBF).withValues(alpha: 0.8);
        }
        if (location.isFinal) {
          return const Color(0xFFC8B464).withValues(alpha: 0.6);
        }
        if (location.hidden) {
          return const Color(0xFF8844FF).withValues(alpha: 0.6);
        }
        return Colors.white.withValues(alpha: 0.4);
      case NodeState.hidden:
        return Colors.transparent;
    }
  }

  /// Толщина обводки.
  double _getBorderWidth() {
    if (isSelected && state != NodeState.current) return 2.5;

    switch (state) {
      case NodeState.current:
        return 2.5;
      case NodeState.neighbor:
        return 2.0;
      case NodeState.visited:
        return hasDetails ? 1.5 : 1.0;
      case NodeState.hidden:
        return 0.0;
    }
  }

  /// Иконка внутри кружка.
  Widget _buildIcon() {
    final opacity = state == NodeState.visited && !isSelected ? 0.6 : 1.0;

    if (location.isFinal) {
      return Opacity(
        opacity: opacity,
        child: const Text('⭐', style: TextStyle(fontSize: 26)),
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

  /// Значок «разведано» — маленький 🔭 в правом верхнем углу.
  Widget _buildDetailsBadge() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF5F8FBF),
            width: 1,
          ),
        ),
        child: const Text(
          '🔭',
          style: TextStyle(fontSize: 9),
        ),
      ),
    );
  }

  /// Подпись локации.
  Widget _buildLabel() {
    final Color textColor;
    final FontWeight weight;

    if (isSelected) {
      textColor = const Color(0xFFFFD070);
      weight = FontWeight.bold;
    } else {
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
          // Разведанные — чуть заметнее.
          if (hasDetails) {
            textColor = const Color(0xFF8FB5D8);
            weight = FontWeight.w500;
          } else {
            textColor = Colors.white.withValues(alpha: 0.5);
            weight = FontWeight.normal;
          }
          break;
        case NodeState.hidden:
          return const SizedBox.shrink();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(3),
        border: isSelected
            ? Border.all(
                color: const Color(0xFFFFD070).withValues(alpha: 0.6),
                width: 1,
              )
            : null,
      ),
      child: Text(
        location.displayScoutedName,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: weight,
          letterSpacing: 0.2,
          height: 1.1,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}