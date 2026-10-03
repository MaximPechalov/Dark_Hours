import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/movement_manager.dart';
import 'package:dark_hours/services/map/search_manager.dart';
import 'package:dark_hours/services/map/rest_manager.dart';
import 'package:dark_hours/services/map/death_manager.dart';
import 'package:dark_hours/services/map/story_trigger_manager.dart';
import 'package:dark_hours/services/progress/achievement_checker.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/time/time_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/map_position.dart';
import 'package:dark_hours/models/items/recipe.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/models/time/rest_action.dart';

import 'package:dark_hours/widgets/panels/penalties_panel.dart';
import 'package:dark_hours/widgets/panels/conditions_panel.dart';
import 'package:dark_hours/widgets/panels/craft_panel.dart';
import 'package:dark_hours/widgets/panels/inventory_panel.dart';
import 'package:dark_hours/widgets/panels/equipment_panel.dart';
import 'package:dark_hours/widgets/panels/rest_panel.dart';
import 'package:dark_hours/widgets/effects/floating_effect.dart';
import 'package:dark_hours/widgets/effects/shimmer_button.dart';

import 'package:dark_hours/screens/gameplay/widgets/map_status_bar.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_current_location.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_zone_painter.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_edge_painter.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_node.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_player_marker.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_info_sheet.dart';

class MapScreen extends StatefulWidget {
  final String characterId;
  final String characterName;
  final dynamic resumeFrom;

  const MapScreen({
    super.key,
    required this.characterId,
    required this.characterName,
    this.resumeFrom,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _controller;

  final TransformationController _transformController =
      TransformationController();

  late AnimationController _markerController;
  late Animation<MapPosition> _markerAnimation;
  MapPosition _markerPosition = const MapPosition(x: 0.5, y: 0.5);
  double _markerRotation = 0.0;
  bool _isMoving = false;

  Size _viewportSize = const Size(400, 600);

  static const double _mapWidth = 1200.0;
  static const double _mapHeight = 1600.0;

  @override
  void initState() {
    super.initState();
    _controller = MapController(
      characterId: widget.characterId,
      characterName: widget.characterName,
      resumeFrom: widget.resumeFrom,
    );
    _controller.addListener(_onControllerChanged);

    _markerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _initController();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _transformController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initController() async {
    await _controller.init();
    if (!mounted) return;

    final cur = _controller.currentLocation;
    if (cur != null) {
      _markerPosition = cur.mapPosition;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerOnLocation(cur);
      });

      final ambiencePath = AudioService.ambienceForLocation(
        locationId: cur.id,
        type: cur.type,
        region: cur.region,
        dangerLevel: cur.dangerLevel,
      );
      if (ambiencePath != null) {
        await AudioService.playAmbience(ambiencePath);
      }
    }

    if (DeathManager.checkDeath(_controller)) {
      await _handleDeath();
      return;
    }
    if (mounted) setState(() {});
  }

  void _centerOnLocation(Location loc) {
    final px = loc.mapPosition.x * _mapWidth;
    final py = loc.mapPosition.y * _mapHeight;

    final viewW = _viewportSize.width;
    final viewH = _viewportSize.height;

    final tx = viewW / 2 - px;
    final ty = viewH / 2 - py;

    _transformController.value = Matrix4.identity()
      ..translate(tx, ty);
  }

  Future<void> _handleDeath() async {
    if (!mounted) return;
    await DeathManager.applyStatsOnDeath(_controller);
    if (!mounted) return;
    await DeathManager.showDeathScreenIfNeeded(context, _controller);
  }

  // ═══════════════════════════════════════════════════════════
  // ПЕРЕХОД
  // ═══════════════════════════════════════════════════════════

  Future<void> _moveTo(String locationId) async {
    final target = _controller.map?.getById(locationId);
    if (target != null) {
      _startMarkerAnimation(target.mapPosition);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final ok = await MovementManager.move(context, _controller, locationId);
    if (!ok || !mounted) return;

    final newLoc = _controller.currentLocation;
    if (newLoc != null) {
      _finishMarkerAnimation(newLoc.mapPosition);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerOnLocation(newLoc);
      });
    }

    if (DeathManager.checkDeath(_controller)) {
      await _handleDeath();
      return;
    }
    await DeathManager.checkFatigue(context, _controller);
    if (mounted) setState(() {});
  }

  void _startMarkerAnimation(MapPosition target) {
    _isMoving = true;

    final dx = target.x - _markerPosition.x;
    final dy = target.y - _markerPosition.y;
    _markerRotation = math.atan2(dy, dx) + math.pi / 2;

    _markerAnimation = Tween<MapPosition>(
      begin: _markerPosition,
      end: target,
    ).animate(CurvedAnimation(
      parent: _markerController,
      curve: Curves.easeInOut,
    ));

    _markerController.forward(from: 0);
    _markerController.addListener(_onMarkerTick);

    setState(() {});
  }

  void _finishMarkerAnimation(MapPosition target) {
    _markerPosition = target;
    _isMoving = false;
    _markerController.stop();
    _markerController.removeListener(_onMarkerTick);
    setState(() {});
  }

  void _onMarkerTick() {
    setState(() {
      _markerPosition = _markerAnimation.value;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // РАЗВЕДКА
  // ═══════════════════════════════════════════════════════════

  /// Разведать округу.
  ///
  /// Тратит 30 минут + 10 стамины + 5 усталости.
  /// Открывает 1-3 соседние локации как scouted.
  Future<void> _scout() async {
    AudioService.playClick();

    final current = _controller.currentLocation;
    if (current == null) return;

    // Проверка: есть ли что разведывать?
    final unknownNeighbors = current.connectionIds.where((id) {
      return !_controller.isScouted(id);
    }).toList();

    if (unknownNeighbors.isEmpty) {
      AudioService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔭 Все соседние места уже разведаны'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    // Стоимость
    if (_controller.stamina < 10) {
      AudioService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Слишком устал для разведки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _controller.setStamina(_controller.stamina - 10);
    _controller.setFatigue(_controller.fatigue + 5);

    // Бросок: сколько локаций разведаем?
    final rng = math.Random();
    final roll = rng.nextInt(100);

    int count;
    String mood;
    if (roll < 15) {
      // Провал
      count = 0;
      mood = 'Ты вглядываешься в темноту. Ничего не видно.';
    } else if (roll < 55) {
      // 1 локация
      count = 1;
      mood = 'Сквозь туман различаешь силуэт...';
    } else if (roll < 85) {
      // 2 локации
      count = 2;
      mood = 'Ты видишь несколько очертаний впереди...';
    } else {
      // 3 локации (удача)
      count = 3;
      mood = 'С высоты ты видишь многое...';
    }

    // Разведываем
    final scoutedList = <String>[];
    unknownNeighbors.shuffle(rng);
    for (int i = 0; i < count && i < unknownNeighbors.length; i++) {
      scoutedList.add(unknownNeighbors[i]);
    }

    _controller.scoutAll(scoutedList);

    // Время
    await _controller.advanceTime(30);
    await _controller.save();

    if (!mounted) return;

    // Показать результат
    await _showScoutResult(mood, scoutedList);

    if (mounted) setState(() {});
  }

  /// Показать модалку с результатом разведки.
  Future<void> _showScoutResult(String mood, List<String> scoutedIds) async {
    if (!mounted) return;

    final map = _controller.map;
    if (map == null) return;

    final locations = scoutedIds
        .map((id) => map.getById(id))
        .whereType<Location>()
        .toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 15, 15, 15),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔭 РАЗВЕДКА',
                style: TextStyle(
                  color: Color(0xFFC8B464),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mood,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              if (locations.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ничего нового.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ] else ...[
                const Text(
                  'Обнаружено:',
                  style: TextStyle(
                    color: Color(0xFFC8B464),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10),
                ...locations.map((loc) => _buildScoutedCard(loc)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AudioService.playClick();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8B464),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ПОНЯТНО',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoutedCard(Location loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC8B464).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            loc.icon,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.displayScoutedName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.displayScoutedDescription,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ДЕЙСТВИЯ
  // ═══════════════════════════════════════════════════════════

  Future<void> _search() async {
    await SearchManager.search(context, _controller);
    if (!mounted) return;
    if (DeathManager.checkDeath(_controller)) {
      await _handleDeath();
      return;
    }
    await DeathManager.checkFatigue(context, _controller);
    if (mounted) setState(() {});
  }

  Future<void> _showRestPanel() async {
    AudioService.playTap();
    final loc = _controller.currentLocation;
    if (loc == null) return;
    final isSafe = loc.dangerLevel <= 3;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return RestPanel(
          isSafeLocation: isSafe,
          onRest: (action) async {
            Navigator.pop(bottomSheetContext);
            await _executeRest(action);
          },
        );
      },
    );
  }

  Future<void> _executeRest(RestAction action) async {
    await RestManager.rest(context, _controller, action);
    if (!mounted) return;
    if (DeathManager.checkDeath(_controller)) {
      await _handleDeath();
      return;
    }
    await DeathManager.checkFatigue(context, _controller);
    if (mounted) setState(() {});
  }

  Future<void> _checkStoryTrigger() async {
    await StoryTriggerManager.checkTrigger(context, _controller);
    if (mounted) setState(() {});
  }

  void _showLocationInfo(Location loc) {
    AudioService.playTap();

    final current = _controller.currentLocation;
    final canMove = current != null && current.isConnectedTo(loc.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MapInfoSheet(
        location: loc,
        canMove: canMove,
        onMove: canMove ? () => _moveTo(loc.id) : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // КРАФТ
  // ═══════════════════════════════════════════════════════════

  void _showCraftPanel() {
    AudioService.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return CraftPanel(
            inventory: _controller.inventory,
            intelligence: _controller.intelligence,
            strength: _controller.strength,
            stamina: _controller.stamina,
            recipes: _controller.allRecipes,
            onCraft: (recipe) async {
              await _craftItem(recipe);
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  Future<void> _craftItem(Recipe recipe) async {
    if (_controller.stamina < 5) {
      AudioService.playError();
      if (!mounted) return;
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
        _controller.removeItem(ing.id);
      }
    }

    final resultItem = _controller.findItemInCatalog(recipe.resultId);
    if (resultItem != null) {
      _controller.addItem(resultItem);
    }

    _controller.trackCraft(isMolotov: recipe.id == 'molotov_craft');
    _controller.applyStatDelta({'stamina': -5, 'fatigue': 5});

    await _controller.advanceTime(recipe.timeMinutes);
    await _controller.save();

    if (!mounted) return;

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
      day: _controller.gameTime.day,
      inventorySize: _controller.inventory.items.length,
      tracker: _controller.tracker,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ИНВЕНТАРЬ / ЭКИПИРОВКА
  // ═══════════════════════════════════════════════════════════

  void _showInventory() {
    AudioService.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return InventoryPanel(
            inventory: _controller.inventory,
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
    _controller.applyStatDelta({
      'hunger': item.hungerRestore,
      'thirst': item.thirstRestore,
      'health': item.healthRestore,
      'sanity': item.sanityRestore,
    });

    if (item.id.contains('pill') ||
        item.id.contains('bandage') ||
        item.id == 'first_aid_kit' ||
        item.id == 'herb_medkit' ||
        item.id == 'splint') {
      _controller.trackMedicineUsed();
    }

    if (item.hungerRestore > 0) {
      FloatingEffectOverlay.show(context, '+${item.hungerRestore} 🍞',
          color: Colors.orange, icon: Icons.restaurant);
    }
    if (item.thirstRestore > 0) {
      FloatingEffectOverlay.show(context, '+${item.thirstRestore} 💧',
          color: Colors.blue, icon: Icons.water_drop);
    }
    if (item.healthRestore > 0) {
      FloatingEffectOverlay.show(context, '+${item.healthRestore} ❤️',
          color: Colors.red, icon: Icons.favorite);
    }

    final curable = <dynamic>[];
    for (final ac in _controller.activeConditions) {
      if (ac.condition.cureItems.contains(item.id)) curable.add(ac);
    }
    for (final ac in curable) {
      _controller.activeConditions.remove(ac);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Вылечено: ${ac.condition.name}'),
          backgroundColor: Colors.green[700],
        ),
      );
    }

    _controller.removeItem(item.id);
    _controller.save();
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
    _controller.equipItem(item, slot);
    _controller.save();
    setState(() {});
  }

  void _dropItem(InventoryItem item) {
    AudioService.playClick();
    _controller.removeAll(item.id);
    _controller.save();
    setState(() {});
  }

  void _showEquipment() {
    AudioService.playTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return EquipmentPanel(
            equipment: _controller.equipment,
            onUnequip: (slot) {
              AudioService.playClick();
              _controller.unequipItem(slot);
              setSheetState(() {});
              setState(() {});
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ВИДИМОСТЬ ЛОКАЦИЙ
  // ═══════════════════════════════════════════════════════════

  NodeState _nodeState(Location loc) {
    if (loc.id == _controller.currentLocation?.id) {
      return NodeState.current;
    }

    if (loc.hidden && !_controller.isLocationUnlocked(loc.id)) {
      return NodeState.hidden;
    }

    final isNeighbor = _controller.currentLocation?.connectionIds
            .contains(loc.id) ??
        false;

    // Если локация не разведана и не соседняя — скрыта.
    if (!_controller.isScouted(loc.id) && !isNeighbor) {
      return NodeState.hidden;
    }

    if (isNeighbor) return NodeState.neighbor;
    return NodeState.visited;
  }

  // ═══════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 10, 10, 10),
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 200, 180, 100),
          ),
        ),
      );
    }

    if (_controller.map == null) {
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
          child: Text('Карта не найдена',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final current = _controller.currentLocation;
    if (current == null) return const SizedBox.shrink();

    final penalties = _getPenalties();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 8, 10),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          MapStatusBar(controller: _controller),
          PenaltiesPanel(penalties: penalties),
          ConditionsPanel(conditions: _controller.activeConditions),

          if (_isMoving)
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC8B464), Colors.transparent],
                ),
              ),
            ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_viewportSize != constraints.biggest) {
                  _viewportSize = constraints.biggest;
                }

                return InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.4,
                  maxScale: 2.0,
                  boundaryMargin: const EdgeInsets.all(400),
                  constrained: false,
                  child: SizedBox(
                    width: _mapWidth,
                    height: _mapHeight,
                    child: _buildMapCanvas(),
                  ),
                );
              },
            ),
          ),

          _buildBottomPanel(current),
        ],
      ),
    );
  }

  Widget _buildMapCanvas() {
    final map = _controller.map!;
    final current = _controller.currentLocation!;

    final edges = buildEdges(
      locations: map.locations,
      visited: map.visitedLocations,
      scouted: _controller.scoutedLocations,
      unlocked: _controller.unlockedLocations,
      currentLocationId: current.id,
    );

    final visibleNodes = map.locations
        .where((loc) => _nodeState(loc) != NodeState.hidden)
        .toList();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: MapZonePainter(
              logicalSize: const Size(_mapWidth, _mapHeight),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: MapEdgePainter(edges: edges),
          ),
        ),
        ...visibleNodes.map((loc) {
          final px = loc.mapPosition.x * _mapWidth;
          final py = loc.mapPosition.y * _mapHeight;
          final state = _nodeState(loc);

          return Positioned(
            left: px - MapNode.labelWidth / 2,
            top: py - MapNode.nodeSize / 2,
            child: MapNode(
              location: loc,
              state: state,
              onTap: () {
                if (state == NodeState.neighbor) {
                  _moveTo(loc.id);
                } else if (state == NodeState.visited) {
                  _showLocationInfo(loc);
                }
              },
            ),
          );
        }),
        Positioned(
          left: _markerPosition.x * _mapWidth - 30,
          top: _markerPosition.y * _mapHeight - 30,
          child: IgnorePointer(
            child: MapPlayerMarker(
              size: 20,
              rotation: _markerRotation,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(Location current) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 12, 12, 12),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFC8B464).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MapCurrentLocation(controller: _controller),
            const SizedBox(height: 8),
            ..._buildActionButtons(current),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          icon: const Icon(Icons.center_focus_strong),
          tooltip: 'Центрировать',
          onPressed: () {
            AudioService.playTap();
            final cur = _controller.currentLocation;
            if (cur != null) _centerOnLocation(cur);
          },
        ),
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
        _buildInventoryButton(),
      ],
    );
  }

  Widget _buildInventoryButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.backpack_outlined),
          tooltip: 'Инвентарь',
          onPressed: _showInventory,
        ),
        if (_controller.inventory.items.isNotEmpty)
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
                '${_controller.inventory.items.length}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildActionButtons(Location current) {
    final widgets = <Widget>[];

    if (_canSearch(current)) {
      widgets.add(_buildSearchButton(current));
      widgets.add(const SizedBox(height: 8));
    }

    // Кнопка разведки — если есть что разведывать.
    if (_canScout(current)) {
      widgets.add(_buildScoutButton());
      widgets.add(const SizedBox(height: 8));
    }

    if (_hasStoryTrigger(current)) {
      widgets.add(_buildStoryButton());
      widgets.add(const SizedBox(height: 8));
    }
    if (current.isFinal) {
      widgets.add(_buildStationButton());
    }

    return widgets;
  }

  bool _canSearch(Location loc) {
    return loc.maxSearches > 0 ||
        loc.lootPool.isNotEmpty ||
        loc.enemies.isNotEmpty ||
        loc.risk != null;
  }

  bool _canScout(Location loc) {
    // Есть ли неизвестные соседи?
    return loc.connectionIds.any((id) => !_controller.isScouted(id));
  }

  bool _hasStoryTrigger(Location loc) {
    if (loc.storyNode == null) return false;
    return loc.canTriggerStory(
      currentChapter: _controller.chapter,
      currentCharacter: widget.characterId,
      triggeredNodes: _controller.flags,
    );
  }

  Widget _buildSearchButton(Location loc) {
    final searched = _controller.searchedCounts[loc.id] ?? 0;
    final remaining = loc.maxSearches - searched;
    String label;
    Color color;
    if (loc.maxSearches == 0) {
      label = '🔍  ОСМОТРЕТЬСЯ (${loc.searchTime} мин)';
      color = const Color.fromARGB(255, 100, 150, 200);
    } else if (remaining > 0) {
      label =
          '🔍  ОБЫСКАТЬ · $remaining из ${loc.maxSearches} (${loc.searchTime} мин)';
      color = const Color.fromARGB(255, 100, 150, 200);
    } else {
      label = '🔍  ОСМОТРЕТЬСЯ (${loc.searchTime} мин)';
      color = const Color.fromARGB(255, 150, 100, 100);
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _search,
        icon: const Icon(Icons.search, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildScoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _scout,
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text(
          '🔭  РАЗВЕДАТЬ ОКРУГУ (30 мин)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 100, 130, 180),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _checkStoryTrigger,
        icon: const Icon(Icons.menu_book, size: 18),
        label: const Text(
          '📖  СЮЖЕТНОЕ СОБЫТИЕ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 200, 120, 100),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStationButton() {
    return SizedBox(
      width: double.infinity,
      child: ShimmerButton(
        text: '🏭  ВОЙТИ НА СТАНЦИЮ',
        icon: Icons.flag,
        onPressed: () async {
          await AchievementManager.unlock('reached_station');
          if (!mounted) return;
          AudioService.playSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🏭 Ты добрался до станции. Конец пути.'),
              duration: Duration(seconds: 4),
              backgroundColor: Color.fromARGB(255, 200, 180, 100),
            ),
          );
        },
      ),
    );
  }

  List<String> _getPenalties() {
    return TimeManager.getPenalties(
      hunger: _controller.hunger,
      thirst: _controller.thirst,
      stamina: _controller.stamina,
      sanity: _controller.sanity,
      fatigue: _controller.fatigue,
    );
  }
}