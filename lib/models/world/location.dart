import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dark_hours/models/world/search_event.dart';
import 'package:dark_hours/models/world/map_position.dart';
import 'package:dark_hours/models/world/connection.dart';

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
  final int maxSearches;
  final List<String> lootPool;
  final List<String> enemies;

  /// Соединения с другими локациями (с временем в пути).
  final List<Connection> connections;

  final String icon;
  final bool repeatable;
  final bool isStart;
  final bool isFinal;
  final bool hidden;
  final String? unlockedBy;
  final String? risk;

  /// Позиция локации на карте.
  final MapPosition mapPosition;

  /// Название зоны.
  final String? mapZone;

  /// Название локации, как её видит разведчик (может быть неточным).
  ///
  /// Если `null` — используется `name`.
  final String? scoutedName;

  /// Описание локации, как её видит разведчик (неполное, с догадками).
  ///
  /// Если `null` — используется `description`.
  final String? scoutedDescription;

  // Сюжетные триггеры
  final String? storyNode;
  final StoryCondition? storyCondition;

  // Уникальные события поиска
  final List<SearchEvent> searchEvents;

  const Location({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.region,
    required this.dangerLevel,
    required this.searchTime,
    required this.maxSearches,
    required this.lootPool,
    required this.enemies,
    required this.connections,
    required this.icon,
    required this.repeatable,
    this.isStart = false,
    this.isFinal = false,
    this.hidden = false,
    this.unlockedBy,
    this.risk,
    this.mapPosition = const MapPosition(x: 0.5, y: 0.5),
    this.mapZone,
    this.scoutedName,
    this.scoutedDescription,
    this.storyNode,
    this.storyCondition,
    this.searchEvents = const [],
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    MapPosition position = const MapPosition(x: 0.5, y: 0.5);
    if (json['mapPosition'] != null) {
      position = MapPosition.fromJson(
        Map<String, dynamic>.from(json['mapPosition']),
      );
    }

    // Парсим connections — поддерживаем оба формата (строки и объекты).
    final rawConnections = json['connections'] as List? ?? [];
    final parsedConnections = rawConnections.map((c) {
      if (c is String) {
        return Connection(targetId: c, minutes: 20);
      } else if (c is Map) {
        return Connection.fromJson(Map<String, dynamic>.from(c));
      }
      return null;
    }).whereType<Connection>().toList();

    return Location(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      region: json['region'],
      dangerLevel: json['danger_level'] ?? 0,
      searchTime: json['search_time'] ?? 30,
      maxSearches: json['max_searches'] ?? 0,
      lootPool: List<String>.from(json['loot_pool'] ?? []),
      enemies: List<String>.from(json['enemies'] ?? []),
      connections: parsedConnections,
      icon: json['icon'],
      repeatable: json['repeatable'] ?? true,
      isStart: json['is_start'] ?? false,
      isFinal: json['is_final'] ?? false,
      hidden: json['hidden'] ?? false,
      unlockedBy: json['unlocked_by'],
      risk: json['risk'],
      mapPosition: position,
      mapZone: json['map_zone'],
      scoutedName: json['scouted_name'],
      scoutedDescription: json['scouted_description'],
      storyNode: json['story_node'],
      storyCondition: json['story_condition'] != null
          ? StoryCondition.fromJson(
              Map<String, dynamic>.from(json['story_condition']),
            )
          : null,
      searchEvents: (json['search_events'] as List? ?? [])
          .map((e) => SearchEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ХЕЛПЕРЫ
  // ═══════════════════════════════════════════════════════════

  /// Список ID соседей (для быстрых проверок).
  List<String> get connectionIds =>
      connections.map((c) => c.targetId).toList();

  /// Сколько минут идти до указанной локации.
  ///
  /// Возвращает `null`, если локация не соседняя.
  int? connectionMinutesTo(String targetId) {
    for (final c in connections) {
      if (c.targetId == targetId) return c.minutes;
    }
    return null;
  }

  /// Является ли локация соседней.
  bool isConnectedTo(String targetId) {
    return connections.any((c) => c.targetId == targetId);
  }

  /// Название для разведки (fallback на `name`).
  String get displayScoutedName => scoutedName ?? name;

  /// Описание для разведки (fallback на `description`).
  String get displayScoutedDescription =>
      scoutedDescription ?? description;

  // ═══════════════════════════════════════════════════════════
  // ГЕТТЕРЫ
  // ═══════════════════════════════════════════════════════════

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

  /// Проверка: сработает ли сюжетный триггер в этой локации.
  bool canTriggerStory({
    required int currentChapter,
    required String currentCharacter,
    required Set<String> triggeredNodes,
  }) {
    if (storyNode == null || storyCondition == null) return false;

    final cond = storyCondition!;

    if (cond.chapter != null && currentChapter < cond.chapter!) {
      return false;
    }

    if (cond.character != null && cond.character != currentCharacter) {
      return false;
    }

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