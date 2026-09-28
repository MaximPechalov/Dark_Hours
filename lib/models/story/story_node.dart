import 'dart:convert';
import 'package:flutter/services.dart';

class StoryChoice {
  final String text;
  final Map<String, dynamic>? effects;
  final String next;
  final Map<String, dynamic>? requires; // ← новое: условия показа

  const StoryChoice({
    required this.text,
    required this.next,
    this.effects,
    this.requires,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'],
      effects: json['effects'],
      next: json['next'],
      requires: json['requires'],
    );
  }

  /// Проверить, доступен ли этот выбор игроку
  bool isAvailable({
    required Map<String, int> stats,
    required Set<String> inventoryIds,
    required Set<String> flags,
  }) {
    if (requires == null) return true;

    final req = requires!;

    // Проверка ресурсов (hunger, thirst, health, sanity, stamina, fatigue)
    if (req['stats'] != null) {
      final statsReq = req['stats'] as Map<String, dynamic>;
      for (final entry in statsReq.entries) {
        final statName = entry.key;
        final condition = entry.value as Map<String, dynamic>;

        final currentValue = stats[statName] ?? 0;

        if (condition['min'] != null && currentValue < condition['min']) {
          return false;
        }
        if (condition['max'] != null && currentValue > condition['max']) {
          return false;
        }
      }
    }

    // Проверка наличия предмета
    if (req['has_item'] != null) {
      final itemId = req['has_item'] as String;
      if (!inventoryIds.contains(itemId)) return false;
    }

    // Проверка отсутствия предмета
    if (req['not_item'] != null) {
      final itemId = req['not_item'] as String;
      if (inventoryIds.contains(itemId)) return false;
    }

    // Проверка флагов (квестовых меток)
    if (req['flag'] != null) {
      final flag = req['flag'] as String;
      if (!flags.contains(flag)) return false;
    }

    if (req['not_flag'] != null) {
      final flag = req['not_flag'] as String;
      if (flags.contains(flag)) return false;
    }

    return true;
  }

  /// Получить объяснение, почему выбор недоступен
  String? getUnavailableReason({
    required Map<String, int> stats,
    required Set<String> inventoryIds,
    required Set<String> flags,
  }) {
    if (requires == null) return null;

    final req = requires!;

    if (req['stats'] != null) {
      final statsReq = req['stats'] as Map<String, dynamic>;
      for (final entry in statsReq.entries) {
        final statName = entry.key;
        final condition = entry.value as Map<String, dynamic>;
        final currentValue = stats[statName] ?? 0;

        if (condition['min'] != null && currentValue < condition['min']) {
          return 'Требуется $statName ≥ ${condition['min']}';
        }
        if (condition['max'] != null && currentValue > condition['max']) {
          return 'Требуется $statName ≤ ${condition['max']}';
        }
      }
    }

    if (req['has_item'] != null) {
      return 'Нужен предмет';
    }
    if (req['not_item'] != null) {
      return 'Предмет мешает';
    }
    if (req['flag'] != null) {
      return 'Нужна предыстория';
    }
    if (req['not_flag'] != null) {
      return 'Предыстория мешает';
    }

    return null;
  }
}

class StoryNode {
  final String id;
  final String title;
  final String text;
  final List<StoryChoice> choices;
  final Map<String, dynamic>? onEnter; // ← новое: эффекты при входе в ноду
  final Map<String, dynamic>? flagsSet; // ← новое: какие флаги ставит нода

  const StoryNode({
    required this.id,
    required this.title,
    required this.text,
    required this.choices,
    this.onEnter,
    this.flagsSet,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'],
      title: json['title'],
      text: json['text'],
      choices: (json['choices'] as List)
          .map((c) => StoryChoice.fromJson(c))
          .toList(),
      onEnter: json['on_enter'],
      flagsSet: json['flags_set'],
    );
  }
}

class Story {
  final String character;
  final String startNode;
  final int chapter; // ← новое
  final Map<String, StoryNode> nodes;

  const Story({
    required this.character,
    required this.startNode,
    required this.chapter,
    required this.nodes,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    final Map<String, StoryNode> nodesMap = {};
    for (final nodeJson in json['nodes']) {
      final node = StoryNode.fromJson(nodeJson);
      nodesMap[node.id] = node;
    }
    return Story(
      character: json['character'],
      startNode: json['start_node'],
      chapter: json['chapter'] ?? 1,
      nodes: nodesMap,
    );
  }

  StoryNode? getNode(String id) => nodes[id];

  /// Загрузить главу по имени персонажа
  static Future<Story?> loadFor(String characterId) async {
    try {
      final String jsonString = await rootBundle
          .loadString('assets/data/story_$characterId.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return Story.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }
}