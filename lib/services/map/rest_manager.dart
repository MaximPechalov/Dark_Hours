import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/combat_manager.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/models/time/game_time.dart';
import 'package:dark_hours/models/time/rest_action.dart';
import 'package:dark_hours/constants/game_constants.dart';

/// Управляет отдыхом игрока.
///
/// Логика:
/// 1. Восстановить статы (стамина, здоровье, психика, усталость).
/// 2. Бонус от спального мешка (если есть).
/// 3. Если локация опасная — риски:
///    - простудиться (шанс зависит от тепла экипировки);
///    - быть ограбленным (при долгом отдыхе);
///    - быть атакованным (при очень долгом отдыхе).
/// 4. Продвинуть время.
/// 5. Автосохранить.
class RestManager {
  /// Выполнить действие отдыха.
  static Future<void> rest(
    BuildContext context,
    MapController controller,
    RestAction action,
  ) async {
    final loc = controller.currentLocation;
    if (loc == null) return;

    final isSafe = loc.dangerLevel <= GameConstants.safeLocationDangerLevel;

    // ─── 1. Восстановление статов ───
    _applyRestStats(controller, action);

    // ─── 2. Бонус спального мешка ───
    _applySleepingBagBonus(controller);

    // ─── 3. Риски в опасной локации ───
    if (!isSafe) {
      // 3.1. Простуда
      _rollCold(controller);

      // 3.2. Ограбление (при долгом отдыхе)
      if (action.timeMinutes >= GameConstants.restTheftMinDuration) {
        _rollTheft(context, controller);
      }

      // 3.3. Атака (при очень долгом отдыхе)
      if (action.timeMinutes >= GameConstants.restAttackMinDuration) {
        final attacked = _rollAttack(context, controller);
        if (attacked) return; // бой запущен, дальше не идём
      }
    }

    // ─── 4. Время ───
    await controller.advanceTime(action.timeMinutes, isSleeping: true);

    // ─── 5. Автосохранение ───
    await controller.save();

    controller.refresh();

    // ─── 6. Снекбар ───
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${action.icon} Отдых: ${action.name}'),
          backgroundColor: const Color.fromARGB(255, 100, 180, 100),
          duration: const Duration(
            seconds: GameConstants.snackbarDefaultSeconds,
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ МЕТОДЫ
  // ═══════════════════════════════════════════════════════════

  /// Применить изменения статов от отдыха
  static void _applyRestStats(MapController controller, RestAction action) {
    controller.applyStatDelta({
      'stamina': action.staminaRestore,
      'health': action.healthRestore,
      'sanity': action.sanityRestore,
      'fatigue': -action.fatigueReduce,
    });
  }

  /// Бонус от спального мешка
  static void _applySleepingBagBonus(MapController controller) {
    if (!controller.inventory.hasItem('sleeping_bag')) return;
    controller.applyStatDelta({
      'stamina': GameConstants.sleepingBagStaminaBonus,
      'sanity': GameConstants.sleepingBagSanityBonus,
    });
  }

  /// Риск простуды при отдыхе в опасной/холодной локации
  static void _rollCold(MapController controller) {
    final riskRoll = Random().nextInt(100);
    final warmth = controller.equipment.totalWarmth;
    final coldChance = warmth >= GameConstants.warmthColdResistThreshold
        ? GameConstants.coldChanceLow
        : GameConstants.coldChanceHigh;

    if (riskRoll >= coldChance) return;

    final newCond = ConditionManager.tryInfect(
      controller.allConditions,
      'cold_weather',
      1.0,
    );
    if (newCond == null) return;

    if (ConditionManager.hasCondition(
      controller.activeConditions,
      newCond.id,
    )) {
      return;
    }

    controller.addCondition(newCond);
  }

  /// Риск ограбления при отдыхе в опасной локации
  static void _rollTheft(
    BuildContext context,
    MapController controller,
  ) {
    final theftRoll = Random().nextInt(100);
    if (theftRoll >= GameConstants.restTheftChance) return;
    if (controller.inventory.items.isEmpty) return;

    final stolen = controller.inventory.items[
        Random().nextInt(controller.inventory.items.length)];
    controller.removeAll(stolen.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💀 Тебя ограбили! Украдено: ${stolen.name}'),
          backgroundColor: Colors.red[700],
          duration: const Duration(
            seconds: GameConstants.snackbarLongSeconds,
          ),
        ),
      );
    }
  }

  /// Риск атаки при отдыхе в опасной локации.
  ///
  /// Возвращает `true`, если бой запущен.
  static bool _rollAttack(
    BuildContext context,
    MapController controller,
  ) {
    final attackRoll = Random().nextInt(100);
    final phaseMultiplier =
        controller.gameTime.phase.dangerMultiplier.toInt();
    final attackChance =
        GameConstants.restAttackBaseChance * phaseMultiplier;

    if (attackRoll >= attackChance) return false;

    // Запускаем бой — но не ждём (асинхронно, огонь и забыли)
    CombatManager.startCombat(context, controller, 'looter_common');
    return true;
  }
}