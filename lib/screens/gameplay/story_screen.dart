import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dark_hours/models/story/story_node.dart';
import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/models/inventory/inventory.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/models/inventory/equipment.dart';
import 'package:dark_hours/models/combat/combat.dart';
import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/models/conditions/active_condition.dart';
import 'package:dark_hours/models/progress/chapter_summary.dart';
import 'package:dark_hours/models/progress/achievement.dart';

import 'package:dark_hours/services/save/save_manager.dart';
import 'package:dark_hours/services/items/item_loader.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';
import 'package:dark_hours/services/progress/run_tracker.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/utils/time_format.dart';

import 'package:dark_hours/widgets/panels/inventory_panel.dart';
import 'package:dark_hours/widgets/panels/equipment_panel.dart';
import 'package:dark_hours/widgets/panels/conditions_panel.dart';
import 'package:dark_hours/widgets/effects/fade_in_text.dart';
import 'package:dark_hours/widgets/effects/floating_effect.dart';
import 'package:dark_hours/widgets/effects/achievement_notifier.dart';
import 'package:dark_hours/widgets/indicators/animated_stat_bar.dart';

import 'package:dark_hours/screens/gameplay/combat_screen.dart';
import 'package:dark_hours/screens/gameplay/map_screen.dart';
import 'package:dark_hours/screens/gameplay/chapter_end_screen.dart';

class StoryScreen extends StatefulWidget {
  final String characterId;
  final String characterName;
  final SaveData? resumeFrom;

  const StoryScreen({
    super.key,
    required this.characterId,
    required this.characterName,
    this.resumeFrom,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  Story? _story;
  StoryNode? _currentNode;
  bool _isLoading = true;
  bool _isEnd = false;

  // Ресурсы
  int hunger = 100;
  int thirst = 100;
  int health = 100;
  int sanity = 100;
  int stamina = 100;
  int fatigue = 0;
  int timeMinutes = 120;
  int chapter = 1;

  final List<String> _history = [];
  final Inventory inventory = Inventory(maxWeight: 30.0);
  final Equipment equipment = Equipment();

  // Болезни
  List<Condition> allConditions = [];
  final List<ActiveCondition> activeConditions = [];

  // Флаги
  final Set<String> _flags = {};

  // Трекер забега
  final RunTracker tracker = RunTracker();

  /// Подписка на поток разблокированных достижений.
  StreamSubscription<Achievement>? _achievementSub;

  @override
  void initState() {
    super.initState();
    _playStoryMusic();

    // Подписка на достижения.
    _achievementSub = AchievementManager.unlockStream.listen((ach) {
      if (mounted) AchievementNotifier.showPopup(context, ach);
    });

    _loadStory();
  }

  @override
  void dispose() {
    _achievementSub?.cancel();
    super.dispose();
  }

  Future<void> _playStoryMusic() async {
    await AudioService.playMusic('audio/music/story_theme.ogg');
  }

  Future<void> _loadStory() async {
    setState(() => _isLoading = true);

    await ItemLoader.init();
    allConditions = await Condition.loadAll();

    if (widget.resumeFrom != null) {
      chapter = widget.resumeFrom!.chapter;
    }

    final story = await Story.load(widget.characterId, chapter: chapter);

    if (story == null) {
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
      timeMinutes = s.timeMinutes;
      chapter = s.chapter;
      _history.addAll(s.history);
      _flags.addAll(s.history);

      for (final itemJson in s.inventoryItems) {
        inventory.items.add(InventoryItem.fromJson(itemJson));
      }

      final restoredEquipment = Equipment.fromJson(s.equipmentItems);
      equipment.weapon = restoredEquipment.weapon;
      equipment.head = restoredEquipment.head;
      equipment.body = restoredEquipment.body;
      equipment.hands = restoredEquipment.hands;
      equipment.feet = restoredEquipment.feet;
      equipment.backpack = restoredEquipment.backpack;

      for (final cJson in s.activeConditions) {
        final condId = cJson['id'] as String;
        final days = cJson['daysRemaining'] as int;
        try {
          final cond = allConditions.firstWhere((c) => c.id == condId);
          activeConditions.add(ActiveCondition(
            condition: cond,
            daysRemaining: days,
          ));
        } catch (e) {
          // Игнорируем невалидную болезнь
        }
      }

      final node =
          story.getNode(s.currentNodeId) ?? story.getNode(story.startNodeId);

      setState(() {
        _story = story;
        _currentNode = node;
        _isEnd = node?.choices.isEmpty ?? false;
        _isLoading = false;
      });

      if (node?.onEnter != null) _applyEffects(node!.onEnter);
    } else {
      final stats = await AchievementManager.loadStats();
      stats.playedCharacters.add(widget.characterId);
      stats.totalGamesPlayed += 1;
      await AchievementManager.saveStats(stats);

      setState(() {
        _story = story;
        _currentNode = story.getNode(story.startNodeId);
        _isLoading = false;
      });

      if (_currentNode?.onEnter != null) _applyEffects(_currentNode!.onEnter);
    }
  }

  void _applyEffects(Map<String, dynamic>? effects) {
    if (effects == null) return;

    if (effects['hunger'] != null) {
      hunger = (hunger + (effects['hunger'] as int)).clamp(0, 100);
    }
    if (effects['thirst'] != null) {
      thirst = (thirst + (effects['thirst'] as int)).clamp(0, 100);
    }
    if (effects['health'] != null) {
      health = (health + (effects['health'] as int)).clamp(0, 100);
    }
    if (effects['sanity'] != null) {
      sanity = (sanity + (effects['sanity'] as int)).clamp(0, 100);
    }
    if (effects['stamina'] != null) {
      stamina = (stamina + (effects['stamina'] as int)).clamp(0, 100);
    }
    if (effects['fatigue'] != null) {
      fatigue = (fatigue + (effects['fatigue'] as int)).clamp(0, 100);
    }
    if (effects['time'] != null) {
      timeMinutes = (timeMinutes + (effects['time'] as int)).clamp(0, 99999);
    }

    if (effects['inventory_add'] != null) {
      final List<dynamic> addIds = effects['inventory_add'];
      for (final id in addIds) {
        final item = ItemLoader.findById(id as String);
        if (item != null) {
          inventory.addItem(item);
          tracker.lootedCount += 1;
        }
      }
    }

    if (effects['inventory_remove'] != null) {
      final List<dynamic> removeIds = effects['inventory_remove'];
      for (final id in removeIds) {
        inventory.removeItem(id as String);
      }
    }

    if (effects['flag_set'] != null) {
      final flag = effects['flag_set'] as String;
      _flags.add(flag);
    }

    if (effects['infect'] != null) {
      final infectData = effects['infect'] as Map<String, dynamic>;
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

  /// Проверить достижения после действия в сюжете.
  ///
  /// Покрывает: first_blood, sharp_shooter, master_crafter,
  /// doctor, hoarder, сюжетные достижения.
  ///
  /// Не ждём результата — попапы покажет подписка на стрим.
  void _checkAchievements() {
    unawaited(AchievementManager.unlockAll(
      characterId: widget.characterId,
      tracker: tracker,
      day: chapter,
      inventorySize: inventory.items.length,
    ));
  }

  String _getStartLocationForCharacter() {
    switch (widget.characterId) {
      case 'boris':
        return 'home_boris';
      case 'alina':
        return 'street_south';
      case 'ivan':
        return 'forest_hut';
      case 'andrey':
        return 'office_tower';
      case 'darya':
        return 'hospital';
      default:
        return 'home_boris';
    }
  }

  Future<void> _autoSave() async {
    if (_currentNode == null) return;

    final data = SaveData(
      characterId: widget.characterId,
      characterName: widget.characterName,
      currentNodeId: _currentNode!.id,
      currentLocationId: _getStartLocationForCharacter(),
      onMap: false,
      hunger: hunger,
      thirst: thirst,
      health: health,
      sanity: sanity,
      stamina: stamina,
      fatigue: fatigue,
      timeMinutes: timeMinutes,
      chapter: chapter,
      history: [..._history, ..._flags],
      inventoryItems: inventory.toJson(),
      equipmentItems: equipment.toJson(),
      activeConditions: activeConditions
          .map((ac) => {
                'id': ac.condition.id,
                'daysRemaining': ac.daysRemaining,
              })
          .toList(),
      searchedCounts: const {},
      unlockedLocations: const [],
      savedAt: DateTime.now(),
    );

    await SaveManager.save(data);
  }

  Future<void> _goToMap() async {
    final save = SaveData(
      characterId: widget.characterId,
      characterName: widget.characterName,
      currentNodeId: _currentNode?.id ?? 'END',
      currentLocationId: _getStartLocationForCharacter(),
      onMap: true,
      hunger: hunger,
      thirst: thirst,
      health: health,
      sanity: sanity,
      stamina: stamina,
      fatigue: fatigue,
      timeMinutes: timeMinutes,
      chapter: chapter + 1,
      history: [..._history, ..._flags],
      inventoryItems: inventory.toJson(),
      equipmentItems: equipment.toJson(),
      activeConditions: activeConditions
          .map((ac) => ({
                'id': ac.condition.id,
                'daysRemaining': ac.daysRemaining,
              }))
          .toList(),
      searchedCounts: const {},
      unlockedLocations: const [],
      savedAt: DateTime.now(),
    );
    await SaveManager.save(save);

    final stats = await AchievementManager.loadStats();
    tracker.applyToStats(stats);

    // Отмечаем главу как пройденную.
    // Формат ID: "boris_ch1", "alina_ch1" и т.д.
    // Нужно для достижений *_master — они открываются
    // только когда глава ЗАВЕРШЕНА, а не когда выбран персонаж.
    stats.completedChapters.add('${widget.characterId}_ch$chapter');

    await AchievementManager.saveStats(stats);

    // Проверяем достижения после завершения главы.
    // Особенно важно для *_master (прохождение за персонажа)
    // и all_characters (все 5 персонажей).
    await AchievementManager.unlockAll(
      characterId: widget.characterId,
      tracker: tracker,
      day: chapter,
      inventorySize: inventory.items.length,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(
          characterId: widget.characterId,
          characterName: widget.characterName,
          resumeFrom: save,
        ),
      ),
    );
  }

  void _showChapterEnd() {
    if (_currentNode == null) return;

    final save = SaveData(
      characterId: widget.characterId,
      characterName: widget.characterName,
      currentNodeId: _currentNode!.id,
      currentLocationId: _getStartLocationForCharacter(),
      onMap: false,
      hunger: hunger,
      thirst: thirst,
      health: health,
      sanity: sanity,
      stamina: stamina,
      fatigue: fatigue,
      timeMinutes: timeMinutes,
      chapter: chapter,
      history: [..._history, ..._flags],
      inventoryItems: inventory.toJson(),
      equipmentItems: equipment.toJson(),
      activeConditions: activeConditions
          .map((ac) => ({
                'id': ac.condition.id,
                'daysRemaining': ac.daysRemaining,
              }))
          .toList(),
      searchedCounts: const {},
      unlockedLocations: const [],
      savedAt: DateTime.now(),
    );

    final summary = ChapterSummary.fromSaveAndTracker(
      save,
      tracker,
      daysSurvived: chapter,
      finalNode: _currentNode!.id,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterEndScreen(summary: summary),
      ),
    );
  }

  void _selectChoice(StoryChoice choice) {
    AudioService.playClick();
    _applyEffects(choice.effects);
    _applyConditionsTick();

    fatigue = (fatigue + 2).clamp(0, 100);
    _history.add(_currentNode!.id);

    if (choice.effects != null && choice.effects!['combat_start'] != null) {
      tracker.hadCombat = true;
      final combat = choice.effects!['combat_start'] as Map<String, dynamic>;
      _startCombat(
        enemyName: combat['enemy_name'] ?? 'Враг',
        enemyHealth: combat['enemy_health'] ?? 30,
        enemyDamage: combat['enemy_damage'] ?? 5,
        enemyProtection: combat['enemy_protection'] ?? 0,
        enemyStrength: combat['enemy_strength'] ?? 5,
        victoryNode: choice.effects!['combat_victory'] ?? choice.next,
        defeatNode: choice.effects!['combat_defeat'] ?? 'END_died',
        fleeNode: choice.effects!['combat_flee'] ?? choice.next,
      );
      return;
    }

    _navigateToNode(choice.next);

    // Проверяем достижения после каждого выбора.
    _checkAchievements();
  }

  void _navigateToNode(String nodeId) {
    final nextNode = _story!.getNode(nodeId);
    if (nextNode == null) {
      setState(() => _isEnd = true);
      _autoSave();
      return;
    }

    if (nextNode.onEnter != null) _applyEffects(nextNode.onEnter);

    if (nextNode.flagsSet != null) {
      final flags = nextNode.flagsSet!['add'];
      if (flags != null) {
        for (final f in flags) {
          _flags.add(f as String);
        }
      }
    }

    if (nextNode.choices.isNotEmpty) {
      setState(() => _currentNode = nextNode);
      _autoSave();
      return;
    }

    if (nextNode.id.startsWith('END_')) {
      setState(() {
        _currentNode = nextNode;
        _isEnd = true;
      });
      _autoSave();
      return;
    }

    final currentActNumber = _story!.getActForNode(nextNode.id);

    if (currentActNumber != null) {
      final nextAct = _story!.getNextAct(currentActNumber);

      if (nextAct != null && nextAct.entryNodes.isNotEmpty) {
        final entryNodeId = nextAct.entryNodes.first;
        final entryNode = _story!.getNode(entryNodeId);

        if (entryNode != null) {
          if (entryNode.onEnter != null) _applyEffects(entryNode.onEnter);

          setState(() {
            _currentNode = entryNode;
            _isEnd = false;
          });

          _autoSave();
          return;
        }
      }
    }

    setState(() {
      _currentNode = nextNode;
      _isEnd = true;
    });
    _autoSave();
  }

  Future<void> _startCombat({
    required String enemyName,
    required int enemyHealth,
    required int enemyDamage,
    required int enemyProtection,
    required int enemyStrength,
    required String victoryNode,
    required String defeatNode,
    required String fleeNode,
  }) async {
    final player = Combatant(
      name: widget.characterName,
      health: health,
      maxHealth: 100,
      damage: equipment.totalDamage > 0 ? equipment.totalDamage : 3,
      protection: equipment.totalProtection,
      strength: 5,
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
    );

    final rawResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CombatScreen(player: player, enemy: enemy),
      ),
    );

    if (!mounted) return;

    String result = 'defeat';
    if (rawResult is Map) {
      result = rawResult['result'] ?? 'defeat';
      health = (rawResult['playerHealth'] as int? ?? player.health).clamp(0, 100);
    } else if (rawResult is String) {
      result = rawResult;
      health = player.health.clamp(0, 100);
    }

    if (result == 'victory') {
      tracker.kills += 1;
      _navigateToNode(victoryNode);
    } else if (result == 'defeat') {
      _navigateToNode(defeatNode);
    } else if (result == 'fled') {
      _navigateToNode(fleeNode);
    }

    _autoSave();

    // Проверяем достижения после боя (first_blood, sharp_shooter).
    _checkAchievements();
  }

  List<StoryChoice> get _availableChoices {
    if (_currentNode == null) return [];
    return _currentNode!.choices.where((c) {
      return c.isAvailable(
        stats: {
          'hunger': hunger,
          'thirst': thirst,
          'health': health,
          'sanity': sanity,
          'stamina': stamina,
          'fatigue': fatigue,
        },
        inventoryIds: inventory.items.map((i) => i.id).toSet(),
        flags: _flags,
      );
    }).toList();
  }

  List<StoryChoice> get _lockedChoices {
    if (_currentNode == null) return [];
    return _currentNode!.choices.where((c) {
      return !c.isAvailable(
        stats: {
          'hunger': hunger,
          'thirst': thirst,
          'health': health,
          'sanity': sanity,
          'stamina': stamina,
          'fatigue': fatigue,
        },
        inventoryIds: inventory.items.map((i) => i.id).toSet(),
        flags: _flags,
      );
    }).toList();
  }

  // ====== ИНВЕНТАРЬ ======
  void _showInventory() {
    AudioService.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return InventoryPanel(
            inventory: inventory,
            onUse: (item) {
              _useItem(item);
              setSheetState(() {});
              setState(() {});
            },
            onEquip: (item) {
              _equipItem(item);
              setSheetState(() {});
              setState(() {});
            },
            onDrop: (item) {
              _dropItem(item);
              setSheetState(() {});
              setState(() {});
            },
          );
        },
      ),
    );
  }

  void _useItem(InventoryItem item) {
    AudioService.playSuccess();
    hunger = (hunger + item.hungerRestore).clamp(0, 100);
    thirst = (thirst + item.thirstRestore).clamp(0, 100);
    health = (health + item.healthRestore).clamp(0, 100);
    sanity = (sanity + item.sanityRestore).clamp(0, 100);

    if (item.hungerRestore > 0) {
      FloatingEffectOverlay.show(
        context,
        '+${item.hungerRestore} 🍞',
        color: Colors.orange,
        icon: Icons.restaurant,
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
    if (item.sanityRestore > 0) {
      FloatingEffectOverlay.show(
        context,
        '+${item.sanityRestore} 🧠',
        color: Colors.purple,
        icon: Icons.psychology,
      );
    }

    final curable = <ActiveCondition>[];
    for (final ac in activeConditions) {
      if (ConditionManager.tryCure(ac, item.id)) {
        curable.add(ac);
      }
    }
    for (final ac in curable) {
      activeConditions.remove(ac);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Вылечено: ${ac.condition.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green[700],
        ),
      );
    }

    inventory.removeItem(item.id);
    _autoSave();
    _checkAchievements();
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

    final oldItem = equipment.unequip(slot);
    if (oldItem != null) {
      inventory.addItem(oldItem);
    }

    equipment.equip(item, slot);
    inventory.removeItem(item.id);
    _autoSave();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Надето: ${item.name}'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color.fromARGB(255, 100, 150, 255),
      ),
    );
  }

  void _dropItem(InventoryItem item) {
    AudioService.playClick();
    inventory.removeAll(item.id);
    _autoSave();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Выброшено: ${item.name}'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _showEquipment() {
    AudioService.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return EquipmentPanel(
            equipment: equipment,
            onUnequip: (slot) {
              AudioService.playClick();
              final item = equipment.unequip(slot);
              if (item != null) {
                inventory.addItem(item);
              }
              setSheetState(() {});
              setState(() {});
              _autoSave();
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

    if (_story == null || _currentNode == null) {
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
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: Text(
            'История не найдена',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

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
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.characterName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Сохранить',
            onPressed: () async {
              AudioService.playClick();
              await _autoSave();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Прогресс сохранён'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color.fromARGB(255, 200, 180, 100),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          ConditionsPanel(conditions: activeConditions),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(_currentNode!.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentNode!.title.toUpperCase(),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 200, 180, 100),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInText(
                      text: _currentNode!.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isEnd) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 180, 100),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🎬 КОНЕЦ ГЛАВЫ',
                          style: TextStyle(
                            color: Color.fromARGB(255, 200, 180, 100),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            AudioService.playClick();
                            _showChapterEnd();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 200, 180, 100),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '🎬  ЗАВЕРШИТЬ ГЛАВУ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            AudioService.playClick();
                            _goToMap();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                const Color.fromARGB(255, 100, 200, 100),
                            side: const BorderSide(
                              color: Color.fromARGB(255, 100, 200, 100),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '🗺️  ВЫЙТИ НА КАРТУ (без титров)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            AudioService.playClick();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'ВЕРНУТЬСЯ В МЕНЮ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (!_isEnd)
                      ..._availableChoices.map((choice) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _selectChoice(choice),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: const Color.fromARGB(
                                          255, 200, 180, 100)
                                      .withValues(alpha: 0.4),
                                ),
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.centerLeft,
                              ),
                              child: Text(
                                '▶  ${choice.text}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    if (!_isEnd && _lockedChoices.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._lockedChoices.map((choice) {
                        final reason = choice.getUnavailableReason(
                          stats: {
                            'hunger': hunger,
                            'thirst': thirst,
                            'health': health,
                            'sanity': sanity,
                            'stamina': stamina,
                            'fatigue': fatigue,
                          },
                          inventoryIds:
                              inventory.items.map((i) => i.id).toSet(),
                          flags: _flags,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 15, 15, 15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[800]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        choice.text,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      if (reason != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '🔒 $reason',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
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
            color: const Color.fromARGB(255, 200, 180, 100)
                .withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Color.fromARGB(255, 200, 180, 100),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                TimeFormat.clock(timeMinutes),
                style: const TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              Text(
                'Глава $chapter · Шаг ${_history.length + 1}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
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
}