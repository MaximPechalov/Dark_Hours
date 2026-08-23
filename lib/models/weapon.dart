import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Weapon {
  final String id;
  final String name;
  final String description;
  final String type; // melee, ranged, special
  final int damage;
  final int requiredStrength;
  final double weight;
  final int durability;
  final String specialAbility;
  final String icon;
  final String rarity; // common, uncommon, rare, epic, legendary
  final String? ammoType;
  final int? ammoMax;

  const Weapon({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.damage,
    required this.requiredStrength,
    required this.weight,
    required this.durability,
    required this.specialAbility,
    required this.icon,
    required this.rarity,
    this.ammoType,
    this.ammoMax,
  });

  factory Weapon.fromJson(Map<String, dynamic> json) {
    return Weapon(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      damage: json['damage'],
      requiredStrength: json['required_strength'],
      weight: json['weight'].toDouble(),
      durability: json['durability'],
      specialAbility: json['special_ability'],
      icon: json['icon'],
      rarity: json['rarity'],
      ammoType: json['ammo_type'],
      ammoMax: json['ammo_max'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'damage': damage,
      'required_strength': requiredStrength,
      'weight': weight,
      'durability': durability,
      'special_ability': specialAbility,
      'icon': icon,
      'rarity': rarity,
      'ammo_type': ammoType,
      'ammo_max': ammoMax,
    };
  }

  // Цвет редкости
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

  // Название редкости на русском
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

  // Тип оружия на русском
  String get typeName {
    switch (type) {
      case 'melee':
        return 'Ближний бой';
      case 'ranged':
        return 'Дальний бой';
      case 'special':
        return 'Специальное';
      default:
        return type;
    }
  }

  // Загрузка всех оружий из JSON
  static Future<List<Weapon>> loadAll() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/weapons.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> weaponsJson = jsonMap['weapons'];
      return weaponsJson.map((json) => Weapon.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
