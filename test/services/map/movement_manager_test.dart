import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dark_hours/models/world/location.dart';
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

  const homeLocation = Location(
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
    connections: ['street'],
    icon: '🏠',
    repeatable: true,
    isStart: true,
  );

  const streetLocation = Location(
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
    connections: ['home'],
    icon: '🛣️',
    repeatable: true,
  );

  const hiddenLocation = Location(
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
    connections: ['street'],
    icon: '🔓',
    repeatable: true,
    hidden: true,
    unlockedBy: 'street',
  );

  MapController makeController({List<Location>? locations}) {
    final c = MapController(
      characterId: 'boris',
      characterName: 'Борис',
    );
    c.initForTest(
      locations: locations ?? const [homeLocation, streetLocation],
    );
    return c;
  }

  /// Хелпер: тестовый widget с Scaffold.
  ///
  /// `onPressed` получает настоящий `BuildContext`, который
  /// можно передать в менеджер.
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
  // validateMove — ЧИСТАЯ ЛОГИКА (без UI)
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
      final c = makeController(
        locations: const [homeLocation, streetLocation, hiddenLocation],
      );
      final result = MovementManager.validateMove(c, 'secret');
      expect(result, MoveResult.hidden);
    });

    test('success для скрытой ОТКРЫТОЙ локации', () {
      final c = makeController(
        locations: const [homeLocation, streetLocation, hiddenLocation],
      );
      c.unlockLocation('secret');
      final result = MovementManager.validateMove(c, 'secret');
      expect(result, MoveResult.success);
    });

    test('noMap если карта не загружена', () {
      final c = MapController(characterId: 'boris', characterName: 'Борис');
      final result = MovementManager.validateMove(c, 'street');
      expect(result, MoveResult.noMap);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // move — WIDGET-ТЕСТЫ
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

    testWidgets('move списывает стамину', (tester) async {
      final c = makeController();
      final staminaBefore = c.stamina;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => MovementManager.move(context, c, 'street'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(
        c.stamina,
        staminaBefore - GameConstants.moveStaminaCost,
      );
    });

    testWidgets('move продвигает время', (tester) async {
      final c = makeController();
      final timeBefore = c.gameTime.totalMinutes;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => MovementManager.move(context, c, 'street'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(
        c.gameTime.totalMinutes,
        timeBefore + GameConstants.moveTimeMinutes,
      );
    });

    testWidgets('move возвращает false для несуществующей локации',
        (tester) async {
      final c = makeController();

      bool? result;
      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) async {
            result =
                await MovementManager.move(context, c, 'nonexistent');
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
      final c = makeController(
        locations: const [homeLocation, streetLocation, hiddenLocation],
      );

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
  });
}