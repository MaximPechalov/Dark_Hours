import 'package:flutter/material.dart';

class PenaltiesPanel extends StatelessWidget {
  final List<String> penalties;

  const PenaltiesPanel({super.key, required this.penalties});

  @override
  Widget build(BuildContext context) {
    if (penalties.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 15, 15),
        border: Border(
          bottom: BorderSide(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: penalties.map((p) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.red.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              p,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}