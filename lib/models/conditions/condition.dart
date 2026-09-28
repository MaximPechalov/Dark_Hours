import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Condition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String severity; // low, medium, high, critical
  final Map<String, int> effectsPerTurn;
  final List<String> cureItems;
  final double cureChance;
  final int durationDays;
  final List<String> source;

  const Condition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.severity,
    required this.effectsPerTurn,
    required this.cureItems,
    required this.cureChance,
    required this.durationDays,
    required this.source,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      severity: json['severity'],
      effectsPerTurn: Map<String, int>.from(json['effects_per_turn'] ?? {}),
      cureItems: List<String>.from(json['cure_items'] ?? []),
      cureChance: (json['cure_chance'] as num).toDouble(),
      durationDays: json['duration_days'],
      source: List<String>.from(json['source'] ?? []),
    );
  }

  Color get severityColor {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get severityName {
    switch (severity) {
      case 'low':
        return 'Лёгкое';
      case 'medium':
        return 'Среднее';
      case 'high':
        return 'Тяжёлое';
      case 'critical':
        return 'Критическое';
      default:
        return severity;
    }
  }

  static Future<List<Condition>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/conditions.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> list = jsonMap['conditions'];
      return list.map((json) => Condition.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}