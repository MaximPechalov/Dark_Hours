import 'package:flutter/material.dart';
import '../models/character.dart';
import '../widgets/character_card.dart';
import 'story_screen.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  String? _selectedCharacterId;

  Widget _buildStatBar(String label, int value) {
    Color barColor;
    switch (label) {
      case 'СИЛА':
        barColor = Colors.red[500]!;
        break;
      case 'ИНТ':
        barColor = Colors.blue[500]!;
        break;
      case 'ХИТР':
        barColor = Colors.purple[500]!;
        break;
      case 'ВЫН':
        barColor = Colors.green[500]!;
        break;
      default:
        barColor = Colors.grey[500]!;
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
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
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterDetail(Character character) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color.fromARGB(255, 200, 180, 100).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                character.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 200, 180, 100)
                      .withOpacity(0.15),
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
          const SizedBox(height: 6),
          Text(
            character.profession,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const Divider(
            color: Color.fromARGB(255, 60, 60, 60),
            height: 20,
          ),
          Text(
            '📌 Старт: ${character.startLocation}',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '🎒 ${character.inventory}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryScreen(
                      characterId: character.id,
                      characterName: character.name,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 200, 180, 100),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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