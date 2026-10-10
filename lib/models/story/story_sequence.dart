import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'chapter_step.dart';

/// Последовательность главы — из `meta.json`.
class StorySequence {
  final String character;
  final String characterName;
  final int chapter;
  final String title;
  final String subtitle;
  final String description;
  final List<ChapterStep> steps;
  final List<StoryEndingData> endings;
  final List<SideQuestMeta> sideQuests;
  final List<KeyFlagData> keyFlags;
  final int estimatedMinutes;

  const StorySequence({
    required this.character,
    required this.characterName,
    required this.chapter,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.steps,
    required this.endings,
    required this.sideQuests,
    required this.keyFlags,
    required this.estimatedMinutes,
  });

  factory StorySequence.fromJson(Map<String, dynamic> json) {
    return StorySequence(
      character: json['character'] as String,
      characterName: json['character_name'] as String? ?? '',
      chapter: json['chapter'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      steps: (json['sequence'] as List? ?? [])
          .map((s) => ChapterStep.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      endings: (json['endings'] as List? ?? [])
          .map((e) => StoryEndingData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sideQuests: (json['side_quests'] as List? ?? [])
          .map((s) => SideQuestMeta.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      keyFlags: (json['key_flags'] as List? ?? [])
          .map((f) => KeyFlagData.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
      estimatedMinutes: json['estimated_minutes'] as int? ?? 0,
    );
  }

  /// Загрузить последовательность главы из `meta.json`.
  ///
  /// Формат: `assets/data/story/{characterId}/chapter_{chapter}/meta.json`.
  static Future<StorySequence?> load(
    String characterId, {
    int chapter = 1,
  }) async {
    try {
      final path =
          'assets/data/story/$characterId/chapter_$chapter/meta.json';

      debugPrint('📖 StorySequence.load: $path');

      final jsonString = await rootBundle.loadString(path);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final sequence = StorySequence.fromJson(json);
      debugPrint(
        '📖 StorySequence.load: загружено ${sequence.steps.length} шагов',
      );
      return sequence;
    } catch (e, stackTrace) {
      debugPrint('❌ StorySequence.load: $e');
      debugPrint('📍 $stackTrace');
      return null;
    }
  }

  ChapterStep? getStep(String id) {
    for (final step in steps) {
      if (step.id == id) return step;
    }
    return null;
  }

  int indexOfStep(String id) {
    return steps.indexWhere((s) => s.id == id);
  }

  ChapterStep? getNextStep(String currentId) {
    final idx = indexOfStep(currentId);
    if (idx < 0 || idx + 1 >= steps.length) return null;
    return steps[idx + 1];
  }

  SideQuestMeta? getSideQuestMeta(String id) {
    for (final sq in sideQuests) {
      if (sq.id == id) return sq;
    }
    return null;
  }
}

/// Данные концовки.
class StoryEndingData {
  final String id;
  final String title;
  final String description;
  final Map<String, dynamic> requires;

  const StoryEndingData({
    required this.id,
    required this.title,
    required this.description,
    required this.requires,
  });

  factory StoryEndingData.fromJson(Map<String, dynamic> json) {
    return StoryEndingData(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requires: Map<String, dynamic>.from(json['requires'] ?? {}),
    );
  }

  /// Проверить, подходит ли эта концовка по флагам.
  bool matches(Set<String> flags) {
    final flagsAll = (requires['flags_all'] as List? ?? []).cast<String>();
    for (final f in flagsAll) {
      if (!flags.contains(f)) return false;
    }

    final flagsNot = (requires['flags_not'] as List? ?? []).cast<String>();
    for (final f in flagsNot) {
      if (flags.contains(f)) return false;
    }

    return true;
  }
}

/// Метаданные побочного квеста (из `meta.json`).
class SideQuestMeta {
  final String id;
  final String title;
  final String file;
  final String? availableOnMap;

  const SideQuestMeta({
    required this.id,
    required this.title,
    required this.file,
    this.availableOnMap,
  });

  factory SideQuestMeta.fromJson(Map<String, dynamic> json) {
    return SideQuestMeta(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      file: json['file'] as String? ?? '',
      availableOnMap: json['available_on_map'] as String?,
    );
  }
}

/// Описание ключевого флага (из `meta.json`).
class KeyFlagData {
  final String id;
  final String description;
  final List<String> setIn;

  const KeyFlagData({
    required this.id,
    required this.description,
    required this.setIn,
  });

  factory KeyFlagData.fromJson(Map<String, dynamic> json) {
    return KeyFlagData(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      setIn: (json['set_in'] as List? ?? []).cast<String>(),
    );
  }
}