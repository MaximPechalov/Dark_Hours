import 'package:flutter/foundation.dart';
import 'package:dark_hours/models/combat/enemy.dart';
import 'package:dark_hours/models/combat/combat.dart';

/// Загрузчик врагов.
///
/// Инициализируется один раз при старте MapScreen.
/// После этого `findById` работает синхронно — враги в кэше.
class EnemyLoader {
  static List<Enemy> _enemies = [];
  static bool _loaded = false;

  /// Загрузить врагов из JSON (один раз)
  static Future<void> init() async {
    if (_loaded) return;
    _enemies = await Enemy.loadAll();
    _loaded = true;
    debugPrint('⚔️ EnemyLoader: загружено ${_enemies.length} врагов');
  }

  /// Найти врага по ID
  static Enemy? findById(String id) {
    try {
      return _enemies.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Получить список врагов по категории
  /// category: human, animal
  static List<Enemy> byCategory(String category) {
    return _enemies.where((e) => e.category == category).toList();
  }

  /// Получить всех врагов
  static List<Enemy> get all => _enemies;

  /// Создать Combatant из Enemy для боя
  ///
  /// Это «мост» между двумя моделями:
  /// - Enemy — данные из JSON (статичные статы)
  /// - Combatant — боевая модель (мутабельное здоровье, статус-эффекты)
  ///
  /// `abilities` уже имеют тип `CombatAbility`, поэтому просто передаём.
  static Combatant toCombatant(Enemy enemy) {
    return Combatant(
      name: enemy.name,
      health: enemy.health,
      maxHealth: enemy.health,
      damage: enemy.damage,
      protection: enemy.protection,
      strength: enemy.strength,
      damageType: enemy.damageType,
      abilities: enemy.abilities,
    );
  }
}