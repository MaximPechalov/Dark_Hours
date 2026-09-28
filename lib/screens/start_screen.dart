import 'package:flutter/material.dart';
import 'character_select_screen.dart';
import 'equipment_test_screen.dart';
import 'map_screen.dart';
import 'story_screen.dart';
import '../services/save_manager.dart';
import '../models/save_data.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  SaveData? _save;
  bool _checkingSave = true;

  @override
  void initState() {
    super.initState();
    _checkForSave();
  }

  Future<void> _checkForSave() async {
    final save = await SaveManager.load();
    if (mounted) {
      setState(() {
        _save = save;
        _checkingSave = false;
      });
    }
  }

  void _continueGame() {
    if (_save == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          // Если игрок был на карте — открываем карту
          if (_save!.onMap) {
            return MapScreen(
              characterId: _save!.characterId,
              characterName: _save!.characterName,
              resumeFrom: _save,
            );
          }
          // Иначе — продолжаем сюжет
          return StoryScreen(
            characterId: _save!.characterId,
            characterName: _save!.characterName,
            resumeFrom: _save,
          );
        },
      ),
    ).then((_) => _checkForSave());
  }

  Future<void> _deleteSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
        title: const Text(
          'Удалить сохранение?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Прогресс будет потерян навсегда.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SaveManager.delete();
      if (mounted) {
        setState(() => _save = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    64,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Иконка
                  Icon(
                    Icons.battery_unknown_outlined,
                    size: 80,
                    color: const Color.fromARGB(255, 200, 180, 100),
                  ),
                  const SizedBox(height: 16),

                  // Название
                  const Text(
                    'ТЕМНЫЕ ЧАСЫ',
                    style: TextStyle(
                      color: Color.fromARGB(255, 200, 180, 100),
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Подзаголовок
                  Text(
                    'ВЫЖИВИ В БЛЕКАУТ',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Тег
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 200, 180, 100)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      '◉ HARDCORE SURVIVAL ◉',
                      style: TextStyle(
                        color: Color.fromARGB(255, 200, 180, 100),
                        fontSize: 12,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ===== КНОПКА "ПРОДОЛЖИТЬ" (если есть сохранение) =====
                  if (!_checkingSave && _save != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continueGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 100, 180, 100),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '▶  ПРОДОЛЖИТЬ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_save!.characterName} · ${SaveManager.formatSaveDate(_save!.savedAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _deleteSave,
                      child: Text(
                        'Удалить сохранение',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ===== КНОПКА "НАЧАТЬ ИГРУ" =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CharacterSelectScreen(),
                          ),
                        ).then((_) => _checkForSave());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 200, 180, 100),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        _save != null ? '▶  НОВАЯ ИГРА' : '▶  НАЧАТЬ ИГРУ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== КНОПКА "КАРТА МИРА" =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapScreen(
                              characterId: 'boris',
                              characterName: 'Борис',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text(
                        '🗺️  КАРТА МИРА (ТЕСТ)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 100, 200, 100),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 100, 200, 100),
                          width: 1.0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== КНОПКА "ТЕСТ СНАРЯЖЕНИЯ" =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EquipmentTestScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 200, 180, 100),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 200, 180, 100),
                          width: 1.0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        '🎒  ТЕСТ СНАРЯЖЕНИЯ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Версия
                  Text(
                    'v 0.3.0',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}