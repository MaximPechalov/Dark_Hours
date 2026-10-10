// lib/screens/main/start_screen.dart

import 'package:flutter/material.dart';
import '../main/character_select_screen.dart';
import '../extra/equipment_test_screen.dart';
import '../gameplay/map/map_screen.dart';
import '../gameplay/story_screen.dart';
import '../extra/achievements_screen.dart';
import '../main/settings_screen.dart';
import 'package:dark_hours/services/save/save_manager.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/models/progress/player_stats.dart';
import 'package:dark_hours/widgets/effects/shimmer_button.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  SaveData? _save;
  PlayerStats? _stats;
  bool _checkingSave = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // На случай, если StartScreen открыт напрямую — включим menu_theme.
    AudioService.forcePlayMusic('audio/music/menu_theme.ogg');
  }

  Future<void> _loadData() async {
    final save = await SaveManager.load();
    final stats = await AchievementManager.loadStats();
    if (mounted) {
      setState(() {
        _save = save;
        _stats = stats;
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
          if (_save!.onMap) {
            return MapScreen(
              characterId: _save!.characterId,
              characterName: _save!.characterName,
              resumeFrom: _save,
            );
          }
          return StoryScreen(
            characterId: _save!.characterId,
            characterName: _save!.characterName,
            resumeFrom: _save,
          );
        },
      ),
    ).then((_) {
      _loadData();
      // При возврате в меню — переключаем музыку
      AudioService.forcePlayMusic('audio/music/menu_theme.ogg');
    });
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
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context, false);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context, true);
            },
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

  Future<void> _openAchievements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AchievementsScreen(),
      ),
    );
    _loadData();
    AudioService.forcePlayMusic('audio/music/menu_theme.ogg');
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
    AudioService.forcePlayMusic('audio/music/menu_theme.ogg');
  }

  Future<void> _openMapTest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          characterId: 'boris',
          characterName: 'Борис',
        ),
      ),
    );
    AudioService.forcePlayMusic('audio/music/menu_theme.ogg');
  }

  Future<void> _openEquipmentTest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EquipmentTestScreen(),
      ),
    );
    AudioService.forcePlayMusic('audio/music/menu_theme.ogg');
  }

  Future<void> _openCharacterSelect() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CharacterSelectScreen(),
      ),
    );
    _loadData();
    AudioService.forcePlayMusic('audio/music/menu_theme.ogg');
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
                            .withValues(alpha: 0.3),
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
                  const SizedBox(height: 20),

                  // Счётчик достижений
                  if (_stats != null && _stats!.unlockedAchievements.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        AudioService.playTap();
                        _openAchievements();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 200, 180, 100)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 180, 100)
                                .withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '${_stats!.unlockedAchievements.length} достижений',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 200, 180, 100),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),

                  // ===== КНОПКА "ПРОДОЛЖИТЬ" =====
                  if (!_checkingSave && _save != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          AudioService.playClick();
                          _continueGame();
                        },
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
                              'ПРОДОЛЖИТЬ',
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
                      onPressed: () {
                        AudioService.playClick();
                        _deleteSave();
                      },
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
                    child: ShimmerButton(
                      text: _save != null ? 'НОВАЯ ИГРА' : 'НАЧАТЬ ИГРУ',
                      icon: Icons.play_arrow,
                      onPressed: _openCharacterSelect,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== КНОПКА "КАРТА МИРА" =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AudioService.playClick();
                        _openMapTest();
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text(
                        'КАРТА МИРА (ТЕСТ)',
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

                  // ===== КНОПКА "ДОСТИЖЕНИЯ" =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AudioService.playClick();
                        _openAchievements();
                      },
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text(
                        'ДОСТИЖЕНИЯ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 200, 180, 100),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 200, 180, 100),
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

                  // ===== КНОПКА "НАСТРОЙКИ" =====
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AudioService.playClick();
                        _openSettings();
                      },
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text(
                        'НАСТРОЙКИ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color.fromARGB(255, 150, 180, 220),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 150, 180, 220),
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AudioService.playClick();
                        _openEquipmentTest();
                      },
                      icon: const Icon(Icons.backpack_outlined, size: 18),
                      label: const Text(
                        'ТЕСТ СНАРЯЖЕНИЯ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[500],
                        side: BorderSide(
                          color: Colors.grey[700]!,
                          width: 1.0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Версия
                  Text(
                    'v 0.6.0',
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