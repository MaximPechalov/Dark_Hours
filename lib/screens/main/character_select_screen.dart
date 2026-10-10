// lib/screens/main/character_select_screen.dart

import 'package:flutter/material.dart';
import 'package:dark_hours/models/character/character.dart';
import 'package:dark_hours/models/character/character_state.dart';
import 'package:dark_hours/widgets/cards/character_card.dart';
import 'package:dark_hours/widgets/cards/character_portrait.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/story/chapter_runner.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/constants/game_constants.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  String? _selectedCharacterId;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    AudioService.playMusic('audio/music/menu_theme.ogg');
  }

  // ═══════════════════════════════════════════════════════════
  // ХЕЛПЕРЫ: текстовые эффекты характеристик
  // ═══════════════════════════════════════════════════════════

  Color _statColor(String label) {
    switch (label) {
      case 'СИЛА':
        return Colors.red[500]!;
      case 'ИНТ':
        return Colors.blue[500]!;
      case 'ХИТР':
        return Colors.purple[500]!;
      case 'ВЫН':
        return Colors.green[500]!;
      default:
        return Colors.grey[500]!;
    }
  }

  String _statEffect(String label, int value) {
    switch (label) {
      case 'СИЛА':
        final fleeBonus = ((value - GameConstants.baseStat) * 5).clamp(-15, 25);
        return 'урон, побег ${fleeBonus >= 0 ? '+' : ''}$fleeBonus%';

      case 'ИНТ':
        return 'крафт, взлом';

      case 'ХИТР':
        return _cunningEffect(value);

      case 'ВЫН':
        return _enduranceEffect(value);

      default:
        return '';
    }
  }

  String _cunningEffect(int cunning) {
    final dodge = (GameConstants.cunningDodgeBonus(cunning) * 100).round();
    final scout = GameConstants.cunningScoutBonus(cunning);
    final flee = (GameConstants.cunningFleeBonus(cunning) * 100).round();
    final craftSave = GameConstants.cunningCraftTimeSave(cunning);

    final parts = <String>[];
    if (dodge != 0) parts.add('уклон ${dodge >= 0 ? '+' : ''}$dodge%');
    if (scout > 0) parts.add('разведка +$scout');
    if (flee > 0) parts.add('побег +$flee%');
    if (craftSave > 0) parts.add('крафт −$craftSave мин');

    if (parts.isEmpty) return 'без бонусов';
    return parts.join(', ');
  }

  String _enduranceEffect(int endurance) {
    final moveMult = GameConstants.enduranceMoveMultiplier(endurance);
    final movePercent = ((1.0 - moveMult) * 100).round();
    final restBonus = GameConstants.enduranceRestBonus(endurance);
    final flee = (GameConstants.enduranceFleeBonus(endurance) * 100).round();

    final parts = <String>[];
    if (movePercent != 0) {
      parts.add('ход ${movePercent > 0 ? '−' : '+'}${movePercent.abs()}%');
    }
    if (restBonus != 0) {
      parts.add('отдых ${restBonus > 0 ? '+' : ''}$restBonus');
    }
    if (flee > 0) parts.add('побег +$flee%');

    if (parts.isEmpty) return 'без бонусов';
    return parts.join(', ');
  }

  // ═══════════════════════════════════════════════════════════
  // МИНИ-БАР ХАРАКТЕРИСТИКИ
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatBar(String label, int value) {
    final barColor = _statColor(label);
    final effect = _statEffect(label, value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: barColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),

        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: FractionallySizedBox(
            widthFactor: value / 10.0,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        Text(
          effect,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 8,
            fontStyle: FontStyle.italic,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // СТАРТ ИГРЫ
  // ═══════════════════════════════════════════════════════════

  Future<void> _startGame(Character character) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    AudioService.playClick();

    // Обновляем статистику
    final stats = await AchievementManager.loadStats();
    stats.playedCharacters.add(character.id);
    stats.totalGamesPlayed += 1;
    await AchievementManager.saveStats(stats);

    if (!mounted) return;

    // Запускаем главу через ChapterRunner
    final runner = ChapterRunner(
      characterId: character.id,
      characterName: character.name,
    );

    final loaded = await runner.load();
    if (!loaded || !mounted) {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Не удалось загрузить главу'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await runner.start(context);

    if (mounted) {
      setState(() => _isStarting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ДЕТАЛИ ПЕРСОНАЖА
  // ═══════════════════════════════════════════════════════════

  Widget _buildCharacterDetail(Character character) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color.fromARGB(255, 200, 180, 100).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CharacterPortrait(
                characterId: character.id,
                state: CharacterState.normal,
                size: 100,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 200, 180, 100)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        character.age,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 200, 180, 100),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            character.profession,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const Divider(color: Color.fromARGB(255, 60, 60, 60), height: 20),
          Text(
            '📌 Старт: ${character.startLocation}',
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '🎒 ${character.inventory}',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 40, 30, 20),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              '⚡ ${character.habitBonus}',
              style: const TextStyle(
                color: Color.fromARGB(255, 200, 180, 100),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${character.description}"',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStatBar('СИЛА', character.strength)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBar('ИНТ', character.intelligence)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBar('ХИТР', character.cunning)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatBar('ВЫН', character.endurance)),
            ],
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isStarting ? null : () => _startGame(character),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 200, 180, 100),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isStarting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.black,
                        ),
                      ),
                    )
                  : const Text(
                      'ВЫБРАТЬ И ИГРАТЬ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.playClick();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'ВЫБЕРИ ПЕРСОНАЖА',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: Character.all.map((character) {
                return CharacterCard(
                  character: character,
                  isSelected: _selectedCharacterId == character.id,
                  onTap: () {
                    AudioService.playTap();
                    setState(() {
                      if (_selectedCharacterId == character.id) {
                        _selectedCharacterId = null;
                      } else {
                        _selectedCharacterId = character.id;
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          if (_selectedCharacterId != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCharacterDetail(
                Character.getById(_selectedCharacterId!)!,
              ),
            ),
        ],
      ),
    );
  }
}