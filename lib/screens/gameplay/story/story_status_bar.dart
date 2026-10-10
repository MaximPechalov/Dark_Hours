import 'package:flutter/material.dart';

import 'package:dark_hours/utils/time_format.dart';
import 'package:dark_hours/widgets/cards/character_portrait_from_stats.dart';
import 'package:dark_hours/widgets/indicators/animated_stat_bar.dart';

/// Статус-бар игрока в StoryScreen.
///
/// Показывает: портрет, время, усталость, главу, шаг, 5 полосок статов.
///
/// **Портрет** — меняется по статам через `CharacterStateCalculator`.
/// Голоден → голодный портрет. Ранен → раненый. Устал → уставший.
class StoryStatusBar extends StatelessWidget {
  final String characterId;

  final int timeMinutes;
  final int fatigue;
  final int chapter;
  final int historyLength;

  final int hunger;
  final int thirst;
  final int health;
  final int sanity;
  final int stamina;

  const StoryStatusBar({
    super.key,
    required this.characterId,
    required this.timeMinutes,
    required this.fatigue,
    required this.chapter,
    required this.historyLength,
    required this.hunger,
    required this.thirst,
    required this.health,
    required this.sanity,
    required this.stamina,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        border: Border(
          bottom: BorderSide(
            color: const Color.fromARGB(255, 200, 180, 100)
                .withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildTopRow(),
          const SizedBox(height: 8),
          _buildStatBars(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        // ⚡ Портрет персонажа — меняется по статам.
        CharacterPortraitFromStats(
          characterId: characterId,
          health: health,
          hunger: hunger,
          fatigue: fatigue,
          size: 40,
        ),
        const SizedBox(width: 10),

        // Время
        const Icon(
          Icons.access_time,
          color: Color.fromARGB(255, 200, 180, 100),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          TimeFormat.clock(timeMinutes),
          style: const TextStyle(
            color: Color.fromARGB(255, 200, 180, 100),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),

        // Усталость
        if (fatigue > 0) ...[
          Icon(
            Icons.bedtime,
            color: fatigue > 80
                ? Colors.red
                : (fatigue > 60 ? Colors.orange : Colors.grey),
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
          const SizedBox(width: 12),
        ],

        // Глава и шаг
        Text(
          'Глава $chapter · Шаг ${historyLength + 1}',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBars() {
    return Row(
      children: [
        Expanded(
          child: AnimatedStatBar(
            icon: '🍞',
            value: hunger,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '💧',
            value: thirst,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '❤️',
            value: health,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '🧠',
            value: sanity,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedStatBar(
            icon: '⚡',
            value: stamina,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}