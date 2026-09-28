import 'dart:convert';
import 'package:flutter/services.dart';

class StoryChoice {
  final String text;
  final Map<String, dynamic>? effects;
  final String next;

  const StoryChoice({
    required this.text,
    required this.next,
    this.effects,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'],
      effects: json['effects'],
      next: json['next'],
    );
  }
}

class StoryNode {
  final String id;
  final String title;
  final String text;
  final List<StoryChoice> choices;

  const StoryNode({
    required this.id,
    required this.title,
    required this.text,
    required this.choices,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'],
      title: json['title'],
      text: json['text'],
      choices: (json['choices'] as List)
          .map((c) => StoryChoice.fromJson(c))
          .toList(),
    );
  }
}

class Story {
  final String character;
  final String startNode;
  final Map<String, StoryNode> nodes;

  const Story({
    required this.character,
    required this.startNode,
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
      nodes: nodesMap,
    );
  }

  StoryNode? getNode(String id) => nodes[id];

  /// Загрузить главу по имени персонажа
  /// Например: Story.loadFor('boris')
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