import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/services/combat/enemy_loader.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/models/combat/combat.dart';
import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/constants/game_constants.dart';
import 'package:dark_hours/screens/gameplay/combat_screen.dart';

/// Управляет боем на карте.
class CombatManager {
  // ═══════════════════════════════════════════════════════════
  // ПУБЛИЧНЫЕ МЕТОДЫ
  // ═══════════════════════════════════════════════════════════

  /// Запустить бой с врагом по его ID (из enemies.json).
  static Future<void> startCombat(
    BuildContext context,
    MapController controller,
    String enemyId,
  ) async {
    final enemy = EnemyLoader.findById(enemyId);
    if (enemy == null) {
      debugPrint('⚠️ CombatManager: враг "$enemyId" не найден');
      return;
    }

    final combatant = EnemyLoader.toCombatant(enemy);

    await startCombatWithParams(
      context,
      controller,
      enemyName: combatant.name,
      enemyHealth: combatant.health,
      enemyDamage: combatant.damage,
      enemyProtection: combatant.protection,
      enemyStrength: combatant.strength,
      damageType: combatant.damageType,
      abilities: combatant.abilities,
    );
  }

  /// Запустить бой с произвольными параметрами.
  static Future<void> startCombatWithParams(
    BuildContext context,
    MapController controller, {
    required String enemyName,
    required int enemyHealth,
    required int enemyDamage,
    required int enemyProtection,
    required int enemyStrength,
    String damageType = 'blunt',
    List<CombatAbility> abilities = const [],
  }) async {
    controller.trackCombat();

    final player = Combatant(
      name: controller.characterName,
      health: controller.health,
      maxHealth: GameConstants.playerMaxHealth,
      damage: controller.equipment.totalDamage > 0
          ? controller.equipment.totalDamage
          : GameConstants.fistsDamage,
      protection: controller.equipment.totalProtection,
      strength: controller.strength,
      damageType: controller.equipment.weaponDamageType,
      resistances: controller.equipment.totalResistances,
    );

    final enemy = Combatant(
      name: enemyName,
      health: enemyHealth,
      maxHealth: enemyHealth,
      damage: enemyDamage,
      protection: enemyProtection,
      strength: enemyStrength,
      damageType: damageType,
      abilities: abilities,
    );

    await AudioService.stopAmbience();

    if (!context.mounted) return;

    final rawResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CombatScreen(
          player: player,
          enemy: enemy,
          characterId: controller.characterId,
          playerHunger: controller.hunger,
          playerFatigue: controller.fatigue,
        ),
      ),
    );

    await AudioService.playMusic('audio/music/map_theme.ogg');

    final loc = controller.currentLocation;
    if (loc != null) {
      final ambiencePath = AudioService.ambienceForLocation(
        locationId: loc.id,
        type: loc.type,
        region: loc.region,
        dangerLevel: loc.dangerLevel,
      );
      if (ambiencePath != null) {
        await AudioService.playAmbience(ambiencePath);
      }
    }

    String result = 'defeat';
    if (rawResult is Map) {
      result = rawResult['result'] ?? 'defeat';
      final newHealth = rawResult['playerHealth'] ?? player.health;
      final oldHealth = controller.health;
      controller.setHealth(newHealth as int);

      if (controller.health < oldHealth) controller.trackDamage();

      _applyStatusEffects(controller, rawResult);
    } else if (rawResult is String) {
      result = rawResult;
      controller.setHealth(player.health);
    }

    await controller.advanceTime(GameConstants.combatTimeMinutes);

    if (result == 'victory') {
      controller.trackVictory();
      if (context.mounted) {
        AudioService.playSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Победа!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (result == 'defeat') {
      await _handleDefeat(context, controller, enemyName);
    }

    await controller.save();
    controller.refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // ЧИСТАЯ ЛОГИКА
  // ═══════════════════════════════════════════════════════════

  @visibleForTesting
  static bool isStoryBoss(String enemyName) {
    return GameConstants.storyBosses.contains(enemyName);
  }

  @visibleForTesting
  static bool isDangerousEnemy(String enemyName) {
    return GameConstants.dangerousEnemyKeywords.any(
      (keyword) => enemyName.contains(keyword),
    );
  }

  @visibleForTesting
  static Location? pickSafeLocation(MapController controller) {
    final map = controller.map;
    if (map == null) return null;

    final safe = map.locations
        .where((l) =>
            l.dangerLevel <= 2 &&
            l.id != map.currentLocationId &&
            !l.hidden)
        .toList();

    if (safe.isEmpty) return null;
    return safe[Random().nextInt(safe.length)];
  }

  /// Найти соседнюю локацию (использует `connectionIds`).
  @visibleForTesting
  static Location? pickNeighborLocation(MapController controller) {
    final map = controller.map;
    if (map == null) return null;

    final neighbors = map.availableConnections
        .where((l) => !l.hidden || controller.isLocationUnlocked(l.id))
        .toList();

    if (neighbors.isEmpty) return null;
    return neighbors[Random().nextInt(neighbors.length)];
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ МЕТОДЫ
  // ═══════════════════════════════════════════════════════════

  static void _applyStatusEffects(
    MapController controller,
    Map<dynamic, dynamic> rawResult,
  ) {
    if (rawResult['wasBleeding'] == true) {
      final bleedCond = _findCondition(controller, 'bleeding');
      if (bleedCond != null &&
          !ConditionManager.hasCondition(
            controller.activeConditions,
            'bleeding',
          )) {
        controller.addCondition(bleedCond);
      }
    }

    if (rawResult['wasPoisoned'] == true) {
      final poisonCond = _findCondition(controller, 'food_poisoning');
      if (poisonCond != null &&
          !ConditionManager.hasCondition(
            controller.activeConditions,
            'food_poisoning',
          )) {
        controller.addCondition(poisonCond);
      }
    }

    if (rawResult['wasInfected'] == true) {
      final infectCond = _findCondition(controller, 'infection');
      if (infectCond != null &&
          !ConditionManager.hasCondition(
            controller.activeConditions,
            'infection',
          )) {
        controller.addCondition(infectCond);
      }
    }
  }

  static Future<void> _handleDefeat(
    BuildContext context,
    MapController controller,
    String enemyName,
  ) async {
    if (isStoryBoss(enemyName)) {
      return;
    }

    controller.trackDefeat();

    final dangerous = isDangerousEnemy(enemyName);

    if (dangerous) {
      await _applyHeavyDefeat(context, controller);
    } else {
      await _applyLightDefeat(context, controller);
    }
  }

  static Future<void> _applyHeavyDefeat(
    BuildContext context,
    MapController controller,
  ) async {
    controller.setHealth(GameConstants.heavyDefeatHealth);

    final bleedCond = _findCondition(controller, 'bleeding');
    if (bleedCond != null &&
        !ConditionManager.hasCondition(
          controller.activeConditions,
          'bleeding',
        )) {
      controller.addCondition(bleedCond);
    }

    controller.loseRandomItems(GameConstants.heavyDefeatLostItems);

    controller.applyStatDelta({
      'sanity': -GameConstants.heavyDefeatSanityPenalty,
      'fatigue': GameConstants.heavyDefeatFatigueGain,
    });

    final target = pickSafeLocation(controller);
    if (target != null) {
      controller.map?.moveTo(target.id);
      // Авто-разведка нового места
      controller.scoutLocation(target.id);
      controller.discoverRegion(target.region);
    }

    if (!context.mounted) return;

    await _showDefeatDialog(
      context,
      controller,
      title: '💀 ТЯЖЁЛОЕ ПОРАЖЕНИЕ',
      message: 'Ты едва выжил. Раны кровоточат, в глазах темнеет. '
          'Тебя ограбили и бросили на произвол судьбы.\n\n'
          'Ты очнулся в безопасном месте. '
          'Потеряно ${GameConstants.heavyDefeatLostItems} предмета.',
      color: Colors.red[900]!,
    );
  }

  static Future<void> _applyLightDefeat(
    BuildContext context,
    MapController controller,
  ) async {
    controller.setHealth(GameConstants.lightDefeatHealth);

    controller.loseRandomItems(GameConstants.lightDefeatLostItems);

    controller.applyStatDelta({
      'sanity': -GameConstants.lightDefeatSanityPenalty,
      'fatigue': GameConstants.lightDefeatFatigueGain,
    });

    final target = pickNeighborLocation(controller);
    if (target != null) {
      controller.map?.moveTo(target.id);
      controller.scoutLocation(target.id);
      controller.discoverRegion(target.region);
    }

    if (!context.mounted) return;

    await _showDefeatDialog(
      context,
      controller,
      title: '🤕 ПОРАЖЕНИЕ',
      message: 'Тебя избили и ограбили. Ты отделался синяками, '
          'но потерял ${GameConstants.lightDefeatLostItems} предмета.\n\n'
          'Ты очнулся в соседнем районе.',
      color: Colors.orange[900]!,
    );
  }

  static dynamic _findCondition(MapController controller, String id) {
    try {
      return controller.allConditions.firstWhere((c) => c.id == id);
    } catch (_) {
      return controller.allConditions.isNotEmpty
          ? controller.allConditions.first
          : null;
    }
  }

  static Future<void> _showDefeatDialog(
    BuildContext context,
    MapController controller, {
    required String title,
    required String message,
    required Color color,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 10, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        content: Text(
          '$message\n\n📊 Всего поражений в этом забеге: ${controller.tracker.defeats}',
          style: const TextStyle(
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
              'ПРОДОЛЖИТЬ',
              style: TextStyle(
                color: Color.fromARGB(255, 200, 180, 100),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}