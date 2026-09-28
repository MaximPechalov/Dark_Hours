import 'dart:math';
import '../models/condition.dart';
import '../models/active_condition.dart';
import '../models/inventory.dart';

class ConditionManager {
  static final Random _rng = Random();

  /// Попытаться заразить игрока
  /// Возвращает Condition, если заражение удалось, иначе null
  static Condition? tryInfect(
    List<Condition> allConditions,
    String source,
    double chance,
  ) {
    if (_rng.nextDouble() > chance) return null;

    // Ищем подходящую болезнь по источнику
    final candidates =
        allConditions.where((c) => c.source.contains(source)).toList();
    if (candidates.isEmpty) return null;

    return candidates[_rng.nextInt(candidates.length)];
  }

  /// Применить все активные болезни на конец хода
  /// Возвращает Map с изменениями: health, hunger, thirst, stamina, sanity
  static Map<String, int> applyEffects(List<ActiveCondition> active) {
    final deltas = <String, int>{};

    for (final ac in active) {
      ac.condition.effectsPerTurn.forEach((key, value) {
        deltas[key] = (deltas[key] ?? 0) + value;
      });
    }

    return deltas;
  }

  /// Попробовать вылечить болезнь предметом
  /// Возвращает true, если лечение успешно
  static bool tryCure(
    ActiveCondition ac,
    String itemId,
  ) {
    if (!ac.condition.cureItems.contains(itemId)) return false;
    if (_rng.nextDouble() > ac.condition.cureChance) return false;
    return true;
  }

  /// Проверить, есть ли уже такая болезнь
  static bool hasCondition(
    List<ActiveCondition> active,
    String conditionId,
  ) {
    return active.any((ac) => ac.condition.id == conditionId);
  }

  /// Уменьшить дни и удалить вылеченные
  static List<ActiveCondition> tickDay(List<ActiveCondition> active) {
    final result = <ActiveCondition>[];
    for (final ac in active) {
      ac.daysRemaining -= 1;
      if (ac.daysRemaining > 0) {
        result.add(ac);
      }
    }
    return result;
  }
}