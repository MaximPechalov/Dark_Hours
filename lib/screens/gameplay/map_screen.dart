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
import 'package:dark_hours/models/items/recipe.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/models/time/rest_action.dart';

import 'package:dark_hours/widgets/panels/penalties_panel.dart';
import 'package:dark_hours/widgets/panels/conditions_panel.dart';
import 'package:dark_hours/widgets/panels/craft_panel.dart';
import 'package:dark_hours/widgets/panels/inventory_panel.dart';
import 'package:dark_hours/widgets/panels/equipment_panel.dart';
import 'package:dark_hours/widgets/panels/rest_panel.dart';
import 'package:dark_hours/widgets/cards/animated_location_card.dart';
import 'package:dark_hours/widgets/effects/floating_effect.dart';
import 'package:dark_hours/widgets/effects/shimmer_button.dart';

import 'package:dark_hours/screens/gameplay/widgets/map_status_bar.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_current_location.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_location_card.dart';

class MapScreen extends StatefulWidget {
  final String characterId;
  final String characterName;
  final dynamic resumeFrom; // SaveData? — чтобы не тянуть импорт

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
  late final MapController _controller;

  @override
  void initState() {
    super.initState();

    _controller = MapController(
      characterId: widget.characterId,
      characterName: widget.characterName,
      resumeFrom: widget.resumeFrom,
    );

    // Подписка на изменения состояния
    _controller.addListener(_onControllerChanged);

    // Загрузка карты
    _initController();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Обработчик изменений в контроллере.
  ///
  /// Только setState — проверка смерти выполняется явно
  /// после каждого действия (см. _search, _moveTo, _executeRest).
  /// Так избегаем рекурсии setState → notifyListeners → setState.
  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Инициализация контроллера + ambience + первая проверка смерти
  Future<void> _initController() async {
    await _controller.init();

    if (!mounted) return;

    // Запуск ambience стартовой локации
    final startLoc = _controller.currentLocation;
    if (startLoc != null) {
      final ambiencePath = AudioService.ambienceForLocation(
        locationId: startLoc.id,
        type: startLoc.type,
        region: startLoc.region,
        dangerLevel: startLoc.dangerLevel,
      );
      if (ambiencePath != null) {
        await AudioService.playAmbience(ambiencePath);
      }
    }

    // Проверка смерти после инициализации
    if (DeathManager.checkDeath(_controller)) {
      await _handleDeath();
      return;
    }

    if (mounted) setState(() {});
  }

  /// Показать экран смерти + сохранить статистику
  Future<void> _handleDeath() async {
    if (!mounted) return;

    await DeathManager.applyStatsOnDeath(_controller);

    if (!mounted) return;
    await DeathManager.showDeathScreenIfNeeded(context, _controller);
  }

  // ═══════════════════════════════════════════════════════════
  // ДЕЙСТВИЯ ПОЛЬЗОВАТЕЛЯ
  // ═══════════════════════════════════════════════════════════

  /// Обыск текущей локации
  Future<void> _search() async {
    await SearchManager.search(context, _controller);

    if (!mounted) return;
    // Проверка смерти после обыска
    if (DeathManager.checkDeath(_controller)) {
      await _handleDeath();
      return;
    }
    await DeathManager.checkFatigue(context, _controller);
    if (mounted) setState(() {});
  }

  /// Переход в локацию
  Future<void> _moveTo(String locationId) async {
    final ok = await MovementManager.move(context, _controller, locationId);
    if (!ok || !mounted) return;

    // Проверка смерти и усталости после перехода
    if (DeathManager.checkDeath(_controller)) {
      await _handleDeath();
      return;
    }
    await DeathManager.checkFatigue(context, _controller);
    if (mounted) setState(() {});
  }

  /// Отдых
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

  /// Ручная проверка сюжетного триггера (по кнопке)
  Future<void> _checkStoryTrigger() async {
    await StoryTriggerManager.checkTrigger(context, _controller);
    if (mounted) setState(() {});
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

    // Списать ингредиенты
    for (final ing in recipe.ingredients) {
      for (int i = 0; i < ing.count; i++) {
        _controller.removeItem(ing.id);
      }
    }

    // Добавить результат
    final resultItem = _findItemForCraft(recipe.resultId);
    if (resultItem != null) {
      _controller.addItem(resultItem);
    }

    _controller.trackCraft(isMolotov: recipe.id == 'molotov_craft');
    _controller.applyStatDelta({
      'stamina': -5,
      'fatigue': 5,
    });

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

  /// Найти предмет для крафта через глобальный каталог.
  ///
  /// MapScreen не знает об ItemLoader — делегирует в MapController.
  InventoryItem? _findItemForCraft(String id) {
    return _controller.findItemInCatalog(id);
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

    // Floating effects
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

    // Лечение болезней
    final curable = <dynamic>[];
    for (final ac in _controller.activeConditions) {
      if (ac.condition.cureItems.contains(item.id)) {
        curable.add(ac);
      }
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
  // UI
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Загрузка
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

    // Карта не загрузилась
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
          child: Text(
            'Карта не найдена',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final current = _controller.currentLocation;
    if (current == null) return const SizedBox.shrink();

    final penalties = _getPenalties();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          MapStatusBar(controller: _controller),
          PenaltiesPanel(penalties: penalties),
          ConditionsPanel(conditions: _controller.activeConditions),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MapCurrentLocation(controller: _controller),
                  const SizedBox(height: 20),
                  ..._buildActionButtons(current),
                  const SizedBox(height: 20),
                  _buildConnectionsHeader(),
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

  // ═══════════════════════════════════════════════════════════
  // APPBAR
  // ═══════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════
  // КНОПКИ ДЕЙСТВИЙ
  // ═══════════════════════════════════════════════════════════

  List<Widget> _buildActionButtons(Location current) {
    final widgets = <Widget>[];

    // Кнопка «Обыскать»
    if (_canSearch(current)) {
      widgets.add(_buildSearchButton(current));
      widgets.add(const SizedBox(height: 10));
    }

    // Кнопка «Сюжетное событие»
    if (_hasStoryTrigger(current)) {
      widgets.add(_buildStoryButton());
      widgets.add(const SizedBox(height: 10));
    }

    // Кнопка «Войти на станцию»
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
          '🔍  ОБЫСКАТЬ · осталось $remaining из ${loc.maxSearches} (${loc.searchTime} мин)';
      color = const Color.fromARGB(255, 100, 150, 200);
    } else {
      label = '🔍  ОСМОТРЕТЬСЯ (рискованно) (${loc.searchTime} мин)';
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 200, 120, 100),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ═══════════════════════════════════════════════════════════
  // СПИСОК СОСЕДНИХ ЛОКАЦИЙ
  // ═══════════════════════════════════════════════════════════

  Widget _buildConnectionsHeader() {
    return const Text(
      'КУДА ИДТИ?',
      style: TextStyle(
        color: Color.fromARGB(255, 200, 180, 100),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }

  List<Widget> _buildAvailableConnections() {
    final map = _controller.map;
    if (map == null) return [];

    final connections = map.availableConnections.where((loc) {
      if (loc.hidden && !_controller.isLocationUnlocked(loc.id)) {
        return false;
      }
      return true;
    }).toList();

    return connections.asMap().entries.map((entry) {
      return AnimatedLocationCard(
        index: entry.key,
        child: MapLocationCard(
          controller: _controller,
          location: entry.value,
          onTap: () => _moveTo(entry.value.id),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // УТИЛИТЫ
  // ═══════════════════════════════════════════════════════════

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