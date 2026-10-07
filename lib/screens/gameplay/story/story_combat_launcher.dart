import 'package:flutter/material.dart';

import 'package:dark_hours/models/combat/combat.dart';
import 'package:dark_hours/models/inventory/equipment.dart';
import 'package:dark_hours/screens/gameplay/combat_screen.dart';

/// Результат боя.
class CombatLaunchResult {
  /// `'victory'` | `'defeat'` | `'fled'`.
  final String result;

  /// HP игрока после боя.
  final int playerHealth;

  const CombatLaunchResult({
    required this.result,
    required this.playerHealth,
  });
}

/// Запуск боя из `StoryScreen`.
///
/// **Чистая логика запуска** — открывает `CombatScreen`, ждёт результат,
/// возвращает его в вызывающий код. Не управляет `StoryScreen` state'ом.
class StoryCombatLauncher {
  StoryCombatLauncher._();

  /// Запустить бой.
  ///
  /// Возвращает `CombatLaunchResult` или `null`, если игрок
  /// закрыл экран без результата (не должно случаться).
  static Future<CombatLaunchResult?> launch({
    required BuildContext context,
    required String characterName,
    required int playerHealth,
    required int enemyHealth,
    required String enemyName,
    required int enemyDamage,
    required int enemyProtection,
    required int enemyStrength,
    required Equipment equipment,
  }) async {
    final player = Combatant(
      name: characterName,
      health: playerHealth,
      maxHealth: 100,
      damage: equipment.totalDamage > 0 ? equipment.totalDamage : 3,
      protection: equipment.totalProtection,
      strength: 5,
      damageType: equipment.weaponDamageType,
      resistances: equipment.totalResistances,
    );

    final enemy = Combatant(
      name: enemyName,
      health: enemyHealth,
      maxHealth: enemyHealth,
      damage: enemyDamage,
      protection: enemyProtection,
      strength: enemyStrength,
    );

    final rawResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CombatScreen(player: player, enemy: enemy),
      ),
    );

    if (!context.mounted) return null;

    String result = 'defeat';
    int newHealth = player.health;

    if (rawResult is Map) {
      result = rawResult['result'] ?? 'defeat';
      newHealth = (rawResult['playerHealth'] as int? ?? player.health)
          .clamp(0, 100);
    } else if (rawResult is String) {
      result = rawResult;
      newHealth = player.health.clamp(0, 100);
    }

    return CombatLaunchResult(
      result: result,
      playerHealth: newHealth,
    );
  }
}