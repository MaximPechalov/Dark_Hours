import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/save/save_manager.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/screens/main/death_screen.dart';
import 'package:dark_hours/constants/game_constants.dart';

/// Что решил DeathManager после проверки усталости.
enum FatigueAction {
  /// Ничего — усталость в норме.
  nothing,

  /// Форсированный автосон (95..99).
  forcedSleep,

  /// Коллапс с последствиями (>= 100).
  collapse,

  /// Смерть от повторного коллапса (коллапс в течение 24 часов).
  died,
}

/// Результат проверки усталости.
class FatigueEvaluation {
  final FatigueAction action;
  final String? deathReason;

  const FatigueEvaluation(this.action, {this.deathReason});
}

/// Управляет смертью, коллапсом и форсированным автосном.
///
/// Что проверяет:
/// 1. Смерть от голода, жажды, здоровья, зимы.
/// 2. Повторный коллапс в течение 24 часов → смерть.
/// 3. Усталость >= 95 → форсированный автосон.
/// 4. Усталость >= 100 → коллапс.
///
/// При смерти:
/// 1. Обновляет статистику игрока (PlayerStats).
/// 2. Открывает DeathScreen.
/// 3. Удаляет сохранение.
class DeathManager {
  /// Проверить состояние на смерть.
  ///
  /// Возвращает `true`, если игрок умер.
  static bool checkDeath(MapController controller) {
    if (controller.isDead) return true;

    String? reason;

    if (controller.hunger <= 0) {
      reason = 'Ты умер от голода. Тело не выдержало.';
    } else if (controller.thirst <= 0) {
      reason = 'Ты умер от обезвоживания.';
    } else if (controller.health <= 0) {
      reason = 'Твои раны оказались смертельными.';
    } else if (controller.gameTime.isWinter) {
      reason = 'Пришла зима. Ты не успел добраться до станции.';
    }

    if (reason == null) return false;

    controller.markDead(reason);
    return true;
  }

  /// Проверить усталость и выполнить действие.
  ///
  /// Может инициировать:
  /// - Форсированный автосон (усталость 95..99)
  /// - Коллапс (усталость >= 100)
  /// - Смерть (повторный коллапс в течение 24 часов)
  static Future<void> checkFatigue(
    BuildContext context,
    MapController controller,
  ) async {
    final evaluation = evaluateFatigue(controller);

    switch (evaluation.action) {
      case FatigueAction.nothing:
        return;

      case FatigueAction.forcedSleep:
        await _forceAutoSleep(context, controller);
        return;

      case FatigueAction.collapse:
        await _handleCollapse(context, controller);
        return;

      case FatigueAction.died:
        controller.markDead(evaluation.deathReason ?? 'Ты умер.');
        return;
    }
  }

  /// Чистая логика проверки усталости — БЕЗ UI.
  ///
  /// Возвращает решение, что делать. Тестируется без BuildContext.
  @visibleForTesting
  static FatigueEvaluation evaluateFatigue(MapController controller) {
    if (controller.isDead) {
      return const FatigueEvaluation(FatigueAction.nothing);
    }

    // Зона 80-95: только предупреждение, обрабатывается UI
    if (controller.fatigue < GameConstants.fatigueForcedSleepThreshold) {
      return const FatigueEvaluation(FatigueAction.nothing);
    }

    // Зона 95-100: форсированный автосон
    if (controller.fatigue < GameConstants.fatigueCollapseThreshold) {
      if (controller.autoSleepTriggered) {
        return const FatigueEvaluation(FatigueAction.nothing);
      }
      return const FatigueEvaluation(FatigueAction.forcedSleep);
    }

    // Зона >= 100: коллапс или смерть
    final lastCollapse = controller.lastCollapseTime;
    if (lastCollapse != null &&
        DateTime.now().difference(lastCollapse).inHours <
            GameConstants.collapseRepeatHours) {
      return const FatigueEvaluation(
        FatigueAction.died,
        deathReason:
            'Твоё тело не выдержало повторного истощения. Сердце остановилось.',
      );
    }

    return const FatigueEvaluation(FatigueAction.collapse);
  }

  /// Открыть DeathScreen, если игрок умер.
  ///
  /// Вызывается из UI-обёртки.
  static Future<void> showDeathScreenIfNeeded(
    BuildContext context,
    MapController controller,
  ) async {
    if (!controller.isDead) return;
    if (!context.mounted) return;

    await AudioService.stopAmbience();

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeathScreen(
          reason: controller.deathReason,
          characterName: controller.characterName,
          dayReached: controller.gameTime.day,
        ),
      ),
    );

    if (context.mounted) {
      await SaveManager.delete();
      Navigator.pop(context);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ МЕТОДЫ — ФОРСИРОВАННЫЙ АВТОСОН
  // ═══════════════════════════════════════════════════════════

  /// Форсированный автосон при усталости 95-99.
  static Future<void> _forceAutoSleep(
    BuildContext context,
    MapController controller,
  ) async {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '😴 Ты засыпаешь прямо на месте... (1 час)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color.fromARGB(255, 100, 100, 200),
      ),
    );

    await controller.advanceTime(
      GameConstants.forcedAutoSleepMinutes,
      isSleeping: true,
    );

    controller.applyStatDelta({
      'fatigue': -GameConstants.forcedAutoSleepFatigueReduce,
      'stamina': -GameConstants.forcedAutoSleepStaminaPenalty,
      'sanity': -GameConstants.forcedAutoSleepSanityPenalty,
    });

    controller.autoSleepTriggered = false;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '😵 Ты проснулся. Разбитость: -15 выносливости.',
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color.fromARGB(255, 150, 100, 100),
      ),
    );

    await controller.save();
    controller.refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ МЕТОДЫ — КОЛЛАПС
  // ═══════════════════════════════════════════════════════════

  /// Коллапс при усталости >= 100.
  static Future<void> _handleCollapse(
    BuildContext context,
    MapController controller,
  ) async {
    // Отметить время коллапса
    controller.lastCollapseTime = DateTime.now();
    controller.trackCollapse();

    if (!context.mounted) return;

    await _showCollapseDialog(context);

    // Продвинуть время + эффекты
    await controller.advanceTime(
      GameConstants.collapseSleepMinutes,
      isSleeping: true,
    );

    controller.applyStatDelta({
      'fatigue': GameConstants.collapseFatigueReset - controller.fatigue,
      'health': -GameConstants.collapseHealthPenalty,
      'sanity': -GameConstants.collapseSanityPenalty,
    });

    // Шансы
    _rollTheftOnCollapse(context, controller);
    _rollColdOnCollapse(controller);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('😵 Ты очнулся. -20 HP, -15 психики.'),
        duration: Duration(seconds: 3),
        backgroundColor: Color.fromARGB(255, 100, 50, 50),
      ),
    );

    await controller.save();
    controller.refresh();
  }

  /// Показать диалог коллапса
  static Future<void> _showCollapseDialog(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 10, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Text(
          '💀 КОЛЛАПС',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Ты теряешь сознание от истощения. Проходит 4 часа...\n\n'
          '⚠️ Если это повторится в течение 24 часов — твоё сердце остановится.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context);
            },
            child: const Text(
              'ОЧНУТЬСЯ',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Шанс ограбления при коллапсе
  static void _rollTheftOnCollapse(
    BuildContext context,
    MapController controller,
  ) {
    final roll = Random().nextInt(100);
    if (roll >= GameConstants.collapseTheftChance) return;
    if (controller.inventory.items.isEmpty) return;

    controller.loseRandomItems(GameConstants.collapseTheftItems);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💀 Пока ты был без сознания, тебя ограбили!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Шанс простуды при коллапсе
  static void _rollColdOnCollapse(MapController controller) {
    final roll = Random().nextInt(100);
    if (roll >= GameConstants.collapseColdChance) return;

    final coldCond = _findCondition(controller, 'cold');
    if (coldCond == null) return;

    if (controller.activeConditions.any((ac) => ac.condition.id == 'cold')) {
      return;
    }

    controller.addCondition(coldCond);
  }

  /// Найти условие по ID
  static Condition? _findCondition(MapController controller, String id) {
    try {
      return controller.allConditions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // СТАТИСТИКА ПРИ СМЕРТИ
  // ═══════════════════════════════════════════════════════════

  /// Обновить статистику игрока при смерти.
  static Future<void> applyStatsOnDeath(MapController controller) async {
    final stats = await AchievementManager.loadStats();
    stats.totalDeaths += 1;
    stats.totalDaysSurvived += controller.gameTime.day;

    if (controller.gameTime.day > stats.bestRunDays) {
      stats.bestRunDays = controller.gameTime.day;
      stats.bestRunCharacter = controller.characterName;
    }

    controller.tracker.applyToStats(stats);
    await AchievementManager.saveStats(stats);
  }
}