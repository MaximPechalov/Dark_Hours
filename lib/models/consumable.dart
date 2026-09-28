import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Consumable {
  final String id;
  final String name;
  final String description;
  final String category; // food, water, medicine, other
  final int hungerRestore;
  final int thirstRestore;
  final int healthRestore;
  final int sanityRestore;
  final double weight;
  final int uses;
  final int spoilDays;
  final String icon;
  final String rarity;

  const Consumable({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.hungerRestore,
    required this.thirstRestore,
    required this.healthRestore,
    required this.sanityRestore,
    required this.weight,
    required this.uses,
    required this.spoilDays,
    required this.icon,
    required this.rarity,
  });

  factory Consumable.fromJson(Map<String, dynamic> json) {
    return Consumable(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      hungerRestore: json['hunger_restore'],
      thirstRestore: json['thirst_restore'],
      healthRestore: json['health_restore'],
      sanityRestore: json['sanity_restore'],
      weight: json['weight'].toDouble(),
      uses: json['uses'],
      spoilDays: json['spoil_days'],
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
        return 'Обычное';
      case 'uncommon':
        return 'Необычное';
      case 'rare':
        return 'Редкое';
      case 'epic':
        return 'Эпическое';
      case 'legendary':
        return 'Легендарное';
      default:
        return rarity;
    }
  }

  String get categoryName {
    switch (category) {
      case 'food':
        return 'Еда';
      case 'water':
        return 'Вода';
      case 'medicine':
        return 'Медицина';
      case 'other':
        return 'Прочее';
      default:
        return category;
    }
  }

  static Future<List<Consumable>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/consumables.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> consumablesJson = jsonMap['consumables'];
      return consumablesJson
          .map((json) => Consumable.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }
}