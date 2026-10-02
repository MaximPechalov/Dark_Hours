import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/models/combat/combat.dart';

void main() {
  Combatant makeCombatant({
    int health = 100,
    int maxHealth = 100,
    int damage = 10,
    int protection = 0,
    int strength = 5,
    String damageType = 'blunt',
    Map<String, int> resistances = const {},
  }) {
    return Combatant(
      name: 'Тест',
      health: health,
      maxHealth: maxHealth,
      damage: damage,
      protection: protection,
      strength: strength,
      damageType: damageType,
      resistances: resistances,
    );
  }

  group('Combatant.calculateDamage', () {
    test('минимальный урон 1', () {
      final strong = makeCombatant(damage: 1);
      final tanky = makeCombatant(protection: 100);
      expect(strong.calculateDamage(tanky), 1);
    });

    test('крит увеличивает урон', () {
      final attacker = makeCombatant(damage: 20);
      final target = makeCombatant();

      final normal = attacker.calculateDamage(target, isCrit: false);
      final crit = attacker.calculateDamage(target, isCrit: true);

      expect(crit, greaterThan(normal));
    });

    test('protection вычитается из урона', () {
      final attacker = makeCombatant(damage: 30);
      final target = makeCombatant(protection: 10);

      final dmg = attacker.calculateDamage(target);
      // 30 + бонус от силы (5-5=0) - 10 protection = 20
      expect(dmg, 20);
    });

    test('сопротивления вычитаются', () {
      final attacker = makeCombatant(damage: 30, damageType: 'firearm');
      final target = makeCombatant(
        protection: 0,
        resistances: {'firearm': 20},
      );

      final dmg = attacker.calculateDamage(target);
      // 30 - 20 = 10
      expect(dmg, 10);
    });

    test('бонус от высокой силы', () {
      final weak = makeCombatant(damage: 10, strength: 5);
      final strong = makeCombatant(damage: 10, strength: 8);

      final weakDmg = weak.calculateDamage(makeCombatant());
      final strongDmg = strong.calculateDamage(makeCombatant());

      // strong: (8-5)*2 = +6 урона
      expect(strongDmg, greaterThan(weakDmg));
    });
  });

  group('Combatant.takeDamage / heal', () {
    test('takeDamage уменьшает health', () {
      final c = makeCombatant(health: 100);
      c.takeDamage(30);
      expect(c.health, 70);
    });

    test('health не опускается ниже 0', () {
      final c = makeCombatant(health: 10);
      c.takeDamage(50);
      expect(c.health, 0);
    });

    test('heal восстанавливает health', () {
      final c = makeCombatant(health: 50);
      c.heal(20);
      expect(c.health, 70);
    });

    test('health не выше maxHealth', () {
      final c = makeCombatant(health: 90, maxHealth: 100);
      c.heal(50);
      expect(c.health, 100);
    });
  });

  group('Combatant.isDead', () {
    test('false при health > 0', () {
      final c = makeCombatant(health: 1);
      expect(c.isDead, false);
    });

    test('true при health = 0', () {
      final c = makeCombatant(health: 0);
      expect(c.isDead, true);
    });
  });

  group('Combatant.critChance', () {
    test('в диапазоне 0.05 - 0.35', () {
      for (int strength = 1; strength <= 10; strength++) {
        final c = makeCombatant(strength: strength);
        expect(c.critChance, greaterThanOrEqualTo(0.05));
        expect(c.critChance, lessThanOrEqualTo(0.35));
      }
    });

    test('выше у сильного персонажа', () {
      final weak = makeCombatant(strength: 3);
      final strong = makeCombatant(strength: 9);
      expect(strong.critChance, greaterThan(weak.critChance));
    });
  });

  group('Combatant статус-эффекты', () {
    test('isStunned при stunTurns > 0', () {
      final c = makeCombatant();
      expect(c.isStunned, false);
      c.stunTurns = 1;
      expect(c.isStunned, true);
    });

    test('tickStatusEffects уменьшает bleedTurns', () {
      final c = makeCombatant();
      c.bleedTurns = 3;
      c.tickStatusEffects();
      expect(c.bleedTurns, 2);
    });

    test('tickStatusEffects наносит урон от кровотечения', () {
      final c = makeCombatant(health: 100);
      c.bleedTurns = 3;
      final dmg = c.tickStatusEffects();
      // Кровотечение: -3 HP за ход
      expect(dmg, 3);
      expect(c.health, 97);
    });

    test('tickStatusEffects наносит урон от яда', () {
      final c = makeCombatant(health: 100);
      c.poisonTurns = 2;
      final dmg = c.tickStatusEffects();
      // Яд: -2 HP за ход
      expect(dmg, 2);
      expect(c.health, 98);
    });
  });
}