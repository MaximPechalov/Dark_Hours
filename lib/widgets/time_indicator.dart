import 'package:flutter/material.dart';
import '../models/game_time.dart';

class TimeIndicator extends StatelessWidget {
  final GameTime time;

  const TimeIndicator({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    final phase = time.phase;
    final daysLeft = time.daysUntilWinter;

    return Row(
      children: [
        // Иконка фазы
        Text(
          phase.icon,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),

        // Время
        Text(
          time.shortTime,
          style: TextStyle(
            color: phase.color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 6),

        // День
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 30, 30),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: daysLeft < 10 ? Colors.red : Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Text(
            'Д$daysLeft',
            style: TextStyle(
              color: daysLeft < 10 ? Colors.red : Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}