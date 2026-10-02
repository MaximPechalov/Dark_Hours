import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/models/inventory/equipment.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';

void main() {
  // Заглушки для тестов — не грузим JSON
  InventoryItem makeWeapon({
    required String id,
    required int damage,
    required String damageType,
  }) {
    return InventoryItem(
      id: id,
      name: id,
      icon: '⚔️',
      rarity: 'common',
      weight: 1.0,
      count: 1,
      sourceType: 'weapon',
      damage: damage,
      damageType: damageType,
    );
  }

  InventoryItem makeArmor({
    required String id,
    required String slot,
    required int protection,
    int warmth = 0,
    Map<String, int> resistances = const {},
  }) {
    return InventoryItem(
      id: id,
      name: id,
      icon: '🦺',
      rarity: 'common',
      weight: 1.0,
      count: 1,
      sourceType: 'armor',
      protection: protection,
      warmth: warmth,
      resistances: resistances,
      armorSlot: slot,
    );
  }

  group('Equipment.totalProtection', () {
    test('0 для пустой экипировки', () {
      final eq = Equipment();
      expect(eq.totalProtection, 0);
    });

    test('суммирует все слоты', () {
      final eq = Equipment();
      eq.body = makeArmor(id: 'body', slot: 'body', protection: 10);
      eq.head = makeArmor(id: 'head', slot: 'head', protection: 20);
      eq.hands = makeArmor(id: 'hands', slot: 'hands', protection: 5);
      eq.feet = makeArmor(id: 'feet', slot: 'feet', protection: 8);

      expect(eq.totalProtection, 43);
    });

    test('backpack и weapon не влияют на защиту', () {
      final eq = Equipment();
      eq.weapon = makeWeapon(id: 'w', damage: 50, damageType: 'blunt');
      eq.backpack = makeArmor(id: 'b', slot: 'backpack', protection: 0);

      expect(eq.totalProtection, 0);
    });
  });

  group('Equipment.totalWarmth', () {
    test('суммирует тепло', () {
      final eq = Equipment();
      eq.body = makeArmor(id: 'body', slot: 'body', protection: 0, warmth: 20);
      eq.head = makeArmor(id: 'head', slot: 'head', protection: 0, warmth: 6);

      expect(eq.totalWarmth, 26);
    });
  });

  group('Equipment.weaponDamageType', () {
    test('blunt для пустой экипировки (кулаки)', () {
      final eq = Equipment();
      expect(eq.weaponDamageType, 'blunt');
    });

    test('cutting для ножа', () {
      final eq = Equipment();
      eq.weapon = makeWeapon(id: 'kitchen_knife', damage: 12, damageType: 'cutting');
      expect(eq.weaponDamageType, 'cutting');
    });

    test('piercing для копья', () {
      final eq = Equipment();
      eq.weapon = makeWeapon(id: 'spear', damage: 24, damageType: 'piercing');
      expect(eq.weaponDamageType, 'piercing');
    });

    test('firearm для пистолета', () {
      final eq = Equipment();
      eq.weapon = makeWeapon(id: 'pistol', damage: 44, damageType: 'firearm');
      expect(eq.weaponDamageType, 'firearm');
    });

    test('blunt для топора', () {
      final eq = Equipment();
      eq.weapon = makeWeapon(id: 'axe', damage: 30, damageType: 'blunt');
      expect(eq.weaponDamageType, 'blunt');
    });
  });

  group('Equipment.totalResistances', () {
    test('0 для пустой экипировки', () {
      final eq = Equipment();
      final res = eq.totalResistances;
      expect(res['cutting'], 0);
      expect(res['blunt'], 0);
      expect(res['piercing'], 0);
      expect(res['firearm'], 0);
    });

    test('суммирует сопротивления', () {
      final eq = Equipment();
      eq.body = makeArmor(
        id: 'vest',
        slot: 'body',
        protection: 50,
        resistances: {'cutting': 20, 'blunt': 10, 'piercing': 40, 'firearm': 50},
      );

      final res = eq.totalResistances;
      expect(res['firearm'], 50);
      expect(res['piercing'], 40);
    });
  });

  group('Equipment.extraSlots', () {
    test('0 без рюкзака', () {
      final eq = Equipment();
      expect(eq.extraSlots, 0);
    });

    test('возвращает extraSlots из рюкзака', () {
      final eq = Equipment();
      eq.backpack = InventoryItem(
        id: 'army_backpack',
        name: 'Рюкзак',
        icon: '🎒',
        rarity: 'common',
        weight: 1.0,
        count: 1,
        sourceType: 'armor',
        armorSlot: 'backpack',
        extraSlots: 30,
      );
      expect(eq.extraSlots, 30);
    });
  });

  group('Equipment.equip / unequip', () {
    test('equip ставит предмет в нужный слот', () {
      final eq = Equipment();
      final jacket = makeArmor(id: 'jacket', slot: 'body', protection: 10);
      eq.equip(jacket, 'body');
      expect(eq.body, jacket);
    });

    test('unequip возвращает предмет и очищает слот', () {
      final eq = Equipment();
      final jacket = makeArmor(id: 'jacket', slot: 'body', protection: 10);
      eq.equip(jacket, 'body');

      final removed = eq.unequip('body');
      expect(removed, jacket);
      expect(eq.body, isNull);
    });

    test('unequip пустого слота возвращает null', () {
      final eq = Equipment();
      expect(eq.unequip('body'), isNull);
    });
  });

  group('Equipment.totalDamage', () {
    test('0 без оружия', () {
      final eq = Equipment();
      expect(eq.totalDamage, 0);
    });

    test('возвращает damage оружия', () {
      final eq = Equipment();
      eq.weapon = makeWeapon(id: 'axe', damage: 30, damageType: 'blunt');
      expect(eq.totalDamage, 30);
    });
  });
}