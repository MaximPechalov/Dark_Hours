import 'dart:convert';
import 'package:flutter/services.dart';

/// Событие, которое может произойти при обыске локации
/// после исчерпания её ресурсов
class SearchEvent {
  final String id;
  final String name;
  final double chance;
  final String text;
  final Map<String, dynamic> effect;

  const SearchEvent({
    required this.id,
    required this.name,
    required this.chance,
    required this.text,
    required this.effect,
  });

  factory SearchEvent.fromJson(Map<String, dynamic> json) {
    return SearchEvent(
      id: json['id'],
      name: json['name'] ?? '',
      chance: (json['chance'] as num).toDouble(),
      text: json['text'] ?? '',
      effect: Map<String, dynamic>.from(json['effect'] ?? {}),
    );
  }

  /// Проверка: применим ли эффект к текущей локации
  /// (например, `unlock_location: "auto"` работает только если
  /// в текущей локации есть скрытая)
  bool isApplicableTo({
    required String currentLocationId,
    required Map<String, String> hiddenLocations, // {unlocked_by: hidden_id}
  }) {
    final unlock = effect['unlock_location'];

    if (unlock == null) return true; // не связано с локациями

    // Если явно указан ID — применяем
    if (unlock is String && unlock != 'auto') return true;

    // Если "auto" — проверяем, есть ли скрытая для текущей локации
    if (unlock == 'auto') {
      return hiddenLocations.containsKey(currentLocationId);
    }

    return true;
  }

  /// Загрузить все общие события
  static Future<List<SearchEvent>> loadAll() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/search_events.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> list = jsonMap['events'] ?? [];
      return list.map((json) => SearchEvent.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}