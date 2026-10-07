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
  final List<Connection> connections;
  final String icon;
  final bool repeatable;
  final bool isStart;
  final bool isFinal;
  final bool hidden;
  final String? unlockedBy;
  final String? risk;
  final MapPosition mapPosition;
  final String? mapZone;
  final String? scoutedName;
  final String? scoutedDescription;
  final String? storyNode;
  final StoryCondition? storyCondition;
  final List<SearchEvent> searchEvents;

  /// Глава, с которой эта локация становится доступной.
  ///
  /// По умолчанию 1 — доступна с начала игры.
  /// Локации с `availableFromChapter > текущая глава` — **скрыты**.
  final int availableFromChapter;

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
    this.availableFromChapter = 1,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    MapPosition position = const MapPosition(x: 0.5, y: 0.5);
    if (json['mapPosition'] != null) {
      position = MapPosition.fromJson(
        Map<String, dynamic>.from(json['mapPosition']),
      );
    }

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
      availableFromChapter: json['is_available_from_chapter'] ?? 1,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ХЕЛПЕРЫ
  // ═══════════════════════════════════════════════════════════

  List<String> get connectionIds =>
      connections.map((c) => c.targetId).toList();

  int? connectionMinutesTo(String targetId) {
    for (final c in connections) {
      if (c.targetId == targetId) return c.minutes;
    }
    return null;
  }

  bool isConnectedTo(String targetId) {
    return connections.any((c) => c.targetId == targetId);
  }

  /// Базовое разведанное имя (видно сразу после старта).
  String get displayScoutedName => scoutedName ?? name;

  /// Базовое разведанное описание (видно сразу после старта).
  String get displayScoutedDescription => scoutedDescription ?? description;

  /// Полное описание локации (после посещения).
  String get displayFullDescription => description;

  /// Доступна ли эта локация в текущей главе.
  bool isAvailableAt(int chapter) {
    return availableFromChapter <= chapter;
  }

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

  // ═══════════════════════════════════════════════════════════
  // ЗАГРУЗКА
  // ═══════════════════════════════════════════════════════════

  static Future<List<Location>> loadAll() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

      final locationFiles = manifest
          .listAssets()
          .where((path) =>
              path.startsWith('assets/data/locations/') &&
              path.endsWith('.json'))
          .toList()
        ..sort();

      if (locationFiles.isEmpty) {
        debugPrint('⚠️ Location.loadAll: нет файлов локаций');
        return [];
      }

      debugPrint('📍 Location.loadAll: найдено ${locationFiles.length} файлов');

      final allLocations = <Location>[];
      final seenIds = <String>{};

      for (final path in locationFiles) {
        try {
          final jsonString = await rootBundle.loadString(path);
          final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
          final list = jsonMap['locations'] as List? ?? [];

          int added = 0;
          int duplicates = 0;

          for (final json in list) {
            final loc = Location.fromJson(
              Map<String, dynamic>.from(json),
            );

            if (seenIds.contains(loc.id)) {
              duplicates++;
              debugPrint('  ❌ ДУБЛИКАТ: ${loc.id} в $path');
              continue;
            }

            seenIds.add(loc.id);
            allLocations.add(loc);
            added++;
          }

          final dupText = duplicates > 0 ? ' (дубликатов: $duplicates)' : '';
          debugPrint('  ✅ $path: $added локаций$dupText');
        } catch (e, stackTrace) {
          debugPrint('  ❌ Ошибка загрузки $path: $e');
          debugPrint('$stackTrace');
        }
      }

      debugPrint(
        '📍 Location.loadAll: всего загружено ${allLocations.length} локаций',
      );
      return allLocations;
    } catch (e, stackTrace) {
      debugPrint('❌ Location.loadAll: критическая ошибка: $e');
      debugPrint('$stackTrace');
      return [];
    }
  }
}