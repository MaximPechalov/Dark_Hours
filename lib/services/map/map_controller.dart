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

  WorldMap? map;

  int hunger = GameConstants.maxStat;
  int thirst = GameConstants.maxStat;
  int health = GameConstants.maxStat;
  int sanity = GameConstants.maxStat;
  int stamina = GameConstants.maxStat;
  int fatigue = 0;

  late GameTime gameTime;
  int chapter = 1;

  int intelligence = GameConstants.defaultIntelligence;
  int strength = GameConstants.defaultStrength;

  final Inventory inventory = Inventory(maxWeight: 30.0);
  final Equipment equipment = Equipment();

  List<Condition> allConditions = [];
  final List<ActiveCondition> activeConditions = [];

  List<Recipe> allRecipes = [];

  final Set<String> flags = {};
  final Map<String, int> searchedCounts = {};
  final Set<String> unlockedLocations = {};

  /// Разведанные локации — игрок знает их название, иконку, общее описание.
  ///
  /// Все локации стартового региона попадают сюда сразу при старте.
  /// Скрытые (`hidden`) локации попадают только через `unlockLocation`.
  final Set<String> scoutedLocations = {};

  /// Локации с уточнённым состоянием — игрок знает, что там СЕЙЧАС.
  ///
  /// Заполняется через `scoutDetails()` — разведку состояния.
  final Set<String> detailedLocations = {};

  /// Открытые регионы.
  final Set<String> discoveredRegions = {};

  final RunTracker tracker = RunTracker();

  bool isLoading = true;
  bool isDead = false;
  String deathReason = '';

  /// Флаг "уже сработал форсированный автосон".
  ///
  /// Сбрасывается при любом сне. Нужен, чтобы автосон не срабатывал
  /// несколько раз подряд.
  bool autoSleepTriggered = false;

  /// Время последнего коллапса.
  ///
  /// Нужен для проверки "повторный коллапс в течение 24 часов → смерть".
  DateTime? lastCollapseTime;

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

  Future<void> init() async {
    isLoading = true;
    refresh();

    await ItemLoader.init();
    await SearchEventLoader.init();
    await EnemyLoader.init();
    allConditions = await Condition.loadAll();
    allRecipes = await Recipe.loadAll();

    final stats = GameConstants.statsFor(characterId);
    intelligence = stats['intelligence'] ?? GameConstants.defaultIntelligence;
    strength = stats['strength'] ?? GameConstants.defaultStrength;

    final locations = await Location.loadAll();
    if (locations.isEmpty) {
      isLoading = false;
      refresh();
      return;
    }

    if (resumeFrom != null) {
      _restoreFromSave(resumeFrom!, locations);
    } else {
      _startNewGame(locations);
    }

    isLoading = false;
    refresh();
  }

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

    // НОВАЯ ЛОГИКА: все локации стартового региона разведаны сразу.
    // Игрок живёт в этом городе — он знает, где что.
    _scoutRegionLocations(locations, startLoc.region);

    // Стартовая локация — ещё и посещена (полное описание).
    // Остальные — только scouted (краткое описание).
    discoverRegion(startLoc.region);
  }

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

    scoutedLocations.clear();
    scoutedLocations.addAll(s.scoutedLocations);

    detailedLocations.clear();
    detailedLocations.addAll(s.detailedLocations);

    discoveredRegions.clear();
    discoveredRegions.addAll(s.discoveredRegions);

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
      } catch (_) {}
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

    // МИГРАЦИЯ: если старые сохранения без scoutedLocations —
    // разведать все локации текущего региона.
    if (scoutedLocations.isEmpty) {
      _scoutRegionLocations(locations, startLoc.region);
      discoverRegion(startLoc.region);
    }

    // МИГРАЦИЯ: если в сохранении нет detailedLocations — оставить пустым.
    // Игроку придётся разведывать заново.
  }

  /// Разведать все локации указанного региона (кроме скрытых).
  void _scoutRegionLocations(List<Location> locations, String region) {
    for (final loc in locations) {
      if (loc.region != region) continue;
      if (loc.hidden) continue;
      if (!loc.isAvailableAt(chapter)) continue;

      scoutedLocations.add(loc.id);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ИССЛЕДОВАНИЕ
  // ═══════════════════════════════════════════════════════════

  /// Знает ли игрок о существовании локации (базовое знание).
  bool isScouted(String locationId) {
    return scoutedLocations.contains(locationId);
  }

  /// Знает ли игрок текущее состояние локации (детальная разведка).
  bool hasDetails(String locationId) {
    return detailedLocations.contains(locationId);
  }

  bool isVisited(String locationId) {
    return map?.visitedLocations.contains(locationId) ?? false;
  }

  bool isRegionDiscovered(String region) {
    return discoveredRegions.contains(region);
  }

  /// Разведать локацию — узнать о её существовании.
  ///
  /// Теперь используется только для:
  /// - Соседей из соседних регионов (при переходе).
  /// - Скрытых локаций (при разведке скрытых).
  ///
  /// Все локации текущего региона уже разведаны при старте.
  void scoutLocation(String locationId) {
    if (scoutedLocations.contains(locationId)) return;
    scoutedLocations.add(locationId);

    final loc = map?.getById(locationId);
    if (loc != null) {
      discoverRegion(loc.region);
    }

    refresh();
  }

  /// Разведать состояние локации — узнать, что там СЕЙЧАС.
  ///
  /// Это НЕ открывает локацию. Локация уже должна быть scouted.
  /// Даёт: количество врагов, наличие лута, состояние здания.
  bool scoutDetails(String locationId) {
    // Разведать детали можно только у известной локации.
    if (!scoutedLocations.contains(locationId)) return false;

    // Если детали уже есть — не тратим ресурсы.
    if (detailedLocations.contains(locationId)) return false;

    detailedLocations.add(locationId);
    refresh();
    return true;
  }

  /// Разведать все локации указанного региона.
  ///
  /// Используется при переходе в новый регион — игрок сразу
  /// видит все локации региона, но без деталей.
  void scoutAll(Iterable<String> locationIds) {
    bool changed = false;
    for (final id in locationIds) {
      if (scoutedLocations.add(id)) {
        changed = true;
        final loc = map?.getById(id);
        if (loc != null) {
          discoveredRegions.add(loc.region);
        }
      }
    }
    if (changed) refresh();
  }

  void discoverRegion(String region) {
    if (discoveredRegions.add(region)) {
      refresh();
    }
  }

  @visibleForTesting
  void setScouted(Set<String> ids) {
    scoutedLocations
      ..clear()
      ..addAll(ids);
    refresh();
  }

  @visibleForTesting
  void setDetailed(Set<String> ids) {
    detailedLocations
      ..clear()
      ..addAll(ids);
    refresh();
  }

  @visibleForTesting
  void setDiscoveredRegions(Set<String> regions) {
    discoveredRegions
      ..clear()
      ..addAll(regions);
    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // ПУБЛИЧНЫЙ API
  // ═══════════════════════════════════════════════════════════

  void refresh() {
    notifyListeners();
  }

  InventoryItem? findItemInCatalog(String id) {
    return ItemLoader.findById(id);
  }

  // ═══════════════════════════════════════════════════════════
  // ИЗМЕНЕНИЕ СОСТОЯНИЯ
  // ═══════════════════════════════════════════════════════════

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

  Future<void> advanceTime(int minutes, {bool isSleeping = false}) async {
    final oldDay = gameTime.day;
    final phaseBefore = gameTime.phase;

    gameTime.advance(minutes);

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

    _applyConditionsTick();

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

  void addCondition(Condition condition) {
    if (ConditionManager.hasCondition(activeConditions, condition.id)) return;
    activeConditions.add(ActiveCondition(
      condition: condition,
      daysRemaining: condition.durationDays,
    ));
    tracker.infections += 1;
    refresh();
  }

  bool tryCureCondition(ActiveCondition ac, String itemId) {
    if (!ConditionManager.tryCure(ac, itemId)) return false;
    activeConditions.remove(ac);
    refresh();
    return true;
  }

  // ═══════════════════════════════════════════════════════════
  // ИНВЕНТАРЬ И ЭКИПИРОВКА
  // ═══════════════════════════════════════════════════════════

  InventoryItem? findItem(String id) => inventory.getById(id);

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

  void removeItem(String id) {
    inventory.removeItem(id);
    refresh();
  }

  void removeAll(String id) {
    inventory.removeAll(id);
    refresh();
  }

  void equipItem(InventoryItem item, String slot) {
    final old = equipment.unequip(slot);
    if (old != null) inventory.addItem(old);

    equipment.equip(item, slot);
    inventory.removeItem(item.id);
    refresh();
  }

  void unequipItem(String slot) {
    final item = equipment.unequip(slot);
    if (item != null) inventory.addItem(item);
    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // ТРЕКЕР
  // ═══════════════════════════════════════════════════════════

  void trackMedicineUsed() => tracker.medicineUsed += 1;

  void trackCraft({required bool isMolotov}) {
    tracker.craftedCount += 1;
    if (isMolotov) tracker.alchemistCrafted = true;
  }

  void trackCombat() => tracker.hadCombat = true;
  void trackDamage() => tracker.hadDamage = true;
  void trackVictory() => tracker.kills += 1;
  void trackDefeat() => tracker.defeats += 1;
  void trackCollapse() => tracker.collapsesCount += 1;

  // ═══════════════════════════════════════════════════════════
  // ФЛАГИ
  // ═══════════════════════════════════════════════════════════

  void setFlag(String flag) {
    flags.add(flag);
    refresh();
  }

  bool hasFlag(String flag) => flags.contains(flag);

  // ═══════════════════════════════════════════════════════════
  // ОБЫСКИ И СКРЫТЫЕ ЛОКАЦИИ
  // ═══════════════════════════════════════════════════════════

  int incrementSearchCount(String locationId) {
    final count = (searchedCounts[locationId] ?? 0) + 1;
    searchedCounts[locationId] = count;
    return count;
  }

  void unlockLocation(String locationId) {
    unlockedLocations.add(locationId);
    scoutedLocations.add(locationId);
    final loc = map?.getById(locationId);
    if (loc != null) discoverRegion(loc.region);
    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // УТИЛИТЫ
  // ═══════════════════════════════════════════════════════════

  void loseRandomItems(int count) {
    final rng = Random();
    for (int i = 0; i < count && inventory.items.isNotEmpty; i++) {
      final index = rng.nextInt(inventory.items.length);
      final lost = inventory.items[index];
      inventory.removeAll(lost.id);
    }
    refresh();
  }

  Location? get currentLocation => map?.current;

  bool isLocationUnlocked(String locationId) {
    return unlockedLocations.contains(locationId);
  }

  // ═══════════════════════════════════════════════════════════
  // СОХРАНЕНИЕ
  // ═══════════════════════════════════════════════════════════

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
      scoutedLocations: scoutedLocations,
      detailedLocations: detailedLocations,
      discoveredRegions: discoveredRegions,
      savedAt: DateTime.now(),
    );

    await SaveManager.save(data);
  }

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

    scoutedLocations.clear();
    scoutedLocations.addAll(save.scoutedLocations);

    detailedLocations.clear();
    detailedLocations.addAll(save.detailedLocations);

    discoveredRegions.clear();
    discoveredRegions.addAll(save.discoveredRegions);

    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // ТЕСТИРОВАНИЕ
  // ═══════════════════════════════════════════════════════════

  @visibleForTesting
  void initForTest({
    required List<Location> locations,
    List<Condition> conditions = const [],
    List<Recipe> recipes = const [],
    int startTimeMinutes = GameConstants.startTimeMinutes,
  }) {
    if (locations.isEmpty) {
      throw ArgumentError('initForTest: locations не может быть пустым');
    }

    allConditions = conditions;
    allRecipes = recipes;

    final stats = GameConstants.statsFor(characterId);
    intelligence = stats['intelligence'] ?? GameConstants.defaultIntelligence;
    strength = stats['strength'] ?? GameConstants.defaultStrength;

    final startLoc = locations.firstWhere(
      (l) => l.isStart,
      orElse: () => locations.first,
    );

    map = WorldMap(
      locations: locations,
      currentLocationId: startLoc.id,
      visitedLocations: {startLoc.id},
    );

    gameTime = GameTime(totalMinutes: startTimeMinutes);

    // НОВАЯ ЛОГИКА: разведать все локации стартового региона.
    _scoutRegionLocations(locations, startLoc.region);
    discoveredRegions.add(startLoc.region);

    isLoading = false;
    refresh();
  }

  // ═══════════════════════════════════════════════════════════
  // СМЕРТЬ
  // ═══════════════════════════════════════════════════════════

  void markDead(String reason) {
    isDead = true;
    deathReason = reason;
    refresh();
  }

  void clearDeath() {
    isDead = false;
    deathReason = '';
    refresh();
  }
}