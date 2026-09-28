import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final bool secret;
  final int points;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.secret,
    required this.points,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      secret: json['secret'] ?? false,
      points: json['points'] ?? 10,
    );
  }

  Color get categoryColor {
    switch (category) {
      case 'combat':
        return Colors.red;
      case 'survival':
        return Colors.orange;
      case 'story':
        return const Color.fromARGB(255, 200, 180, 100);
      case 'crafting':
        return Colors.blue;
      case 'loot':
        return Colors.green;
      case 'medicine':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String get categoryName {
    switch (category) {
      case 'combat':
        return 'Бой';
      case 'survival':
        return 'Выживание';
      case 'story':
        return 'Сюжет';
      case 'crafting':
        return 'Крафт';
      case 'loot':
        return 'Добыча';
      case 'medicine':
        return 'Медицина';
      default:
        return category;
    }
  }

  static Future<List<Achievement>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/achievements.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> list = jsonMap['achievements'];
      return list.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}