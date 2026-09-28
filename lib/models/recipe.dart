import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RecipeIngredient {
  final String id;
  final int count;

  const RecipeIngredient({
    required this.id,
    required this.count,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'],
      count: json['count'],
    );
  }
}

class Recipe {
  final String id;
  final String name;
  final String resultId;
  final String resultIcon;
  final String resultName;
  final String description;
  final List<RecipeIngredient> ingredients;
  final int timeMinutes;
  final int requiredIntelligence;
  final int requiredStrength;
  final String category; // weapon, tool, armor, medicine, ammo, other
  final String rarity;

  const Recipe({
    required this.id,
    required this.name,
    required this.resultId,
    required this.resultIcon,
    required this.resultName,
    required this.description,
    required this.ingredients,
    required this.timeMinutes,
    required this.requiredIntelligence,
    required this.requiredStrength,
    required this.category,
    required this.rarity,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      resultId: json['result_id'],
      resultIcon: json['result_icon'],
      resultName: json['result_name'],
      description: json['description'],
      ingredients: (json['ingredients'] as List)
          .map((i) => RecipeIngredient.fromJson(i))
          .toList(),
      timeMinutes: json['time_minutes'],
      requiredIntelligence: json['required_intelligence'],
      requiredStrength: json['required_strength'],
      category: json['category'],
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
      case 'weapon':
        return 'Оружие';
      case 'tool':
        return 'Инструмент';
      case 'armor':
        return 'Броня';
      case 'medicine':
        return 'Медицина';
      case 'ammo':
        return 'Патроны';
      case 'other':
        return 'Прочее';
      default:
        return category;
    }
  }

  static Future<List<Recipe>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/recipes.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> recipesJson = jsonMap['recipes'];
      return recipesJson.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}