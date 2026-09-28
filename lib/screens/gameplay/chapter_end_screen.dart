import 'package:flutter/material.dart';
import 'package:dark_hours/models/progress/chapter_summary.dart';
import 'package:dark_hours/screens/gameplay/credits_screen.dart';

class ChapterEndScreen extends StatelessWidget {
  final ChapterSummary summary;

  const ChapterEndScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 5, 5, 5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Метка
              Text(
                '◉ ГЛАВА ${summary.chapter} ЗАВЕРШЕНА ◉',
                style: const TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 12,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 20),

              // Заголовок концовки
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 200, 180, 100),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary.finalTitle,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 200, 180, 100),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Описание
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  summary.finalDescription,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 1),

              // Персонаж
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color.fromARGB(255, 200, 180, 100),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    summary.characterName,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 200, 180, 100),
                      fontSize: 14,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Кнопка «Смотреть титры»
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreditsScreen(summary: summary),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text(
                    'СМОТРЕТЬ ТИТРЫ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 200, 180, 100),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Кнопка «Пропустить»
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'ПРОПУСТИТЬ',
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
      ),
    );
  }
}