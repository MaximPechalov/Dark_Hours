import 'package:flutter/material.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

/// Модалка с информацией о локации (для клика по посещённой).
class MapInfoSheet extends StatelessWidget {
  final Location location;
  final VoidCallback? onMove;
  final bool canMove;

  const MapInfoSheet({
    super.key,
    required this.location,
    this.onMove,
    this.canMove = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 15, 15, 15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: location.dangerColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    location.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '⚠️ ${location.dangerName}',
                            style: TextStyle(
                              color: location.dangerColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '📍 ${location.mapZone ?? location.region}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Описание
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 20, 20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[850]!,
                  width: 1,
                ),
              ),
              child: Text(
                location.description,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Статы
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('⚠️ Опасность ${location.dangerLevel}', location.dangerColor),
                if (location.searchTime > 0)
                  _chip(
                    '⏱️ ${location.searchTime} мин',
                    Colors.blue[400]!,
                  ),
                if (location.enemies.isNotEmpty)
                  _chip(
                    '👥 ${location.enemies.length}',
                    Colors.red[400]!,
                  ),
                if (location.lootPool.isNotEmpty)
                  _chip(
                    '🎁 ${location.lootPool.length}',
                    Colors.green[400]!,
                  ),
                if (location.risk != null)
                  _chip('☣️ Опасность', Colors.deepOrange[400]!),
              ],
            ),
            const SizedBox(height: 24),

            // Кнопка перемещения (если это сосед)
            if (canMove && onMove != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AudioService.playClick();
                    Navigator.pop(context);
                    onMove!();
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text(
                    'ПЕРЕЙТИ СЮДА',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8B464),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                },
                child: Text(
                  'ЗАКРЫТЬ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
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