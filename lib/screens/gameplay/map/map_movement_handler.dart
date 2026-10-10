// lib/screens/gameplay/map/map_movement_handler.dart

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/movement_manager.dart';
import 'package:dark_hours/services/map/death_manager.dart';
import 'package:dark_hours/services/map/region_background_cache.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/models/world/map_position.dart';

import 'package:dark_hours/screens/gameplay/map/map_screen.dart';

/// Управляет перемещением, анимацией маркера и сменой региона.
///
/// **Ответственности:**
/// - Плавная анимация маркера при переходе.
/// - Центрирование камеры на текущей локации.
/// - Смена региона: загрузка фона + оверлей.
/// - Разведка локаций (одна / массовая).
/// - Проверка смерти и усталости после действий.
class MapMovementHandler {
  final MapScreenState screen;

  MapMovementHandler(this.screen);

  // ═══════════════════════════════════════════════════════════
  // СОСТОЯНИЕ АНИМАЦИИ МАРКЕРА
  // ═══════════════════════════════════════════════════════════

  MapPosition _markerPosition = const MapPosition(x: 0.5, y: 0.5);
  double _markerRotation = 0.0;
  bool _isMoving = false;

  late Animation<MapPosition> _markerAnimation;
  bool _markerListenerAttached = false;

  MapPosition get markerPosition => _markerPosition;
  double get markerRotation => _markerRotation;
  bool get isMoving => _isMoving;

  // ═══════════════════════════════════════════════════════════
  // ИНИЦИАЛИЗАЦИЯ
  // ═══════════════════════════════════════════════════════════

  /// Установить стартовую позицию маркера.
  void initializeMarkerPosition(Location loc) {
    _markerPosition = loc.mapPosition;
  }

  // ═══════════════════════════════════════════════════════════
  // ЦЕНТРИРОВАНИЕ
  // ═══════════════════════════════════════════════════════════

  /// Центрировать камеру на локации.
  void centerOnLocation(Location loc) {
    final px = loc.mapPosition.x * screen.mapWidth;
    final py = loc.mapPosition.y * screen.mapHeight;

    final viewSize = screen.viewportSize;
    final tx = viewSize.width / 2 - px;
    final ty = viewSize.height / 2 - py;

    screen.transformController.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1);
  }

  // ═══════════════════════════════════════════════════════════
  // ПЕРЕХОД
  // ═══════════════════════════════════════════════════════════

  /// Перейти в локацию с анимацией маркера.
  Future<void> moveTo(String locationId) async {
    final target = screen.controller.map?.getById(locationId);
    if (target != null) {
      _startMarkerAnimation(target.mapPosition);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final ok = await MovementManager.move(
      screen.context,
      screen.controller,
      locationId,
    );

    if (!ok || !screen.mounted) return;

    final newLoc = screen.controller.currentLocation;
    if (newLoc != null) {
      _finishMarkerAnimation(newLoc.mapPosition);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (screen.mounted) centerOnLocation(newLoc);
      });
    }

    screen.selectedLocation = null;

    if (DeathManager.checkDeath(screen.controller)) {
      await handleDeath();
      return;
    }

    await DeathManager.checkFatigue(screen.context, screen.controller);
    screen.rebuild();
  }

  // ═══════════════════════════════════════════════════════════
  // АНИМАЦИЯ МАРКЕРА
  // ═══════════════════════════════════════════════════════════

  void _startMarkerAnimation(MapPosition target) {
    _isMoving = true;

    final dx = target.x - _markerPosition.x;
    final dy = target.y - _markerPosition.y;
    _markerRotation = math.atan2(dy, dx) + math.pi / 2;

    _markerAnimation = Tween<MapPosition>(
      begin: _markerPosition,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: screen.markerController,
        curve: Curves.easeInOut,
      ),
    );

    if (!_markerListenerAttached) {
      screen.markerController.addListener(_onMarkerTick);
      _markerListenerAttached = true;
    }

    screen.markerController.forward(from: 0);
    screen.rebuild();
  }

  void _finishMarkerAnimation(MapPosition target) {
    _markerPosition = target;
    _isMoving = false;

    screen.markerController.stop();
    if (_markerListenerAttached) {
      screen.markerController.removeListener(_onMarkerTick);
      _markerListenerAttached = false;
    }

    screen.rebuild();
  }

  void _onMarkerTick() {
    _markerPosition = _markerAnimation.value;
    screen.rebuild();
  }

  // ═══════════════════════════════════════════════════════════
  // СМЕНА РЕГИОНА
  // ═══════════════════════════════════════════════════════════

  /// Обработчик смены региона.
  ///
  /// **Логика:**
  /// 1. Показывает **непрозрачный** оверлей.
  /// 2. Загружает фон нового региона **под оверлеем**.
  /// 3. Когда фон готов — обновляет `regionBackground`.
  /// 4. Держит оверлей ещё 800 ms.
  /// 5. Убирает оверлей — карта показывается с новым фоном.
  Future<void> onRegionChanged(String newRegion) async {
    final name = screen.regionDisplayName(newRegion);

    screen.showRegionTransition = true;
    screen.transitionRegionName = name;
    screen.loadedRegionId = null;

    await loadRegionBackground(newRegion);

    if (!screen.mounted) return;

    await Future.delayed(const Duration(milliseconds: 800));

    if (!screen.mounted) return;

    screen.showRegionTransition = false;

    if (screen.mounted) {
      ScaffoldMessenger.of(screen.context).showSnackBar(
        SnackBar(
          content: Text('🚪 Ты пересёк границу: $name'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 100, 130, 180),
        ),
      );
    }
  }

  /// Загрузить фон региона (если ещё не загружен).
  Future<void> loadRegionBackground(String regionId) async {
    if (screen.loadedRegionId == regionId &&
        screen.regionBackground != null) {
      return;
    }

    final layout = screen.getLayoutForRegion(regionId);
    if (layout == null) return;

    final ui.Image? image = await RegionBackgroundCache.get(
      regionId: regionId,
      layout: layout,
    );

    if (!screen.mounted) return;

    screen.regionBackground = image;
    screen.loadedRegionId = regionId;
  }

  // ═══════════════════════════════════════════════════════════
  // СМЕРТЬ
  // ═══════════════════════════════════════════════════════════

  /// Обработать смерть игрока.
  Future<void> handleDeath() async {
    if (!screen.mounted) return;
    await DeathManager.applyStatsOnDeath(screen.controller);
    if (!screen.mounted) return;
    await DeathManager.showDeathScreenIfNeeded(
      screen.context,
      screen.controller,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // РАЗВЕДКА — одна локация
  // ═══════════════════════════════════════════════════════════

  /// Разведать состояние одной локации (30 мин, 10 стамины).
  Future<void> scoutSingle(String locationId) async {
    if (screen.controller.stamina < 10) {
      AudioService.playError();
      if (!screen.mounted) return;
      ScaffoldMessenger.of(screen.context).showSnackBar(
        const SnackBar(
          content: Text('❌ Слишком устал для разведки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    screen.controller.setStamina(screen.controller.stamina - 10);
    screen.controller.setFatigue(screen.controller.fatigue + 5);

    final ok = screen.controller.scoutDetails(locationId);
    if (!ok) {
      AudioService.playError();
      return;
    }

    await screen.controller.advanceTime(30);
    await screen.controller.save();

    if (!screen.mounted) return;

    AudioService.playSuccess();
    final loc = screen.controller.map?.getById(locationId);
    if (loc != null) {
      final details = buildDetailText(loc);
      ScaffoldMessenger.of(screen.context).showSnackBar(
        SnackBar(
          content: Text('🔭 ${loc.displayScoutedName}: $details'),
          backgroundColor: const Color.fromARGB(255, 100, 130, 180),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    screen.rebuild();
  }

  // ═══════════════════════════════════════════════════════════
  // РАЗВЕДКА — массовая
  // ═══════════════════════════════════════════════════════════

  /// Найти локации региона, которые можно разведать.
  List<Location> getScoutCandidates(Location current) {
    final map = screen.controller.map;
    if (map == null) return [];

    final result = <Location>[];

    for (final loc in map.locations) {
      if (loc.region != current.region) continue;
      if (loc.id == current.id) continue;
      if (loc.hidden && !screen.controller.isLocationUnlocked(loc.id)) {
        continue;
      }
      if (!screen.controller.isScouted(loc.id)) continue;
      if (screen.controller.hasDetails(loc.id)) continue;

      result.add(loc);
    }

    return result;
  }

  /// Есть ли что разведать в регионе?
  bool canScout(Location current) {
    final unknown = getScoutCandidates(current);
    return unknown.isNotEmpty && screen.controller.stamina >= 10;
  }

  /// Массовая разведка района (30 мин, 10 стамины).
  Future<void> scout() async {
    AudioService.playClick();

    final current = screen.controller.currentLocation;
    if (current == null) return;

    final candidates = getScoutCandidates(current);

    if (candidates.isEmpty) {
      AudioService.playError();
      if (!screen.mounted) return;
      ScaffoldMessenger.of(screen.context).showSnackBar(
        const SnackBar(
          content: Text('🔭 Ты уже знаешь всё об этом районе'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    if (screen.controller.stamina < 10) {
      AudioService.playError();
      if (!screen.mounted) return;
      ScaffoldMessenger.of(screen.context).showSnackBar(
        const SnackBar(
          content: Text('❌ Слишком устал для разведки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    screen.controller.setStamina(screen.controller.stamina - 10);
    screen.controller.setFatigue(screen.controller.fatigue + 5);

    final rng = math.Random();
    final roll = rng.nextInt(100);

    int count;
    String mood;
    if (roll < 20) {
      count = 0;
      mood = 'Ты обходишь район, но ничего нового не замечаешь.';
    } else if (roll < 60) {
      count = 1;
      mood = 'Ты прислушиваешься. Один из домов ведёт себя странно...';
    } else if (roll < 90) {
      count = 2;
      mood = 'Ты замечаешь перемены сразу в двух местах...';
    } else {
      count = 3;
      mood = 'С высоты ты видишь многое. Район раскрывает свои секреты...';
    }

    final scoutedList = <String>[];
    candidates.shuffle(rng);
    for (int i = 0; i < count && i < candidates.length; i++) {
      screen.controller.scoutDetails(candidates[i].id);
      scoutedList.add(candidates[i].id);
    }

    await screen.controller.advanceTime(30);
    await screen.controller.save();

    if (!screen.mounted) return;

    await showScoutResult(mood, scoutedList);

    screen.rebuild();
  }

  /// Показать результат массовой разведки.
  Future<void> showScoutResult(String mood, List<String> scoutedIds) async {
    if (!screen.mounted) return;

    final map = screen.controller.map;
    if (map == null) return;

    final locations = scoutedIds
        .map((id) => map.getById(id))
        .whereType<Location>()
        .toList();

    await showModalBottomSheet(
      context: screen.context,
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
                '🔭 РАЗВЕДКА РАЙОНА',
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
              if (locations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ничего нового. Район тих — или прячется.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              else ...[
                const Text(
                  'Что удалось заметить:',
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
    final details = buildDetailText(loc);

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
          Text(loc.icon, style: const TextStyle(fontSize: 28)),
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
                  details,
                  style: TextStyle(
                    color: Colors.grey[400],
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

  /// Построить короткое описание состояния локации.
  String buildDetailText(Location loc) {
    final parts = <String>[];

    if (loc.dangerLevel >= 8) {
      parts.add('очень опасно');
    } else if (loc.dangerLevel >= 6) {
      parts.add('опасно');
    } else if (loc.dangerLevel >= 4) {
      parts.add('настороженно');
    } else if (loc.dangerLevel >= 2) {
      parts.add('спокойно');
    } else {
      parts.add('тихо');
    }

    if (loc.enemies.isNotEmpty) {
      parts.add('${loc.enemies.length} цел. врагов');
    } else {
      parts.add('врагов не видно');
    }

    if (loc.lootPool.isNotEmpty) {
      final searched = screen.controller.searchedCounts[loc.id] ?? 0;
      if (searched < loc.maxSearches) {
        parts.add('есть чем поживиться');
      } else {
        parts.add('уже обчищено');
      }
    }

    if (loc.risk != null) {
      parts.add('⚠️ риск');
    }

    return parts.join(', ');
  }
}