import 'package:flutter_test/flutter_test.dart';
import '../../_helpers/test_fixtures.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/services/map/map_controller.dart';

void main() {
  // ═══════════════════════════════════════════════════════════
  // ФИКСТУРЫ
  // ═══════════════════════════════════════════════════════════

  final homeLocation = Location(
    id: 'home',
    name: 'Дом',
    description: 'Твой дом',
    type: 'safe_house',
    region: 'city',
    dangerLevel: 0,
    searchTime: 30,
    maxSearches: 3,
    lootPool: ['canned_stew'],
    enemies: [],
    connections: conns(['street']),
    icon: '🏠',
    repeatable: true,
    isStart: true,
  );

  final streetLocation = Location(
    id: 'street',
    name: 'Улица',
    description: 'Пустая улица',
    type: 'street',
    region: 'city',
    dangerLevel: 3,
    searchTime: 15,
    maxSearches: 3,
    lootPool: ['bandage'],
    enemies: [],
    connections: conns(['home']),
    icon: '🛣️',
    repeatable: true,
  );

  /// Локация из другого региона — не должна попасть в scouted.
  final forestLocation = Location(
    id: 'forest',
    name: 'Лес',
    description: 'Лес',
    type: 'forest',
    region: 'forest',
    dangerLevel: 2,
    searchTime: 20,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: conns(['home']),
    icon: '🌲',
    repeatable: true,
  );

  /// Скрытая локация — не должна попасть в scouted при старте.
  final hiddenLocation = Location(
    id: 'secret',
    name: 'Секрет',
    description: 'Скрытая',
    type: 'hidden',
    region: 'city',
    dangerLevel: 3,
    searchTime: 30,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: conns(['home']),
    icon: '🔓',
    repeatable: true,
    hidden: true,
    unlockedBy: 'home',
  );

  const infectionCondition = Condition(
    id: 'infection',
    name: 'Инфекция',
    description: 'Рана заражена',
    icon: '🦠',
    severity: 'medium',
    effectsPerTurn: {'health': -3},
    cureItems: ['antibiotic_pill'],
    cureChance: 0.9,
    durationDays: 5,
    source: ['combat_wound'],
  );

  const coldCondition = Condition(
    id: 'cold',
    name: 'Простуда',
    description: 'Промок',
    icon: '🤧',
    severity: 'low',
    effectsPerTurn: {'health': -1},
    cureItems: ['herb_medkit'],
    cureChance: 0.8,
    durationDays: 4,
    source: ['cold_weather'],
  );

  /// Создать контроллер с ручными локациями
  MapController makeController({
    String characterId = 'boris',
    String characterName = 'Борис',
    List<Location>? locations,
    List<Condition>? conditions,
  }) {
    final controller = MapController(
      characterId: characterId,
      characterName: characterName,
    );
    controller.initForTest(
      locations: locations ?? [homeLocation, streetLocation],
      conditions: conditions ?? [infectionCondition, coldCondition],
    );
    return controller;
  }

  /// Создать простой предмет для тестов
  InventoryItem makeItem({
    String id = 'test_item',
    double weight = 1.0,
    int count = 1,
    String sourceType = 'consumable',
    int hungerRestore = 0,
    int thirstRestore = 0,
    int healthRestore = 0,
    int sanityRestore = 0,
  }) {
    return InventoryItem(
      id: id,
      name: id,
      icon: '📦',
      rarity: 'common',
      weight: weight,
      count: count,
      sourceType: sourceType,
      hungerRestore: hungerRestore,
      thirstRestore: thirstRestore,
      healthRestore: healthRestore,
      sanityRestore: sanityRestore,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ИНИЦИАЛИЗАЦИЯ
  // ═══════════════════════════════════════════════════════════

  group('MapController.initForTest', () {
    test('создаёт карту с двумя локациями', () {
      final c = makeController();
      expect(c.map, isNotNull);
      expect(c.map!.locations.length, 2);
    });

    test('устанавливает стартовую локацию (isStart: true)', () {
      final c = makeController();
      expect(c.currentLocation, isNotNull);
      expect(c.currentLocation!.id, 'home');
    });

    test('устанавливает isLoading = false', () {
      final c = makeController();
      expect(c.isLoading, false);
    });

    test('загружает переданные условия', () {
      final c = makeController();
      expect(c.allConditions.length, 2);
      expect(
        c.allConditions.map((x) => x.id).toSet(),
        {'infection', 'cold'},
      );
    });

    test('устанавливает характеристики персонажа из GameConstants', () {
      final c = makeController(characterId: 'boris');
      expect(c.intelligence, 5);
      expect(c.strength, 7);
    });

    test('кидает ArgumentError для пустого списка локаций', () {
      final c = MapController(characterId: 'boris', characterName: 'Борис');
      expect(
        () => c.initForTest(locations: []),
        throwsArgumentError,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════
  // НОВАЯ ЛОГИКА РАЗВЕДКИ
  // ═══════════════════════════════════════════════════════════

  group('MapController — авторазведка при старте', () {
    test('все локации стартового региона — scouted', () {
      final c = makeController();
      expect(c.isScouted('home'), true);
      expect(c.isScouted('street'), true);
    });

    test('скрытые локации НЕ попадают в scouted при старте', () {
      final c = makeController(
        locations: [homeLocation, streetLocation, hiddenLocation],
      );
      expect(c.isScouted('home'), true);
      expect(c.isScouted('street'), true);
      expect(c.isScouted('secret'), false);
    });

    test('локации другого региона НЕ попадают в scouted при старте', () {
      final c = makeController(
        locations: [homeLocation, streetLocation, forestLocation],
      );
      expect(c.isScouted('home'), true);
      expect(c.isScouted('street'), true);
      expect(c.isScouted('forest'), false);
    });

    test('detailedLocations пуст при старте', () {
      final c = makeController();
      expect(c.detailedLocations, isEmpty);
    });

    test('hasDetails возвращает false при старте', () {
      final c = makeController();
      expect(c.hasDetails('home'), false);
      expect(c.hasDetails('street'), false);
    });

    test('стартовый регион добавляется в discoveredRegions', () {
      final c = makeController();
      expect(c.isRegionDiscovered('city'), true);
    });
  });

  group('MapController.scoutLocation', () {
    test('добавляет новую локацию в scouted', () {
      final c = makeController(
        locations: [homeLocation, streetLocation, forestLocation],
      );
      expect(c.isScouted('forest'), false);

      c.scoutLocation('forest');

      expect(c.isScouted('forest'), true);
    });

    test('не дублирует уже разведанные локации', () {
      final c = makeController();
      final countBefore = c.scoutedLocations.length;
      c.scoutLocation('home');
      expect(c.scoutedLocations.length, countBefore);
    });

    test('разведывает регион локации', () {
      final c = makeController(
        locations: [homeLocation, streetLocation, forestLocation],
      );
      expect(c.isRegionDiscovered('forest'), false);

      c.scoutLocation('forest');

      expect(c.isRegionDiscovered('forest'), true);
    });
  });

  group('MapController.scoutDetails', () {
    test('возвращает true для scouted-локации', () {
      final c = makeController();
      expect(c.isScouted('street'), true);

      final ok = c.scoutDetails('street');

      expect(ok, true);
      expect(c.hasDetails('street'), true);
    });

    test('возвращает false для локации НЕ в scouted', () {
      final c = makeController(
        locations: [homeLocation, streetLocation, hiddenLocation],
      );
      expect(c.isScouted('secret'), false);

      final ok = c.scoutDetails('secret');

      expect(ok, false);
      expect(c.hasDetails('secret'), false);
    });

    test('возвращает false при повторной разведке', () {
      final c = makeController();

      final first = c.scoutDetails('street');
      final second = c.scoutDetails('street');

      expect(first, true);
      expect(second, false);
    });

    test('добавляет локацию в detailedLocations', () {
      final c = makeController();
      expect(c.detailedLocations.contains('street'), false);

      c.scoutDetails('street');

      expect(c.detailedLocations.contains('street'), true);
    });

    test('вызывает notifyListeners при успехе', () {
      final c = makeController();
      int notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.scoutDetails('street');

      expect(notifyCount, greaterThan(0));
    });

    test('НЕ вызывает notifyListeners при повторной разведке', () {
      final c = makeController();
      c.scoutDetails('street'); // первый раз

      int notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.scoutDetails('street'); // второй раз — не должно

      expect(notifyCount, 0);
    });
  });

  group('MapController.hasDetails', () {
    test('false для неразведанной локации', () {
      final c = makeController();
      expect(c.hasDetails('street'), false);
    });

    test('true после scoutDetails', () {
      final c = makeController();
      c.scoutDetails('street');
      expect(c.hasDetails('street'), true);
    });

    test('false для несуществующей локации', () {
      final c = makeController();
      expect(c.hasDetails('nonexistent'), false);
    });
  });

  group('MapController.setDetailed — тестовый хелпер', () {
    test('устанавливает detailedLocations', () {
      final c = makeController();
      c.setDetailed({'street', 'home'});
      expect(c.hasDetails('street'), true);
      expect(c.hasDetails('home'), true);
    });

    test('очищает предыдущие значения', () {
      final c = makeController();
      c.scoutDetails('street');
      expect(c.hasDetails('street'), true);

      c.setDetailed({'home'});

      expect(c.hasDetails('street'), false);
      expect(c.hasDetails('home'), true);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // STAT DELTAS
  // ═══════════════════════════════════════════════════════════

  group('MapController.applyStatDelta', () {
    test('уменьшает health в пределах 0..100', () {
      final c = makeController();
      c.setHealth(50);
      c.applyStatDelta({'health': -30});
      expect(c.health, 20);
    });

    test('не опускает health ниже 0', () {
      final c = makeController();
      c.setHealth(10);
      c.applyStatDelta({'health': -100});
      expect(c.health, 0);
    });

    test('не поднимает health выше 100', () {
      final c = makeController();
      c.setHealth(90);
      c.applyStatDelta({'health': 50});
      expect(c.health, 100);
    });

    test('применяет сразу несколько статов', () {
      final c = makeController();
      c.setHealth(50);
      c.setHunger(50);
      c.setThirst(50);
      c.applyStatDelta({
        'health': -10,
        'hunger': -20,
        'thirst': 15,
      });
      expect(c.health, 40);
      expect(c.hunger, 30);
      expect(c.thirst, 65);
    });

    test('не трогает статы, которых нет в delta', () {
      final c = makeController();
      c.setHealth(50);
      c.setHunger(50);
      c.applyStatDelta({'health': -10});
      expect(c.health, 40);
      expect(c.hunger, 50);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // SET-МЕТОДЫ
  // ═══════════════════════════════════════════════════════════

  group('MapController.setXxx', () {
    test('setHealth клампит значение', () {
      final c = makeController();
      c.setHealth(150);
      expect(c.health, 100);
      c.setHealth(-50);
      expect(c.health, 0);
    });

    test('setFatigue клампит значение', () {
      final c = makeController();
      c.setFatigue(200);
      expect(c.fatigue, 100);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ADVANCE TIME
  // ═══════════════════════════════════════════════════════════

  group('MapController.advanceTime', () {
    test('увеличивает totalMinutes', () async {
      final c = makeController();
      final before = c.gameTime.totalMinutes;
      await c.advanceTime(60);
      expect(c.gameTime.totalMinutes, before + 60);
    });

    test('уменьшает голод и жажду', () async {
      final c = makeController();
      c.setHunger(100);
      c.setThirst(100);
      await c.advanceTime(600);
      expect(c.hunger, lessThan(100));
      expect(c.thirst, lessThan(100));
    });

    test('увеличивает усталость при бодрствовании', () async {
      final c = makeController();
      c.setFatigue(0);
      await c.advanceTime(600);
      expect(c.fatigue, greaterThan(0));
    });

    test('не увеличивает усталость при isSleeping: true', () async {
      final c = makeController();
      c.setFatigue(0);
      await c.advanceTime(600, isSleeping: true);
      expect(c.fatigue, 0);
    });

    test('тик активных условий снижает health', () async {
      final c = makeController();
      c.setHealth(100);
      c.addCondition(infectionCondition);
      await c.advanceTime(60);
      expect(c.health, lessThan(100));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // УСЛОВИЯ
  // ═══════════════════════════════════════════════════════════

  group('MapController.addCondition', () {
    test('добавляет новое условие', () {
      final c = makeController();
      expect(c.activeConditions.length, 0);
      c.addCondition(infectionCondition);
      expect(c.activeConditions.length, 1);
      expect(c.activeConditions.first.condition.id, 'infection');
    });

    test('не добавляет дубликат того же условия', () {
      final c = makeController();
      c.addCondition(infectionCondition);
      c.addCondition(infectionCondition);
      expect(c.activeConditions.length, 1);
    });

    test('увеличивает tracker.infections', () {
      final c = makeController();
      final before = c.tracker.infections;
      c.addCondition(infectionCondition);
      expect(c.tracker.infections, before + 1);
    });

    test('устанавливает daysRemaining = durationDays', () {
      final c = makeController();
      c.addCondition(infectionCondition);
      expect(c.activeConditions.first.daysRemaining, 5);
    });
  });

  group('MapController.tryCureCondition', () {
    test('возвращает false для неподходящего предмета', () {
      final c = makeController();
      c.addCondition(infectionCondition);
      final ac = c.activeConditions.first;
      final cured = c.tryCureCondition(ac, 'bandage');
      expect(cured, false);
      expect(c.activeConditions.length, 1);
    });

    test('возвращает true для подходящего (cureChance = 1.0)', () {
      const guaranteedCure = Condition(
        id: 'bleeding',
        name: 'Кровотечение',
        description: 'Кровь',
        icon: '🩸',
        severity: 'critical',
        effectsPerTurn: {'health': -8},
        cureItems: ['bandage'],
        cureChance: 1.0,
        durationDays: 1,
        source: ['combat_wound'],
      );

      final c = makeController(
        conditions: [guaranteedCure],
      );
      c.addCondition(guaranteedCure);
      final ac = c.activeConditions.first;
      final cured = c.tryCureCondition(ac, 'bandage');
      expect(cured, true);
      expect(c.activeConditions.length, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ИНВЕНТАРЬ
  // ═══════════════════════════════════════════════════════════

  group('MapController.addItem', () {
    test('добавляет предмет в инвентарь', () {
      final c = makeController();
      final ok = c.addItem(makeItem(id: 'bandage'));
      expect(ok, true);
      expect(c.inventory.hasItem('bandage'), true);
    });

    test('увеличивает tracker.lootedCount', () {
      final c = makeController();
      final before = c.tracker.lootedCount;
      c.addItem(makeItem(id: 'bandage'));
      expect(c.tracker.lootedCount, before + 1);
    });

    test('обновляет tracker.maxInventorySize', () {
      final c = makeController();
      final before = c.tracker.maxInventorySize;
      c.addItem(makeItem(id: 'a'));
      c.addItem(makeItem(id: 'b'));
      c.addItem(makeItem(id: 'c'));
      expect(c.tracker.maxInventorySize, greaterThan(before));
    });
  });

  group('MapController.removeItem / removeAll', () {
    test('removeItem уменьшает count', () {
      final c = makeController();
      c.addItem(makeItem(id: 'bandage', count: 3));
      c.removeItem('bandage');
      expect(c.inventory.countOf('bandage'), 2);
    });

    test('removeAll удаляет полностью', () {
      final c = makeController();
      c.addItem(makeItem(id: 'bandage', count: 3));
      c.removeAll('bandage');
      expect(c.inventory.hasItem('bandage'), false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ЭКИПИРОВКА
  // ═══════════════════════════════════════════════════════════

  group('MapController.equipItem / unequipItem', () {
    test('equipItem переносит предмет из инвентаря в слот', () {
      final c = makeController();
      final weapon = makeItem(
        id: 'knife',
        sourceType: 'weapon',
      );
      c.addItem(weapon);
      expect(c.inventory.hasItem('knife'), true);

      c.equipItem(weapon, 'weapon');
      expect(c.equipment.weapon, isNotNull);
      expect(c.equipment.weapon!.id, 'knife');
      expect(c.inventory.hasItem('knife'), false);
    });

    test('equipItem возвращает старое оружие в инвентарь', () {
      final c = makeController();
      final oldWeapon = makeItem(id: 'old_knife', sourceType: 'weapon');
      final newWeapon = makeItem(id: 'new_knife', sourceType: 'weapon');

      c.addItem(oldWeapon);
      c.equipItem(oldWeapon, 'weapon');

      c.addItem(newWeapon);
      c.equipItem(newWeapon, 'weapon');

      expect(c.equipment.weapon!.id, 'new_knife');
      expect(c.inventory.hasItem('old_knife'), true);
    });

    test('unequipItem возвращает предмет в инвентарь', () {
      final c = makeController();
      final weapon = makeItem(id: 'knife', sourceType: 'weapon');
      c.addItem(weapon);
      c.equipItem(weapon, 'weapon');

      c.unequipItem('weapon');
      expect(c.equipment.weapon, isNull);
      expect(c.inventory.hasItem('knife'), true);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // LOSE ITEMS
  // ═══════════════════════════════════════════════════════════

  group('MapController.loseRandomItems', () {
    test('теряет ровно N предметов, если их столько есть', () {
      final c = makeController();
      c.addItem(makeItem(id: 'a'));
      c.addItem(makeItem(id: 'b'));
      c.addItem(makeItem(id: 'c'));
      expect(c.inventory.items.length, 3);

      c.loseRandomItems(2);
      expect(c.inventory.items.length, 1);
    });

    test('не падает, если инвентарь пуст', () {
      final c = makeController();
      expect(() => c.loseRandomItems(5), returnsNormally);
      expect(c.inventory.items.length, 0);
    });

    test('теряет всё, если count больше размера', () {
      final c = makeController();
      c.addItem(makeItem(id: 'a'));
      c.addItem(makeItem(id: 'b'));
      c.loseRandomItems(10);
      expect(c.inventory.items.length, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // СМЕРТЬ
  // ═══════════════════════════════════════════════════════════

  group('MapController.markDead / clearDeath', () {
    test('markDead устанавливает isDead = true и reason', () {
      final c = makeController();
      expect(c.isDead, false);
      c.markDead('Умер от голода');
      expect(c.isDead, true);
      expect(c.deathReason, 'Умер от голода');
    });

    test('clearDeath сбрасывает флаги', () {
      final c = makeController();
      c.markDead('Причина');
      c.clearDeath();
      expect(c.isDead, false);
      expect(c.deathReason, '');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ФЛАГИ И ЛОКАЦИИ
  // ═══════════════════════════════════════════════════════════

  group('MapController flags / locations', () {
    test('setFlag добавляет флаг', () {
      final c = makeController();
      c.setFlag('test_flag');
      expect(c.hasFlag('test_flag'), true);
    });

    test('unlockLocation добавляет локацию в открытые + scouted', () {
      final c = makeController(
        locations: [homeLocation, streetLocation, hiddenLocation],
      );
      expect(c.isLocationUnlocked('secret'), false);
      expect(c.isScouted('secret'), false);

      c.unlockLocation('secret');

      expect(c.isLocationUnlocked('secret'), true);
      expect(c.isScouted('secret'), true);
    });

    test('incrementSearchCount увеличивает счётчик', () {
      final c = makeController();
      expect(c.searchedCounts['home'], isNull);
      c.incrementSearchCount('home');
      c.incrementSearchCount('home');
      expect(c.searchedCounts['home'], 2);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // NOTIFY LISTENERS
  // ═══════════════════════════════════════════════════════════

  group('MapController.refresh', () {
    test('refresh вызывает notifyListeners', () {
      final c = makeController();
      int notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.refresh();
      c.refresh();
      c.refresh();

      expect(notifyCount, 3);
    });

    test('applyStatDelta вызывает notifyListeners', () {
      final c = makeController();
      int notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.applyStatDelta({'health': -5});
      expect(notifyCount, greaterThan(0));
    });

    test('setFlag вызывает notifyListeners', () {
      final c = makeController();
      int notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.setFlag('x');
      expect(notifyCount, 1);
    });

    test('scoutDetails вызывает notifyListeners при успехе', () {
      final c = makeController();
      int notifyCount = 0;
      c.addListener(() => notifyCount++);

      c.scoutDetails('street');
      expect(notifyCount, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // КОМПЛЕКСНЫЕ ПРОВЕРКИ
  // ═══════════════════════════════════════════════════════════

  group('MapController — комплексные проверки', () {
    test('после initForTest готов к использованию', () {
      final c = makeController();
      expect(c.isLoading, false);
      expect(c.map, isNotNull);
      expect(c.currentLocation, isNotNull);
      expect(c.gameTime.day, 1);
      expect(c.hunger, 100);
      expect(c.thirst, 100);
      expect(c.health, 100);
    });

    test('gameTime доступно сразу после initForTest', () {
      final c = makeController();
      expect(c.gameTime.totalMinutes, 480);
      expect(c.gameTime.day, 1);
    });

    test('контроллер принимает кастомное startTimeMinutes', () {
      final c = MapController(characterId: 'boris', characterName: 'Борис');
      c.initForTest(
        locations: [homeLocation, streetLocation],
        startTimeMinutes: 600,
      );
      expect(c.gameTime.totalMinutes, 600);
    });

    test('полный цикл: старт → разведка деталей → hasDetails', () {
      final c = makeController();

      // Старт: все локации scouted, но без деталей.
      expect(c.isScouted('street'), true);
      expect(c.hasDetails('street'), false);

      // Разведка деталей.
      final ok = c.scoutDetails('street');

      // Проверка.
      expect(ok, true);
      expect(c.hasDetails('street'), true);
      expect(c.detailedLocations.length, 1);
    });
  });
}