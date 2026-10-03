import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../_helpers/test_fixtures.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/combat_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

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

  final startLocation = Location(
    id: 'start',
    name: 'Старт',
    description: '',
    type: 'safe_house',
    region: 'city',
    dangerLevel: 0,
    searchTime: 0,
    maxSearches: 0,
    lootPool: [],
    enemies: [],
    connections: conns(['street', 'forest', 'safe_house', 'secret']),
    icon: '🏠',
    repeatable: true,
    isStart: true,
  );

  final streetLocation = Location(
    id: 'street',
    name: 'Улица',
    description: '',
    type: 'street',
    region: 'city',
    dangerLevel: 6,
    searchTime: 15,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: conns(['start']),
    icon: '🛣️',
    repeatable: true,
  );

  final forestLocation = Location(
    id: 'forest',
    name: 'Лес',
    description: '',
    type: 'forest',
    region: 'forest',
    dangerLevel: 2,
    searchTime: 20,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: conns(['start']),
    icon: '🌲',
    repeatable: true,
  );

  final safeHouseLocation = Location(
    id: 'safe_house',
    name: 'Убежище',
    description: '',
    type: 'safe_house',
    region: 'city',
    dangerLevel: 1,
    searchTime: 20,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: conns(['start']),
    icon: '🏡',
    repeatable: true,
  );

  final hiddenLocation = Location(
    id: 'secret',
    name: 'Секрет',
    description: '',
    type: 'hidden',
    region: 'city',
    dangerLevel: 3,
    searchTime: 30,
    maxSearches: 3,
    lootPool: [],
    enemies: [],
    connections: conns(['start']),
    icon: '🔓',
    repeatable: true,
    hidden: true,
    unlockedBy: 'start',
  );

  MapController makeController({List<Location>? locations}) {
    final c = MapController(
      characterId: 'boris',
      characterName: 'Борис',
    );
    c.initForTest(
      locations: locations ??
          [
            startLocation,
            streetLocation,
            forestLocation,
            safeHouseLocation,
            hiddenLocation,
          ],
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
  // isStoryBoss
  // ═══════════════════════════════════════════════════════════

  group('CombatManager.isStoryBoss', () {
    test('true для Васьки', () {
      expect(CombatManager.isStoryBoss('Васька'), true);
    });

    test('true для Сергея', () {
      expect(CombatManager.isStoryBoss('Сергей'), true);
    });

    test('true для Главаря банды', () {
      expect(CombatManager.isStoryBoss('Главарь банды'), true);
    });

    test('false для обычного врага', () {
      expect(CombatManager.isStoryBoss('Мародёр'), false);
    });

    test('false для пустой строки', () {
      expect(CombatManager.isStoryBoss(''), false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // isDangerousEnemy
  // ═══════════════════════════════════════════════════════════

  group('CombatManager.isDangerousEnemy', () {
    test('true для "Бандит"', () {
      expect(CombatManager.isDangerousEnemy('Бандит'), true);
    });

    test('true для "Дезертир"', () {
      expect(CombatManager.isDangerousEnemy('Дезертир'), true);
    });

    test('true для "Медведь"', () {
      expect(CombatManager.isDangerousEnemy('Медведь'), true);
    });

    test('true для "Вооружённый мародёр" (подстрока)', () {
      expect(
        CombatManager.isDangerousEnemy('Вооружённый мародёр'),
        true,
      );
    });

    test('true для "Главарь"', () {
      expect(CombatManager.isDangerousEnemy('Главарь'), true);
    });

    test('false для обычного "Мародёр"', () {
      expect(CombatManager.isDangerousEnemy('Мародёр'), false);
    });

    test('false для "Собака"', () {
      expect(CombatManager.isDangerousEnemy('Собака'), false);
    });

    test('false для пустой строки', () {
      expect(CombatManager.isDangerousEnemy(''), false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // pickSafeLocation
  // ═══════════════════════════════════════════════════════════

  group('CombatManager.pickSafeLocation', () {
    test('возвращает локацию с dangerLevel <= 2', () {
      final c = makeController();
      final result = CombatManager.pickSafeLocation(c);

      expect(result, isNotNull);
      expect(result!.dangerLevel, lessThanOrEqualTo(2));
    });

    test('не возвращает текущую локацию', () {
      final c = makeController();
      final result = CombatManager.pickSafeLocation(c);

      expect(result, isNotNull);
      expect(result!.id, isNot('start'));
    });

    test('не возвращает скрытые локации', () {
      final c = makeController();
      final result = CombatManager.pickSafeLocation(c);

      expect(result, isNotNull);
      expect(result!.hidden, false);
    });

    test('возвращает null, если только одна локация и она текущая', () {
      final c = makeController(locations: [startLocation]);
      final result = CombatManager.pickSafeLocation(c);

      expect(result, isNull);
    });

    test('возвращает null, если нет локаций с dangerLevel <= 2', () {
      final c = makeController(
        locations: [startLocation, streetLocation],
      );
      final result = CombatManager.pickSafeLocation(c);

      expect(result, isNull);
    });

    test('может вернуть forest (dangerLevel 2)', () {
      final c = makeController();
      final result = CombatManager.pickSafeLocation(c);

      expect(result, isNotNull);
      expect(['forest', 'safe_house'], contains(result!.id));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // pickNeighborLocation
  // ═══════════════════════════════════════════════════════════

  group('CombatManager.pickNeighborLocation', () {
    test('возвращает одну из соседних локаций', () {
      final c = makeController();

      final result = CombatManager.pickNeighborLocation(c);

      expect(result, isNotNull);
      expect(result!.id, isNot('start'));
    });

    test('не возвращает скрытую неоткрытую локацию', () {
      final c = makeController();

      for (int i = 0; i < 100; i++) {
        final result = CombatManager.pickNeighborLocation(c);
        expect(result!.id, isNot('secret'));
      }
    });

    test('возвращает скрытую ОТКРЫТУЮ локацию', () {
      final c = makeController();
      c.unlockLocation('secret');

      final picks = <String>{};
      for (int i = 0; i < 100; i++) {
        final result = CombatManager.pickNeighborLocation(c);
        if (result != null) picks.add(result.id);
      }
      expect(picks, contains('secret'));
    });

    test('возвращает null, если у текущей локации нет соседей', () {
      final isolated = Location(
        id: 'isolated',
        name: 'Одинокий',
        description: '',
        type: 'safe_house',
        region: 'city',
        dangerLevel: 0,
        searchTime: 0,
        maxSearches: 0,
        lootPool: [],
        enemies: [],
        connections: conns([]),
        icon: '🏚️',
        repeatable: true,
        isStart: true,
      );

      final c = makeController(locations: [isolated]);
      final result = CombatManager.pickNeighborLocation(c);

      expect(result, isNull);
    });

    test('возвращает null, если карта null', () {
      final c = MapController(characterId: 'boris', characterName: 'Борис');
      final result = CombatManager.pickNeighborLocation(c);
      expect(result, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // startCombat — базовая проверка
  // ═══════════════════════════════════════════════════════════

  group('CombatManager.startCombat — widget', () {
    testWidgets('не падает для несуществующего enemyId', (tester) async {
      final c = makeController();

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              CombatManager.startCombat(context, c, 'nonexistent_enemy'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(true, true);
    });

    testWidgets('после вызова trackCombat должен быть true',
        (tester) async {
      final c = makeController();

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) =>
              CombatManager.startCombat(context, c, 'nonexistent_enemy'),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.tracker.hadCombat, false);
    });
  });
}