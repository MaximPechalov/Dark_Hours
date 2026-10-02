import 'dart:convert';
import 'package:flutter/services.dart';

/// Модель врага — загружается из assets/data/enemies.json
///
/// Враги бывают только двух категорий:
/// - human (люди) — мародёры, бандиты, дезертиры
/// - animal (звери) — собаки, волки, кабаны, медведи, лисы, вороны
///
/// Никаких заражённых или мутантов — это реалистичный постапокалипсис.
class Enemy {
  final String id;
  final String name;
  final String description;
  final String category; // human, animal
  final int health;
  final int damage;
  final int protection;
  final int strength;
  final String damageType; // blunt, cutting, piercing, firearm
  final List<EnemyAbility> abilities;

  const Enemy({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.health,
    required this.damage,
    required this.protection,
    required this.strength,
    required this.damageType,
    required this.abilities,
  });

  factory Enemy.fromJson(Map<String, dynamic> json) {
    final rawAbilities = (json['abilities'] as List? ?? []);
    final abilities = rawAbilities
        .map((a) => EnemyAbility.fromJson(Map<String, dynamic>.from(a)))
        .toList();

    return Enemy(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'human',
      health: json['health'] ?? 30,
      damage: json['damage'] ?? 10,
      protection: json['protection'] ?? 0,
      strength: json['strength'] ?? 5,
      damageType: json['damage_type'] ?? json['damageType'] ?? 'blunt',
      abilities: abilities,
    );
  }

  /// Загрузить всех врагов из JSON
  static Future<List<Enemy>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/enemies.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> list = jsonMap['enemies'] ?? [];
      return list.map((json) => Enemy.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Способность врага в бою
class EnemyAbility {
  final String id;
  final String name;
  final String description;
  final double chance;
  final String effect; // skip_turn, poison, infection, bleeding

  const EnemyAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.chance,
    required this.effect,
  });

  factory EnemyAbility.fromJson(Map<String, dynamic> json) {
    return EnemyAbility(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      chance: (json['chance'] as num).toDouble(),
      effect: json['effect'],
    );
  }
}