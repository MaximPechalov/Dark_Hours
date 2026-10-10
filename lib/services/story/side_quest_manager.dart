import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:dark_hours/models/story/side_quest.dart';
import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/services/map/map_controller.dart';

/// Управляет побочными квестами.
class SideQuestManager {
  final MapController controller;
  final String characterId;
  final int chapter;

  final Map<String, SideQuest> allQuests = {};
  final Map<String, ActiveSideQuest> activeQuests = {};

  SideQuestManager({
    required this.controller,
    required this.characterId,
    this.chapter = 1,
  });

  /// Загрузить квест по ID.
  Future<SideQuest?> loadQuest(String questId) async {
    if (allQuests.containsKey(questId)) return allQuests[questId];

    final path =
        'assets/data/story/$characterId/chapter_$chapter/side_quests/$questId.json';

    try {
      final jsonString = await rootBundle.loadString(path);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final quest = SideQuest.fromJson(json);
      allQuests[questId] = quest;
      return quest;
    } catch (e) {
      debugPrint('❌ SideQuestManager: не удалось загрузить "$questId" — $e');
      return null;
    }
  }

  /// Активировать квесты для текущей карты.
  Future<void> activateForMap(List<String> questIds) async {
    for (final id in questIds) {
      if (activeQuests.containsKey(id)) continue;
      if (_completedIds().contains(id)) continue;

      final quest = await loadQuest(id);
      if (quest == null) continue;

      activeQuests[id] = ActiveSideQuest(
        quest: quest,
        status: SideQuestStatus.active,
      );

      debugPrint('🆕 SideQuestManager: активирован "$id"');
    }
  }

  /// Проверить триггеры при входе в локацию.
  Future<List<SideQuest>> checkTriggers(Location location) async {
    final triggered = <SideQuest>[];

    for (final entry in activeQuests.entries) {
      final aq = entry.value;
      if (aq.status != SideQuestStatus.active) continue;

      final trigger = aq.quest.trigger;
      if (trigger.locationId != location.id) continue;

      // Проверить condition триггера
      if (!_checkCondition(trigger.condition)) continue;

      // Проверить, не сработал ли уже
      if (controller.flags.contains('_sq_triggered_${aq.quest.id}')) {
        continue;
      }

      controller.setFlag('_sq_triggered_${aq.quest.id}');
      triggered.add(aq.quest);

      debugPrint('🎯 SideQuestManager: сработал триггер "${aq.quest.id}"');
    }

    return triggered;
  }

  /// Проверить прогресс всех активных квестов.
  ///
  /// Вызывается после каждого действия игрока: перемещение, обыск, использование предмета.
  Future<List<SideQuestOutcome>> checkProgress() async {
    final results = <SideQuestOutcome>[];

    for (final entry in activeQuests.entries.toList()) {
      final aq = entry.value;
      if (aq.status != SideQuestStatus.active) continue;

      // Обновить статус шагов
      _updateSteps(aq);

      // Проверить, готов ли исход
      final outcome = aq.quest.resolveOutcome(
        flags: controller.flags,
        inventoryIds: controller.inventory.items.map((i) => i.id).toSet(),
      );

      if (outcome != null) {
        await _applyOutcome(aq, outcome);
        results.add(outcome);
      }
    }

    return results;
  }

  /// Проверить, истёк ли квест.
  Future<void> checkExpiry() async {
    for (final entry in activeQuests.entries.toList()) {
      final aq = entry.value;
      if (aq.status != SideQuestStatus.active) continue;

      final expiry = aq.quest.expiresOn;
      if (expiry == null) continue;

      if (controller.flags.contains(expiry.flagSet)) {
        aq.status = SideQuestStatus.expired;
        controller.setFlag('_sq_expired_${aq.quest.id}');

        debugPrint('⌛ SideQuestManager: истёк "${aq.quest.id}"');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ
  // ═══════════════════════════════════════════════════════════

  void _updateSteps(ActiveSideQuest aq) {
    for (final step in aq.quest.steps) {
      if (aq.isStepComplete(step.id)) continue;

      bool done = false;

      switch (step.type) {
        case 'reach_location':
          done = controller.currentLocation?.id == step.target;
          break;
        case 'find_npc':
          done = controller.flags.contains('_sq_${aq.quest.id}_found_${step.target}');
          break;
        case 'use_item':
        case 'give_item':
          done = controller.flags.contains('_sq_${aq.quest.id}_${step.id}');
          break;
        case 'interact':
          done = controller.flags.contains('_sq_${aq.quest.id}_${step.id}');
          break;
      }

      if (done) {
        aq.markStepComplete(step.id);

        // Установить флаг шага
        final flag = step.completionFlag;
        if (flag != null) {
          controller.setFlag(flag);
        }
      }
    }
  }

  Future<void> _applyOutcome(
    ActiveSideQuest aq,
    SideQuestOutcome outcome,
  ) async {
    if (outcome.flagSet != null) {
      controller.setFlag(outcome.flagSet!);
    }

    if (outcome.reward != null) {
      for (final itemId in outcome.reward!.items) {
        final item = controller.findItemInCatalog(itemId);
        if (item != null) controller.addItem(item);
      }
      if (outcome.reward!.sanity != 0) {
        controller.applyStatDelta({'sanity': outcome.reward!.sanity});
      }
    }

    if (outcome.penalty != null) {
      if (outcome.penalty!.sanity != 0) {
        controller.applyStatDelta({'sanity': outcome.penalty!.sanity});
      }
    }

    aq.status = SideQuestStatus.completed;
    controller.setFlag('_sq_done_${aq.quest.id}');

    debugPrint('✅ SideQuestManager: завершён "${aq.quest.id}" → ${outcome.id}');
  }

  bool _checkCondition(Map<String, dynamic>? condition) {
    if (condition == null) return true;

    final flagsAll = (condition['flags_all'] as List? ?? []).cast<String>();
    for (final f in flagsAll) {
      if (!controller.flags.contains(f)) return false;
    }

    final flagsNot = (condition['flags_not'] as List? ?? []).cast<String>();
    for (final f in flagsNot) {
      if (controller.flags.contains(f)) return false;
    }

    return true;
  }

  Set<String> _completedIds() {
    return activeQuests.entries
        .where((e) => e.value.status == SideQuestStatus.completed)
        .map((e) => e.key)
        .toSet();
  }

  /// Публичный список активных квестов (для UI).
  List<ActiveSideQuest> get active => activeQuests.values
      .where((aq) => aq.status == SideQuestStatus.active)
      .toList();

  /// Публичный список завершённых квестов (для UI).
  List<ActiveSideQuest> get completed => activeQuests.values
      .where((aq) => aq.status == SideQuestStatus.completed)
      .toList();
}