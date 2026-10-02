import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/models/world/world_map.dart';
import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/models/inventory/inventory.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/models/inventory/equipment.dart';
import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/models/conditions/active_condition.dart';
import 'package:dark_hours/models/items/recipe.dart';
import 'package:dark_hours/models/time/game_time.dart';

import 'package:dark_hours/services/save/save_manager.dart';
import 'package:dark_hours/services/items/item_loader.dart';
import 'package:dark_hours/services/items/search_event_loader.dart';
import 'package:dark_hours/services/combat/enemy_loader.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/services/time/time_manager.dart';
import 'package:dark_hours/services/progress/run_tracker.dart';

import 'package:dark_hours/constants/game_constants.dart';

/// Центральный контроллер карты.
///
/// Хранит **всё** состояние игры на карте:
/// - локации и текущую позицию
/// - статы игрока (голод, жажда, здоровье, психика, стамина, усталость)
/// - инвентарь и экипировку
/// - активные болезни
/// - игровое время
/// - счётчики обысков и открытые скрытые локации
/// - трекер забега
///
/// Действия делегируются менеджерам:
/// - MovementManager — перемещение
/// - SearchManager — обыск
/// - RestManager — отдых
/// - CombatManager — бой
/// - StoryTriggerManager — сюжетные триггеры
/// - DeathManager — смерть и коллапс
class MapController extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════
  // ВХОДНЫЕ ДАННЫЕ
  // ═══════════════════════════════════════════════════════════

  final String characterId;
  final String characterName;
  final SaveData? resumeFrom;

  // ═══════════════════════════════════════════════════════════
  // СОСТОЯНИЕ ИГРЫ
  // ═══════════════════════════════════════════════════════════

  /// Карта и текущая локация
  WorldMap? map;

  /// Статы
  int hunger = GameConstants.maxStat;
  int thirst = GameConstants.maxStat;
  int health = GameConstants.maxStat;
  int sanity = GameConstants.maxStat;
  int stamina = GameConstants.maxStat;
  int fatigue = 0;

  /// Игровое время
  late GameTime gameTime;

  /// Глава
  int chapter = 1;

  /// Характеристики персонажа
  int intelligence = GameConstants.defaultIntelligence;
  int strength = GameConstants.defaultStrength;

  /// Инвентарь и экипировка
  final Inventory inventory = Inventory(maxWeight: 30.0);
  final Equipment equipment = Equipment();

  /// Все возможные болезни + активные
  List<Condition> allConditions = [];
  final List<ActiveCondition> activeConditions = [];

  /// Рецепты крафта
  List<Recipe> allRecipes = [];

  /// Флаги (для сюжета и достижений)
  final Set<String> flags = {};

  /// Счётчики обысков по локациям
  final Map<String, int> searchedCounts = {};

  /// Открытые скрытые локации
  final Set<String> unlockedLocations = {};

  /// Трекер забега (для достижений)
  final RunTracker tracker = RunTracker();

  // ═══════════════════════════════════════════════════════════
  // ФЛАГИ СОСТОЯНИЯ
  // ═══════════════════════════════════════════════════════════

  bool isLoading = true;
  bool isDead = false;
  String deathReason = '';

  bool _autoSleepTriggered = false;
  DateTime? _lastCollapseTime;

  // ═══════════════════════════════════════════════════════════
  // GETTERS / SETTERS ДЛЯ ФЛАГОВ
  // ═══════════════════════════════════════════════════════════

  bool get autoSleepTriggered => _autoSleepTriggered;
  set autoSleepTriggered(bool value) {
    _autoSleepTriggered = value;
  }

  DateTime? get lastCollapseTime => _lastCollapseTime;
  set lastCollapseTime(DateTime? value) {
    _lastCollapseTime = value;
  }

  // ═══════════════════════════════════════════════════════════
  // КОНСТРУКТОР
  // ═══════════════════════════════════════════════════════════

  MapController({
    required this.characterId,
    required this.characterName,
    this.resumeFrom,
  }) {
    gameTime = GameTime(totalMinutes: GameConstants.startTimeMinutes);
  }

  // ═══════════════════════════════════════════════════════════
  // ИНИЦИАЛИЗАЦИЯ
  // ═══════════════════════════════════════════════════════════

  /// Загрузить карту и (опционально) восстановить сохранение
  Future<void> init() async {
    isLoading = true;
    refresh();

    // Загружаем справочники
    await ItemLoader.init();
    await SearchEventLoader.init();
    await EnemyLoader.init();
    allConditions = await Condition.loadAll();
    allRecipes = await Recipe.loadAll();

    // Характеристики персонажа
    final stats = GameConstants.statsFor(characterId);
    intelligence = stats['intelligence'] ?? GameConstants.defaultIntelligence;
    strength = stats['strength'] ?? GameConstants.defaultStrength;

    // Загружаем локации
    final locations = await Location.loadAll();
    if (locations.isEmpty) {
      isLoading = false;
      refresh();
      return;
    }

    // Восстанавливаем сохранение или начинаем заново
    if (resumeFrom != null) {
      _restoreFromSave(resumeFrom!, locations);
    } else {
      _startNewGame(locations);
    }

    isLoading = false;
    refresh();
  }

  /// Начать новую игру
  void _startNewGame(List<Location> locations) {
    final startLoc = locations.firstWhere(
      (l) => l.isStart,
      orElse: () => locations.first,
    );

    map = WorldMap(
      locations: locations,
      currentLocationId: startLoc.id,
      visitedLocations: {startLoc.id},
    );

    gameTime = GameTime(totalMinutes: GameConstants.startTimeMinutes);
  }

  /// Восстановить состояние из сохранения
  void _restoreFromSave(SaveData s, List<Location> locations) {
    hunger = s.hunger;
    thirst = s.thirst;
    health = s.health;
    sanity = s.sanity;
    stamina = s.stamina;
    fatigue = s.fatigue;
    gameTime = GameTime.fromSave(s.timeMinutes);
    chapter = s.chapter;

    flags.addAll(s.history);

    searchedCounts.clear();
    searchedCounts.addAll(s.searchedCounts);

    unlockedLocations.clear();
    unlockedLocations.addAll(s.unlockedLocations);

    inventory.items.clear();
    for (final itemJson in s.inventoryItems) {
      inventory.items.add(InventoryItem.fromJson(itemJson));
    }

    final restored = Equipment.fromJson(s.equipmentItems);
    equipment.weapon = restored.weapon;
    equipment.head = restored.head;
    equipment.body = restored.body;
    equipment.hands = restored.hands;
    equipment.feet = restored.feet;
    equipment.backpack = restored.backpack;

    activeConditions.clear();
    for (final cJson in s.activeConditions) {
      final condId = cJson['id'] as String;
      final days = cJson['daysRemaining'] as int;
      try {
        final cond = allConditions.firstWhere((c) => c.id == condId);
        activeConditions.add(
          ActiveCondition(condition: cond, daysRemaining: days),
        );
      } catch (_) {
        // Игнорируем невалидную болезнь
      }
    }

    final startLoc = locations.firstWhere(
      (l) => l.id == s.currentLocationId,
      orElse: () => locations.firstWhere(
        (l) => l.isStart,
        orElse: () => locations.first,
      ),
    );

    map = WorldMap(
      locations: locations,
      currentLocationId: startLoc.id,
      visitedLocations: {startLoc.id},
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ПУБЛИЧНЫЙ API ДЛЯ МЕНЕДЖЕРОВ
  // ═══════════════════════════════════════════════════════════

  /// Публичная обёртка над notifyListeners().
  ///
  /// Менеджеры вызывают refresh() вместо notifyListeners(),
  /// потому что notifyListeners() — protected member ChangeNotifier.
  void refresh() {
    notifyListeners();
  }

  /// Найти предмет в глобальном каталоге (ItemLoader).
  ///
  /// Используется для крафта: recipe.resultId → InventoryItem.
  /// MapScreen не знает об ItemLoader напрямую — всё через контроллер.
  InventoryItem? findItemInCatalog(String id) {
    return ItemLoader.findById(id);
  }

  // ═══════════════════════════════════════════════════════════
  // ИЗМЕНЕНИЕ СОСТОЯНИЯ
  // ═══════════════════════════════════════════════════════════

  /// Применить изменения к статам (с автоограничением 0..100)
  void applyStatDelta(Map<String, int> delta) {
    if (delta['hunger'] != null) {
      hunger = (hunger + delta['hunger']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (delta['thirst'] != null) {
      thirst = (thirst + delta['thirst']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (delta['health'] != null) {
      health = (health + delta['health']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (delta['sanity'] != null) {
      sanity = (sanity + delta['sanity']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (delta['stamina'] != null) {
      stamina = (stamina + delta['stamina']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (delta['fatigue'] != null) {
      fatigue = (fatigue + delta['fatigue']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    refresh();
  }

  /// Прямая установка стата (без delta)
  void setHunger(int value) {
    hunger = value.clamp(GameConstants.minStat, GameConstants.maxStat);
  }

  void setThirst(int value) {
    thirst = value.clamp(GameConstants.minStat, GameConstants.maxStat);
  }

  void setHealth(int value) {
    health = value.clamp(GameConstants.minStat, GameConstants.maxStat);
  }

  void setSanity(int value) {
    sanity = value.clamp(GameConstants.minStat, GameConstants.maxStat);
  }

  void setStamina(int value) {
    stamina = value.clamp(GameConstants.minStat, GameConstants.maxStat);
  }

  void setFatigue(int value) {
    fatigue = value.clamp(GameConstants.minStat, GameConstants.maxStat);
  }

  // ═══════════════════════════════════════════════════════════
  // ИГРОВОЕ ВРЕМЯ
  // ═══════════════════════════════════════════════════════════

  /// Продвинуть время на N минут с расходом статов
  Future<void> advanceTime(int minutes, {bool isSleeping = false}) async {
    final oldDay = gameTime.day;
    final phaseBefore = gameTime.phase;

    gameTime.advance(minutes);


    // Расход голода/жажды/усталости
    final consumption = TimeManager.calculateConsumption(
      minutes: minutes,
      phase: phaseBefore,
      isSleeping: isSleeping,
    );

    hunger = (hunger + (consumption['hunger'] ?? 0))
        .clamp(GameConstants.minStat, GameConstants.maxStat);
    thirst = (thirst + (consumption['thirst'] ?? 0))
        .clamp(GameConstants.minStat, GameConstants.maxStat);
    if (!isSleeping) {
      fatigue = (fatigue + (consumption['fatigue'] ?? 0))
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }

    // Тик активных болезней
    _applyConditionsTick();

    // Новый день — обновляем трекер и проверяем достижения
    if (gameTime.day > oldDay) {
      tracker.nightsPassed += 1;
      if (phaseBefore == TimePhase.night) {
        tracker.nightsSurvived += 1;
      }

      if (sanity < GameConstants.sanityStressThreshold) {
        tracker.sanityDaysLow += 1;
      } else {
        tracker.sanityDaysLow = 0;
      }
    }

    refresh();
  }

  /// Тик активных болезней (вызывается из advanceTime)
  void _applyConditionsTick() {
    if (activeConditions.isEmpty) return;

    final deltas = ConditionManager.applyEffects(activeConditions);
    if (deltas['health'] != null) {
      health = (health + deltas['health']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (deltas['hunger'] != null) {
      hunger = (hunger + deltas['hunger']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (deltas['thirst'] != null) {
      thirst = (thirst + deltas['thirst']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (deltas['stamina'] != null) {
      stamina = (stamina + deltas['stamina']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
    if (deltas['sanity'] != null) {
      sanity = (sanity + deltas['sanity']!)
          .clamp(GameConstants.minStat, GameConstants.maxStat);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // УСЛОВИЯ
  // ═══════════════════════════════════════════════════════════

  /// Добавить условие, если его ещё нет
  void addCondition(Condition condition) {
    if (ConditionManager.hasCondition(activeConditions, condition.id)) return;
    activeConditions.add(ActiveCondition(
      condition: condition,
      daysRemaining: condition.durationDays,
    ));
    tracker.infections += 1;
    refresh();
  }

  /// Попробовать вылечить условие предметом
  bool tryCureCondition(ActiveCondition ac, String itemId) {
    if (!ConditionManager.tryCure(ac, itemId)) return false;
    activeConditions.remove(ac);
    refresh();
    return true;
  }

  // ═══════════════════════════════════════════════════════════
  // ИНВЕНТАРЬ И ЭКИПИРОВКА
  // ═══════════════════════════════════════════════════════════

  /// Найти предмет в инвентаре по ID
  InventoryItem? findItem(String id) => inventory.getById(id);

  /// Добавить предмет (с трекингом для достижений)
  bool addItem(InventoryItem item) {
    final ok = inventory.addItem(item);
    if (ok) {
      tracker.lootedCount += 1;
      if (inventory.items.length > tracker.maxInventorySize) {
        tracker.maxInventorySize = inventory.items.length;
      }
      refresh();
    }
    return ok;
  }

  /// Удалить предмет из инвентаря
  void removeItem(String id) {
    inventory.removeItem(id);
    refresh();
  }

  /// Удалить предмет полностью
  void removeAll(String id) {
    inventory.removeAll(id);
    refresh();
  }

  /// Надеть предмет
  void equipItem(InventoryItem item, String slot) {
    final old = equipment.unequip(slot);
    if (old != null) inventory.addItem(old);

    equipment.equip(item, slot);
    inventory.removeItem(item.id);
    refresh();
  }

  /// Снять предмет (возвращается в инвентарь)
  void unequipItem(String slot) {
    final item = equipment.unequip(slot);
    if (item != null) inventory.addItem(item);
    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // ТРЕКЕР
  // ═══════════════════════════════════════════════════════════

  /// Отметить использование медицинского предмета
  void trackMedicineUsed() {
    tracker.medicineUsed += 1;
  }

  /// Отметить крафт
  void trackCraft({required bool isMolotov}) {
    tracker.craftedCount += 1;
    if (isMolotov) tracker.alchemistCrafted = true;
  }

  /// Отметить бой
  void trackCombat() {
    tracker.hadCombat = true;
  }

  /// Отметить урон в бою
  void trackDamage() {
    tracker.hadDamage = true;
  }

  /// Отметить победу в бою
  void trackVictory() {
    tracker.kills += 1;
  }

  /// Отметить поражение
  void trackDefeat() {
    tracker.defeats += 1;
  }

  /// Отметить коллапс
  void trackCollapse() {
    tracker.collapsesCount += 1;
  }

  // ═══════════════════════════════════════════════════════════
  // ФЛАГИ
  // ═══════════════════════════════════════════════════════════

  /// Установить флаг
  void setFlag(String flag) {
    flags.add(flag);
    refresh();
  }

  /// Есть ли флаг
  bool hasFlag(String flag) => flags.contains(flag);

  // ═══════════════════════════════════════════════════════════
  // ОБЫСКИ И СКРЫТЫЕ ЛОКАЦИИ
  // ═══════════════════════════════════════════════════════════

  /// Увеличить счётчик обысков
  int incrementSearchCount(String locationId) {
    final count = (searchedCounts[locationId] ?? 0) + 1;
    searchedCounts[locationId] = count;
    return count;
  }

  /// Открыть скрытую локацию
  void unlockLocation(String locationId) {
    unlockedLocations.add(locationId);
    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // УТИЛИТЫ
  // ═══════════════════════════════════════════════════════════

  /// Потерять N случайных предметов из инвентаря
  void loseRandomItems(int count) {
    final rng = Random();
    for (int i = 0; i < count && inventory.items.isNotEmpty; i++) {
      final index = rng.nextInt(inventory.items.length);
      final lost = inventory.items[index];
      inventory.removeAll(lost.id);
    }
    refresh();
  }

  /// Текущая локация
  Location? get currentLocation => map?.current;

  /// Проверить, находится ли локация в списке доступных
  bool isLocationUnlocked(String locationId) {
    return unlockedLocations.contains(locationId);
  }

  // ═══════════════════════════════════════════════════════════
  // СОХРАНЕНИЕ
  // ═══════════════════════════════════════════════════════════

  /// Автосохранить текущее состояние
  Future<void> save() async {
    if (map == null) return;

    final data = SaveData(
      characterId: characterId,
      characterName: characterName,
      currentNodeId: 'map',
      currentLocationId: map!.currentLocationId,
      onMap: true,
      hunger: hunger,
      thirst: thirst,
      health: health,
      sanity: sanity,
      stamina: stamina,
      fatigue: fatigue,
      timeMinutes: gameTime.totalMinutes,
      chapter: chapter,
      history: flags.toList(),
      inventoryItems: inventory.toJson(),
      equipmentItems: equipment.toJson(),
      activeConditions: activeConditions
          .map((ac) => {
                'id': ac.condition.id,
                'daysRemaining': ac.daysRemaining,
              })
          .toList(),
      searchedCounts: searchedCounts,
      unlockedLocations: unlockedLocations.toList(),
      savedAt: DateTime.now(),
    );

    await SaveManager.save(data);
  }

  /// Перечитать сохранение (после StoryScreen)
  Future<void> reloadFromSave() async {
    final save = await SaveManager.load();
    if (save == null) return;

    hunger = save.hunger;
    thirst = save.thirst;
    health = save.health;
    sanity = save.sanity;
    stamina = save.stamina;
    fatigue = save.fatigue;
    gameTime = GameTime.fromSave(save.timeMinutes);
    chapter = save.chapter;

    inventory.items.clear();
    for (final itemJson in save.inventoryItems) {
      inventory.items.add(InventoryItem.fromJson(itemJson));
    }

    final restored = Equipment.fromJson(save.equipmentItems);
    equipment.weapon = restored.weapon;
    equipment.head = restored.head;
    equipment.body = restored.body;
    equipment.hands = restored.hands;
    equipment.feet = restored.feet;
    equipment.backpack = restored.backpack;

    activeConditions.clear();
    for (final cJson in save.activeConditions) {
      final condId = cJson['id'] as String;
      final days = cJson['daysRemaining'] as int;
      try {
        final cond = allConditions.firstWhere((c) => c.id == condId);
        activeConditions.add(
          ActiveCondition(condition: cond, daysRemaining: days),
        );
      } catch (_) {}
    }

    flags.clear();
    flags.addAll(save.history);

    searchedCounts.clear();
    searchedCounts.addAll(save.searchedCounts);

    unlockedLocations.clear();
    unlockedLocations.addAll(save.unlockedLocations);

    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // СМЕРТЬ
  // ═══════════════════════════════════════════════════════════

  /// Проверить, не умер ли игрок
  void markDead(String reason) {
    isDead = true;
    deathReason = reason;
    refresh();
  }

  /// Сбросить флаг смерти (после DeathScreen)
  void clearDeath() {
    isDead = false;
    deathReason = '';
    refresh();
  }
}