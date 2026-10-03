import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/combat_manager.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/models/time/game_time.dart';
import 'package:dark_hours/models/time/rest_action.dart';
import 'package:dark_hours/constants/game_constants.dart';

/// Результат проверки на простуду.
class ColdResult {
  final bool infected;
  final int chance;

  const ColdResult({required this.infected, required this.chance});
}

/// Результат проверки на ограбление.
class TheftResult {
  final bool stolen;
  final int chance;
  final int itemsToLose;

  const TheftResult({
    required this.stolen,
    required this.chance,
    this.itemsToLose = 1,
  });
}

/// Управляет отдыхом игрока.
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

    _applyRestStats(controller, action);
    _applySleepingBagBonus(controller);

    if (!isSafe) {
      final cold = rollCold(controller);
      if (cold.infected) {
        _applyCold(controller);
      }

      if (action.timeMinutes >= GameConstants.restTheftMinDuration) {
        final theft = rollTheft(controller);
        if (theft.stolen) {
          _applyTheft(context, controller, theft.itemsToLose);
        }
      }

      if (action.timeMinutes >= GameConstants.restAttackMinDuration) {
        final attacked = rollAttack(controller);
        if (attacked) {
          _triggerAttack(context, controller);
          return;
        }
      }
    }

    await controller.advanceTime(action.timeMinutes, isSleeping: true);
    await controller.save();
    controller.refresh();

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
  // ЧИСТАЯ ЛОГИКА
  // ═══════════════════════════════════════════════════════════

  /// Вычислить дельты статов от отдыха.
  @visibleForTesting
  static Map<String, int> computeRestStats(
    MapController controller,
    RestAction action,
  ) {
    final delta = <String, int>{
      'stamina': action.staminaRestore,
      'health': action.healthRestore,
      'sanity': action.sanityRestore,
      'fatigue': -action.fatigueReduce,
    };

    if (controller.inventory.hasItem('sleeping_bag')) {
      delta['stamina'] =
          (delta['stamina'] ?? 0) + GameConstants.sleepingBagStaminaBonus;
      delta['sanity'] =
          (delta['sanity'] ?? 0) + GameConstants.sleepingBagSanityBonus;
    }

    return delta;
  }

  /// Определить, простудится ли игрок.
  @visibleForTesting
  static ColdResult rollCold(MapController controller) {
    final warmth = controller.equipment.totalWarmth;
    final chance = warmth >= GameConstants.warmthColdResistThreshold
        ? GameConstants.coldChanceLow
        : GameConstants.coldChanceHigh;

    final roll = Random().nextInt(100);
    return ColdResult(
      infected: roll < chance,
      chance: chance,
    );
  }

  /// Определить, ограбят ли игрока.
  @visibleForTesting
  static TheftResult rollTheft(MapController controller) {
    if (controller.inventory.items.isEmpty) {
      return const TheftResult(
        stolen: false,
        chance: GameConstants.restTheftChance,
      );
    }

    final roll = Random().nextInt(100);
    return TheftResult(
      stolen: roll < GameConstants.restTheftChance,
      chance: GameConstants.restTheftChance,
      itemsToLose: 1,
    );
  }

  /// Определить, атакуют ли игрока.
  ///
  /// ⚠️ ВАЖНО: multiplier — double (0.8, 1.0, 1.2, 1.8).
  /// Нельзя использовать `.toInt()` — 0.8.toInt() = 0.
  /// Умножаем на double, потом округляем до int.
  @visibleForTesting
  static bool rollAttack(MapController controller) {
    final attackRoll = Random().nextInt(100);
    final multiplier = controller.gameTime.phase.dangerMultiplier;
    final attackChance =
        (GameConstants.restAttackBaseChance * multiplier).round();

    return attackRoll < attackChance;
  }

  // ═══════════════════════════════════════════════════════════
  // ПРИМЕНЕНИЕ ЭФФЕКТОВ
  // ═══════════════════════════════════════════════════════════

  static void _applyRestStats(MapController controller, RestAction action) {
    final delta = computeRestStats(controller, action);
    controller.applyStatDelta(delta);
  }

  static void _applySleepingBagBonus(MapController controller) {
    // Бонус уже учтён в computeRestStats
  }

  static void _applyCold(MapController controller) {
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

  static void _applyTheft(
    BuildContext context,
    MapController controller,
    int itemsToLose,
  ) {
    final stolen = <String>[];
    for (int i = 0; i < itemsToLose; i++) {
      if (controller.inventory.items.isEmpty) break;
      final item = controller.inventory.items[
          Random().nextInt(controller.inventory.items.length)];
      stolen.add(item.name);
      controller.removeAll(item.id);
    }

    if (context.mounted && stolen.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💀 Тебя ограбили! Украдено: ${stolen.join(", ")}'),
          backgroundColor: Colors.red[700],
          duration: const Duration(
            seconds: GameConstants.snackbarLongSeconds,
          ),
        ),
      );
    }
  }

  static void _triggerAttack(
    BuildContext context,
    MapController controller,
  ) {
    CombatManager.startCombat(context, controller, 'looter_common');
  }
}