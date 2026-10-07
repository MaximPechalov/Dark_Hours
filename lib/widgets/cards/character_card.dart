import 'package:flutter/material.dart';
import 'package:dark_hours/models/character/character.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final bool isSelected;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 40, 40, 40)
              : const Color.fromARGB(255, 20, 20, 20),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 200, 180, 100)
                : Colors.transparent,
            width: 2.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color.fromARGB(255, 200, 180, 100)
                        .withValues(alpha: 0.3),
                    blurRadius: 15.0,
                    spreadRadius: 2.0,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Аватар (первая буква имени)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  character.name[0],
                  style: const TextStyle(
                    color: Color.fromARGB(255, 200, 180, 100),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Информация о персонаже
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${character.age} · ${character.profession}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    character.startingLine,
                    style: TextStyle(
                      color: const Color.fromARGB(255, 200, 180, 100)
                          .withValues(alpha: 0.8),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            // Индикатор выбора
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 200, 180, 100)
                      : Colors.grey[600]!,
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        color: Color.fromARGB(255, 200, 180, 100),
                        size: 16,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}