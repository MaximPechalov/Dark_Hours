import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/models/world/location.dart';

/// Кликабельная карточка соседней локации.
///
/// Показывает:
/// - иконку локации
/// - название
/// - краткое описание (в одну строку)
/// - чипы: опасность, кол-во врагов, лута, счётчик обысков
/// - значок «📖» если здесь ждёт сюжетное событие
///
/// По тапу вызывает [onTap].
class MapLocationCard extends StatelessWidget {
  final MapController controller;
  final Location location;
  final VoidCallback onTap;

  const MapLocationCard({
    super.key,
    required this.controller,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHidden = location.hidden;
    final searched = controller.searchedCounts[location.id] ?? 0;
    final remaining =
        (location.maxSearches - searched).clamp(0, location.maxSearches);

    final borderColor = isHidden
        ? const Color.fromARGB(255, 100, 200, 100).withOpacity(0.5)
        : location.dangerColor.withOpacity(0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 18, 18, 18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(isHidden, remaining)),
            _buildArrow(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ИКОНКА
  // ═══════════════════════════════════════════════════════════

  Widget _buildIcon() {
    return Text(
      location.icon,
      style: const TextStyle(fontSize: 32),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ИНФОРМАЦИЯ
  // ═══════════════════════════════════════════════════════════

  Widget _buildInfo(bool isHidden, int remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(isHidden),
        const SizedBox(height: 4),
        _buildDescription(),
        const SizedBox(height: 6),
        _buildChips(remaining),
      ],
    );
  }

  Widget _buildTitleRow(bool isHidden) {
    return Row(
      children: [
        Flexible(
          child: Text(
            location.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isHidden) ...[
          const SizedBox(width: 6),
          const Text('🔓', style: TextStyle(fontSize: 12)),
        ],
        if (_hasStoryTrigger()) ...[
          const SizedBox(width: 6),
          _buildStoryBadge(),
        ],
      ],
    );
  }

  Widget _buildStoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 200, 120, 100),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '📖',
        style: TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      location.description,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ЧИПЫ
  // ═══════════════════════════════════════════════════════════

  Widget _buildChips(int remaining) {
    return Row(
      children: [
        _buildChip('⚠️ ${location.dangerLevel}', location.dangerColor),
        const SizedBox(width: 6),
        if (location.enemies.isNotEmpty)
          _buildChip(
            '👥 ${location.enemies.length}',
            Colors.red[400]!,
          ),
        if (location.lootPool.isNotEmpty) ...[
          const SizedBox(width: 6),
          _buildChip('🎁', Colors.green[400]!),
        ],
        if (location.maxSearches > 0 && remaining > 0) ...[
          const SizedBox(width: 6),
          _buildChip('🔍 $remaining', Colors.cyan[400]!),
        ],
        if (location.maxSearches > 0 && remaining == 0) ...[
          const SizedBox(width: 6),
          _buildChip('🔍 пусто', Colors.grey[600]!),
        ],
      ],
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // СТРЕЛКА
  // ═══════════════════════════════════════════════════════════

  Widget _buildArrow() {
    return const Icon(
      Icons.arrow_forward_ios,
      color: Color.fromARGB(255, 200, 180, 100),
      size: 16,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // СЮЖЕТНЫЙ ТРИГГЕР
  // ═══════════════════════════════════════════════════════════

  /// Есть ли в этой локации сюжетный триггер, который ещё не сработал.
  bool _hasStoryTrigger() {
    if (location.storyNode == null) return false;

    return location.canTriggerStory(
      currentChapter: controller.chapter,
      currentCharacter: controller.characterId,
      triggeredNodes: controller.flags,
    );
  }
}