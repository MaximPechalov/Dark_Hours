import 'package:flutter/material.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

class DeathScreen extends StatefulWidget {
  final String reason;
  final String characterName;
  final int dayReached;

  const DeathScreen({
    super.key,
    required this.reason,
    required this.characterName,
    required this.dayReached,
  });

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> {
  @override
  void initState() {
    super.initState();
    _playDeathSound();
  }

  Future<void> _playDeathSound() async {
    await AudioService.stopAll();
    await AudioService.playError();
  }

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
              const Spacer(flex: 2),

              // Череп
              const Text(
                '💀',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),

              // Заголовок
              const Text(
                'КОНЕЦ',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8.0,
                ),
              ),
              const SizedBox(height: 12),

              // Имя
              Text(
                widget.characterName,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),

              // День
              Text(
                'Продержался: ${widget.dayReached} ${_daysWord(widget.dayReached)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),

              const Spacer(flex: 1),

              // Причина
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 20, 10, 10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Причина смерти',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reason,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Кнопка
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AudioService.playClick();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'НАЧАТЬ ЗАНОВО',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  String _daysWord(int days) {
    final mod10 = days % 10;
    final mod100 = days % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'дня';
    }
    return 'дней';
  }
}