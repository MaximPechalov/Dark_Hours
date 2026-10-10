// test/services/map/rest_manager_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../_helpers/test_fixtures.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/models/time/rest_action.dart';
import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/rest_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/constants/game_constants.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AudioService.enabled = false;
  });

  tearDown(() {
    AudioService.enabled = true;
  });

  // ═══════════════════════════════════════════════════════════
  // ФИКСТУРЫ
  // ═══════════════════════════════════════════════════════════

  final safeLocation = Location(
    id: 'home',
    name: 'Дом',
    description: 'Твой дом',
    type: 'safe_house',
    region: 'city',
    dangerLevel: 0,
    searchTime: 30,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: conns([]),
    icon: '🏠',
    repeatable: true,
    isStart: true,
  );

  final dangerLocation = Location(
    id: 'street',
    name: 'Улица',
    description: 'Опасная улица',
    type: 'street',
    region: 'city',
    dangerLevel: 7,
    searchTime: 15,
    maxSearches: 3,
    lootPool: [],
    enemies: ['looter_common'],
    connections: conns(['home']),
    icon: '🛣️',
    repeatable: true,
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

  MapController makeController({
    String characterId = 'boris',
    List<Location>? locations,
    int startTimeMinutes = GameConstants.startTimeMinutes,
  }) {
    final c = MapController(
      characterId: characterId,
      characterName: characterId,
    );
    c.initForTest(
      locations: locations ?? [safeLocation],
      conditions: [coldCondition],
      startTimeMinutes: startTimeMinutes,
    );
    return c;
  }

  InventoryItem makeItem({
    required String id,
    double weight = 1.0,
  }) {
    return InventoryItem(
      id: id,
      name: id,
      icon: '📦',
      rarity: 'common',
      weight: weight,
      count: 1,
      sourceType: 'resource',
    );
  }

  Widget makeTestApp({
    required Future<void> Function(BuildContext context) onPressed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('TEST'),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // computeRestStats — базовые значения
  // ═══════════════════════════════════════════════════════════

  group('RestManager.computeRestStats — базовые значения', () {
    test('short_rest даёт базовые дельты без спальника, endurance 5', () {
      final c = makeController();
      c.setEndurance(5);

      final delta = RestManager.computeRestStats(c, RestAction.all[0]);

      expect(delta['stamina'], RestAction.all[0].staminaRestore);
      expect(delta['health'], RestAction.all[0].healthRestore);
      expect(delta['sanity'], RestAction.all[0].sanityRestore);
      expect(delta['fatigue'], -RestAction.all[0].fatigueReduce);
    });

    test('full_sleep даёт больше стамины, чем short_rest', () {
      final c = makeController();
      c.setEndurance(5);

      final shortDelta = RestManager.computeRestStats(c, RestAction.all[0]);
      final fullDelta = RestManager.computeRestStats(c, RestAction.all[2]);

      expect(fullDelta['stamina'], greaterThan(shortDelta['stamina']!));
    });

    test('fatigue всегда отрицательный (уменьшение)', () {
      final c = makeController();
      c.setEndurance(5);

      for (final action in RestAction.all) {
        final delta = RestManager.computeRestStats(c, action);
        expect(delta['fatigue'], lessThanOrEqualTo(0));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════
  // computeRestStats — бонус спальника
  // ═══════════════════════════════════════════════════════════

  group('RestManager.computeRestStats — бонус спальника', () {
    test('бонус +10 stamina и +10 sanity', () {
      final c = makeController();
      c.setEndurance(5);
      c.addItem(makeItem(id: 'sleeping_bag'));

      final withBag = RestManager.computeRestStats(c, RestAction.all[0]);

      expect(
        withBag['stamina'],
        RestAction.all[0].staminaRestore +
            GameConstants.sleepingBagStaminaBonus,
      );
      expect(
        withBag['sanity'],
        RestAction.all[0].sanityRestore +
            GameConstants.sleepingBagSanityBonus,
      );
    });

    test('без спальника бонуса нет', () {
      final c = makeController();
      c.setEndurance(5);

      final delta = RestManager.computeRestStats(c, RestAction.all[1]);

      expect(delta['stamina'], RestAction.all[1].staminaRestore);
      expect(delta['sanity'], RestAction.all[1].sanityRestore);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // computeRestStats — бонус endurance
  // ═══════════════════════════════════════════════════════════

  group('RestManager.computeRestStats — бонус endurance', () {
    test('Алина (endurance 9) восстанавливает больше стамины, чем Иван (3)',
        () {
      final alina = makeController(characterId: 'alina');
      final ivan = makeController(characterId: 'ivan');

      expect(alina.endurance, 9);
      expect(ivan.endurance, 3);

      final alinaDelta = RestManager.computeRestStats(alina, RestAction.all[1]);
      final ivanDelta = RestManager.computeRestStats(ivan, RestAction.all[1]);

      expect(alinaDelta['stamina'], greaterThan(ivanDelta['stamina']!));
    });

    test('endurance 5 (baseStat) — бонус 0', () {
      final c = makeController();
      c.setEndurance(5);

      final delta = RestManager.computeRestStats(c, RestAction.all[1]);

      expect(delta['stamina'], RestAction.all[1].staminaRestore);
    });

    test('endurance 10 — бонус +10 к стамине', () {
      final c = makeController();
      c.setEndurance(10);

      final delta = RestManager.computeRestStats(c, RestAction.all[1]);

      expect(
        delta['stamina'],
        RestAction.all[1].staminaRestore +
            GameConstants.enduranceRestBonusMax,
      );
    });

    test('endurance 1 — штраф -6 к стамине', () {
      final c = makeController();
      c.setEndurance(1);

      final delta = RestManager.computeRestStats(c, RestAction.all[1]);

      expect(
        delta['stamina'],
        RestAction.all[1].staminaRestore +
            GameConstants.enduranceRestBonusMin,
      );
    });

    test('спальник + endurance стакаются', () {
      final c = makeController(characterId: 'alina');
      c.addItem(makeItem(id: 'sleeping_bag'));

      final delta = RestManager.computeRestStats(c, RestAction.all[2]);

      final expected = RestAction.all[2].staminaRestore +
          GameConstants.sleepingBagStaminaBonus +
          GameConstants.enduranceRestBonus(9);

      expect(delta['stamina'], expected);
    });

    test('endurance НЕ влияет на health и sanity', () {
      final c = makeController();
      c.setEndurance(10);

      final delta = RestManager.computeRestStats(c, RestAction.all[1]);

      expect(delta['health'], RestAction.all[1].healthRestore);
      expect(delta['sanity'], RestAction.all[1].sanityRestore);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // rollCold
  // ═══════════════════════════════════════════════════════════

  group('RestManager.rollCold', () {
    test('chance = coldChanceHigh при отсутствии тёплой одежды', () {
      final c = makeController();
      final result = RestManager.rollCold(c);
      expect(result.chance, GameConstants.coldChanceHigh);
    });

    test('chance = coldChanceLow при тёплой одежде', () {
      final c = makeController();

      final coat = InventoryItem(
        id: 'winter_coat',
        name: 'Зимнее пальто',
        icon: '🧥',
        rarity: 'uncommon',
        weight: 3.5,
        count: 1,
        sourceType: 'armor',
        armorSlot: 'body',
        warmth: 60,
      );
      c.addItem(coat);
      c.equipItem(coat, 'body');

      final result = RestManager.rollCold(c);
      expect(result.chance, GameConstants.coldChanceLow);
    });

    test('при 100 бросках хотя бы раз infected = true (chance > 0)', () {
      final c = makeController();
      bool anyInfected = false;
      for (int i = 0; i < 100; i++) {
        if (RestManager.rollCold(c).infected) {
          anyInfected = true;
          break;
        }
      }
      expect(anyInfected, true);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // rollTheft
  // ═══════════════════════════════════════════════════════════

  group('RestManager.rollTheft', () {
    test('stolen = false, если инвентарь пуст', () {
      final c = makeController();
      expect(c.inventory.items.isEmpty, true);

      final result = RestManager.rollTheft(c);
      expect(result.stolen, false);
    });

    test('chance = restTheftChance', () {
      final c = makeController();
      c.addItem(makeItem(id: 'bandage'));

      final result = RestManager.rollTheft(c);
      expect(result.chance, GameConstants.restTheftChance);
    });

    test('itemsToLose = 1', () {
      final c = makeController();
      c.addItem(makeItem(id: 'bandage'));

      final result = RestManager.rollTheft(c);
      expect(result.itemsToLose, 1);
    });

    test('при 100 бросках хотя бы раз stolen = true', () {
      final c = makeController();
      c.addItem(makeItem(id: 'bandage'));

      bool anyStolen = false;
      for (int i = 0; i < 100; i++) {
        if (RestManager.rollTheft(c).stolen) {
          anyStolen = true;
          break;
        }
      }
      expect(anyStolen, true);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // rollAttack
  // ═══════════════════════════════════════════════════════════

  group('RestManager.rollAttack', () {
    test('при 100 бросках хотя бы раз true', () {
      final c = makeController();
      bool anyAttack = false;
      for (int i = 0; i < 100; i++) {
        if (RestManager.rollAttack(c)) {
          anyAttack = true;
          break;
        }
      }
      expect(anyAttack, true);
    });

    test('шанс атаки > 0 даже утром (round, не toInt)', () {
      // Утро (8:00) — dangerMultiplier = 0.8
      // 20 * 0.8 = 16 → округлится до 16, не до 0
      final c = makeController(
        startTimeMinutes: 8 * 60,
      );
      bool anyAttack = false;
      for (int i = 0; i < 200; i++) {
        if (RestManager.rollAttack(c)) {
          anyAttack = true;
          break;
        }
      }
      expect(anyAttack, true);
    });

    test('ночью шанс выше, чем днём (за 500 бросков)', () {
      final dayC = makeController(startTimeMinutes: 12 * 60);
      final nightC = makeController(startTimeMinutes: 23 * 60);

      int dayAttacks = 0;
      int nightAttacks = 0;
      for (int i = 0; i < 500; i++) {
        if (RestManager.rollAttack(dayC)) dayAttacks++;
        if (RestManager.rollAttack(nightC)) nightAttacks++;
      }

      expect(nightAttacks, greaterThan(dayAttacks));
    });

    test('не падает в разное время суток', () {
      for (final hour in [6, 10, 14, 18, 22, 2]) {
        final c = makeController(startTimeMinutes: hour * 60);
        expect(() => RestManager.rollAttack(c), returnsNormally);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════
  // rest — widget-тесты
  // ═══════════════════════════════════════════════════════════

  group('RestManager.rest — widget', () {
    testWidgets('short_rest восстанавливает стамину с учётом endurance',
        (tester) async {
      // Борис: endurance 6 → enduranceRestBonus(6) = +2
      // stamina до = 20, short_rest = +20, endurance = +2 → 42
      final c = makeController();
      c.setStamina(20);
      final enduranceBonus = GameConstants.enduranceRestBonus(c.endurance);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              RestManager.rest(context, c, RestAction.all[0]),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      final expected = (20 + RestAction.all[0].staminaRestore + enduranceBonus)
          .clamp(0, 100);

      expect(c.stamina, expected);
    });

    testWidgets('short_rest с endurance 5 даёт чистое значение', (tester) async {
      final c = makeController();
      c.setEndurance(5);
      c.setStamina(20);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              RestManager.rest(context, c, RestAction.all[0]),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.stamina, 20 + RestAction.all[0].staminaRestore);
    });

    testWidgets('short_rest продвигает время', (tester) async {
      final c = makeController();
      final timeBefore = c.gameTime.totalMinutes;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              RestManager.rest(context, c, RestAction.all[0]),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(
        c.gameTime.totalMinutes,
        timeBefore + RestAction.all[0].timeMinutes,
      );
    });

    testWidgets('rest уменьшает усталость', (tester) async {
      final c = makeController();
      c.setFatigue(50);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              RestManager.rest(context, c, RestAction.all[1]),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.fatigue, lessThan(50));
    });

    testWidgets('rest в безопасной локации не даёт простуды', (tester) async {
      final c = makeController(locations: [safeLocation]);
      c.setFatigue(0);
      c.setHealth(100);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              RestManager.rest(context, c, RestAction.all[2]),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(
        c.activeConditions.any((ac) => ac.condition.id == 'cold'),
        false,
      );
    });

    testWidgets('rest в опасной локации не падает', (tester) async {
      final c = makeController(locations: [dangerLocation]);
      c.addItem(makeItem(id: 'bandage'));
      c.setFatigue(0);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              RestManager.rest(context, c, RestAction.all[3]),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(true, true);
    });
  });
}