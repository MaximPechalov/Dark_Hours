import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/widgets/indicators/time_indicator.dart';
import 'package:dark_hours/widgets/indicators/animated_stat_bar.dart';

/// Верхняя панель статуса игрока.
///
/// Показывает:
/// - время (TimeIndicator)
/// - усталость (если > 0)
/// - счётчик поражений (если > 0)
/// - текущую главу
/// - пять полосок статов: голод, жажда, здоровье, психика, стамина
class MapStatusBar extends StatelessWidget {
  final MapController controller;

  const MapStatusBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        border: Border(
          bottom: BorderSide(
            color: const Color.fromARGB(255, 200, 180, 100).withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildTopRow(),
          const SizedBox(height: 8),
          _buildStatsRow(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ВЕРХНИЙ РЯД: время + усталость + поражения + глава
  // ═══════════════════════════════════════════════════════════

  Widget _buildTopRow() {
    return Row(
      children: [
        TimeIndicator(time: controller.gameTime),
        const Spacer(),
        if (controller.fatigue > 0) ...[
          _buildFatigueIndicator(),
          const SizedBox(width: 12),
        ],
        if (controller.tracker.defeats > 0) ...[
          _buildDefeatsIndicator(),
          const SizedBox(width: 12),
        ],
        _buildChapterLabel(),
      ],
    );
  }

  Widget _buildFatigueIndicator() {
    final fatigue = controller.fatigue;
    final color = fatigue > 80
        ? Colors.red
        : (fatigue > 60 ? Colors.orange : Colors.grey);

    return Row(
      children: [
        Icon(
          Icons.bedtime,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          'Устал $fatigue%',
          style: TextStyle(
            color: fatigue > 80
                ? Colors.red
                : (fatigue > 60 ? Colors.orange : Colors.grey[500]),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDefeatsIndicator() {
    return Row(
      children: [
        Icon(
          Icons.healing,
          color: Colors.orange[300],
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          '${controller.tracker.defeats}',
          style: TextStyle(
            color: Colors.orange[300],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChapterLabel() {
    return Text(
      'Глава ${controller.chapter}',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 12,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // НИЖНИЙ РЯД: пять полосок статов
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: AnimatedStatBar(
            icon: '🍞',
            value: controller.hunger,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '💧',
            value: controller.thirst,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '❤️',
            value: controller.health,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '🧠',
            value: controller.sanity,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '⚡',
            value: controller.stamina,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}