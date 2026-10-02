import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/combat_manager.dart';
import 'package:dark_hours/services/items/item_loader.dart';
import 'package:dark_hours/services/items/search_event_loader.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/search_event.dart';
import 'package:dark_hours/widgets/effects/floating_effect.dart';
import 'package:dark_hours/constants/game_constants.dart';

/// Управляет обыском локаций.
///
/// Логика:
/// 1. Проверить, есть ли что искать.
/// 2. Списать стамину и усталость.
/// 3. Проверить risk локации (шанс заболеть).
/// 4. Если ещё есть "свежие" обыски — стандартный поиск (лут из пула).
/// 5. Если обыски кончились — случайное событие.
/// 6. Продвинуть время.
/// 7. Шанс встретить врага.
/// 8. Автосохранить.
class SearchManager {
  /// Обыскать текущую локацию.
  static Future<void> search(
    BuildContext context,
    MapController controller,
  ) async {
    final loc = controller.currentLocation;
    if (loc == null) return;

    // ─── 1. Проверка: есть ли что искать ───
    if (_nothingToSearch(loc)) {
      AudioService.playError();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Здесь нечего искать'),
            backgroundColor: Colors.grey,
          ),
        );
      }
      return;
    }

    AudioService.playClick();

    // ─── 2. Стоимость ───
    controller.setStamina(
      controller.stamina - GameConstants.searchStaminaCost,
    );
    controller.setFatigue(
      controller.fatigue + GameConstants.searchFatigueCost,
    );

    // ─── 3. Risk локации ───
    if (loc.risk != null) {
      await _applyLocationRisk(context, controller, loc);
    }

    // ─── 4-5. Стандартный поиск или событие ───
    final searched = controller.searchedCounts[loc.id] ?? 0;
    final hasRemainingLoot = searched < loc.maxSearches;

    if (hasRemainingLoot) {
      await _standardSearch(context, controller, loc);
    } else {
      await _eventSearch(context, controller, loc);
    }

    // ─── 6. Время ───
    await controller.advanceTime(loc.searchTime);

    // ─── 7. Шанс встретить врага ───
    if (hasRemainingLoot && loc.enemies.isNotEmpty && !loc.isFinal) {
      final enemyRoll = Random().nextInt(GameConstants.enemyEncounterChance);
      if (enemyRoll == 0) {
        await CombatManager.startCombat(
          context,
          controller,
          loc.enemies[0],
        );
        return;
      }
    }

    // ─── 8. Автосохранение ───
    await controller.save();

    controller.refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ МЕТОДЫ
  // ═══════════════════════════════════════════════════════════

  /// Проверить, есть ли что искать в локации
  static bool _nothingToSearch(Location loc) {
    return loc.maxSearches == 0 &&
        loc.lootPool.isEmpty &&
        loc.enemies.isEmpty &&
        loc.risk == null;
  }

  /// Применить риск локации (шанс заразиться)
  static Future<void> _applyLocationRisk(
    BuildContext context,
    MapController controller,
    Location loc,
  ) async {
    final newCond = ConditionManager.tryInfect(
      controller.allConditions,
      loc.risk!,
      GameConstants.locationRiskChance,
    );
    if (newCond == null) return;

    if (ConditionManager.hasCondition(
      controller.activeConditions,
      newCond.id,
    )) {
      return;
    }

    controller.addCondition(newCond);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newCond.icon} Ты подхватил: ${newCond.name}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// Стандартный поиск — берём случайный лут из пула
  static Future<void> _standardSearch(
    BuildContext context,
    MapController controller,
    Location loc,
  ) async {
    controller.incrementSearchCount(loc.id);

    if (loc.lootPool.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ничего не найдено'),
            backgroundColor: Colors.grey,
          ),
        );
      }
      return;
    }

    final foundItemId = loc.lootPool[Random().nextInt(loc.lootPool.length)];
    final item = ItemLoader.findById(foundItemId);
    if (item == null) return;

    if (!controller.addItem(item)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Рюкзак переполнен'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      AudioService.playSuccess();
      FloatingEffectOverlay.show(
        context,
        'Найдено: ${item.name}',
        color: const Color.fromARGB(255, 100, 180, 100),
        icon: Icons.search,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Найдено: ${item.icon} ${item.name}'),
          backgroundColor: const Color.fromARGB(255, 100, 180, 100),
        ),
      );
    }
  }

  /// Поиск события — когда стандартный пул исчерпан
  static Future<void> _eventSearch(
    BuildContext context,
    MapController controller,
    Location loc,
  ) async {
    final map = controller.map;
    if (map == null) return;

    final pool = SearchEventLoader.getPoolFor(
      locationEvents: loc.searchEvents,
    );

    final hiddenMap = SearchEventLoader.buildHiddenMap(map.locations);

    final event = _rollSearchEvent(
      pool: pool,
      currentLocationId: loc.id,
      hiddenMap: hiddenMap,
    );

    if (event == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ты обходишь ещё раз. Ничего нового.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
      return;
    }

    await _applySearchEvent(context, controller, event, loc);
  }

  /// Бросить случайное событие из пула
  static SearchEvent? _rollSearchEvent({
    required List<SearchEvent> pool,
    required String currentLocationId,
    required Map<String, String> hiddenMap,
  }) {
    final rng = Random();

    final applicable = pool.where((e) {
      return e.isApplicableTo(
        currentLocationId: currentLocationId,
        hiddenLocations: hiddenMap,
      );
    }).toList();

    double totalChance = 0.0;
    for (final e in applicable) {
      totalChance += e.chance;
    }

    final roll = rng.nextDouble() * (totalChance > 1.0 ? totalChance : 1.0);

    double cumulative = 0.0;
    for (final event in applicable) {
      cumulative += event.chance;
      if (roll < cumulative) {
        return event;
      }
    }

    return null;
  }

  /// Применить событие поиска
  static Future<void> _applySearchEvent(
    BuildContext context,
    MapController controller,
    SearchEvent event,
    Location loc,
  ) async {
    // Показать текст события
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(event.text),
          duration: const Duration(seconds: 4),
          backgroundColor: const Color.fromARGB(255, 40, 40, 60),
        ),
      );
    }

    final effect = event.effect;

    // ─── Статы ───
    _applyStatEffects(context, controller, effect);

    // ─── Случайный лут ───
    if (effect['random_loot'] != null) {
      await _applyRandomLoot(context, controller, effect);
    }

    // ─── Открытие локации ───
    if (effect['unlock_location'] != null) {
      await _applyUnlockLocation(context, controller, effect, loc);
    }

    // ─── Флаги ───
    if (effect['flag_set'] != null) {
      controller.setFlag(effect['flag_set'] as String);
    }

    // ─── Заражение ───
    if (effect['infect'] != null) {
      await _applyInfect(context, controller, effect);
    }

    // ─── Бой ───
    if (effect['combat_start'] != null) {
      await _applyCombatStart(context, controller, effect);
    }
  }

  static void _applyStatEffects(
    BuildContext context,
    MapController controller,
    Map<String, dynamic> effect,
  ) {
    final delta = <String, int>{};

    if (effect['health'] != null) {
      delta['health'] = effect['health'] as int;
    }
    if (effect['sanity'] != null) {
      delta['sanity'] = effect['sanity'] as int;
    }
    if (effect['hunger'] != null) {
      delta['hunger'] = effect['hunger'] as int;
    }
    if (effect['thirst'] != null) {
      delta['thirst'] = effect['thirst'] as int;
    }
    if (effect['stamina'] != null) {
      delta['stamina'] = effect['stamina'] as int;
    }
    if (effect['fatigue'] != null) {
      delta['fatigue'] = effect['fatigue'] as int;
    }

    if (delta.isEmpty) return;

    controller.applyStatDelta(delta);

    // Floating effect
    if (context.mounted) {
      if (delta['health'] != null) {
        FloatingEffectOverlay.show(
          context,
          '${delta['health']! > 0 ? '+' : ''}${delta['health']} ❤️',
          color: delta['health']! > 0 ? Colors.green : Colors.red,
          icon: Icons.favorite,
        );
      }
      if (delta['sanity'] != null) {
        FloatingEffectOverlay.show(
          context,
          '${delta['sanity']! > 0 ? '+' : ''}${delta['sanity']} 🧠',
          color: delta['sanity']! > 0 ? Colors.purple : Colors.red,
          icon: Icons.psychology,
        );
      }
    }
  }

  static Future<void> _applyRandomLoot(
    BuildContext context,
    MapController controller,
    Map<String, dynamic> effect,
  ) async {
    final lootIds = List<String>.from(effect['random_loot']);
    if (lootIds.isEmpty) return;

    final randomId = lootIds[Random().nextInt(lootIds.length)];
    final item = ItemLoader.findById(randomId);
    if (item == null) return;

    if (!controller.addItem(item)) return;

    if (context.mounted) {
      AudioService.playSuccess();
      FloatingEffectOverlay.show(
        context,
        'Найдено: ${item.name}',
        color: const Color.fromARGB(255, 100, 180, 100),
        icon: Icons.search,
      );
    }
  }

  static Future<void> _applyUnlockLocation(
    BuildContext context,
    MapController controller,
    Map<String, dynamic> effect,
    Location loc,
  ) async {
    final unlockValue = effect['unlock_location'];
    final map = controller.map;
    if (map == null) return;

    String? hiddenId;

    if (unlockValue == 'auto') {
      final hiddenMap = SearchEventLoader.buildHiddenMap(map.locations);
      hiddenId = hiddenMap[loc.id];
    } else if (unlockValue is String) {
      hiddenId = unlockValue;
    }

    if (hiddenId == null) return;
    if (controller.isLocationUnlocked(hiddenId)) return;

    controller.unlockLocation(hiddenId);

    final hidden = map.getById(hiddenId);
    if (hidden == null) return;

    if (context.mounted) {
      AudioService.playNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔓 Открыто новое место: ${hidden.name}'),
          duration: const Duration(seconds: 4),
          backgroundColor: const Color.fromARGB(255, 200, 180, 100),
        ),
      );
    }
  }

  static Future<void> _applyInfect(
    BuildContext context,
    MapController controller,
    Map<String, dynamic> effect,
  ) async {
    final infectData = effect['infect'] as Map<String, dynamic>;
    final source = infectData['source'] as String;
    final chance = (infectData['chance'] as num?)?.toDouble() ?? 0.5;

    final newCondition = ConditionManager.tryInfect(
      controller.allConditions,
      source,
      chance,
    );
    if (newCondition == null) return;

    if (ConditionManager.hasCondition(
      controller.activeConditions,
      newCondition.id,
    )) {
      return;
    }

    controller.addCondition(newCondition);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${newCondition.icon} Ты подхватил: ${newCondition.name}',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  static Future<void> _applyCombatStart(
    BuildContext context,
    MapController controller,
    Map<String, dynamic> effect,
  ) async {
    final combat = effect['combat_start'] as Map<String, dynamic>;
    final enemyName = combat['enemy_name'] as String? ?? 'Враг';
    final enemyHealth = combat['enemy_health'] as int? ?? 30;
    final enemyDamage = combat['enemy_damage'] as int? ?? 10;
    final enemyProtection = combat['enemy_protection'] as int? ?? 0;
    final enemyStrength = combat['enemy_strength'] as int? ?? 5;

    await CombatManager.startCombatWithParams(
      context,
      controller,
      enemyName: enemyName,
      enemyHealth: enemyHealth,
      enemyDamage: enemyDamage,
      enemyProtection: enemyProtection,
      enemyStrength: enemyStrength,
    );
  }
}