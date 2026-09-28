import 'package:flutter/material.dart';
import '../models/world_map.dart';
import '../models/location.dart';
import '../models/save_data.dart';
import '../models/inventory.dart';
import '../models/inventory_item.dart';
import '../models/equipment.dart';
import '../models/condition.dart';
import '../models/active_condition.dart';
import '../models/combat.dart';
import '../models/rest_action.dart';
import '../models/recipe.dart';
import '../models/game_time.dart';
import '../services/save_manager.dart';
import '../services/item_loader.dart';
import '../services/condition_manager.dart';
import '../services/time_manager.dart';
import '../services/run_tracker.dart';
import '../services/achievement_checker.dart';
import '../services/achievement_manager.dart';
import '../widgets/inventory_panel.dart';
import '../widgets/equipment_panel.dart';
import '../widgets/conditions_panel.dart';
import '../widgets/rest_panel.dart';
import '../widgets/craft_panel.dart';
import '../widgets/time_indicator.dart';
import '../widgets/penalties_panel.dart';
import '../widgets/death_screen.dart';
import '../widgets/animated_stat_bar.dart';
import '../widgets/floating_effect.dart';
import '../widgets/animated_location_card.dart';
import '../widgets/shimmer_button.dart';
import 'combat_screen.dart';
import 'story_screen.dart';

class MapScreen extends StatefulWidget {
  final String characterId;
  final String characterName;
  final SaveData? resumeFrom;

  const MapScreen({
    super.key,
    required this.characterId,
    required this.characterName,
    this.resumeFrom,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  WorldMap? _map;
  bool _isLoading = true;

  // Ресурсы
  int hunger = 100;
  int thirst = 100;
  int health = 100;
  int sanity = 100;
  int stamina = 100;
  int fatigue = 0;

  // Игровое время
  late GameTime gameTime;

  int chapter = 1;

  // Характеристики персонажа
  int intelligence = 5;
  int strength = 5;

  final Inventory inventory = Inventory(maxWeight: 30.0);
  final Equipment equipment = Equipment();

  List<Condition> allConditions = [];
  final List<ActiveCondition> activeConditions = [];

  List<Recipe> allRecipes = [];

  final Set<String> _triggeredStoryNodes = {};

  bool _isDead = false;
  String _deathReason = '';

  // Трекер текущего забега
  final RunTracker tracker = RunTracker();

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  void _loadCharacterStats() {
    switch (widget.characterId) {
      case 'boris':
        intelligence = 5;
        strength = 7;
        break;
      case 'alina':
        intelligence = 4;
        strength = 3;
        break;
      case 'ivan':
        intelligence = 8;
        strength = 4;
        break;
      case 'andrey':
        intelligence = 9;
        strength = 2;
        break;
      case 'darya':
        intelligence = 7;
        strength = 4;
        break;
      default:
        intelligence = 5;
        strength = 5;
    }
  }

  Future<void> _loadMap() async {
    setState(() => _isLoading = true);

    await ItemLoader.init();
    allConditions = await Condition.loadAll();
    allRecipes = await Recipe.loadAll();
    _loadCharacterStats();

    final locations = await Location.loadAll();
    if (locations.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    if (widget.resumeFrom != null) {
      final s = widget.resumeFrom!;
      hunger = s.hunger;
      thirst = s.thirst;
      health = s.health;
      sanity = s.sanity;
      stamina = s.stamina;
      fatigue = s.fatigue;
      gameTime = GameTime.fromSave(s.timeMinutes);
      chapter = s.chapter;

      _triggeredStoryNodes.addAll(s.history);

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

      setState(() {
        _map = WorldMap(
          locations: locations,
          currentLocationId: startLoc.id,
          visitedLocations: {startLoc.id},
        );
        _isLoading = false;
      });
    } else {
      final startLoc = locations.firstWhere(
        (l) => l.isStart,
        orElse: () => locations.first,
      );

      setState(() {
        gameTime = GameTime(totalMinutes: 8 * 60);
        _map = WorldMap(
          locations: locations,
          currentLocationId: startLoc.id,
          visitedLocations: {startLoc.id},
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _advanceTime(int minutes, {bool isSleeping = false}) async {
    final oldDay = gameTime.day;
    final phaseBefore = gameTime.phase;

    gameTime.advance(minutes);
    final phaseAfter = gameTime.phase;

    final consumption = TimeManager.calculateConsumption(
      minutes: minutes,
      phase: phaseBefore,
      isSleeping: isSleeping,
    );

    hunger = (hunger + (consumption['hunger'] ?? 0)).clamp(0, 100);
    thirst = (thirst + (consumption['thirst'] ?? 0)).clamp(0, 100);
    if (!isSleeping) {
      fatigue = (fatigue + (consumption['fatigue'] ?? 0)).clamp(0, 100);
    }

    _applyConditionsTick();

    // Смена дня
    if (gameTime.day > oldDay) {
      tracker.nightsPassed += 1;
      if (phaseBefore == TimePhase.night) {
        tracker.nightsSurvived += 1;
      }

      if (sanity < 20) {
        tracker.sanityDaysLow += 1;
      } else {
        tracker.sanityDaysLow = 0;
      }

      // Проверка достижений на новый день
      if (mounted) {
        await AchievementChecker.check(
          context: context,
          characterId: widget.characterId,
          day: gameTime.day,
          inventorySize: inventory.items.length,
          tracker: tracker,
          sanityDays: tracker.sanityDaysLow,
        );
      }
    }

    _checkDeath();

    if (phaseBefore != phaseAfter && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${phaseAfter.icon} ${phaseAfter.name} — ${gameTime.formatted}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: phaseAfter.color.withOpacity(0.8),
        ),
      );
    }
  }

  void _checkDeath() {
    if (_isDead) return;

    String? reason;

    if (hunger <= 0) {
      reason = 'Ты умер от голода. Тело не выдержало.';
    } else if (thirst <= 0) {
      reason = 'Ты умер от обезвоживания.';
    } else if (health <= 0) {
      reason = 'Твои раны оказались смертельными.';
    } else if (fatigue >= 100) {
      reason = 'Ты умер от истощения. Сердце остановилось.';
    } else if (gameTime.isWinter) {
      reason = 'Пришла зима. Ты не успел добраться до станции.';
    }

    if (reason != null) {
      _isDead = true;
      _deathReason = reason;
      _applyStatsOnDeath();
      _showDeathScreen();
    }
  }

  Future<void> _applyStatsOnDeath() async {
    final stats = await AchievementManager.loadStats();
    stats.totalDeaths += 1;
    stats.totalDaysSurvived += gameTime.day;

    if (gameTime.day > stats.bestRunDays) {
      stats.bestRunDays = gameTime.day;
      stats.bestRunCharacter = widget.characterName;
    }

    tracker.applyToStats(stats);
    await AchievementManager.saveStats(stats);
  }

  void _showDeathScreen() {
    Future.microtask(() async {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeathScreen(
            reason: _deathReason,
            characterName: widget.characterName,
            dayReached: gameTime.day,
          ),
        ),
      );
      if (mounted) {
        await SaveManager.delete();
        Navigator.pop(context);
      }
    });
  }

  Future<void> _autoSave() async {
    if (_map == null) return;

    final data = SaveData(
      characterId: widget.characterId,
      characterName: widget.characterName,
      currentNodeId: 'map',
      currentLocationId: _map!.currentLocationId,
      onMap: true,
      hunger: hunger,
      thirst: thirst,
      health: health,
      sanity: sanity,
      stamina: stamina,
      fatigue: fatigue,
      timeMinutes: gameTime.totalMinutes,
      chapter: chapter,
      history: _triggeredStoryNodes.toList(),
      inventoryItems: inventory.toJson(),
      equipmentItems: equipment.toJson(),
      activeConditions: activeConditions
          .map((ac) => {
                'id': ac.condition.id,
                'daysRemaining': ac.daysRemaining,
              })
          .toList(),
      savedAt: DateTime.now(),
    );

    await SaveManager.save(data);
  }

  void _applyConditionsTick() {
    if (activeConditions.isEmpty) return;

    final deltas = ConditionManager.applyEffects(activeConditions);
    if (deltas['health'] != null) {
      health = (health + deltas['health']!).clamp(0, 100);
    }
    if (deltas['hunger'] != null) {
      hunger = (hunger + deltas['hunger']!).clamp(0, 100);
    }
    if (deltas['thirst'] != null) {
      thirst = (thirst + deltas['thirst']!).clamp(0, 100);
    }
    if (deltas['stamina'] != null) {
      stamina = (stamina + deltas['stamina']!).clamp(0, 100);
    }
    if (deltas['sanity'] != null) {
      sanity = (sanity + deltas['sanity']!).clamp(0, 100);
    }
  }

  // ====== КРАФТ ======
  void _showCraftPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CraftPanel(
              inventory: inventory,
              intelligence: intelligence,
              strength: strength,
              stamina: stamina,
              recipes: allRecipes,
              onCraft: (recipe) {
                _craftItem(recipe);
                setSheetState(() {});
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Future<void> _craftItem(Recipe recipe) async {
    if (stamina < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Слишком устал для крафта'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (final ing in recipe.ingredients) {
      for (int i = 0; i < ing.count; i++) {
        inventory.removeItem(ing.id);
      }
    }

    final resultItem = ItemLoader.findById(recipe.resultId);
    if (resultItem != null) {
      inventory.addItem(resultItem);
    }

    // Трекер крафта
    tracker.craftedCount += 1;
    if (recipe.id == 'molotov_craft') {
      tracker.alchemistCrafted = true;
    }

    stamina = (stamina - 5).clamp(0, 100);
    fatigue = (fatigue + 5).clamp(0, 100);

    await _advanceTime(recipe.timeMinutes);
    await _autoSave();

    if (mounted) {
      FloatingEffectOverlay.show(
        context,
        'Создано: ${recipe.resultName}',
        color: const Color.fromARGB(255, 100, 180, 100),
        icon: Icons.build,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${recipe.resultIcon} Создано: ${recipe.resultName}',
          ),
          backgroundColor: const Color.fromARGB(255, 100, 180, 100),
          duration: const Duration(seconds: 2),
        ),
      );

      await AchievementChecker.check(
        context: context,
        characterId: widget.characterId,
        day: gameTime.day,
        inventorySize: inventory.items.length,
        tracker: tracker,
      );
    }
  }

  // ====== СЮЖЕТНЫЕ ТРИГГЕРЫ ======
  Future<void> _checkStoryTrigger() async {
    final loc = _map!.current;

    if (loc.storyNode == null) return;
    if (!loc.canTriggerStory(
      currentChapter: chapter,
      currentCharacter: widget.characterId,
      triggeredNodes: _triggeredStoryNodes,
    )) {
      return;
    }

    final story = await Story.loadFor(widget.characterId);
    if (story == null) return;

    final node = story.getNode(loc.storyNode!);
    if (node == null) return;

    _triggeredStoryNodes.add(loc.storyNode!);
    await _autoSave();

    if (!mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
        title: const Text(
          '📖 СЮЖЕТНОЕ СОБЫТИЕ',
          style: TextStyle(
            color: Color.fromARGB(255, 200, 180, 100),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        content: Text(
          '${loc.name} — здесь тебя ждёт важная встреча.',
          style: TextStyle(color: Colors.grey[300], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ПРОДОЛЖИТЬ',
              style: TextStyle(
                color: Color.fromARGB(255, 200, 180, 100),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    final saveForStory = SaveData(
      characterId: widget.characterId,
      characterName: widget.characterName,
      currentNodeId: loc.storyNode!,
      currentLocationId: _map!.currentLocationId,
      onMap: false,
      hunger: hunger,
      thirst: thirst,
      health: health,
      sanity: sanity,
      stamina: stamina,
      fatigue: fatigue,
      timeMinutes: gameTime.totalMinutes,
      chapter: chapter,
      history: _triggeredStoryNodes.toList(),
      inventoryItems: inventory.toJson(),
      equipmentItems: equipment.toJson(),
      activeConditions: activeConditions
          .map((ac) => ({
                'id': ac.condition.id,
                'daysRemaining': ac.daysRemaining,
              }))
          .toList(),
      savedAt: DateTime.now(),
    );

    await SaveManager.save(saveForStory);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryScreen(
          characterId: widget.characterId,
          characterName: widget.characterName,
          resumeFrom: saveForStory,
        ),
      ),
    ).then((_) {
      _reloadFromSave();
    });
  }

  Future<void> _reloadFromSave() async {
    final save = await SaveManager.load();
    if (save == null || !mounted) return;

    setState(() {
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

      _triggeredStoryNodes.clear();
      _triggeredStoryNodes.addAll(save.history);
    });

    _checkDeath();
  }

  // ====== ОТДЫХ ======
  void _showRestPanel() {
    final loc = _map!.current;
    final isSafe = loc.dangerLevel <= 3;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return RestPanel(
          isSafeLocation: isSafe,
          onRest: (action) {
            Navigator.pop(bottomSheetContext);
            _rest(action);
          },
        );
      },
    );
  }

  Future<void> _rest(RestAction action) async {
    final loc = _map!.current;
    final isSafe = loc.dangerLevel <= 3;

    stamina = (stamina + action.staminaRestore).clamp(0, 100);
    health = (health + action.healthRestore).clamp(0, 100);
    sanity = (sanity + action.sanityRestore).clamp(0, 100);
    fatigue = (fatigue - action.fatigueReduce).clamp(0, 100);

    final hasSleepingBag = inventory.hasItem('sleeping_bag');
    if (hasSleepingBag) {
      stamina = (stamina + 10).clamp(0, 100);
      sanity = (sanity + 10).clamp(0, 100);
    }

    if (!isSafe) {
      final riskRoll = DateTime.now().millisecond % 100;
      final warmth = equipment.totalWarmth;
      final coldChance = warmth >= 20 ? 10 : 30;
      final phaseMultiplier = gameTime.phase.dangerMultiplier.toInt();

      if (riskRoll < coldChance) {
        final newCond = ConditionManager.tryInfect(
          allConditions,
          'cold_weather',
          1.0,
        );
        if (newCond != null &&
            !ConditionManager.hasCondition(activeConditions, newCond.id)) {
          activeConditions.add(
            ActiveCondition(
              condition: newCond,
              daysRemaining: newCond.durationDays,
            ),
          );
          tracker.infections += 1;
        }
      }

      if (action.timeMinutes >= 240) {
        final theftRoll = DateTime.now().millisecond % 100;
        if (theftRoll < 25 && inventory.items.isNotEmpty) {
          final stolen = inventory.items[
              DateTime.now().millisecond % inventory.items.length];
          inventory.removeAll(stolen.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('💀 Тебя ограбили! Украдено: ${stolen.name}'),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (action.timeMinutes >= 480) {
        final attackRoll = DateTime.now().millisecond % 100;
        if (attackRoll < 20 * phaseMultiplier) {
          _startCombat('looter_common');
          return;
        }
      }
    }

    await _advanceTime(action.timeMinutes, isSleeping: true);
    await _autoSave();

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${action.icon} Отдых: ${action.name}'),
          backgroundColor: const Color.fromARGB(255, 100, 180, 100),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ====== ПЕРЕМЕЩЕНИЕ ======
  Future<void> _moveTo(String locationId) async {
    final target = _map!.getById(locationId);
    if (target == null) return;

    stamina = (stamina - 5).clamp(0, 100);

    await _advanceTime(20);

    setState(() {
      _map!.moveTo(locationId);
    });

    await _autoSave();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Переход: ${target.name}'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color.fromARGB(255, 200, 180, 100),
      ),
    );

    await _checkStoryTrigger();
  }

  // ====== ОБЫСК ======
  Future<void> _searchLocation() async {
    final loc = _map!.current;

    if (loc.lootPool.isEmpty && loc.enemies.isEmpty && loc.risk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Здесь нечего искать'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    stamina = (stamina - 10).clamp(0, 100);
    fatigue = (fatigue + 8).clamp(0, 100);

    if (loc.risk != null) {
      final newCond = ConditionManager.tryInfect(allConditions, loc.risk!, 0.4);
      if (newCond != null &&
          !ConditionManager.hasCondition(activeConditions, newCond.id)) {
        activeConditions.add(
          ActiveCondition(
            condition: newCond,
            daysRemaining: newCond.durationDays,
          ),
        );
        tracker.infections += 1;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newCond.icon} Ты подхватил: ${newCond.name}'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }

    String? foundItemId;
    if (loc.lootPool.isNotEmpty) {
      foundItemId =
          loc.lootPool[DateTime.now().millisecond % loc.lootPool.length];
      final item = ItemLoader.findById(foundItemId);
      if (item != null && inventory.addItem(item)) {
        tracker.lootedCount += 1;
        if (inventory.items.length > tracker.maxInventorySize) {
          tracker.maxInventorySize = inventory.items.length;
        }
        if (mounted) {
          FloatingEffectOverlay.show(
            context,
            'Найдено: ${item.name}',
            color: const Color.fromARGB(255, 100, 180, 100),
            icon: Icons.search,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Найдено: ${item.icon} ${item.name}'),
              backgroundColor: const Color.fromARGB(255, 100, 180, 100),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ничего не найдено'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }

    await _advanceTime(loc.searchTime);

    if (loc.enemies.isNotEmpty && !loc.isFinal) {
      final enemyRoll = DateTime.now().millisecond % 3;
      if (enemyRoll == 0) {
        _startCombat(loc.enemies[0]);
        return;
      }
    }

    await _autoSave();

    if (mounted) {
      setState(() {});

      await AchievementChecker.check(
        context: context,
        characterId: widget.characterId,
        day: gameTime.day,
        inventorySize: inventory.items.length,
        tracker: tracker,
      );
    }
  }

  // ====== БОЙ ======
  Future<void> _startCombat(String enemyId) async {
    final enemyData = _getEnemyData(enemyId);
    if (enemyData == null) return;

    tracker.hadCombat = true;

    final player = Combatant(
      name: widget.characterName,
      health: health,
      maxHealth: 100,
      damage: equipment.totalDamage > 0 ? equipment.totalDamage : 3,
      protection: equipment.totalProtection,
      strength: strength,
    );

    final enemy = Combatant(
      name: enemyData['name']!,
      health: enemyData['health']!,
      maxHealth: enemyData['health']!,
      damage: enemyData['damage']!,
      protection: enemyData['protection']!,
      strength: enemyData['strength']!,
    );

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CombatScreen(player: player, enemy: enemy),
      ),
    );

    if (!mounted) return;

    final oldHealth = health;
    health = player.health.clamp(0, 100);

    if (health < oldHealth) {
      tracker.hadDamage = true;
    }

    await _advanceTime(10);

    if (result == 'victory') {
      tracker.kills += 1;

      if (health < 70) {
        final infect = ConditionManager.tryInfect(
          allConditions,
          'combat_wound',
          0.4,
        );
        if (infect != null &&
            !ConditionManager.hasCondition(activeConditions, infect.id)) {
          activeConditions.add(
            ActiveCondition(
              condition: infect,
              daysRemaining: infect.durationDays,
            ),
          );
          tracker.infections += 1;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Победа!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (result == 'defeat') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💀 Поражение. Ты едва выжил.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      health = 10;
    }

    await _autoSave();

    if (mounted) {
      setState(() {});

      await AchievementChecker.check(
        context: context,
        characterId: widget.characterId,
        day: gameTime.day,
        inventorySize: inventory.items.length,
        tracker: tracker,
      );
    }
  }

  Map<String, dynamic>? _getEnemyData(String id) {
    switch (id) {
      case 'looter_common':
        return {
          'name': 'Мародёр',
          'health': 25,
          'damage': 8,
          'protection': 1,
          'strength': 5,
        };
      case 'looter_armed':
        return {
          'name': 'Вооружённый мародёр',
          'health': 40,
          'damage': 14,
          'protection': 4,
          'strength': 7,
        };
      case 'bandit':
        return {
          'name': 'Бандит',
          'health': 55,
          'damage': 18,
          'protection': 6,
          'strength': 8,
        };
      case 'infected':
        return {
          'name': 'Заражённый',
          'health': 35,
          'damage': 15,
          'protection': 2,
          'strength': 6,
        };
      default:
        return null;
    }
  }

  // ====== ПРЕДМЕТЫ ======
  void _useItem(InventoryItem item) {
    hunger = (hunger + item.hungerRestore).clamp(0, 100);
    thirst = (thirst + item.thirstRestore).clamp(0, 100);
    health = (health + item.healthRestore).clamp(0, 100);
    sanity = (sanity + item.sanityRestore).clamp(0, 100);

    // Считаем медицинские предметы
    if (item.id.contains('pill') ||
        item.id.contains('bandage') ||
        item.id == 'first_aid_kit' ||
        item.id == 'herb_medkit' ||
        item.id == 'splint') {
      tracker.medicineUsed += 1;
    }

    // Всплывающие эффекты
    if (item.hungerRestore > 0) {
      FloatingEffectOverlay.show(
        context,
        '+${item.hungerRestore} 🍞',
        color: Colors.orange,
        icon: Icons.restaurant,
      );
    }
    if (item.thirstRestore > 0) {
      FloatingEffectOverlay.show(
        context,
        '+${item.thirstRestore} 💧',
        color: Colors.blue,
        icon: Icons.water_drop,
      );
    }
    if (item.healthRestore > 0) {
      FloatingEffectOverlay.show(
        context,
        '+${item.healthRestore} ❤️',
        color: Colors.red,
        icon: Icons.favorite,
      );
    }

    final curable = <ActiveCondition>[];
    for (final ac in activeConditions) {
      if (ConditionManager.tryCure(ac, item.id)) curable.add(ac);
    }
    for (final ac in curable) {
      activeConditions.remove(ac);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Вылечено: ${ac.condition.name}'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    }

    inventory.removeItem(item.id);
    _autoSave();
    setState(() {});
  }

  void _equipItem(InventoryItem item) {
    String? slot;
    if (item.sourceType == 'weapon') {
      slot = 'weapon';
    } else if (item.sourceType == 'armor') {
      slot = item.armorSlot;
    }
    if (slot == null) return;

    final old = equipment.unequip(slot);
    if (old != null) inventory.addItem(old);

    equipment.equip(item, slot);
    inventory.removeItem(item.id);
    _autoSave();
    setState(() {});
  }

  void _dropItem(InventoryItem item) {
    inventory.removeAll(item.id);
    _autoSave();
    setState(() {});
  }

  void _showInventory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return InventoryPanel(
            inventory: inventory,
            onUse: (item) {
              _useItem(item);
              setSheetState(() {});
            },
            onEquip: (item) {
              _equipItem(item);
              setSheetState(() {});
            },
            onDrop: (item) {
              _dropItem(item);
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  void _showEquipment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return EquipmentPanel(
            equipment: equipment,
            onUnequip: (slot) {
              final item = equipment.unequip(slot);
              if (item != null) inventory.addItem(item);
              setSheetState(() {});
              _autoSave();
              setState(() {});
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 10, 10, 10),
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 200, 180, 100),
          ),
        ),
      );
    }

    if (_map == null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 10, 10, 10),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Карта не найдена', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final current = _map!.current;
    final penalties = TimeManager.getPenalties(
      hunger: hunger,
      thirst: thirst,
      stamina: stamina,
      sanity: sanity,
      fatigue: fatigue,
    );

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'КАРТА',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            tooltip: 'Крафт',
            onPressed: _showCraftPanel,
          ),
          IconButton(
            icon: const Icon(Icons.hotel),
            tooltip: 'Отдохнуть',
            onPressed: _showRestPanel,
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Экипировка',
            onPressed: _showEquipment,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.backpack_outlined),
                tooltip: 'Инвентарь',
                onPressed: _showInventory,
              ),
              if (inventory.items.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 200, 180, 100),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${inventory.items.length}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          PenaltiesPanel(penalties: penalties),
          ConditionsPanel(conditions: activeConditions),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentLocation(current),
                  const SizedBox(height: 20),

                  if (current.lootPool.isNotEmpty ||
                      current.enemies.isNotEmpty ||
                      current.risk != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _searchLocation,
                        icon: const Icon(Icons.search, size: 18),
                        label: Text(
                          '🔍  ОБЫСКАТЬ (${current.searchTime} мин)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 100, 150, 200),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                  if (current.storyNode != null &&
                      current.canTriggerStory(
                        currentChapter: chapter,
                        currentCharacter: widget.characterId,
                        triggeredNodes: _triggeredStoryNodes,
                      ))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _checkStoryTrigger,
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: const Text(
                            '📖  СЮЖЕТНОЕ СОБЫТИЕ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 200, 120, 100),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (current.isFinal)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ShimmerButton(
                          text: '🏭  ВОЙТИ НА СТАНЦИЮ',
                          icon: Icons.flag,
                          onPressed: () async {
                            await AchievementManager.unlock('reached_station');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '🏭 Ты добрался до станции. Конец пути.',
                                  ),
                                  duration: Duration(seconds: 4),
                                  backgroundColor:
                                      Color.fromARGB(255, 200, 180, 100),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    'КУДА ИДТИ?',
                    style: TextStyle(
                      color: Color.fromARGB(255, 200, 180, 100),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Анимированные карточки локаций
                  ..._map!.availableConnections.asMap().entries.map((entry) {
                    return AnimatedLocationCard(
                      index: entry.key,
                      child: _buildLocationCard(entry.value),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocation(Location loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 200, 180, 100),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(loc.icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ТЫ ЗДЕСЬ · ${gameTime.phase.name.toUpperCase()}',
                      style: TextStyle(
                        color: gameTime.phase.color,
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            loc.description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChip('⚠️ ${loc.dangerName}', loc.dangerColor),
              _buildChip('⏱️ ${loc.searchTime} мин', Colors.blue[400]!),
              if (loc.enemies.isNotEmpty)
                _buildChip('👥 ${loc.enemies.length}', Colors.red[400]!),
              if (loc.lootPool.isNotEmpty)
                _buildChip('🎁 ${loc.lootPool.length}', Colors.green[400]!),
              if (loc.risk != null)
                _buildChip('☣️ Опасность', Colors.deepOrange[400]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location loc) {
    return GestureDetector(
      onTap: () => _moveTo(loc.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 18, 18, 18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: loc.dangerColor.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(loc.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          loc.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (loc.storyNode != null &&
                          loc.canTriggerStory(
                            currentChapter: chapter,
                            currentCharacter: widget.characterId,
                            triggeredNodes: _triggeredStoryNodes,
                          )) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 200, 120, 100),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '📖',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.description,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildChip('⚠️ ${loc.dangerLevel}',
                          loc.dangerColor,
                          small: true),
                      const SizedBox(width: 6),
                      if (loc.enemies.isNotEmpty)
                        _buildChip('👥 ${loc.enemies.length}',
                            Colors.red[400]!,
                            small: true),
                      if (loc.lootPool.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildChip('🎁', Colors.green[400]!, small: true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color.fromARGB(255, 200, 180, 100),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        border: Border(
          bottom: BorderSide(
            color: const Color.fromARGB(255, 200, 180, 100).withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              TimeIndicator(time: gameTime),
              const Spacer(),
              if (fatigue > 0) ...[
                Icon(
                  Icons.bedtime,
                  color: fatigue > 60 ? Colors.red : Colors.orange,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Устал $fatigue%',
                  style: TextStyle(
                    color: fatigue > 60 ? Colors.red : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                'Глава $chapter',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AnimatedStatBar(
                  icon: '🍞',
                  value: hunger,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedStatBar(
                  icon: '💧',
                  value: thirst,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedStatBar(
                  icon: '❤️',
                  value: health,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedStatBar(
                  icon: '🧠',
                  value: sanity,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedStatBar(
                  icon: '⚡',
                  value: stamina,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}