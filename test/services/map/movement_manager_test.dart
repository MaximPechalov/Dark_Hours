// test/services/map/movement_manager_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/connection.dart';
import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/movement_manager.dart';
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

  final homeLocation = Location(
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
    connections: const [
      Connection(targetId: 'street', minutes: 15),
      Connection(targetId: 'secret', minutes: 30),
    ],
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
    lootPool: [],
    enemies: [],
    connections: const [
      Connection(targetId: 'home', minutes: 15),
      Connection(targetId: 'far_place', minutes: 90),
    ],
    icon: '🛣️',
    repeatable: true,
  );

  final farLocation = Location(
    id: 'far_place',
    name: 'Далёкое место',
    description: 'Далеко',
    type: 'street',
    region: 'far',
    dangerLevel: 4,
    searchTime: 20,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: const [
      Connection(targetId: 'street', minutes: 90),
    ],
    icon: '🏚️',
    repeatable: true,
  );

  final hiddenLocation = Location(
    id: 'secret',
    name: 'Секретное место',
    description: 'Скрытая локация',
    type: 'hidden',
    region: 'city',
    dangerLevel: 5,
    searchTime: 30,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: const [
      Connection(targetId: 'home', minutes: 30),
    ],
    icon: '🔓',
    repeatable: true,
    hidden: true,
    unlockedBy: 'home',
  );

  MapController makeController({String characterId = 'boris'}) {
    final c = MapController(
      characterId: characterId,
      characterName: characterId,
    );
    c.initForTest(
      locations: [homeLocation, streetLocation, farLocation, hiddenLocation],
    );
    return c;
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
  // validateMove
  // ═══════════════════════════════════════════════════════════

  group('MovementManager.validateMove', () {
    test('success для существующей доступной локации', () {
      final c = makeController();
      final result = MovementManager.validateMove(c, 'street');
      expect(result, MoveResult.success);
    });

    test('notFound для несуществующей локации', () {
      final c = makeController();
      final result = MovementManager.validateMove(c, 'nonexistent');
      expect(result, MoveResult.notFound);
    });

    test('hidden для скрытой неоткрытой локации', () {
      final c = makeController();
      final result = MovementManager.validateMove(c, 'secret');
      expect(result, MoveResult.hidden);
    });

    test('success для скрытой ОТКРЫТОЙ локации', () {
      final c = makeController();
      c.unlockLocation('secret');
      final result = MovementManager.validateMove(c, 'secret');
      expect(result, MoveResult.success);
    });

    test('notConnected для несоединённой локации', () {
      final c = makeController();
      c.map!.moveTo('street');
      final result = MovementManager.validateMove(c, 'far_place');
      expect(result, MoveResult.success);

      c.map!.moveTo('home');
      final result2 = MovementManager.validateMove(c, 'far_place');
      expect(result2, MoveResult.notConnected);
    });

    test('noMap если карта не загружена', () {
      final c = MapController(characterId: 'boris', characterName: 'Борис');
      final result = MovementManager.validateMove(c, 'street');
      expect(result, MoveResult.noMap);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // computeStaminaCost — базовая стоимость (endurance = 5)
  // ═══════════════════════════════════════════════════════════

  group('MovementManager.computeStaminaCost — базовая стоимость', () {
    // endurance = 5 (baseStat) → множитель 1.0, чистая база.
    const base = GameConstants.baseStat;

    test('минимум 2 стамины для очень коротких переходов', () {
      expect(MovementManager.computeStaminaCost(5, base), 2);
      expect(MovementManager.computeStaminaCost(10, base), 2);
    });

    test('15 минут → 2 стамины', () {
      expect(MovementManager.computeStaminaCost(15, base), 2);
    });

    test('60 минут → 6 стамины', () {
      expect(MovementManager.computeStaminaCost(60, base), 6);
    });

    test('120 минут → 12 стамины', () {
      expect(MovementManager.computeStaminaCost(120, base), 12);
    });

    test('максимум 20 стамины (кламп)', () {
      expect(MovementManager.computeStaminaCost(500, base), 20);
      expect(MovementManager.computeStaminaCost(1000, base), 20);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // computeStaminaCost — влияние endurance
  // ═══════════════════════════════════════════════════════════

  group('MovementManager.computeStaminaCost — влияние endurance', () {
    test('endurance 9 (Алина) — дешевле базовой стоимости', () {
      // 60 мин → база 6, множитель для endurance 9 = 0.80 → 4.8 → 5
      final cost = MovementManager.computeStaminaCost(60, 9);
      final baseCost = MovementManager.computeStaminaCost(60, 5);

      expect(cost, lessThan(baseCost));
      expect(cost, 5);
    });

    test('endurance 3 (Иван) — дороже базовой стоимости', () {
      // 60 мин → база 6, множитель для endurance 3 = 1.10 → 6.6 → 7
      final cost = MovementManager.computeStaminaCost(60, 3);
      final baseCost = MovementManager.computeStaminaCost(60, 5);

      expect(cost, greaterThan(baseCost));
      expect(cost, 7);
    });

    test('endurance 10 — скидка 25%', () {
      // 60 мин → база 6, множитель 0.75 → 4.5 → 5
      final cost = MovementManager.computeStaminaCost(60, 10);
      expect(cost, 5);
    });

    test('endurance 1 — максимальный штраф 20%', () {
      // 60 мин → база 6, множитель 1.20 → 7.2 → 7
      final cost = MovementManager.computeStaminaCost(60, 1);
      expect(cost, 7);
    });

    test('endurance 6 (Борис) — почти база, округляется вверх', () {
      // 60 мин → база 6, множитель 0.95 → 5.7 → 6
      final cost = MovementManager.computeStaminaCost(60, 6);
      expect(cost, 6);
    });

    test('минимум 1 стамина даже при endurance 10', () {
      // 5 минут → база 2, множитель 0.75 → 1.5 → 2
      final cost = MovementManager.computeStaminaCost(5, 10);
      expect(cost, greaterThanOrEqualTo(1));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // СРАВНЕНИЕ ПЕРСОНАЖЕЙ
  // ═══════════════════════════════════════════════════════════

  group('MovementManager — сравнение персонажей', () {
    test('Алина (endurance 9) тратит меньше стамины, чем Борис (6)', () {
      final alina = makeController(characterId: 'alina');
      final boris = makeController(characterId: 'boris');

      expect(alina.endurance, 9);
      expect(boris.endurance, 6);

      final alinaCost =
          MovementManager.computeStaminaCost(60, alina.endurance);
      final borisCost =
          MovementManager.computeStaminaCost(60, boris.endurance);

      expect(alinaCost, lessThan(borisCost));
      expect(alinaCost, 5);
      expect(borisCost, 6);
    });

    test('Иван (endurance 3) тратит больше стамины, чем Борис (6)', () {
      final ivan = makeController(characterId: 'ivan');
      final boris = makeController(characterId: 'boris');

      expect(ivan.endurance, 3);
      expect(boris.endurance, 6);

      final ivanCost =
          MovementManager.computeStaminaCost(60, ivan.endurance);
      final borisCost =
          MovementManager.computeStaminaCost(60, boris.endurance);

      expect(ivanCost, greaterThan(borisCost));
      expect(ivanCost, 7);
      expect(borisCost, 6);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // move — widget-тесты
  // ═══════════════════════════════════════════════════════════

  group('MovementManager.move — widget', () {
    testWidgets('success переход меняет локацию', (tester) async {
      final c = makeController();
      expect(c.currentLocation!.id, 'home');

      bool? result;
      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) async {
            result = await MovementManager.move(context, c, 'street');
          },
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(result, true);
      expect(c.currentLocation!.id, 'street');
    });

    testWidgets('move продвигает время на Connection.minutes',
        (tester) async {
      final c = makeController();
      final timeBefore = c.gameTime.totalMinutes;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => MovementManager.move(context, c, 'street'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.gameTime.totalMinutes, timeBefore + 15);
    });

    testWidgets('move тратит стамину через computeStaminaCost с endurance',
        (tester) async {
      // boris: endurance 6 → множитель 0.95
      // 15 мин → база 2 → 2 * 0.95 = 1.9 → 2
      final c = makeController();
      c.setStamina(80);
      final staminaBefore = c.stamina;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => MovementManager.move(context, c, 'street'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.stamina, staminaBefore - 2);
    });

    testWidgets('долгий переход тратит больше стамины', (tester) async {
      // boris: endurance 6 → множитель 0.95
      // 90 мин → база 9 → 9 * 0.95 = 8.55 → 9
      final c = makeController();
      c.map!.moveTo('street');
      c.setStamina(80);
      final staminaBefore = c.stamina;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              MovementManager.move(context, c, 'far_place'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.stamina, staminaBefore - 9);
    });

    testWidgets('move возвращает false для несуществующей локации',
        (tester) async {
      final c = makeController();

      bool? result;
      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) async {
            result = await MovementManager.move(context, c, 'nonexistent');
          },
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(result, false);
      expect(c.currentLocation!.id, 'home');
    });

    testWidgets('move возвращает false для скрытой неоткрытой локации',
        (tester) async {
      final c = makeController();

      bool? result;
      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) async {
            result = await MovementManager.move(context, c, 'secret');
          },
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(result, false);
      expect(c.currentLocation!.id, 'home');
    });

    testWidgets('move авто-разведывает НОВУЮ локацию (далёкую)',
        (tester) async {
      final c = makeController();
      c.map!.moveTo('street');

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              MovementManager.move(context, c, 'far_place'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.currentLocation!.id, 'far_place');
      expect(c.isScouted('far_place'), true);
    });
  });
}