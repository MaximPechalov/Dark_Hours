// lib/services/story/chapter_manager.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:dark_hours/models/story/chapter_step.dart';
import 'package:dark_hours/models/story/story_sequence.dart';
import 'package:dark_hours/services/story/side_quest_manager.dart';

/// Управляет последовательностью главы.
///
/// Читает `meta.json` и вызывает **колбэки** для каждого шага:
/// - `onAct` — открыть StoryScreen.
/// - `onMap` — открыть MapScreen с целью.
/// - `onComplete` — глава завершена.
class ChapterManager {
  final String characterId;
  final int chapter;

  StorySequence? sequence;
  int currentIndex = 0;
  bool isComplete = false;

  SideQuestManager? sideQuestManager;

  // Колбэки
  final Future<void> Function(ChapterStep step) onAct;
  final Future<void> Function(ChapterStep step) onMap;
  final Future<void> Function() onComplete;

  ChapterManager({
    required this.characterId,
    required this.chapter,
    required this.onAct,
    required this.onMap,
    required this.onComplete,
  });

  /// Загрузить `meta.json`.
  Future<bool> load() async {
    final path =
        'assets/data/story/$characterId/chapter_$chapter/meta.json';

    try {
      final jsonString = await rootBundle.loadString(path);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      sequence = StorySequence.fromJson(json);
      debugPrint(
        '📖 ChapterManager: загружено ${sequence!.steps.length} шагов',
      );
      return true;
    } catch (e) {
      debugPrint('❌ ChapterManager: не удалось загрузить $path — $e');
      return false;
    }
  }

  /// Начать главу с первого шага.
  Future<void> start() async {
    if (sequence == null) return;
    currentIndex = 0;
    await _executeCurrentStep();
  }

  /// Продолжить с текущего шага.
  Future<void> resume() async {
    if (sequence == null) return;
    await _executeCurrentStep();
  }

  /// Перейти к следующему шагу.
  Future<void> advance() async {
    if (sequence == null) return;

    currentIndex++;
    if (currentIndex >= sequence!.steps.length) {
      isComplete = true;
      await onComplete();
      return;
    }

    await _executeCurrentStep();
  }

  /// Установить менеджер квестов.
  void attachSideQuests(SideQuestManager manager) {
    sideQuestManager = manager;
  }

  /// Получить текущий шаг.
  ChapterStep? get currentStep {
    if (sequence == null) return null;
    if (currentIndex >= sequence!.steps.length) return null;
    return sequence!.steps[currentIndex];
  }

  /// Прогресс: сколько шагов пройдено.
  double get progress {
    if (sequence == null || sequence!.steps.isEmpty) return 0;
    return currentIndex / sequence!.steps.length;
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ
  // ═══════════════════════════════════════════════════════════

  Future<void> _executeCurrentStep() async {
    final step = currentStep;
    if (step == null) return;

    debugPrint(
      '📖 ChapterManager: шаг $currentIndex — ${step.type.name} "${step.id}"',
    );

    if (step.isAct) {
      await onAct(step);
    } else if (step.isMap) {
      await onMap(step);
    }
  }
}