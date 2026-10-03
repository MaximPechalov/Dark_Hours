import 'package:flutter/material.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

/// Модалка с информацией о локации.
///
/// Показывает три уровня знания:
/// - **visited** — игрок был здесь, полное описание + все детали.
/// - **detailed** — разведано состояние, но не был.
/// - **scouted** — знает только название и общее описание.
class MapInfoSheet extends StatelessWidget {
  final Location location;
  final bool canMove;
  final bool canScout;
  final bool isBorder;
  final int? travelMinutes;
  final bool isVisited;
  final bool isScouted;
  final bool hasDetails;
  final VoidCallback? onMove;
  final VoidCallback? onScout;

  const MapInfoSheet({
    super.key,
    required this.location,
    this.canMove = false,
    this.canScout = false,
    this.isBorder = false,
    this.travelMinutes,
    this.isVisited = false,
    this.isScouted = false,
    this.hasDetails = false,
    this.onMove,
    this.onScout,
  });

  @override
  Widget build(BuildContext context) {
    final showFull = isVisited;
    final showDetails = hasDetails && !isVisited;

    // Название и описание — по уровню знания.
    final name = showFull
        ? location.name
        : location.displayScoutedName;

    final description = showFull
        ? location.displayFullDescription
        : location.displayScoutedDescription;

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
            _buildHeader(name),
            const SizedBox(height: 20),

            _buildDescription(description, showFull, showDetails),
            const SizedBox(height: 16),

            // Чипы состояния — только если visited или detailed.
            if (showFull || showDetails) ...[
              _buildStatsChips(showFull),
              const SizedBox(height: 20),
            ],

            // Время в пути.
            if (canMove && travelMinutes != null) ...[
              _buildTravelInfo(travelMinutes!),
              const SizedBox(height: 16),
            ],

            // Кнопка «Перейти».
            if (canMove && onMove != null) ...[
              _buildMoveButton(context),
              const SizedBox(height: 8),
            ],

            // Кнопка «Разведать».
            if (canScout && onScout != null && !isVisited) ...[
              _buildScoutButton(context),
              const SizedBox(height: 8),
            ],

            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ЗАГОЛОВОК
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeader(String name) {
    return Row(
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
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    final status = _getStatus();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: status.color, width: 1),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (location.mapZone != null) ...[
          const SizedBox(width: 8),
          Text(
            '📍 ${location.mapZone}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  _LocationStatus _getStatus() {
    if (canMove) {
      return _LocationStatus(
        label: isBorder ? 'ЗА ГРАНИЦЕЙ' : 'ДОСТУПНА',
        color: isBorder
            ? const Color(0xFFFF8040)
            : const Color(0xFFC8B464),
      );
    }
    if (isVisited) {
      return const _LocationStatus(
        label: 'ИЗВЕСТНА',
        color: Color(0xFF888888),
      );
    }
    if (hasDetails) {
      return const _LocationStatus(
        label: 'РАЗВЕДАНА',
        color: Color(0xFF5F8FBF),
      );
    }
    if (isScouted) {
      return const _LocationStatus(
        label: 'ПРЕДПОЛОЖЕНИЕ',
        color: Color(0xFF888888),
      );
    }
    return const _LocationStatus(
      label: 'НЕИЗВЕСТНА',
      color: Color(0xFF666666),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ОПИСАНИЕ
  // ═══════════════════════════════════════════════════════════

  Widget _buildDescription(String description, bool showFull, bool showDetails) {
    // Для detailed без visited — генерируем уточнённое описание.
    final text = showDetails
        ? _buildDetailedDescription()
        : description;

    final label = showFull
        ? null
        : (showDetails
            ? 'РАЗВЕДАНО'
            : 'ПРЕДПОЛОЖЕНИЕ');

    final labelIcon = showDetails
        ? Icons.visibility_outlined
        : Icons.help_outline;

    final labelColor = showDetails
        ? const Color(0xFF5F8FBF)
        : const Color(0xFFC8B464).withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: showFull
              ? Colors.grey[850]!
              : (showDetails
                  ? const Color(0xFF5F8FBF).withValues(alpha: 0.3)
                  : const Color(0xFFC8B464).withValues(alpha: 0.3)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    labelIcon,
                    size: 12,
                    color: labelColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 9,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            text,
            style: TextStyle(
              color: showFull ? Colors.grey[300] : Colors.grey[400],
              fontSize: 13,
              height: 1.5,
              fontStyle: showFull ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Построить уточнённое описание состояния локации.
  String _buildDetailedDescription() {
    final parts = <String>[];

    // Опасность.
    if (location.dangerLevel >= 8) {
      parts.add('Очень опасно — лучше не соваться без подготовки.');
    } else if (location.dangerLevel >= 6) {
      parts.add('Опасно. Здесь легко нарваться на trouble.');
    } else if (location.dangerLevel >= 4) {
      parts.add('Настороженная тишина. Что-то здесь не так.');
    } else if (location.dangerLevel >= 2) {
      parts.add('Спокойно. Но расслабляться не стоит.');
    } else {
      parts.add('Тихо и безопасно.');
    }

    // Враги.
    if (location.enemies.isNotEmpty) {
      parts.add('Замечено целей: ${location.enemies.length}.');
    } else {
      parts.add('Врагов не видно.');
    }

    // Лут.
    if (location.lootPool.isNotEmpty) {
      parts.add('Есть чем поживиться.');
    }

    // Риск.
    if (location.risk != null) {
      parts.add('⚠️ Опасная зона.');
    }

    return parts.join(' ');
  }

  // ═══════════════════════════════════════════════════════════
  // ЧИПЫ СТАТИСТИКИ
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatsChips(bool showFull) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _chip('⚠️ ${location.dangerName}', location.dangerColor),
        if (location.searchTime > 0)
          _chip('⏱️ ${location.searchTime} мин', Colors.blue[400]!),
        if (location.enemies.isNotEmpty)
          _chip('👥 ${location.enemies.length}', Colors.red[400]!),
        if (location.lootPool.isNotEmpty)
          _chip('🎁 ${location.lootPool.length}', Colors.green[400]!),
        if (location.risk != null)
          _chip('☣️ Опасность', Colors.deepOrange[400]!),
      ],
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

  // ═══════════════════════════════════════════════════════════
  // ВРЕМЯ В ПУТИ
  // ═══════════════════════════════════════════════════════════

  Widget _buildTravelInfo(int minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC8B464).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8B464).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_walk,
            color: Color(0xFFC8B464),
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'Время в пути: ${_formatTime(minutes)}',
            style: const TextStyle(
              color: Color(0xFFC8B464),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // КНОПКИ
  // ═══════════════════════════════════════════════════════════

  Widget _buildMoveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          AudioService.playClick();
          Navigator.pop(context);
          onMove!();
        },
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text(
          'ПЕРЕЙТИ',
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
    );
  }

  Widget _buildScoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          AudioService.playClick();
          Navigator.pop(context);
          onScout!();
        },
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text(
          '🔭  РАЗВЕДАТЬ СОСТОЯНИЕ (30 мин)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5F8FBF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ХЕЛПЕРЫ
  // ═══════════════════════════════════════════════════════════

  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes мин';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }
}

class _LocationStatus {
  final String label;
  final Color color;

  const _LocationStatus({required this.label, required this.color});
}