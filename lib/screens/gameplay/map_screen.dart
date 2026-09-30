import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dark_hours/models/world/world_map.dart';
import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/search_event.dart';
import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/models/inventory/inventory.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/models/inventory/equipment.dart';
import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/models/conditions/active_condition.dart';
import 'package:dark_hours/models/combat/combat.dart';
import 'package:dark_hours/models/time/rest_action.dart';
import 'package:dark_hours/models/items/recipe.dart';
import 'package:dark_hours/models/time/game_time.dart';
import 'package:dark_hours/models/story/story_node.dart';

import 'package:dark_hours/services/save/save_manager.dart';
import 'package:dark_hours/services/items/item_loader.dart';
import 'package:dark_hours/services/items/search_event_loader.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/services/time/time_manager.dart';
import 'package:dark_hours/services/progress/run_tracker.dart';
import 'package:dark_hours/services/progress/achievement_checker.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

import 'package:dark_hours/widgets/panels/inventory_panel.dart';
import 'package:dark_hours/widgets/panels/equipment_panel.dart';
import 'package:dark_hours/widgets/panels/conditions_panel.dart';
import 'package:dark_hours/widgets/panels/rest_panel.dart';
import 'package:dark_hours/widgets/panels/craft_panel.dart';
import 'package:dark_hours/widgets/panels/penalties_panel.dart';
import 'package:dark_hours/widgets/indicators/time_indicator.dart';
import 'package:dark_hours/widgets/indicators/animated_stat_bar.dart';
import 'package:dark_hours/widgets/effects/floating_effect.dart';
import 'package:dark_hours/widgets/cards/animated_location_card.dart';
import 'package:dark_hours/widgets/effects/shimmer_button.dart';

import 'package:dark_hours/screens/main/death_screen.dart';
import 'package:dark_hours/screens/gameplay/combat_screen.dart';
import 'package:dark_hours/screens/gameplay/story_screen.dart';

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

  // Счётчики обысков и открытые скрытые локации
  final Map<String, int> _searchedCounts = {};
  final Set<String> _unlockedLocations = {};

  bool _isDead = false;
  String _deathReason = '';

  final RunTracker tracker = RunTracker();

  DateTime? _lastCollapseTime;
  bool _autoSleepTriggered = false;

  @override
  void initState() {
    super.initState();
    _playMapMusic();
    _loadMap();
  }

  Future<void> _playMapMusic() async {
    await AudioService.playMusic('audio/music/map_theme.ogg');
  }

  /// Запустить ambience для текущей локации
  Future<void> _startAmbienceFor(Location loc) async {
    final path = AudioService.ambienceForLocation(
      locationId: loc.id,
      type: loc.type,
      region: loc.region,
      dangerLevel: loc.dangerLevel,
    );
    if (path != null) {
      await AudioService.playAmbience(path);
    }
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
    await SearchEventLoader.init();
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

      _searchedCounts.clear();
      _searchedCounts.addAll(s.searchedCounts);

      _unlockedLocations.clear();
      _unlockedLocations.addAll(s.unlockedLocations);

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

      // Ambience для стартовой локации
      await _startAmbienceFor(startLoc);
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

      // Ambience для стартовой локации
      await _startAmbienceFor(startLoc);
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
    _checkFatigue();

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

  void _checkFatigue() {
    if (_isDead || fatigue < 80) return;

    if (fatigue >= 80 && fatigue < 95) {
      return;
    }

    if (fatigue >= 95 && fatigue < 100) {
      if (!_autoSleepTriggered) {
        _autoSleepTriggered = true;
        _forceAutoSleep();
      }
      return;
    }

    if (fatigue >= 100) {
      if (_lastCollapseTime != null &&
          DateTime.now().difference(_lastCollapseTime!).inHours < 24) {
        _isDead = true;
        _deathReason =
            'Твоё тело не выдержало повторного истощения. Сердце остановилось.';
        _applyStatsOnDeath();
        _showDeathScreen();
        return;
      }

      _collapse();
    }
  }

  Future<void> _forceAutoSleep() async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '😴 Ты засыпаешь прямо на месте... (1 час)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color.fromARGB(255, 100, 100, 200),
      ),
    );

    await _advanceTime(60, isSleeping: true);

    fatigue = (fatigue - 15).clamp(0, 100);
    stamina = (stamina - 15).clamp(0, 100);
    sanity = (sanity - 5).clamp(0, 100);

    _autoSleepTriggered = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '😵 Ты проснулся. Разбитость: -15 выносливости.',
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Color.fromARGB(255, 150, 100, 100),
        ),
      );
      setState(() {});
    }

    await _autoSave();
  }

  Future<void> _collapse() async {
    _lastCollapseTime = DateTime.now();
    tracker.collapsesCount += 1;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 10, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Text(
          '💀 КОЛЛАПС',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Ты теряешь сознание от истощения. Проходит 4 часа...\n\n'
          '⚠️ Если это повторится в течение 24 часов — твоё сердце остановится.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context);
            },
            child: const Text(
              'ОЧНУТЬСЯ',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    await _advanceTime(240, isSleeping: true);
    fatigue = 60;
    health = (health - 20).clamp(0, 100);
    sanity = (sanity - 15).clamp(0, 100);

    if (Random().nextInt(100) < 30 && inventory.items.isNotEmpty) {
      _loseRandomItems(2);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💀 Пока ты был без сознания, тебя ограбили!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    if (Random().nextInt(100) < 40) {
      final coldCond = allConditions.firstWhere(
        (c) => c.id == 'cold',
        orElse: () => allConditions.first,
      );
      if (!ConditionManager.hasCondition(activeConditions, 'cold')) {
        activeConditions.add(ActiveCondition(
          condition: coldCond,
          daysRemaining: coldCond.durationDays,
        ));
        tracker.infections += 1;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('😵 Ты очнулся. -20 HP, -15 психики.'),
          duration: Duration(seconds: 3),
          backgroundColor: Color.fromARGB(255, 100, 50, 50),
        ),
      );
    }

    await _autoSave();
    if (mounted) setState(() {});
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
      await AudioService.stopAmbience();
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
      searchedCounts: _searchedCounts,
      unlockedLocations: _unlockedLocations.toList(),
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
    AudioService.playTap();
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
      AudioService.playError();
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

    tracker.craftedCount += 1;
    if (recipe.id == 'molotov_craft') {
      tracker.alchemistCrafted = true;
    }

    stamina = (stamina - 5).clamp(0, 100);
    fatigue = (fatigue + 5).clamp(0, 100);

    await _advanceTime(recipe.timeMinutes);
    await _autoSave();

    if (mounted) {
      AudioService.playSuccess();
      FloatingEffectOverlay.show(
        context,
        'Создано: ${recipe.resultName}',
        color: const Color.fromARGB(255, 100, 180, 100),
        icon: Icons.build,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.resultIcon} Создано: ${recipe.resultName}'),
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

    final story = await Story.load(widget.characterId, chapter: chapter);
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
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context, true);
            },
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
      searchedCounts: _searchedCounts,
      unlockedLocations: _unlockedLocations.toList(),
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

      _searchedCounts.clear();
      _searchedCounts.addAll(save.searchedCounts);

      _unlockedLocations.clear();
      _unlockedLocations.addAll(save.unlockedLocations);
    });

    // Музыка: возвращаемся на карту — играем map_theme
    await AudioService.playMusic('audio/music/map_theme.ogg');

    // Ambience для текущей локации
    if (_map != null) {
      await _startAmbienceFor(_map!.current);
    }

    _checkDeath();
  }

  // ====== ОТДЫХ ======
  void _showRestPanel() {
    AudioService.playTap();
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
      final riskRoll = Random().nextInt(100);
      final warmth = equipment.totalWarmth;
      final coldChance = warmth >= 40 ? 10 : 30;
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
        final theftRoll = Random().nextInt(100);
        if (theftRoll < 25 && inventory.items.isNotEmpty) {
          final stolen = inventory.items[
              Random().nextInt(inventory.items.length)];
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
        final attackRoll = Random().nextInt(100);
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

    if (target.hidden && !_unlockedLocations.contains(target.id)) {
      return;
    }

    AudioService.playClick();

    stamina = (stamina - 5).clamp(0, 100);

    await _advanceTime(20);

    setState(() {
      _map!.moveTo(locationId);
    });

    // Ambience для новой локации
    await _startAmbienceFor(target);

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

    if (loc.maxSearches == 0 &&
        loc.lootPool.isEmpty &&
        loc.enemies.isEmpty &&
        loc.risk == null) {
      AudioService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Здесь нечего искать'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    AudioService.playClick();

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

    final searched = _searchedCounts[loc.id] ?? 0;
    final hasRemainingLoot = searched < loc.maxSearches;

    if (hasRemainingLoot) {
      await _standardSearch(loc);
    } else {
      await _eventSearch(loc);
    }

    await _advanceTime(loc.searchTime);

    if (hasRemainingLoot && loc.enemies.isNotEmpty && !loc.isFinal) {
      final enemyRoll = Random().nextInt(3);
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

  Future<void> _standardSearch(Location loc) async {
    final searched = _searchedCounts[loc.id] ?? 0;
    _searchedCounts[loc.id] = searched + 1;

    String? foundItemId;
    if (loc.lootPool.isNotEmpty) {
      foundItemId = loc.lootPool[Random().nextInt(loc.lootPool.length)];
      final item = ItemLoader.findById(foundItemId);
      if (item != null && inventory.addItem(item)) {
        tracker.lootedCount += 1;
        if (inventory.items.length > tracker.maxInventorySize) {
          tracker.maxInventorySize = inventory.items.length;
        }
        if (mounted) {
          AudioService.playSuccess();
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
  }

  Future<void> _eventSearch(Location loc) async {
    final pool = SearchEventLoader.getPoolFor(
      locationEvents: loc.searchEvents,
    );

    final hiddenMap = SearchEventLoader.buildHiddenMap(_map!.locations);

    final event = _rollSearchEvent(
      pool: pool,
      currentLocationId: loc.id,
      hiddenMap: hiddenMap,
    );

    if (event == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ты обходишь ещё раз. Ничего нового.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
      return;
    }

    await _applySearchEvent(event, loc);
  }

  Future<void> _applySearchEvent(SearchEvent event, Location loc) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(event.text),
          duration: const Duration(seconds: 4),
          backgroundColor: const Color.fromARGB(255, 40, 40, 60),
        ),
      );
    }

    final effect = event.effect;

    if (effect['health'] != null) {
      health = (health + (effect['health'] as int)).clamp(0, 100);
      if (mounted) {
        FloatingEffectOverlay.show(
          context,
          '${effect['health'] > 0 ? '+' : ''}${effect['health']} ❤️',
          color: effect['health'] > 0 ? Colors.green : Colors.red,
          icon: Icons.favorite,
        );
      }
    }
    if (effect['sanity'] != null) {
      sanity = (sanity + (effect['sanity'] as int)).clamp(0, 100);
      if (mounted) {
        FloatingEffectOverlay.show(
          context,
          '${effect['sanity'] > 0 ? '+' : ''}${effect['sanity']} 🧠',
          color: effect['sanity'] > 0 ? Colors.purple : Colors.red,
          icon: Icons.psychology,
        );
      }
    }
    if (effect['hunger'] != null) {
      hunger = (hunger + (effect['hunger'] as int)).clamp(0, 100);
    }
    if (effect['thirst'] != null) {
      thirst = (thirst + (effect['thirst'] as int)).clamp(0, 100);
    }
    if (effect['stamina'] != null) {
      stamina = (stamina + (effect['stamina'] as int)).clamp(0, 100);
    }
    if (effect['fatigue'] != null) {
      fatigue = (fatigue + (effect['fatigue'] as int)).clamp(0, 100);
    }

    if (effect['random_loot'] != null) {
      final lootIds = List<String>.from(effect['random_loot']);
      if (lootIds.isNotEmpty) {
        final randomId = lootIds[Random().nextInt(lootIds.length)];
        final item = ItemLoader.findById(randomId);
        if (item != null && inventory.addItem(item)) {
          tracker.lootedCount += 1;
          if (mounted) {
            AudioService.playSuccess();
            FloatingEffectOverlay.show(
              context,
              'Найдено: ${item.name}',
              color: const Color.fromARGB(255, 100, 180, 100),
              icon: Icons.search,
            );
          }
        }
      }
    }

    if (effect['unlock_location'] != null) {
      final unlockValue = effect['unlock_location'];

      if (unlockValue == 'auto') {
        final hiddenMap = SearchEventLoader.buildHiddenMap(_map!.locations);
        final hiddenId = hiddenMap[loc.id];

        if (hiddenId != null && !_unlockedLocations.contains(hiddenId)) {
          _unlockedLocations.add(hiddenId);
          final hidden = _map!.getById(hiddenId);
          if (hidden != null && mounted) {
            AudioService.playNotification();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🔓 Открыто новое место: ${hidden.name}',
                ),
                duration: const Duration(seconds: 4),
                backgroundColor: const Color.fromARGB(255, 200, 180, 100),
              ),
            );
          }
        }
      } else if (unlockValue is String && unlockValue != 'auto') {
        if (!_unlockedLocations.contains(unlockValue)) {
          _unlockedLocations.add(unlockValue);
          final hidden = _map!.getById(unlockValue);
          if (hidden != null && mounted) {
            AudioService.playNotification();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🔓 Открыто новое место: ${hidden.name}',
                ),
                duration: const Duration(seconds: 4),
                backgroundColor: const Color.fromARGB(255, 200, 180, 100),
              ),
            );
          }
        }
      }
    }

    if (effect['flag_set'] != null) {
      final flag = effect['flag_set'] as String;
      _triggeredStoryNodes.add(flag);
    }

    if (effect['infect'] != null) {
      final infectData = effect['infect'] as Map<String, dynamic>;
      final source = infectData['source'] as String;
      final chance = (infectData['chance'] as num?)?.toDouble() ?? 0.5;

      final newCondition =
          ConditionManager.tryInfect(allConditions, source, chance);
      if (newCondition != null &&
          !ConditionManager.hasCondition(
              activeConditions, newCondition.id)) {
        activeConditions.add(ActiveCondition(
          condition: newCondition,
          daysRemaining: newCondition.durationDays,
        ));
        tracker.infections += 1;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${newCondition.icon} Ты подхватил: ${newCondition.name}',
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }

    if (effect['combat_start'] != null) {
      final combat = effect['combat_start'] as Map<String, dynamic>;
      final enemyName = combat['enemy_name'] as String? ?? 'Враг';
      final enemyHealth = combat['enemy_health'] as int? ?? 30;
      final enemyDamage = combat['enemy_damage'] as int? ?? 10;
      final enemyProtection = combat['enemy_protection'] as int? ?? 0;
      final enemyStrength = combat['enemy_strength'] as int? ?? 5;

      await _startCombatWithParams(
        enemyName: enemyName,
        enemyHealth: enemyHealth,
        enemyDamage: enemyDamage,
        enemyProtection: enemyProtection,
        enemyStrength: enemyStrength,
      );
      return;
    }
  }

  SearchEvent? _rollSearchEvent({
    required List<SearchEvent> pool,
    required String currentLocationId,
    required Map<String, String> hiddenMap,
  }) {
    final rng = Random();

    final applicable = pool.where((e) {
      return e.isApplicableTo(
        currentLocationId: currentLocationId,
        hiddenLocations: hiddenMap,
      );
    }).toList();

    double totalChance = 0.0;
    for (final e in applicable) {
      totalChance += e.chance;
    }

    final roll = rng.nextDouble() * (totalChance > 1.0 ? totalChance : 1.0);

    double cumulative = 0.0;
    for (final event in applicable) {
      cumulative += event.chance;
      if (roll < cumulative) {
        return event;
      }
    }

    return null;
  }

  // ====== БОЙ ======
  Future<void> _startCombat(String enemyId) async {
    final enemyData = _getEnemyData(enemyId);
    if (enemyData == null) return;

    await _startCombatWithParams(
      enemyName: enemyData['name']!,
      enemyHealth: enemyData['health']!,
      enemyDamage: enemyData['damage']!,
      enemyProtection: enemyData['protection']!,
      enemyStrength: enemyData['strength']!,
      damageType: enemyData['damageType'] ?? 'blunt',
      abilities: enemyData['abilities'] ?? [],
    );
  }

  Future<void> _startCombatWithParams({
    required String enemyName,
    required int enemyHealth,
    required int enemyDamage,
    required int enemyProtection,
    required int enemyStrength,
    String damageType = 'blunt',
    List<CombatAbility> abilities = const [],
  }) async {
    tracker.hadCombat = true;

    final player = Combatant(
      name: widget.characterName,
      health: health,
      maxHealth: 100,
      damage: equipment.totalDamage > 0 ? equipment.totalDamage : 3,
      protection: equipment.totalProtection,
      strength: strength,
      damageType: equipment.weaponDamageType,
      resistances: equipment.totalResistances,
    );

    final enemy = Combatant(
      name: enemyName,
      health: enemyHealth,
      maxHealth: enemyHealth,
      damage: enemyDamage,
      protection: enemyProtection,
      strength: enemyStrength,
      damageType: damageType,
      abilities: abilities,
    );

    // Останавливаем ambience на время боя
    await AudioService.stopAmbience();

    final rawResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CombatScreen(player: player, enemy: enemy),
      ),
    );

    if (!mounted) return;

    // Возвращаем музыку карты и ambience локации
    await AudioService.playMusic('audio/music/map_theme.ogg');
    if (_map != null) {
      await _startAmbienceFor(_map!.current);
    }

    String result = 'defeat';

    if (rawResult is Map) {
      result = rawResult['result'] ?? 'defeat';
      final newHealth = rawResult['playerHealth'] ?? player.health;
      final oldHealth = health;
      health = (newHealth as int).clamp(0, 100);

      if (health < oldHealth) tracker.hadDamage = true;

      if (rawResult['wasBleeding'] == true) {
        final bleedCond = allConditions.firstWhere(
          (c) => c.id == 'bleeding',
          orElse: () => allConditions.first,
        );
        if (!ConditionManager.hasCondition(activeConditions, 'bleeding')) {
          activeConditions.add(ActiveCondition(
            condition: bleedCond,
            daysRemaining: 1,
          ));
        }
      }
      if (rawResult['wasPoisoned'] == true) {
        final poisonCond = allConditions.firstWhere(
          (c) => c.id == 'food_poisoning',
          orElse: () => allConditions.first,
        );
        if (!ConditionManager.hasCondition(
            activeConditions, 'food_poisoning')) {
          activeConditions.add(ActiveCondition(
            condition: poisonCond,
            daysRemaining: poisonCond.durationDays,
          ));
          tracker.infections += 1;
        }
      }
      if (rawResult['wasInfected'] == true) {
        final infectCond = allConditions.firstWhere(
          (c) => c.id == 'infection',
          orElse: () => allConditions.first,
        );
        if (!ConditionManager.hasCondition(activeConditions, 'infection')) {
          activeConditions.add(ActiveCondition(
            condition: infectCond,
            daysRemaining: infectCond.durationDays,
          ));
          tracker.infections += 1;
        }
      }
    } else if (rawResult is String) {
      result = rawResult;
      health = player.health.clamp(0, 100);
    }

    await _advanceTime(10);

    if (result == 'victory') {
      tracker.kills += 1;
      if (mounted) {
        AudioService.playSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏆 Победа!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (result == 'defeat') {
      _handleDefeat(enemyName);
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

  void _handleDefeat(String enemyName) {
    final isStoryBoss = ['Васька', 'Сергей'].contains(enemyName);

    if (isStoryBoss) {
      _checkDeath();
      return;
    }

    final isDangerous = enemyName.contains('Бандит') ||
        enemyName.contains('Заражённый') ||
        enemyName.contains('Вооружённый');

    tracker.defeats += 1;

    if (isDangerous) {
      health = 5;

      final bleedCond = allConditions.firstWhere(
        (c) => c.id == 'bleeding',
        orElse: () => allConditions.first,
      );
      if (!ConditionManager.hasCondition(activeConditions, 'bleeding')) {
        activeConditions.add(ActiveCondition(
          condition: bleedCond,
          daysRemaining: 1,
        ));
      }

      _loseRandomItems(3);
      sanity = (sanity - 25).clamp(0, 100);
      fatigue = (fatigue + 40).clamp(0, 100);
      _moveToSafeLocation();

      if (mounted) {
        _showDefeatDialog(
          title: '💀 ТЯЖЁЛОЕ ПОРАЖЕНИЕ',
          message: 'Ты едва выжил. Раны кровоточат, в глазах темнеет. '
              'Тебя ограбили и бросили на произвол судьбы.\n\n'
              'Ты очнулся в безопасном месте. Потеряно 3 предмета.',
          color: Colors.red[900]!,
        );
      }
    } else {
      health = 15;

      _loseRandomItems(2);
      sanity = (sanity - 10).clamp(0, 100);
      fatigue = (fatigue + 30).clamp(0, 100);
      _moveToNeighborLocation();

      if (mounted) {
        _showDefeatDialog(
          title: '🤕 ПОРАЖЕНИЕ',
          message: 'Тебя избили и ограбили. Ты отделался синяками, '
              'но потерял 2 предмета.\n\n'
              'Ты очнулся в соседнем районе.',
          color: Colors.orange[900]!,
        );
      }
    }
  }

  Future<void> _showDefeatDialog({
    required String title,
    required String message,
    required Color color,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 10, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        content: Text(
          '$message\n\n📊 Всего поражений в этом забеге: ${tracker.defeats}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context);
            },
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
  }

  void _moveToSafeLocation() {
    if (_map == null) return;

    final safeLocations = _map!.locations
        .where((l) =>
            l.dangerLevel <= 2 &&
            l.id != _map!.currentLocationId &&
            !l.hidden)
        .toList();

    if (safeLocations.isEmpty) return;

    final target = safeLocations[Random().nextInt(safeLocations.length)];
    _map!.moveTo(target.id);
  }

  void _moveToNeighborLocation() {
    if (_map == null) return;

    final neighbors = _map!.availableConnections
        .where((l) => !l.hidden || _unlockedLocations.contains(l.id))
        .toList();

    if (neighbors.isEmpty) return;

    final target = neighbors[Random().nextInt(neighbors.length)];
    _map!.moveTo(target.id);
  }

  void _loseRandomItems(int count) {
    final rng = Random();
    for (int i = 0; i < count && inventory.items.isNotEmpty; i++) {
      final index = rng.nextInt(inventory.items.length);
      final lost = inventory.items[index];
      inventory.removeAll(lost.id);
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
          'damageType': 'blunt',
          'abilities': <CombatAbility>[],
        };
      case 'looter_armed':
        return {
          'name': 'Вооружённый мародёр',
          'health': 40,
          'damage': 14,
          'protection': 4,
          'strength': 7,
          'damageType': 'cutting',
          'abilities': <CombatAbility>[
            const CombatAbility(
              id: 'poison',
              name: 'Отравленный клинок',
              description: 'Клинок смазан ядом',
              chance: 0.3,
              effect: 'poison',
            ),
          ],
        };
      case 'bandit':
        return {
          'name': 'Бандит',
          'health': 55,
          'damage': 18,
          'protection': 6,
          'strength': 8,
          'damageType': 'blunt',
          'abilities': <CombatAbility>[
            const CombatAbility(
              id: 'stun',
              name: 'Оглушающий удар',
              description: 'Удар в голову',
              chance: 0.25,
              effect: 'skip_turn',
            ),
            const CombatAbility(
              id: 'bleed',
              name: 'Рваная рана',
              description: 'Глубокий порез',
              chance: 0.2,
              effect: 'bleeding',
            ),
          ],
        };
      case 'infected':
        return {
          'name': 'Заражённый',
          'health': 35,
          'damage': 15,
          'protection': 2,
          'strength': 6,
          'damageType': 'cutting',
          'abilities': <CombatAbility>[
            const CombatAbility(
              id: 'infection',
              name: 'Инфекционный укус',
              description: 'Укус с заражением',
              chance: 0.5,
              effect: 'infection',
            ),
          ],
        };
      default:
        return null;
    }
  }

  // ====== ПРЕДМЕТЫ ======
  void _useItem(InventoryItem item) {
    AudioService.playSuccess();
    hunger = (hunger + item.hungerRestore).clamp(0, 100);
    thirst = (thirst + item.thirstRestore).clamp(0, 100);
    health = (health + item.healthRestore).clamp(0, 100);
    sanity = (sanity + item.sanityRestore).clamp(0, 100);

    if (item.id.contains('pill') ||
        item.id.contains('bandage') ||
        item.id == 'first_aid_kit' ||
        item.id == 'herb_medkit' ||
        item.id == 'splint') {
      tracker.medicineUsed += 1;
    }

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
    AudioService.playClick();

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
    AudioService.playClick();
    inventory.removeAll(item.id);
    _autoSave();
    setState(() {});
  }

  void _showInventory() {
    AudioService.playTap();
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
    AudioService.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return EquipmentPanel(
            equipment: equipment,
            onUnequip: (slot) {
              AudioService.playClick();
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

  // ====== UI ======
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(context);
            },
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioService.playClick();
            AudioService.stopAmbience();
            Navigator.pop(context);
          },
        ),
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

                  if (current.maxSearches > 0 ||
                      current.lootPool.isNotEmpty ||
                      current.enemies.isNotEmpty ||
                      current.risk != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _searchLocation,
                        icon: const Icon(Icons.search, size: 18),
                        label: Text(
                          '🔍  ${_searchButtonLabel(current)} (${current.searchTime} мин)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _searchButtonColor(current),
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
                              AudioService.playSuccess();
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

                  ..._buildAvailableConnections(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _searchButtonLabel(Location loc) {
    if (loc.maxSearches == 0) {
      return 'ОСМОТРЕТЬСЯ';
    }

    final searched = _searchedCounts[loc.id] ?? 0;
    final remaining = loc.maxSearches - searched;

    if (remaining > 0) {
      return 'ОБЫСКАТЬ · осталось $remaining из ${loc.maxSearches}';
    }

    return 'ОСМОТРЕТЬСЯ (рискованно)';
  }

  Color _searchButtonColor(Location loc) {
    if (loc.maxSearches == 0) {
      return const Color.fromARGB(255, 100, 150, 200);
    }

    final searched = _searchedCounts[loc.id] ?? 0;
    if (searched < loc.maxSearches) {
      return const Color.fromARGB(255, 100, 150, 200);
    }

    return const Color.fromARGB(255, 150, 100, 100);
  }

  List<Widget> _buildAvailableConnections() {
    final connections = _map!.availableConnections.where((loc) {
      if (loc.hidden && !_unlockedLocations.contains(loc.id)) {
        return false;
      }
      return true;
    }).toList();

    return connections.asMap().entries.map((entry) {
      return AnimatedLocationCard(
        index: entry.key,
        child: _buildLocationCard(entry.value),
      );
    }).toList();
  }

  Widget _buildCurrentLocation(Location loc) {
    final searched = _searchedCounts[loc.id] ?? 0;
    final remaining = (loc.maxSearches - searched).clamp(0, loc.maxSearches);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 20, 20, 20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: loc.hidden
              ? const Color.fromARGB(255, 100, 200, 100)
              : const Color.fromARGB(255, 200, 180, 100),
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
                    Row(
                      children: [
                        Text(
                          'ТЫ ЗДЕСЬ · ${gameTime.phase.name.toUpperCase()}',
                          style: TextStyle(
                            color: gameTime.phase.color,
                            fontSize: 10,
                            letterSpacing: 2.0,
                          ),
                        ),
                        if (loc.hidden) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 100, 200, 100)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color.fromARGB(
                                    255, 100, 200, 100),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '🔓 СКРЫТОЕ',
                              style: TextStyle(
                                color: Color.fromARGB(255, 100, 200, 100),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
              if (loc.maxSearches > 0)
                _buildChip(
                  '🔍 $remaining / ${loc.maxSearches}',
                  remaining > 0
                      ? Colors.cyan[400]!
                      : Colors.grey[600]!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location loc) {
    final isHidden = loc.hidden;
    final searched = _searchedCounts[loc.id] ?? 0;
    final remaining = (loc.maxSearches - searched).clamp(0, loc.maxSearches);

    final borderColor = isHidden
        ? const Color.fromARGB(255, 100, 200, 100).withOpacity(0.5)
        : loc.dangerColor.withOpacity(0.4);

    return GestureDetector(
      onTap: () => _moveTo(loc.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 18, 18, 18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
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
                      if (isHidden) ...[
                        const SizedBox(width: 6),
                        const Text('🔓', style: TextStyle(fontSize: 12)),
                      ],
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
                      if (loc.maxSearches > 0 && remaining > 0) ...[
                        const SizedBox(width: 6),
                        _buildChip(
                          '🔍 $remaining',
                          Colors.cyan[400]!,
                          small: true,
                        ),
                      ],
                      if (loc.maxSearches > 0 && remaining == 0) ...[
                        const SizedBox(width: 6),
                        _buildChip(
                          '🔍 пусто',
                          Colors.grey[600]!,
                          small: true,
                        ),
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
                  color: fatigue > 80
                      ? Colors.red
                      : (fatigue > 60 ? Colors.orange : Colors.grey),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Устал $fatigue%',
                  style: TextStyle(
                    color: fatigue > 80
                        ? Colors.red
                        : (fatigue > 60 ? Colors.orange : Colors.grey[500]),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (tracker.defeats > 0) ...[
                Icon(
                  Icons.healing,
                  color: Colors.orange[300],
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${tracker.defeats}',
                  style: TextStyle(
                    color: Colors.orange[300],
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