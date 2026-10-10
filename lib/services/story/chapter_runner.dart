// lib/services/story/chapter_runner.dart

import 'package:flutter/material.dart';

import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/models/story/chapter_step.dart';
import 'package:dark_hours/models/story/story_sequence.dart';
import 'package:dark_hours/models/progress/chapter_summary.dart';

import 'package:dark_hours/services/story/chapter_manager.dart';
import 'package:dark_hours/services/story/side_quest_manager.dart';
import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/progress/run_tracker.dart';

import 'package:dark_hours/screens/gameplay/story_screen.dart';
import 'package:dark_hours/screens/gameplay/map/map_screen.dart';
import 'package:dark_hours/screens/gameplay/chapter_end_screen.dart';

/// Управляет всем потоком главы: акт → карта → акт.
///
/// Использование:
/// ```dart
/// final runner = ChapterRunner(characterId: 'boris');
/// await runner.load();
/// runner.start(context);
/// ```
class ChapterRunner {
  final String characterId;
  final String characterName;
  final SaveData? resumeFrom;

  StorySequence? sequence;
  ChapterManager? manager;
  SideQuestManager? sideQuestManager;
  MapController? mapController;
  final RunTracker tracker = RunTracker();

  BuildContext? _context;

  ChapterRunner({
    required this.characterId,
    required this.characterName,
    this.resumeFrom,
  });

  /// Загрузить `meta.json`.
  Future<bool> load() async {
    sequence = await StorySequence.load(characterId, chapter: 1);
    if (sequence == null) return false;

    manager = ChapterManager(
      characterId: characterId,
      chapter: 1,
      onAct: _runAct,
      onMap: _runMap,
      onComplete: _runComplete,
    );

    return await manager!.load();
  }

  /// Начать с начала.
  Future<void> start(BuildContext context) async {
    if (manager == null) return;
    _context = context;
    await manager!.start();
  }

  /// Продолжить с текущего шага.
  Future<void> resume(BuildContext context) async {
    if (manager == null) return;
    _context = context;
    await manager!.resume();
  }

  // ═══════════════════════════════════════════════════════════
  // КОЛБЭКИ
  // ═══════════════════════════════════════════════════════════

  Future<void> _runAct(ChapterStep step) async {
    if (_context == null || !_context!.mounted) return;

    await Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (_) => StoryScreen(
          characterId: characterId,
          characterName: characterName,
          resumeFrom: resumeFrom,
          actId: step.id,
          mode: step.id == 'act_8' ? 'final' : 'trigger',
        ),
      ),
    );

    if (!_context!.mounted) return;

    // Акт завершён — переходим к следующему шагу.
    await manager?.advance();
  }

  Future<void> _runMap(ChapterStep step) async {
    if (_context == null || !_context!.mounted) return;

    // Создаём MapController если ещё нет
    mapController ??= MapController(
      characterId: characterId,
      characterName: characterName,
      resumeFrom: resumeFrom,
    );

    await Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          characterId: characterId,
          characterName: characterName,
          resumeFrom: resumeFrom,
          chapterStep: step,
          onGoalComplete: () {
            if (_context != null && _context!.mounted) {
              Navigator.pop(_context!);
            }
          },
        ),
      ),
    );

    if (!_context!.mounted) return;

    // Карта завершена — переходим к следующему шагу.
    await manager?.advance();
  }

  Future<void> _runComplete() async {
    if (_context == null || !_context!.mounted) return;

    final summary = ChapterSummary.fromSaveAndTracker(
      resumeFrom ?? _emptySave(),
      tracker,
      daysSurvived: 1,
      finalNode: 'chapter_1_complete',
    );

    await Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (_) => ChapterEndScreen(summary: summary),
      ),
    );
  }

  SaveData _emptySave() {
    return SaveData(
      characterId: characterId,
      characterName: characterName,
      currentNodeId: 'END',
      currentLocationId: 'home_boris',
      onMap: false,
      hunger: 100,
      thirst: 100,
      health: 100,
      sanity: 100,
      stamina: 100,
      fatigue: 0,
      timeMinutes: 480,
      chapter: 1,
      history: [],
      inventoryItems: [],
      equipmentItems: {},
      activeConditions: [],
      savedAt: DateTime.now(),
    );
  }
}