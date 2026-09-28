import 'dart:math';

/// Способность врага в бою
class CombatAbility {
  final String id;
  final String name;
  final String description;
  final double chance;
  final String effect; // skip_turn, poison, infection, bleeding

  const CombatAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.chance,
    required this.effect,
  });

  factory CombatAbility.fromJson(Map<String, dynamic> json) {
    return CombatAbility(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      chance: (json['chance'] as num).toDouble(),
      effect: json['effect'],
    );
  }
}

class Combatant {
  final String name;
  int health;
  int maxHealth;
  int damage;
  int protection;
  int strength;
  final String damageType;
  final Map<String, int> resistances;
  final List<CombatAbility> abilities;

  // Статус-эффекты
  int stunTurns = 0;
  int bleedTurns = 0;
  int poisonTurns = 0;
  bool isInfected = false;

  Combatant({
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.damage,
    required this.protection,
    required this.strength,
    this.damageType = 'blunt',
    this.resistances = const {},
    this.abilities = const [],
  });

  bool get isDead => health <= 0;
  bool get isStunned => stunTurns > 0;
  bool get isBleeding => bleedTurns > 0;
  bool get isPoisoned => poisonTurns > 0;

  /// Шанс крита
  double get critChance {
    final base = 0.10 + (strength - 5) * 0.02;
    return base.clamp(0.05, 0.35);
  }

  /// Урон с учётом типа, крита, сопротивлений
  int calculateDamage(Combatant target, {bool isCrit = false}) {
    int raw = damage;

    // Бонус от силы
    raw += (strength - 5) * 2;

    // Тип урона vs сопротивления цели
    final targetResist = target.resistances[damageType] ?? 0;
    raw = raw - targetResist;

    // Крит
    if (isCrit) raw = (raw * 1.8).round();

    // Общая защита
    raw -= target.protection;

    if (raw < 1) raw = 1;
    return raw;
  }

  void takeDamage(int dmg) {
    health = (health - dmg).clamp(0, maxHealth);
  }

  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }

  bool rollCrit() {
    return Random().nextDouble() < critChance;
  }

  CombatAbility? rollAbility() {
    if (abilities.isEmpty) return null;
    for (final ability in abilities) {
      if (Random().nextDouble() < ability.chance) {
        return ability;
      }
    }
    return null;
  }

  /// Тик статусов (в конце хода)
  /// Возвращает суммарный урон от статусов
  int tickStatusEffects() {
    int totalDamage = 0;

    if (bleedTurns > 0) {
      health = (health - 3).clamp(0, maxHealth);
      bleedTurns--;
      totalDamage += 3;
    }

    if (poisonTurns > 0) {
      health = (health - 2).clamp(0, maxHealth);
      poisonTurns--;
      totalDamage += 2;
    }

    return totalDamage;
  }

  void decrementStun() {
    if (stunTurns > 0) stunTurns--;
  }
}