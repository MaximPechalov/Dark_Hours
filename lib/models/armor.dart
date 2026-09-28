import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Armor {
  final String id;
  final String name;
  final String description;
  final String slot; // head, body, hands, feet, backpack
  final int protection;
  final int warmth;
  final double weight;
  final int durability;
  final String icon;
  final String rarity;
  final int? extraSlots;

  const Armor({
    required this.id,
    required this.name,
    required this.description,
    required this.slot,
    required this.protection,
    required this.warmth,
    required this.weight,
    required this.durability,
    required this.icon,
    required this.rarity,
    this.extraSlots,
  });

  factory Armor.fromJson(Map<String, dynamic> json) {
    return Armor(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      slot: json['slot'],
      protection: json['protection'],
      warmth: json['warmth'],
      weight: json['weight'].toDouble(),
      durability: json['durability'],
      icon: json['icon'],
      rarity: json['rarity'],
      extraSlots: json['extra_slots'],
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

  String get slotName {
    switch (slot) {
      case 'head':
        return 'Голова';
      case 'body':
        return 'Тело';
      case 'hands':
        return 'Руки';
      case 'feet':
        return 'Ноги';
      case 'backpack':
        return 'Рюкзак';
      default:
        return slot;
    }
  }

  static Future<List<Armor>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/armor.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> armorJson = jsonMap['armor'];
      return armorJson.map((json) => Armor.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}