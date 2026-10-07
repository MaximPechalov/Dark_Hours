import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/models/conditions/active_condition.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/services/items/item_loader.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';

/// Результат применения эффектов.
class EffectsResult {
  final Map<String, int> statDelta;
  final List<String> itemsToAdd;
  final List<String> itemsToRemove;
  final Set<String> flagsToSet;
  final List<Condition> newConditions;

  const EffectsResult({
    this.statDelta = const {},
    this.itemsToAdd = const [],
    this.itemsToRemove = const [],
    this.flagsToSet = const {},
    this.newConditions = const [],
  });
}

/// Применение эффектов из сюжета.
///
/// **Чистая логика** — не знает про `StoryScreen` и `BuildContext`.
/// Только анализирует `Map<String, dynamic>` из JSON и возвращает результат.
class StoryEffects {
  StoryEffects._();

  /// Применить эффекты из JSON.
  ///
  /// Не изменяет ничего напрямую — только собирает `EffectsResult`.
  static EffectsResult apply({
    required Map<String, dynamic>? effects,
    required List<Condition> allConditions,
    required List<ActiveCondition> activeConditions,
  }) {
    if (effects == null) return const EffectsResult();

    final statDelta = <String, int>{};
    final itemsToAdd = <String>[];
    final itemsToRemove = <String>[];
    final flagsToSet = <String>{};
    final newConditions = <Condition>[];

    // === Статы ===
    for (final key in [
      'hunger', 'thirst', 'health', 'sanity', 'stamina',
      'fatigue', 'time',
    ]) {
      final value = effects[key];
      if (value is int && value != 0) {
        statDelta[key] = value;
      }
    }

    // === Предметы: добавить ===
    if (effects['inventory_add'] != null) {
      final list = effects['inventory_add'] as List;
      for (final id in list) {
        itemsToAdd.add(id as String);
      }
    }

    // === Предметы: удалить ===
    if (effects['inventory_remove'] != null) {
      final list = effects['inventory_remove'] as List;
      for (final id in list) {
        itemsToRemove.add(id as String);
      }
    }

    // === Флаги ===
    if (effects['flag_set'] != null) {
      flagsToSet.add(effects['flag_set'] as String);
    }

    // === Инфекция ===
    if (effects['infect'] != null) {
      final infectData = effects['infect'] as Map<String, dynamic>;
      final source = infectData['source'] as String;
      final chance = (infectData['chance'] as num?)?.toDouble() ?? 0.5;

      final newCondition = ConditionManager.tryInfect(
        allConditions,
        source,
        chance,
      );

      if (newCondition != null &&
          !ConditionManager.hasCondition(
              activeConditions, newCondition.id)) {
        newConditions.add(newCondition);
      }
    }

    return EffectsResult(
      statDelta: statDelta,
      itemsToAdd: itemsToAdd,
      itemsToRemove: itemsToRemove,
      flagsToSet: flagsToSet,
      newConditions: newConditions,
    );
  }

  /// Применить тик активных условий.
  static Map<String, int> applyConditionsTick(
    List<ActiveCondition> activeConditions,
  ) {
    if (activeConditions.isEmpty) return const {};
    return ConditionManager.applyEffects(activeConditions);
  }

  /// Разрешить ID предмета в `InventoryItem`.
  static InventoryItem? resolveItem(String id) {
    return ItemLoader.findById(id);
  }
}