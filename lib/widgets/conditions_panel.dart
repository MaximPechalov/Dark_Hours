import 'package:flutter/material.dart';
import '../models/active_condition.dart';

class ConditionsPanel extends StatelessWidget {
  final List<ActiveCondition> conditions;

  const ConditionsPanel({super.key, required this.conditions});

  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 25, 15, 15),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(
                'СОСТОЯНИЯ (${conditions.length})',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: conditions.map((ac) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ac.condition.severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ac.condition.severityColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ac.condition.icon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ac.condition.name,
                      style: TextStyle(
                        color: ac.condition.severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${ac.daysRemaining}д)',
                      style: TextStyle(
                        color: ac.condition.severityColor.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}