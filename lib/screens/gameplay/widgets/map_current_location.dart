import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/time/game_time.dart';

/// Карточка текущей локации.
///
/// Показывает:
/// - иконку локации
/// - метку «ТЫ ЗДЕСЬ» + фазу суток
/// - значок «🔓 СКРЫТОЕ» (если локация скрытая)
/// - название локации
/// - полное описание
/// - чипы: опасность, время поиска, кол-во врагов, лута, риска,
///   счётчик обысков
class MapCurrentLocation extends StatelessWidget {
  final MapController controller;

  const MapCurrentLocation({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final loc = controller.currentLocation;
    if (loc == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: loc.hidden
              ? const Color.fromARGB(255, 100, 200, 100)
              : const Color.fromARGB(255, 200, 180, 100),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(loc),
          const SizedBox(height: 12),
          _buildDescription(loc),
          const SizedBox(height: 12),
          _buildChips(loc),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER: иконка + метка + название
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeader(Location loc) {
    return Row(
      children: [
        Text(loc.icon, style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopLabelRow(loc),
              const SizedBox(height: 4),
              Text(
                loc.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopLabelRow(Location loc) {
    return Row(
      children: [
        Text(
          'ТЫ ЗДЕСЬ · ${controller.gameTime.phase.name.toUpperCase()}',
          style: TextStyle(
            color: controller.gameTime.phase.color,
            fontSize: 10,
            letterSpacing: 2.0,
          ),
        ),
        if (loc.hidden) ...[
          const SizedBox(width: 6),
          _buildHiddenBadge(),
        ],
      ],
    );
  }

  Widget _buildHiddenBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 100, 200, 100).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color.fromARGB(255, 100, 200, 100),
          width: 1,
        ),
      ),
      child: const Text(
        '🔓 СКРЫТОЕ',
        style: TextStyle(
          color: Color.fromARGB(255, 100, 200, 100),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ОПИСАНИЕ
  // ═══════════════════════════════════════════════════════════

  Widget _buildDescription(Location loc) {
    return Text(
      loc.description,
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 13,
        height: 1.5,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ЧИПЫ
  // ═══════════════════════════════════════════════════════════

  Widget _buildChips(Location loc) {
    final searched = controller.searchedCounts[loc.id] ?? 0;
    final remaining = (loc.maxSearches - searched).clamp(0, loc.maxSearches);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildChip('⚠️ ${loc.dangerName}', loc.dangerColor),
        _buildChip('⏱️ ${loc.searchTime} мин', Colors.blue[400]!),
        if (loc.enemies.isNotEmpty)
          _buildChip('👥 ${loc.enemies.length}', Colors.red[400]!),
        if (loc.lootPool.isNotEmpty)
          _buildChip('🎁 ${loc.lootPool.length}', Colors.green[400]!),
        if (loc.risk != null)
          _buildChip('☣️ Опасность', Colors.deepOrange[400]!),
        if (loc.maxSearches > 0)
          _buildChip(
            '🔍 $remaining / ${loc.maxSearches}',
            remaining > 0 ? Colors.cyan[400]! : Colors.grey[600]!,
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ХЕЛПЕР
  // ═══════════════════════════════════════════════════════════

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}