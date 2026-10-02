import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/services/items/item_loader.dart';

void main() {
  setUpAll(() async {
    // Нужно для работы rootBundle в тестах
    TestWidgetsFlutterBinding.ensureInitialized();
    await ItemLoader.init();
  });

  group('ItemLoader.findById — оружие', () {
    test('находит нож', () {
      final knife = ItemLoader.findById('kitchen_knife');
      expect(knife, isNotNull);
      expect(knife!.name, 'Кухонный нож');
      expect(knife.sourceType, 'weapon');
      expect(knife.damage, 12);
      expect(knife.damageType, 'cutting');
    });

    test('находит топор', () {
      final axe = ItemLoader.findById('axe');
      expect(axe, isNotNull);
      expect(axe!.sourceType, 'weapon');
      expect(axe.damage, 30);
      expect(axe.damageType, 'blunt');
    });

    test('находит пистолет', () {
      final pistol = ItemLoader.findById('pistol');
      expect(pistol, isNotNull);
      expect(pistol!.damage, 44);
      expect(pistol.damageType, 'firearm');
    });
  });

  group('ItemLoader.findById — броня', () {
    test('находит кожаную куртку', () {
      final jacket = ItemLoader.findById('leather_jacket');
      expect(jacket, isNotNull);
      expect(jacket!.sourceType, 'armor');
      expect(jacket.protection, 10);
      expect(jacket.warmth, 20);
      expect(jacket.armorSlot, 'body');
    });

    test('находит бронежилет с сопротивлениями', () {
      final vest = ItemLoader.findById('kevlar_vest');
      expect(vest, isNotNull);
      expect(vest!.protection, 50);
      expect(vest.resistances['firearm'], 50);
      expect(vest.resistances['piercing'], 40);
    });

    test('находит рюкзак с extraSlots', () {
      final backpack = ItemLoader.findById('army_backpack');
      expect(backpack, isNotNull);
      expect(backpack!.sourceType, 'armor');
      expect(backpack.extraSlots, 30);
    });
  });

  group('ItemLoader.findById — расходники', () {
    test('находит воду', () {
      final water = ItemLoader.findById('water_bottle');
      expect(water, isNotNull);
      expect(water!.sourceType, 'consumable');
      expect(water.thirstRestore, 40);
    });

    test('находит аптечку (tool)', () {
      // first_aid_kit определён в tools.json — это инструмент,
      // хотя и используется как медикамент.
      final kit = ItemLoader.findById('first_aid_kit');
      expect(kit, isNotNull);
      expect(kit!.sourceType, 'tool');
    });

    test('находит тушёнку', () {
      final stew = ItemLoader.findById('canned_stew');
      expect(stew, isNotNull);
      expect(stew!.hungerRestore, 40);
    });
  });

  group('ItemLoader.findById — инструменты', () {
    test('находит фонарик', () {
      final flashlight = ItemLoader.findById('flashlight');
      expect(flashlight, isNotNull);
      expect(flashlight!.sourceType, 'tool');
    });

    test('находит отмычки', () {
      final lockpick = ItemLoader.findById('lock_pick');
      expect(lockpick, isNotNull);
      expect(lockpick!.sourceType, 'tool');
    });
  });

  group('ItemLoader.findById — ресурсы', () {
    test('находит дрова', () {
      final wood = ItemLoader.findById('wood');
      expect(wood, isNotNull);
      expect(wood!.sourceType, 'resource');
    });

    test('находит свисток', () {
      final whistle = ItemLoader.findById('whistle');
      expect(whistle, isNotNull);
      expect(whistle!.sourceType, 'resource');
      expect(whistle.name, 'Свисток');
    });

    test('находит ключ-карту', () {
      final keycard = ItemLoader.findById('keycard');
      expect(keycard, isNotNull);
      expect(keycard!.sourceType, 'resource');
      expect(keycard.name, 'Ключ-карта');
    });
  });

  group('ItemLoader.findById — ошибки', () {
    test('возвращает null для несуществующего предмета', () {
      expect(ItemLoader.findById('nonexistent_item'), isNull);
    });

    test('возвращает null для пустой строки', () {
      expect(ItemLoader.findById(''), isNull);
    });
  });

  group('ItemLoader — counts', () {
    test('загружено больше 0 оружия', () {
      expect(ItemLoader.allWeapons.length, greaterThan(0));
    });

    test('загружено больше 0 брони', () {
      expect(ItemLoader.allArmor.length, greaterThan(0));
    });

    test('загружено больше 0 расходников', () {
      expect(ItemLoader.allConsumables.length, greaterThan(0));
    });
  });
}