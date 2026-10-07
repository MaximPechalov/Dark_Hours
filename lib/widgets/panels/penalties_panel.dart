import 'package:flutter/material.dart';

class PenaltiesPanel extends StatelessWidget {
  final List<String> penalties;

  const PenaltiesPanel({super.key, required this.penalties});

  @override
  Widget build(BuildContext context) {
    if (penalties.isEmpty) return const SizedBox.shrink();

    // Проверяем категории
    final hasCritical = penalties.any((p) =>
        p.contains('КРИТИЧНО') ||
        p.contains('Коллапс') ||
        p.contains('Изнеможение') ||
        p.contains('Истощение'));
    final hasComfort = penalties.any((p) => p.contains('Комфорт'));

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData iconData;

    if (hasComfort) {
      bgColor = const Color.fromARGB(255, 15, 30, 15);
      borderColor = Colors.green.withValues(alpha: 0.4);
      textColor = Colors.green;
      iconData = Icons.check_circle;
    } else if (hasCritical) {
      bgColor = const Color.fromARGB(255, 40, 10, 10);
      borderColor = Colors.red.withValues(alpha: 0.6);
      textColor = Colors.red;
      iconData = Icons.warning;
    } else {
      bgColor = const Color.fromARGB(255, 30, 15, 15);
      borderColor = Colors.red.withValues(alpha: 0.3);
      textColor = Colors.red;
      iconData = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                iconData,
                color: textColor,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                hasComfort
                    ? 'БОНУСЫ'
                    : (hasCritical
                        ? 'КРИТИЧЕСКИЕ ШТРАФЫ'
                        : 'АКТИВНЫЕ ШТРАФЫ'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Штрафы
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: penalties.map((p) {
              final isCritical = p.contains('КРИТИЧНО') ||
                  p.contains('Коллапс') ||
                  p.contains('Изнеможение') ||
                  p.contains('Истощение');
              final isComfort = p.contains('Комфорт');

              Color chipColor = textColor;
              if (isComfort) chipColor = Colors.green;
              if (isCritical) chipColor = Colors.red[900]!;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: isCritical ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: chipColor.withValues(alpha: isCritical ? 0.8 : 0.4),
                    width: isCritical ? 1.5 : 1,
                  ),
                  boxShadow: isCritical
                      ? [
                          BoxShadow(
                            color: chipColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    color: chipColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}