import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameResource {
  final String id;
  final String name;
  final String description;
  final String category; // material, special, ammo
  final double weight;
  final int stackMax;
  final String icon;
  final String rarity;

  const GameResource({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.weight,
    required this.stackMax,
    required this.icon,
    required this.rarity,
  });

  factory GameResource.fromJson(Map<String, dynamic> json) {
    return GameResource(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      weight: json['weight'].toDouble(),
      stackMax: json['stack_max'],
      icon: json['icon'],
      rarity: json['rarity'],
    );
  }

  Color get rarityColor {
    switch (rarity) {
      case 'common':
        return const Color.fromARGB(255, 150, 150, 150);
      case 'uncommon':
        return const Color.fromARGB(255, 100, 200, 100);
      case 'rare':
        return const Color.fromARGB(255, 100, 150, 255);
      case 'epic':
        return const Color.fromARGB(255, 200, 100, 255);
      case 'legendary':
        return const Color.fromARGB(255, 255, 200, 50);
      default:
        return Colors.white;
    }
  }

  String get rarityName {
    switch (rarity) {
      case 'common':
        return 'Обычный';
      case 'uncommon':
        return 'Необычный';
      case 'rare':
        return 'Редкий';
      case 'epic':
        return 'Эпический';
      case 'legendary':
        return 'Легендарный';
      default:
        return rarity;
    }
  }

  String get categoryName {
    switch (category) {
      case 'material':
        return 'Материал';
      case 'special':
        return 'Особый';
      case 'ammo':
        return 'Боеприпасы';
      default:
        return category;
    }
  }

  static Future<List<GameResource>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/resources.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> resourcesJson = jsonMap['resources'];
      return resourcesJson
          .map((json) => GameResource.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }
}