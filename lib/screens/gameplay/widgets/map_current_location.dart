import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';

/// Компактная карточка текущей локации (внизу экрана).
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 18, 18, 18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: loc.hidden
              ? const Color(0xFF64C864)
              : const Color(0xFFC8B464),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Верхняя строка: иконка + название
          Row(
            children: [
              Text(
                loc.icon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (loc.hidden)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64C864).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFF64C864),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '🔓',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Описание в одну строку
          Text(
            loc.description,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Чипы в одну строку
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('⚠️ ${loc.dangerLevel}', loc.dangerColor),
                const SizedBox(width: 6),
                if (loc.searchTime > 0)
                  _chip(
                    '⏱️ ${loc.searchTime}м',
                    Colors.blue[400]!,
                  ),
                if (loc.enemies.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _chip('👥 ${loc.enemies.length}', Colors.red[400]!),
                ],
                if (loc.lootPool.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _chip('🎁', Colors.green[400]!),
                ],
                if (loc.risk != null) ...[
                  const SizedBox(width: 6),
                  _chip('☣️', Colors.deepOrange[400]!),
                ],
                if (loc.maxSearches > 0) ...[
                  const SizedBox(width: 6),
                  _chip(
                    '🔍 ${(loc.maxSearches - (controller.searchedCounts[loc.id] ?? 0)).clamp(0, loc.maxSearches)}/${loc.maxSearches}',
                    Colors.cyan[400]!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
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
}