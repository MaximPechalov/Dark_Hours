import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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