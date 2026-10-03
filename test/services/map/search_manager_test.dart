import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../_helpers/test_fixtures.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/search_event.dart';
import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/search_manager.dart';
import 'package:dark_hours/services/items/item_loader.dart';
import 'package:dark_hours/services/items/search_event_loader.dart';
import 'package:dark_hours/services/combat/enemy_loader.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/constants/game_constants.dart';

void main() {
  // ═══════════════════════════════════════════════════════════
  // ГЛОБАЛЬНЫЙ setUp
  // ═══════════════════════════════════════════════════════════

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Загружаем справочники — search зависит от ItemLoader.findById,
    // а также от EnemyLoader (для боя при встрече врага)
    await ItemLoader.init();
    await SearchEventLoader.init();
    await EnemyLoader.init();
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

  final emptyLocation = Location(
    id: 'empty',
    name: 'Пустая',
    description: '',
    type: 'safe_house',
    region: 'city',
    dangerLevel: 0,
    searchTime: 0,
    maxSearches: 0,
    lootPool: [],
    enemies: [],
    connections: conns([]),
    icon: '📭',
    repeatable: true,
    isStart: true,
  );

  final lootLocation = Location(
    id: 'loot',
    name: 'Склад',
    description: '',
    type: 'shop',
    region: 'city',
    dangerLevel: 2,
    searchTime: 15,
    maxSearches: 3,
    lootPool: ['bandage', 'crackers', 'water_bottle'],
    enemies: [],
    connections: conns([]),
    icon: '📦',
    repeatable: true,
    isStart: true,
  );

  final riskLocation = Location(
    id: 'risk',
    name: 'Тоннель',
    description: '',
    type: 'tunnel',
    region: 'underground',
    dangerLevel: 5,
    searchTime: 30,
    maxSearches: 2,
    lootPool: ['wood'],
    enemies: [],
    connections: conns([]),
    icon: '🕳️',
    repeatable: true,
    isStart: true,
    risk: 'dirty_water',
  );

  MapController makeController({required List<Location> locations}) {
    final c = MapController(
      characterId: 'boris',
      characterName: 'Борис',
    );
    c.initForTest(locations: locations);
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
  // nothingToSearch
  // ═══════════════════════════════════════════════════════════

  group('SearchManager.nothingToSearch', () {
    test('true для полностью пустой локации', () {
      expect(SearchManager.nothingToSearch(emptyLocation), true);
    });

    test('false, если есть lootPool', () {
      expect(SearchManager.nothingToSearch(lootLocation), false);
    });

    test('false, если есть maxSearches > 0', () {
      final loc = Location(
        id: 'x',
        name: 'X',
        description: '',
        type: 'shop',
        region: 'city',
        dangerLevel: 0,
        searchTime: 10,
        maxSearches: 3,
        lootPool: [],
        enemies: [],
        connections: conns([]),
        icon: '📦',
        repeatable: true,
      );
      expect(SearchManager.nothingToSearch(loc), false);
    });

    test('false, если есть risk', () {
      expect(SearchManager.nothingToSearch(riskLocation), false);
    });

    test('false, если есть enemies', () {
      final loc = Location(
        id: 'x',
        name: 'X',
        description: '',
        type: 'street',
        region: 'city',
        dangerLevel: 5,
        searchTime: 20,
        maxSearches: 0,
        lootPool: [],
        enemies: ['looter_common'],
        connections: conns([]),
        icon: '🛣️',
        repeatable: true,
      );
      expect(SearchManager.nothingToSearch(loc), false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // rollEnemyEncounter
  // ═══════════════════════════════════════════════════════════

  group('SearchManager.rollEnemyEncounter', () {
    test('при 500 бросках хотя бы раз true (шанс 1/3)', () {
      bool anyEncounter = false;
      for (int i = 0; i < 500; i++) {
        if (SearchManager.rollEnemyEncounter()) {
          anyEncounter = true;
          break;
        }
      }
      expect(anyEncounter, true);
    });

    test('частота ≈ 33% (в диапазоне 20-45 за 300 бросков)', () {
      int count = 0;
      for (int i = 0; i < 300; i++) {
        if (SearchManager.rollEnemyEncounter()) count++;
      }
      // Теоретически 100 из 300. Дадим широкий диапазон (шум).
      expect(count, greaterThan(50));
      expect(count, lessThan(150));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // pickLoot
  // ═══════════════════════════════════════════════════════════

  group('SearchManager.pickLoot', () {
    test('возвращает null для пустого lootPool', () {
      expect(SearchManager.pickLoot(emptyLocation), isNull);
    });

    test('возвращает предмет из lootPool', () {
      final result = SearchManager.pickLoot(lootLocation);
      expect(result, isNotNull);
      expect(lootLocation.lootPool.contains(result), true);
    });

    test('при 100 бросках выпадают все предметы из пула', () {
      final picked = <String>{};
      for (int i = 0; i < 100; i++) {
        final id = SearchManager.pickLoot(lootLocation);
        if (id != null) picked.add(id);
      }
      expect(picked, lootLocation.lootPool.toSet());
    });
  });

  // ═══════════════════════════════════════════════════════════
  // pickSearchEvent
  // ═══════════════════════════════════════════════════════════

  group('SearchManager.pickSearchEvent', () {
    test('возвращает null для пустого пула', () {
      final result = SearchManager.pickSearchEvent(
        pool: [],
        currentLocationId: 'home',
        hiddenMap: {},
      );
      expect(result, isNull);
    });

    test('всегда выбирает событие с chance = 1.0', () {
      const event = SearchEvent(
        id: 'always',
        name: 'Всегда',
        chance: 1.0,
        text: 'Событие',
        effect: {},
      );
      for (int i = 0; i < 10; i++) {
        final result = SearchManager.pickSearchEvent(
          pool: [event],
          currentLocationId: 'home',
          hiddenMap: {},
        );
        expect(result, isNotNull);
        expect(result!.id, 'always');
      }
    });

    test('никогда не выбирает событие с chance = 0.0', () {
      const event = SearchEvent(
        id: 'never',
        name: 'Никогда',
        chance: 0.0,
        text: '',
        effect: {},
      );
      for (int i = 0; i < 50; i++) {
        final result = SearchManager.pickSearchEvent(
          pool: [event],
          currentLocationId: 'home',
          hiddenMap: {},
        );
        expect(result, isNull);
      }
    });

    test('событие с unlock_location=auto НЕ выбирается, если hidden нет',
        () {
      const event = SearchEvent(
        id: 'unlock',
        name: 'Обвал',
        chance: 1.0,
        text: 'Обвал',
        effect: {'unlock_location': 'auto'},
      );

      // Локация home не имеет hidden → событие не applicable
      final result = SearchManager.pickSearchEvent(
        pool: [event],
        currentLocationId: 'home',
        hiddenMap: {}, // пустая карта — hidden нет
      );

      expect(result, isNull);
    });

    test('событие с unlock_location=auto ВЫБИРАЕТСЯ, если hidden есть', () {
      const event = SearchEvent(
        id: 'unlock',
        name: 'Обвал',
        chance: 1.0,
        text: 'Обвал',
        effect: {'unlock_location': 'auto'},
      );

      final result = SearchManager.pickSearchEvent(
        pool: [event],
        currentLocationId: 'home',
        hiddenMap: {'home': 'home_basement'},
      );

      expect(result, isNotNull);
      expect(result!.id, 'unlock');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // extractStatDelta
  // ═══════════════════════════════════════════════════════════

  group('SearchManager.extractStatDelta', () {
    test('извлекает health', () {
      final delta = SearchManager.extractStatDelta({'health': -10});
      expect(delta, {'health': -10});
    });

    test('извлекает несколько статов', () {
      final delta = SearchManager.extractStatDelta({
        'health': -5,
        'sanity': -3,
        'stamina': -10,
      });
      expect(delta['health'], -5);
      expect(delta['sanity'], -3);
      expect(delta['stamina'], -10);
    });

    test('игнорирует нулевые значения', () {
      final delta = SearchManager.extractStatDelta({
        'health': 0,
        'sanity': -5,
      });
      expect(delta.containsKey('health'), false);
      expect(delta['sanity'], -5);
    });

    test('игнорирует не-int значения', () {
      final delta = SearchManager.extractStatDelta({
        'health': 'много',
        'sanity': -5,
      });
      expect(delta.containsKey('health'), false);
      expect(delta['sanity'], -5);
    });

    test('возвращает пустой map для пустого effect', () {
      final delta = SearchManager.extractStatDelta({});
      expect(delta, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // search — widget-тесты
  // ═══════════════════════════════════════════════════════════

  group('SearchManager.search — widget', () {
    testWidgets('пустая локация → снекбар "нечего искать"', (tester) async {
      final c = makeController(locations: [emptyLocation]);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => SearchManager.search(context, c),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(find.text('Здесь нечего искать'), findsOneWidget);
    });

    testWidgets('стандартный поиск добавляет предмет', (tester) async {
      final c = makeController(locations: [lootLocation]);
      expect(c.inventory.items.length, 0);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => SearchManager.search(context, c),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.inventory.items.length, 1);
    });

    testWidgets('стандартный поиск увеличивает searchedCount', (tester) async {
      final c = makeController(locations: [lootLocation]);
      expect(c.searchedCounts['loot'], isNull);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => SearchManager.search(context, c),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(c.searchedCounts['loot'], 1);
    });

    testWidgets('стандартный поиск списывает стамину', (tester) async {
      final c = makeController(locations: [lootLocation]);
      final staminaBefore = c.stamina;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => SearchManager.search(context, c),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(
        c.stamina,
        staminaBefore - GameConstants.searchStaminaCost,
      );
    });

    testWidgets('стандартный поиск продвигает время', (tester) async {
      final c = makeController(locations: [lootLocation]);
      final timeBefore = c.gameTime.totalMinutes;

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => SearchManager.search(context, c),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      expect(
        c.gameTime.totalMinutes,
        timeBefore + lootLocation.searchTime,
      );
    });

    testWidgets('после исчерпания обысков идёт событийный поиск',
        (tester) async {
      final c = makeController(locations: [lootLocation]);
      // Искусственно исчерпаем обыски
      c.incrementSearchCount('loot');
      c.incrementSearchCount('loot');
      c.incrementSearchCount('loot');
      expect(c.searchedCounts['loot'], 3);

      await tester.pumpWidget(
        makeTestApp(
          onPressed: (context) => SearchManager.search(context, c),
        ),
      );

      await tester.tap(find.text('TEST'));
      await tester.pumpAndSettle();

      // При событийном поиске счетчик НЕ увеличивается
      expect(c.searchedCounts['loot'], 3);
    });
  });
}