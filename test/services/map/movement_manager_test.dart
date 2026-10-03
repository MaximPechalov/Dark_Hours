import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/connection.dart';
import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/movement_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

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

  MapController makeController() {
    final c = MapController(
      characterId: 'boris',
      characterName: 'Борис',
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
      // far_place соединён только со street, но не с home.
      // Из home нельзя попасть в far_place.
      final c = makeController();
      // Перейдём в street
      c.map!.moveTo('street');
      final result = MovementManager.validateMove(c, 'far_place');
      expect(result, MoveResult.success); // street → far_place есть

      // А из home — нельзя.
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
  // computeStaminaCost
  // ═══════════════════════════════════════════════════════════

  group('MovementManager.computeStaminaCost', () {
    test('минимум 2 стамины (для коротких переходов)', () {
      expect(MovementManager.computeStaminaCost(5), 2);
      expect(MovementManager.computeStaminaCost(10), 2);
    });

    test('15 минут → 2 стамины', () {
      expect(MovementManager.computeStaminaCost(15), 2);
    });

    test('60 минут → 6 стамины', () {
      expect(MovementManager.computeStaminaCost(60), 6);
    });

    test('120 минут → 12 стамины', () {
      expect(MovementManager.computeStaminaCost(120), 12);
    });

    test('максимум 20 стамины', () {
      expect(MovementManager.computeStaminaCost(500), 20);
      expect(MovementManager.computeStaminaCost(1000), 20);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // move — widget
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

    testWidgets('move продвигает время на Connection.minutes', (tester) async {
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

    testWidgets('move тратит стамину через computeStaminaCost', (tester) async {
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

      // 15 минут → 2 стамины
      expect(c.stamina, staminaBefore - 2);
    });

    testWidgets('долгий переход тратит больше стамины', (tester) async {
      final c = makeController();
      // Перейдём в street, потом в far_place (90 мин)
      c.map!.moveTo('street');
      c.setStamina(80);
      final staminaBefore = c.stamina;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => MovementManager.move(context, c, 'far_place'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      // 90 минут → 9 стамины
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
      // Перейдём в street, потом в far_place
      c.map!.moveTo('street');

      // far_place — не сосед home, но сосед street.
      // При initForTest он разведан (сосед street).
      // Проверим — после перехода far_place становится visited и scouted.
      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => MovementManager.move(context, c, 'far_place'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.currentLocation!.id, 'far_place');
      expect(c.isScouted('far_place'), true);
    });
  });
}