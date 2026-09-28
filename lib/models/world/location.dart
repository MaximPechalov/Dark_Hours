import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StoryCondition {
  final int? chapter;
  final String? character;
  final bool once;

  const StoryCondition({
    this.chapter,
    this.character,
    this.once = true,
  });

  factory StoryCondition.fromJson(Map<String, dynamic> json) {
    return StoryCondition(
      chapter: json['chapter'],
      character: json['character'],
      once: json['once'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter': chapter,
      'character': character,
      'once': once,
    };
  }
}

class Location {
  final String id;
  final String name;
  final String description;
  final String type;
  final String region;
  final int dangerLevel;
  final int searchTime;
  final List<String> lootPool;
  final List<String> enemies;
  final List<String> connections;
  final String icon;
  final bool repeatable;
  final bool isStart;
  final bool isFinal;
  final String? risk;

  // Сюжетные триггеры
  final String? storyNode;
  final StoryCondition? storyCondition;

  const Location({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.region,
    required this.dangerLevel,
    required this.searchTime,
    required this.lootPool,
    required this.enemies,
    required this.connections,
    required this.icon,
    required this.repeatable,
    this.isStart = false,
    this.isFinal = false,
    this.risk,
    this.storyNode,
    this.storyCondition,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      region: json['region'],
      dangerLevel: json['danger_level'],
      searchTime: json['search_time'],
      lootPool: List<String>.from(json['loot_pool'] ?? []),
      enemies: List<String>.from(json['enemies'] ?? []),
      connections: List<String>.from(json['connections'] ?? []),
      icon: json['icon'],
      repeatable: json['repeatable'] ?? true,
      isStart: json['is_start'] ?? false,
      isFinal: json['is_final'] ?? false,
      risk: json['risk'],
      storyNode: json['story_node'],
      storyCondition: json['story_condition'] != null
          ? StoryCondition.fromJson(
              Map<String, dynamic>.from(json['story_condition']),
            )
          : null,
    );
  }

  Color get dangerColor {
    if (dangerLevel <= 2) return Colors.green;
    if (dangerLevel <= 4) return Colors.lightGreen;
    if (dangerLevel <= 6) return Colors.orange;
    if (dangerLevel <= 8) return Colors.deepOrange;
    return Colors.red;
  }

  String get dangerName {
    if (dangerLevel <= 2) return 'Безопасно';
    if (dangerLevel <= 4) return 'Слабая угроза';
    if (dangerLevel <= 6) return 'Средняя угроза';
    if (dangerLevel <= 8) return 'Опасно';
    return 'Смертельно';
  }

  /// Проверка: сработает ли сюжетный триггер в этой локации
  bool canTriggerStory({
    required int currentChapter,
    required String currentCharacter,
    required Set<String> triggeredNodes,
  }) {
    if (storyNode == null || storyCondition == null) return false;

    final cond = storyCondition!;

    // Проверка по главе
    if (cond.chapter != null && currentChapter < cond.chapter!) {
      return false;
    }

    // Проверка по персонажу
    if (cond.character != null && cond.character != currentCharacter) {
      return false;
    }

    // Проверка "только один раз"
    if (cond.once && triggeredNodes.contains(storyNode)) {
      return false;
    }

    return true;
  }

  static Future<List<Location>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/locations.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> list = jsonMap['locations'];
      return list.map((json) => Location.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}