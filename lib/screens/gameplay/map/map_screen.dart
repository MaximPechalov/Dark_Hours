// lib/screens/gameplay/map/map_screen.dart
// ignore_for_file: unnecessary_getters_setters

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/death_manager.dart';
import 'package:dark_hours/services/map/region_background_cache.dart';
import 'package:dark_hours/services/map/map_goal_tracker.dart';
import 'package:dark_hours/services/story/side_quest_manager.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/time/time_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/region_layout.dart';
import 'package:dark_hours/models/progress/achievement.dart';
import 'package:dark_hours/models/story/chapter_step.dart';

import 'package:dark_hours/widgets/panels/penalties_panel.dart';
import 'package:dark_hours/widgets/panels/conditions_panel.dart';
import 'package:dark_hours/widgets/effects/achievement_notifier.dart';

import 'package:dark_hours/screens/gameplay/widgets/map_status_bar.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_current_location.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_edge_painter.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_node.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_player_marker.dart';
import 'package:dark_hours/screens/gameplay/widgets/map_info_sheet.dart';

import 'package:dark_hours/models/world/layouts/city_south_layout.dart';
import 'package:dark_hours/models/world/layouts/city_center_layout.dart';

import 'map_movement_handler.dart';
import 'map_panel_coordinator.dart';
import 'map_action_buttons.dart';
import 'map_region_transition.dart';

/// Экран карты.
///
/// **Ответственности:**
/// - Держит `MapController` и синхронизирует UI.
/// - Собирает композицию из виджетов других файлов.
/// - Делегирует переходы в [MapMovementHandler].
/// - Делегирует bottom-sheet'ы в [MapPanelCoordinator].
/// - Делегирует кнопки в [MapActionButtonsBuilder].
/// - Делегирует оверлей перехода в [MapRegionTransition].
/// - **Проверяет цель карты** через [MapGoalTracker].
/// - **Следит за побочными квестами** через [SideQuestManager].
class MapScreen extends StatefulWidget {
  final String characterId;
  final String characterName;
  final dynamic resumeFrom;

  /// Шаг главы (если запускается из ChapterRunner).
  ///
  /// Если `null` — карта работает в "свободном режиме" (тест).
  final ChapterStep? chapterStep;

  /// Колбэк, вызывается когда цель карты достигнута.
  final VoidCallback? onGoalComplete;

  const MapScreen({
    super.key,
    required this.characterId,
    required this.characterName,
    this.resumeFrom,
    this.chapterStep,
    this.onGoalComplete,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════
  // КОНТРОЛЛЕР
  // ═══════════════════════════════════════════════════════════

  late final MapController _controller;

  MapController get controller => _controller;

  String get characterId => widget.characterId;
  String get characterName => widget.characterName;

  // ═══════════════════════════════════════════════════════════
  // КАРТА
  // ═══════════════════════════════════════════════════════════

  final TransformationController _transformController =
      TransformationController();

  Size _viewportSize = const Size(400, 600);

  ui.Image? _regionBackground;
  String? _loadedRegionId;
  String? _lastRegionId;

  bool _showRegionTransition = false;
  String _transitionRegionName = '';

  Location? _selectedLocation;

  // ═══════════════════════════════════════════════════════════
  // НОВОЕ: ЦЕЛЬ И КВЕСТЫ
  // ═══════════════════════════════════════════════════════════

  MapGoalTracker? _goalTracker;
  SideQuestManager? _sideQuestManager;

  /// Защита от повторного показа попапа цели.
  bool _goalPopupShown = false;

  // ═══════════════════════════════════════════════════════════
  // ГЕТТЕРЫ И СЕТТЕРЫ ДЛЯ ХЕНДЛЕРОВ
  // ═══════════════════════════════════════════════════════════

  TransformationController get transformController => _transformController;
  Size get viewportSize => _viewportSize;
  ui.Image? get regionBackground => _regionBackground;
  bool get showRegionTransition => _showRegionTransition;
  String get transitionRegionName => _transitionRegionName;
  Location? get selectedLocation => _selectedLocation;
  String? get loadedRegionId => _loadedRegionId;
  String? get lastRegionId => _lastRegionId;

  set selectedLocation(Location? value) {
    setState(() => _selectedLocation = value);
  }

  set regionBackground(ui.Image? value) {
    setState(() => _regionBackground = value);
  }

  set showRegionTransition(bool value) {
    setState(() => _showRegionTransition = value);
  }

  set transitionRegionName(String value) {
    _transitionRegionName = value;
  }

  set loadedRegionId(String? value) {
    _loadedRegionId = value;
  }

  set lastRegionId(String? value) {
    _lastRegionId = value;
  }

  // ═══════════════════════════════════════════════════════════
  // АНИМАЦИЯ МАРКЕРА
  // ═══════════════════════════════════════════════════════════

  late AnimationController _markerController;

  AnimationController get markerController => _markerController;

  // ═══════════════════════════════════════════════════════════
  // ХЕНДЛЕРЫ
  // ═══════════════════════════════════════════════════════════

  late final MapMovementHandler _movementHandler;
  late final MapPanelCoordinator _panelCoordinator;
  late final MapActionButtonsBuilder _actionButtonsBuilder;

  MapMovementHandler get movementHandler => _movementHandler;
  MapPanelCoordinator get panelCoordinator => _panelCoordinator;
  MapActionButtonsBuilder get actionButtonsBuilder => _actionButtonsBuilder;

  static const double _mapWidth = 800.0;
  static const double _mapHeight = 1200.0;

  double get mapWidth => _mapWidth;
  double get mapHeight => _mapHeight;

  // ═══════════════════════════════════════════════════════════
  // ПОДПИСКИ
  // ═══════════════════════════════════════════════════════════

  StreamSubscription<Achievement>? _achievementSub;

  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();

    _controller = MapController(
      characterId: widget.characterId,
      characterName: widget.characterName,
      resumeFrom: widget.resumeFrom,
    );
    _controller.addListener(_onControllerChanged);

    _achievementSub = AchievementManager.unlockStream.listen((ach) {
      if (mounted) AchievementNotifier.showPopup(context, ach);
    });

    _markerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _movementHandler = MapMovementHandler(this);
    _panelCoordinator = MapPanelCoordinator(this);
    _actionButtonsBuilder = MapActionButtonsBuilder(this);

    _initController();
  }

  @override
  void dispose() {
    _achievementSub?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _transformController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // СЛУШАТЕЛЬ КОНТРОЛЛЕРА
  // ═══════════════════════════════════════════════════════════

  void _onControllerChanged() {
    if (!mounted) return;

    final currentRegion = _controller.currentLocation?.region;
    if (currentRegion != null && _lastRegionId != null) {
      if (currentRegion != _lastRegionId) {
        _movementHandler.onRegionChanged(currentRegion);
      }
    }
    if (currentRegion != null) {
      _lastRegionId = currentRegion;
    }

    setState(() {});

    // Проверяем цель и квесты
    _checkGoalAndQuests();
  }

  // ═══════════════════════════════════════════════════════════
  // ИНИЦИАЛИЗАЦИЯ
  // ═══════════════════════════════════════════════════════════

  Future<void> _initController() async {
    await _controller.init();
    if (!mounted) return;

    final cur = _controller.currentLocation;
    if (cur != null) {
      _movementHandler.initializeMarkerPosition(cur);

      _lastRegionId = cur.region;
      _loadedRegionId = cur.region;

      final layout = getLayoutForRegion(cur.region);
      if (layout != null) {
        final image = await RegionBackgroundCache.get(
          regionId: cur.region,
          layout: layout,
        );
        if (mounted) {
          setState(() {
            _regionBackground = image;
          });
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _movementHandler.centerOnLocation(cur);
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
      await _movementHandler.handleDeath();
      return;
    }

    // ═══════════════════════════════════════════════════════════
    // ИНИЦИАЛИЗАЦИЯ ЦЕЛИ И КВЕСТОВ
    // ═══════════════════════════════════════════════════════════

    final step = widget.chapterStep;
    if (step != null && step.isMap && step.goal != null) {
      // Устанавливаем время старта цели
      _controller.setMapGoalStartedAt(_controller.gameTime.totalMinutes);

      // Создаём трекер
      _goalTracker = MapGoalTracker(
        goal: step.goal!,
        controller: _controller,
        goalStartedAtMinutes: _controller.gameTime.totalMinutes,
      );

      // Активируем квесты
      _sideQuestManager = SideQuestManager(
        controller: _controller,
        characterId: widget.characterId,
        chapter: _controller.chapter,
      );
      await _sideQuestManager!.activateForMap(step.sideQuests);

      debugPrint('🎯 MapScreen: цель="${step.goal!.type}", '
          'квестов=${step.sideQuests.length}');

      // Проверяем цель сразу после входа (вдруг игрок уже здесь)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkGoalAndQuests();
      });
    }

    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════
  // ПРОВЕРКА ЦЕЛИ И КВЕСТОВ
  // ═══════════════════════════════════════════════════════════

  Future<void> _checkGoalAndQuests() async {
    if (!mounted) return;

    // 1. Квесты
    if (_sideQuestManager != null) {
      await _sideQuestManager!.checkProgress();
      await _sideQuestManager!.checkExpiry();

      final currentLoc = _controller.currentLocation;
      if (currentLoc != null) {
        final triggered =
            await _sideQuestManager!.checkTriggers(currentLoc);
        for (final quest in triggered) {
          if (mounted) {
            _showQuestTriggered(quest.title, quest.description);
          }
        }
      }
    }

    // 2. Цель карты
    if (_goalTracker == null) return;
    if (_goalPopupShown) return;

    if (_goalTracker!.isComplete()) {
      _goalPopupShown = true;
      final message =
          _goalTracker!.getCompleteMessage() ?? 'Цель достигнута.';
      if (mounted) {
        _showGoalComplete(message);
      }
      return;
    }

    if (_goalTracker!.isTimedOut()) {
      _goalPopupShown = true;
      final message =
          _goalTracker!.getTimeoutMessage() ?? 'Время вышло.';
      final flag = _goalTracker!.getTimeoutFlag();
      if (flag != null) {
        _controller.setFlag(flag);
      }
      if (mounted) {
        _showGoalFailed(message);
      }
    }
  }

  void _showGoalComplete(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 15, 30, 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFFC8B464),
            width: 2,
          ),
        ),
        title: const Text(
          '✅ ЦЕЛЬ ДОСТИГНУТА',
          style: TextStyle(
            color: Color(0xFFC8B464),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(dialogContext);
              widget.onGoalComplete?.call();
            },
            child: const Text(
              'ПРОДОЛЖИТЬ →',
              style: TextStyle(
                color: Color(0xFFC8B464),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalFailed(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 30, 15, 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Text(
          '💀 ЦЕЛЬ ПРОВАЛЕНА',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(dialogContext);
              widget.onGoalComplete?.call();
            },
            child: const Text(
              'ПРОДОЛЖИТЬ →',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuestTriggered(String title, String description) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 15, 20, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF5F8FBF),
            width: 2,
          ),
        ),
        title: const Text(
          '🎯 НОВЫЙ КВЕСТ',
          style: TextStyle(
            color: Color(0xFF5F8FBF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'ПОНЯТНО',
              style: TextStyle(
                color: Color(0xFF5F8FBF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ПУБЛИЧНЫЕ ХЕЛПЕРЫ (для хендлеров)
  // ═══════════════════════════════════════════════════════════

  void updateViewportSize(Size size) {
    if (_viewportSize != size) {
      _viewportSize = size;
    }
  }

  RegionLayout? getLayoutForRegion(String regionId) {
    switch (regionId) {
      case 'city_south':
        return CitySouthLayout.layout;
      case 'city_center':
        return CityCenterLayout.layout;
      default:
        return CitySouthLayout.layout;
    }
  }

  String regionDisplayName(String regionId) {
    switch (regionId) {
      case 'city_south':
        return 'Юг города';
      case 'city_center':
        return 'Центр города';
      case 'forest':
        return 'Лес';
      case 'highway':
        return 'Трасса';
      case 'north':
        return 'Север';
      case 'underground':
        return 'Подземелье';
      default:
        return regionId;
    }
  }

  void rebuild() {
    if (mounted) setState(() {});
  }

  void onNodeTap(Location loc) {
    AudioService.playTap();

    final current = _controller.currentLocation;
    if (current == null) return;
    if (loc.id == current.id) return;

    setState(() {
      _selectedLocation = loc;
    });

    _showLocationMenu(loc);
  }

  Future<void> _showLocationMenu(Location loc) async {
    final current = _controller.currentLocation;
    if (current == null) return;

    final isNeighbor = current.isConnectedTo(loc.id);
    final canMove = isNeighbor && loc.isAvailableAt(_controller.chapter);
    final isVisited = _controller.map!.visitedLocations.contains(loc.id);
    final isDetailed = _controller.hasDetails(loc.id);

    final canScoutDetails = isNeighbor &&
        _controller.isScouted(loc.id) &&
        !isDetailed &&
        _controller.stamina >= 10;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MapInfoSheet(
        location: loc,
        canMove: canMove,
        canScout: canScoutDetails,
        isBorder: loc.region != current.region,
        travelMinutes:
            isNeighbor ? current.connectionMinutesTo(loc.id) : null,
        isVisited: isVisited,
        isScouted: _controller.isScouted(loc.id),
        hasDetails: isDetailed,
        onMove: canMove ? () => _movementHandler.moveTo(loc.id) : null,
        onScout: canScoutDetails
            ? () => _movementHandler.scoutSingle(loc.id)
            : null,
      ),
    );

    if (mounted) {
      setState(() {
        _selectedLocation = null;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ВИДИМОСТЬ ЛОКАЦИЙ
  // ═══════════════════════════════════════════════════════════

  NodeState nodeState(Location loc) {
    if (!loc.isAvailableAt(_controller.chapter)) {
      return NodeState.hidden;
    }

    final current = _controller.currentLocation;
    if (current == null) return NodeState.hidden;

    if (loc.id == current.id) {
      return NodeState.current;
    }

    if (loc.hidden && !_controller.isLocationUnlocked(loc.id)) {
      return NodeState.hidden;
    }

    if (loc.region != current.region) {
      return NodeState.hidden;
    }

    final isNeighbor = current.connectionIds.contains(loc.id);
    if (isNeighbor) {
      return NodeState.neighbor;
    }

    if (_controller.isScouted(loc.id)) {
      return NodeState.visited;
    }

    return NodeState.hidden;
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
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
      backgroundColor: const Color.fromARGB(255, 8, 8, 10),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              MapStatusBar(controller: _controller),
              PenaltiesPanel(penalties: penalties),
              ConditionsPanel(conditions: _controller.activeConditions),

              if (_movementHandler.isMoving)
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
                    updateViewportSize(constraints.biggest);

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

          MapRegionTransition(
            visible: _showRegionTransition,
            regionName: _transitionRegionName,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // APP BAR
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
      title: Text(
        _controller.currentLocation?.region == 'underground'
            ? 'ПОДЗЕМЕЛЬЕ'
            : 'КАРТА',
        style: const TextStyle(
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
            if (cur != null) _movementHandler.centerOnLocation(cur);
          },
        ),
        IconButton(
          icon: const Icon(Icons.build_circle_outlined),
          tooltip: 'Крафт',
          onPressed: _panelCoordinator.showCraftPanel,
        ),
        IconButton(
          icon: const Icon(Icons.hotel),
          tooltip: 'Отдохнуть',
          onPressed: _panelCoordinator.showRestPanel,
        ),
        IconButton(
          icon: const Icon(Icons.shield_outlined),
          tooltip: 'Экипировка',
          onPressed: _panelCoordinator.showEquipment,
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
          onPressed: _panelCoordinator.showInventory,
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
  // CANVAS КАРТЫ
  // ═══════════════════════════════════════════════════════════

  Widget _buildMapCanvas() {
    final map = _controller.map!;
    final current = _controller.currentLocation!;
    final regionId = current.region;

    if (_showRegionTransition) {
      return Container(color: const Color(0xFF08080A));
    }

    final regionLocations = map.locations
        .where((l) =>
            l.region == regionId && l.isAvailableAt(_controller.chapter))
        .toList();

    final visibleNodes = regionLocations
        .where((loc) => nodeState(loc) != NodeState.hidden)
        .toList();

    MapEdge? selectedEdge;
    if (_selectedLocation != null) {
      final isNeighbor = current.isConnectedTo(_selectedLocation!.id);
      if (isNeighbor) {
        final minutes = current.connectionMinutesTo(_selectedLocation!.id);
        if (minutes != null) {
          selectedEdge = MapEdge(
            from: current.mapPosition,
            to: _selectedLocation!.mapPosition,
            minutes: minutes,
          );
        }
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _regionBackground != null
              ? RawImage(
                  image: _regionBackground,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                )
              : _buildFallbackBackground(),
        ),

        Positioned.fill(
          child: CustomPaint(
            painter: MapEdgePainter(edge: selectedEdge),
          ),
        ),

        _buildRegionLabel(regionId),

        ...visibleNodes.map((loc) {
          final px = loc.mapPosition.x * _mapWidth;
          final py = loc.mapPosition.y * _mapHeight;
          final state = nodeState(loc);

          return Positioned(
            left: px - MapNode.labelWidth / 2,
            top: py - MapNode.nodeSize / 2,
            child: MapNode(
              location: loc,
              state: state,
              isSelected: _selectedLocation?.id == loc.id,
              hasDetails: _controller.hasDetails(loc.id),
              onTap: () => onNodeTap(loc),
            ),
          );
        }),

        Positioned(
          left: _movementHandler.markerPosition.x * _mapWidth - 30,
          top: _movementHandler.markerPosition.y * _mapHeight - 30,
          child: IgnorePointer(
            child: MapPlayerMarker(
              size: 20,
              rotation: _movementHandler.markerRotation,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: const Color(0xFF0A0A0A),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC8B464)),
      ),
    );
  }

  Widget _buildRegionLabel(String regionId) {
    return Positioned(
      top: 20,
      right: 20,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141414).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFC8B464).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            regionDisplayName(regionId).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFC8B464),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // НИЖНЯЯ ПАНЕЛЬ
  // ═══════════════════════════════════════════════════════════

  Widget _buildBottomPanel(Location current) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
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
            // Цель карты
            if (_goalTracker != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8B464).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC8B464).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag,
                      color: Color(0xFFC8B464),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ТЕКУЩАЯ ЦЕЛЬ',
                            style: TextStyle(
                              color: Color(0xFFC8B464),
                              fontSize: 9,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.chapterStep?.goal?.hint ??
                                widget.chapterStep?.description ??
                                'Достигни цели',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            MapCurrentLocation(controller: _controller),
            const SizedBox(height: 8),
            ..._actionButtonsBuilder.build(current),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ШТРАФЫ
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