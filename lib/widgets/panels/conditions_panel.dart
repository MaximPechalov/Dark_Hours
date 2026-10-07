import 'package:flutter/material.dart';
import 'package:dark_hours/models/conditions/active_condition.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

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
            color: Colors.red.withValues(alpha: 0.3),
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
              const Spacer(),
              Text(
                'нажми для деталей',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: conditions.map((ac) {
              return GestureDetector(
                onTap: () {
                  AudioService.playTap();
                  _showConditionDetails(context, ac);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ac.condition.severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ac.condition.severityColor.withValues(alpha: 0.5),
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
                          color: ac.condition.severityColor.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showConditionDetails(BuildContext context, ActiveCondition ac) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => ConditionDetailsSheet(active: ac),
    );
  }
}

class ConditionDetailsSheet extends StatelessWidget {
  final ActiveCondition active;

  const ConditionDetailsSheet({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final condition = active.condition;
    final color = condition.severityColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 15, 15, 15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    condition.icon,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        condition.name.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          condition.severityName,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Описание
            Text(
              condition.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Эффекты за ход
            if (condition.effectsPerTurn.isNotEmpty) ...[
              _sectionTitle('ЭФФЕКТЫ ЗА ХОД'),
              const SizedBox(height: 8),
              ...condition.effectsPerTurn.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        _statIcon(e.key),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statName(e.key),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${e.value > 0 ? '+' : ''}${e.value}',
                        style: TextStyle(
                          color: e.value > 0 ? Colors.green : Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Лечение
            if (condition.cureItems.isNotEmpty) ...[
              _sectionTitle('СРЕДСТВА ЛЕЧЕНИЯ'),
              const SizedBox(height: 8),
              ...condition.cureItems.map((itemId) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _itemName(itemId),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(condition.cureChance * 100).round()}%',
                        style: TextStyle(
                          color: Colors.green[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Прогресс
            _sectionTitle('ПРОГРЕСС'),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: active.progress,
                      backgroundColor: Colors.grey[900],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'осталось ${active.daysRemaining} дн.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Источники
            if (condition.source.isNotEmpty) ...[
              _sectionTitle('ИСТОЧНИКИ'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: condition.source.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _sourceName(s),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Кнопка закрыть
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  AudioService.playClick();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ЗАКРЫТЬ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color.fromARGB(255, 200, 180, 100),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }

  String _statIcon(String key) {
    switch (key) {
      case 'health':
        return '❤️';
      case 'hunger':
        return '🍞';
      case 'thirst':
        return '💧';
      case 'stamina':
        return '⚡';
      case 'sanity':
        return '🧠';
      case 'strength':
        return '💪';
      case 'intelligence':
        return '📚';
      default:
        return '•';
    }
  }

  String _statName(String key) {
    switch (key) {
      case 'health':
        return 'Здоровье';
      case 'hunger':
        return 'Голод';
      case 'thirst':
        return 'Жажда';
      case 'stamina':
        return 'Выносливость';
      case 'sanity':
        return 'Психика';
      case 'strength':
        return 'Сила';
      case 'intelligence':
        return 'Интеллект';
      default:
        return key;
    }
  }

  String _itemName(String id) {
    const names = {
      'antibiotic_pill': 'Антибиотик',
      'herb_medkit': 'Травяной сбор',
      'painkiller_pill': 'Обезболивающее',
      'vodka': 'Водка',
      'bandage': 'Бинт',
      'first_aid_kit': 'Аптечка',
      'splint': 'Шина',
      'anti_rad': 'Антирад',
    };
    return names[id] ?? id;
  }

  String _sourceName(String id) {
    const names = {
      'combat_wound': 'Боевая рана',
      'dirty_water': 'Грязная вода',
      'hospital_basement': 'Больничный подвал',
      'radioactive_zone': 'Радиоактивная зона',
      'nuclear_site': 'Ядерный объект',
      'raw_meat': 'Сырое мясо',
      'dog_food': 'Собачий корм',
      'cold_weather': 'Холод',
      'wet_clothes': 'Мокрая одежда',
      'rain': 'Дождь',
      'cold_ignored': 'Переохлаждение',
      'cold_weather_extended': 'Долгий холод',
      'low_sanity': 'Низкая психика',
      'stress': 'Стресс',
      'night_attack': 'Ночное нападение',
      'fall': 'Падение',
      'combat_critical': 'Критический удар',
      'explosion': 'Взрыв',
      'stab': 'Ножевое ранение',
      'gunshot': 'Огнестрельное ранение',
    };
    return names[id] ?? id;
  }
}