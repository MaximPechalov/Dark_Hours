import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/death_manager.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/constants/game_constants.dart';

void main() {
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
    connections: [],
    icon: '🏠',
    repeatable: true,
    isStart: true,
  );

  MapController makeController({
    String characterId = 'boris',
    String characterName = 'Борис',
    int startTimeMinutes = GameConstants.startTimeMinutes,
  }) {
    final c = MapController(
      characterId: characterId,
      characterName: characterName,
    );
    c.initForTest(
      locations: const [homeLocation],
      startTimeMinutes: startTimeMinutes,
    );
    return c;
  }

  // ═══════════════════════════════════════════════════════════
  // checkDeath — смерть от разных причин
  // ═══════════════════════════════════════════════════════════

  group('DeathManager.checkDeath', () {
    test('false при нормальных статах', () {
      final c = makeController();
      expect(DeathManager.checkDeath(c), false);
      expect(c.isDead, false);
    });

    test('true при hunger <= 0', () {
      final c = makeController();
      c.setHunger(0);
      expect(DeathManager.checkDeath(c), true);
      expect(c.isDead, true);
      expect(c.deathReason, contains('голод'));
    });

    test('true при thirst <= 0', () {
      final c = makeController();
      c.setThirst(0);
      expect(DeathManager.checkDeath(c), true);
      expect(c.isDead, true);
      expect(c.deathReason, contains('обезвоживан'));
    });

    test('true при health <= 0', () {
      final c = makeController();
      c.setHealth(0);
      expect(DeathManager.checkDeath(c), true);
      expect(c.isDead, true);
      expect(c.deathReason, contains('ран'));
    });

    test('false при health = 1, hunger = 1, thirst = 1', () {
      final c = makeController();
      c.setHealth(1);
      c.setHunger(1);
      c.setThirst(1);
      expect(DeathManager.checkDeath(c), false);
    });

    test('голод имеет приоритет над жаждой (проверка порядка)', () {
      final c = makeController();
      c.setHunger(0);
      c.setThirst(0);
      DeathManager.checkDeath(c);
      expect(c.deathReason, contains('голод'));
    });

    test('если isDead уже true — возвращает true без изменения reason', () {
      final c = makeController();
      c.markDead('Уже мёртв');
      expect(DeathManager.checkDeath(c), true);
      expect(c.deathReason, 'Уже мёртв');
    });

    test('устанавливает isDead = true', () {
      final c = makeController();
      c.setHealth(0);
      expect(c.isDead, false);
      DeathManager.checkDeath(c);
      expect(c.isDead, true);
    });

    test('true при isWinter (после 60 дней)', () {
      // startTimeMinutes = 61 день в минутах → зима
      final c = makeController(
        startTimeMinutes: 61 * 24 * 60,
      );
      expect(DeathManager.checkDeath(c), true);
      expect(c.deathReason, contains('зима'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // evaluateFatigue — чистая логика
  // ═══════════════════════════════════════════════════════════

  group('DeathManager.evaluateFatigue — зона nothing', () {
    test('nothing при fatigue = 0', () {
      final c = makeController();
      c.setFatigue(0);
      final result = DeathManager.evaluateFatigue(c);
      expect(result.action, FatigueAction.nothing);
    });

    test('nothing при fatigue = 50', () {
      final c = makeController();
      c.setFatigue(50);
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.nothing);
    });

    test('nothing при fatigue = 79 (ниже порога warning)', () {
      final c = makeController();
      c.setFatigue(79);
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.nothing);
    });

    test('nothing при fatigue = 80 (зона warning, но не автосон)', () {
      final c = makeController();
      c.setFatigue(80);
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.nothing);
    });

    test('nothing при fatigue = 94 (за шаг до forcedSleep)', () {
      final c = makeController();
      c.setFatigue(94);
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.nothing);
    });
  });

  group('DeathManager.evaluateFatigue — зона forcedSleep', () {
    test('forcedSleep при fatigue = 95 (граница)', () {
      final c = makeController();
      c.setFatigue(95);
      expect(
        DeathManager.evaluateFatigue(c).action,
        FatigueAction.forcedSleep,
      );
    });

    test('forcedSleep при fatigue = 99', () {
      final c = makeController();
      c.setFatigue(99);
      expect(
        DeathManager.evaluateFatigue(c).action,
        FatigueAction.forcedSleep,
      );
    });

    test('nothing при fatigue = 95, но autoSleepTriggered = true', () {
      final c = makeController();
      c.setFatigue(95);
      c.autoSleepTriggered = true;
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.nothing);
    });

    test('forcedSleep при fatigue = 97 и autoSleepTriggered = false', () {
      final c = makeController();
      c.setFatigue(97);
      c.autoSleepTriggered = false;
      expect(
        DeathManager.evaluateFatigue(c).action,
        FatigueAction.forcedSleep,
      );
    });
  });

  group('DeathManager.evaluateFatigue — зона collapse', () {
    test('collapse при fatigue = 100 без прошлого коллапса', () {
      final c = makeController();
      c.setFatigue(100);
      c.lastCollapseTime = null;
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.collapse);
    });

    test('collapse при fatigue = 100 и коллапс 25 часов назад', () {
      final c = makeController();
      c.setFatigue(100);
      c.lastCollapseTime = DateTime.now().subtract(
        const Duration(hours: 25),
      );
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.collapse);
    });
  });

  group('DeathManager.evaluateFatigue — зона died', () {
    test('died при fatigue = 100 и коллапсе 1 час назад', () {
      final c = makeController();
      c.setFatigue(100);
      c.lastCollapseTime = DateTime.now().subtract(
        const Duration(hours: 1),
      );
      final result = DeathManager.evaluateFatigue(c);
      expect(result.action, FatigueAction.died);
      expect(result.deathReason, isNotNull);
      expect(result.deathReason, contains('истощени'));
    });

    test('died при fatigue = 100 и коллапсе 23 часа назад (граница)', () {
      final c = makeController();
      c.setFatigue(100);
      c.lastCollapseTime = DateTime.now().subtract(
        const Duration(hours: 23),
      );
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.died);
    });

    test('collapse при fatigue = 100 и коллапсе ровно 24 часа назад', () {
      final c = makeController();
      c.setFatigue(100);
      c.lastCollapseTime = DateTime.now().subtract(
        const Duration(hours: 24),
      );
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.collapse);
    });

    test('nothing при isDead = true, даже если fatigue = 100', () {
      final c = makeController();
      c.setFatigue(100);
      c.markDead('Уже мёртв');
      expect(DeathManager.evaluateFatigue(c).action, FatigueAction.nothing);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // applyStatsOnDeath — статистика при смерти
  // ═══════════════════════════════════════════════════════════

  group('DeathManager.applyStatsOnDeath', () {
    setUp(() async {
      // Очищаем SharedPreferences И кэш AchievementManager
      SharedPreferences.setMockInitialValues({});
      await AchievementManager.reset();
    });

    test('увеличивает totalDeaths на 1', () async {
      final c = makeController();
      final statsBefore = await AchievementManager.loadStats();
      final before = statsBefore.totalDeaths;

      await DeathManager.applyStatsOnDeath(c);

      final statsAfter = await AchievementManager.loadStats();
      expect(statsAfter.totalDeaths, before + 1);
    });

    test('добавляет текущий день в totalDaysSurvived', () async {
      final c = makeController();
      // gameTime.day = 1 сразу после initForTest
      final statsBefore = await AchievementManager.loadStats();
      final before = statsBefore.totalDaysSurvived;

      await DeathManager.applyStatsOnDeath(c);

      final statsAfter = await AchievementManager.loadStats();
      expect(statsAfter.totalDaysSurvived, before + 1);
    });

    test('обновляет bestRunDays, если текущий день больше', () async {
      // Загружаем начальную статистику и задаём bestRunDays = 5
      final initial = await AchievementManager.loadStats();
      initial.bestRunDays = 5;
      await AchievementManager.saveStats(initial);

      // Создаём контроллер и двигаем время на 10 дней
      final c = makeController();
      await c.advanceTime(10 * 24 * 60); // 10 дней

      await DeathManager.applyStatsOnDeath(c);

      final statsAfter = await AchievementManager.loadStats();
      expect(statsAfter.bestRunDays, greaterThanOrEqualTo(11));
    });

    test('НЕ обновляет bestRunDays, если текущий день меньше', () async {
      final initial = await AchievementManager.loadStats();
      initial.bestRunDays = 100;
      initial.bestRunCharacter = 'Андрей';
      await AchievementManager.saveStats(initial);

      final c = makeController(characterName: 'Борис');
      await DeathManager.applyStatsOnDeath(c);

      final statsAfter = await AchievementManager.loadStats();
      expect(statsAfter.bestRunDays, 100);
      expect(statsAfter.bestRunCharacter, 'Андрей');
    });

    test('устанавливает bestRunCharacter при новом рекорде', () async {
      final c = makeController(characterName: 'Иван Ильич');
      await DeathManager.applyStatsOnDeath(c);

      final statsAfter = await AchievementManager.loadStats();
      expect(statsAfter.bestRunCharacter, 'Иван Ильич');
    });

    test('applyToStats переносит kills/defeats/crafted из tracker', () async {
      final c = makeController();
      c.tracker.kills = 3;
      c.tracker.defeats = 2;
      c.tracker.craftedCount = 5;

      final statsBefore = await AchievementManager.loadStats();
      final killsBefore = statsBefore.totalKills;
      final defeatsBefore = statsBefore.totalDefeats;
      final craftedBefore = statsBefore.totalItemsCrafted;

      await DeathManager.applyStatsOnDeath(c);

      final statsAfter = await AchievementManager.loadStats();
      expect(statsAfter.totalKills, killsBefore + 3);
      expect(statsAfter.totalDefeats, defeatsBefore + 2);
      expect(statsAfter.totalItemsCrafted, craftedBefore + 5);
    });
  });
}