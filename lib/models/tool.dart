import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Tool {
  final String id;
  final String name;
  final String description;
  final String type;
  final double weight;
  final int durability;
  final String specialAbility;
  final String icon;
  final String rarity;
  final int uses;
  final bool? fuelRequired;

  const Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.weight,
    required this.durability,
    required this.specialAbility,
    required this.icon,
    required this.rarity,
    required this.uses,
    this.fuelRequired,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      weight: json['weight'].toDouble(),
      durability: json['durability'],
      specialAbility: json['special_ability'],
      icon: json['icon'],
      rarity: json['rarity'],
      uses: json['uses'],
      fuelRequired: json['fuel_required'],
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

  String get typeName {
    switch (type) {
      case 'survival':
        return 'Выживание';
      case 'repair':
        return 'Ремонт';
      case 'medical':
        return 'Медицина';
      case 'special':
        return 'Специальное';
      default:
        return type;
    }
  }

  static Future<List<Tool>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/tools.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> toolsJson = jsonMap['tools'];
      return toolsJson.map((json) => Tool.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}