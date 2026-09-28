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
import '../services/save_manager.dart';
import '../services/item_loader.dart';
import '../services/condition_manager.dart';
import '../widgets/inventory_panel.dart';
import '../widgets/equipment_panel.dart';
import '../widgets/conditions_panel.dart';
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
  int timeMinutes = 120;
  int chapter = 1;

  final Inventory inventory = Inventory(maxWeight: 30.0);
  final Equipment equipment = Equipment();

  List<Condition> allConditions = [];
  final List<ActiveCondition> activeConditions = [];

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    setState(() => _isLoading = true);

    await ItemLoader.init();
    allConditions = await Condition.loadAll();

    final locations = await Location.loadAll();
    if (locations.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Восстановление из сохранения
    if (widget.resumeFrom != null) {
      final s = widget.resumeFrom!;
      hunger = s.hunger;
      thirst = s.thirst;
      health = s.health;
      sanity = s.sanity;
      stamina = s.stamina;
      timeMinutes = s.timeMinutes;
      chapter = s.chapter;

      // Инвентарь
      for (final itemJson in s.inventoryItems) {
        inventory.items.add(InventoryItem.fromJson(itemJson));
      }

      // Экипировка
      final restored = Equipment.fromJson(s.equipmentItems);
      equipment.weapon = restored.weapon;
      equipment.head = restored.head;
      equipment.body = restored.body;
      equipment.hands = restored.hands;
      equipment.feet = restored.feet;
      equipment.backpack = restored.backpack;

      // Болезни
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
        _map = WorldMap(
          locations: locations,
          currentLocationId: startLoc.id,
          visitedLocations: {startLoc.id},
        );
        _isLoading = false;
      });
    }
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
      timeMinutes: timeMinutes,
      chapter: chapter,
      history: const [],
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

  /// Перемещение в другую локацию
  Future<void> _moveTo(String locationId) async {
    final target = _map!.getById(locationId);
    if (target == null) return;

    // Тратим время
    timeMinutes += 20;
    stamina = (stamina - 5).clamp(0, 100);
    hunger = (hunger - 3).clamp(0, 100);
    thirst = (thirst - 3).clamp(0, 100);

    _applyConditionsTick();

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
  }

  /// Обыскать локацию
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

    // Тратим время и стамину
    timeMinutes += loc.searchTime;
    stamina = (stamina - 10).clamp(0, 100);
    hunger = (hunger - 5).clamp(0, 100);
    thirst = (thirst - 5).clamp(0, 100);

    // Риск заражения
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

    // Поиск лута
    String? foundItemId;
    if (loc.lootPool.isNotEmpty) {
      foundItemId = loc.lootPool[
          DateTime.now().millisecond % loc.lootPool.length];
      final item = ItemLoader.findById(foundItemId);
      if (item != null && inventory.addItem(item)) {
        if (mounted) {
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

    // Враг
    if (loc.enemies.isNotEmpty && !_isFinalLoc(loc)) {
      final enemyRoll = DateTime.now().millisecond % 3;
      if (enemyRoll == 0) {
        // 33% шанс встретить врага
        _startCombat(loc.enemies[0]);
      }
    }

    _applyConditionsTick();
    await _autoSave();
    if (mounted) setState(() {});
  }

  bool _isFinalLoc(Location loc) => loc.isFinal;

  /// Начать бой
  Future<void> _startCombat(String enemyId) async {
    final enemyData = _getEnemyData(enemyId);
    if (enemyData == null) return;

    final player = Combatant(
      name: widget.characterName,
      health: health,
      maxHealth: 100,
      damage: equipment.totalDamage > 0 ? equipment.totalDamage : 3,
      protection: equipment.totalProtection,
      strength: 5,
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
    health = player.health.clamp(0, 100);

    if (result == 'victory') {
      // Заражение от раны
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
    if (mounted) setState(() {});
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

  /// Использование предмета
  void _useItem(InventoryItem item) {
    hunger = (hunger + item.hungerRestore).clamp(0, 100);
    thirst = (thirst + item.thirstRestore).clamp(0, 100);
    health = (health + item.healthRestore).clamp(0, 100);
    sanity = (sanity + item.sanityRestore).clamp(0, 100);

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

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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
            icon: const Icon(Icons.shield_outlined),
            onPressed: _showEquipment,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.backpack_outlined),
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
          ConditionsPanel(conditions: activeConditions),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentLocation(current),
                  const SizedBox(height: 20),

                  // Кнопка "Обыскать локацию"
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

                  // Финальная локация
                  if (current.isFinal)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🏭 Ты добрался до станции. Конец пути. (Глава 2 в разработке)',
                              ),
                              duration: Duration(seconds: 4),
                              backgroundColor: Color.fromARGB(255, 200, 180, 100),
                            ),
                          );
                        },
                        icon: const Icon(Icons.flag, size: 18),
                        label: const Text(
                          '🏭  ВОЙТИ НА СТАНЦИЮ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 200, 180, 100),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                  ..._map!.availableConnections.map(_buildLocationCard),
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
                      'ТЫ ЗДЕСЬ',
                      style: TextStyle(
                        color: Colors.grey[500],
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
                  Text(
                    loc.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
              const Icon(
                Icons.access_time,
                color: Color.fromARGB(255, 200, 180, 100),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(timeMinutes),
                style: const TextStyle(
                  color: Color.fromARGB(255, 200, 180, 100),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Глава $chapter',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStat('🍞', hunger, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildStat('💧', thirst, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStat('❤️', health, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildStat('🧠', sanity, Colors.purple)),
              const SizedBox(width: 8),
              Expanded(child: _buildStat('⚡', stamina, Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String icon, int value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[900],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
      ],
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