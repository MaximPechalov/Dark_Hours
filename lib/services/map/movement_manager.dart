import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/story_trigger_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

/// Результат попытки перейти в локацию.
enum MoveResult {
  success,
  noMap,
  notFound,
  hidden,
  notConnected,
}

/// Управляет перемещением между локациями.
class MovementManager {
  /// Перейти в локацию по ID.
  static Future<bool> move(
    BuildContext context,
    MapController controller,
    String locationId,
  ) async {
    final validation = validateMove(controller, locationId);
    if (validation != MoveResult.success) {
      debugPrint('⚠️ MovementManager: переход отклонён — $validation');
      return false;
    }

    final map = controller.map!;
    final target = map.getById(locationId)!;
    final current = controller.currentLocation;

    // ─── 1. Время перехода из Connection ───
    int travelMinutes = 20;
    if (current != null) {
      final minutes = current.connectionMinutesTo(locationId);
      if (minutes != null) {
        travelMinutes = minutes;
      }
    }

    // ─── 2. Расход стамины пропорционально времени ───
    // 15 мин → 2 стамины, 60 мин → 6, 120 мин → 12, 200 мин → 20 (max).
    final staminaCost = (travelMinutes / 10).round().clamp(2, 20);
    controller.setStamina(controller.stamina - staminaCost);

    // ─── 3. Звук клика ───
    AudioService.playClick();

    // ─── 4. Продвигаем время ───
    await controller.advanceTime(travelMinutes);

    // ─── 5. Меняем локацию ───
    map.moveTo(locationId);

    // ─── 6. Авто-разведка новой локации ───
    controller.scoutLocation(locationId);
    controller.discoverRegion(target.region);

    for (final conn in target.connections) {
      controller.scoutedLocations.add(conn.targetId);
    }

    controller.refresh();

    // ─── 7. Ambience ───
    final ambiencePath = AudioService.ambienceForLocation(
      locationId: target.id,
      type: target.type,
      region: target.region,
      dangerLevel: target.dangerLevel,
    );
    if (ambiencePath != null) {
      await AudioService.playAmbience(ambiencePath);
    }

    // ─── 8. Автосохранение ───
    await controller.save();

    // ─── 9. Снекбар ───
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Переход: ${target.name} · ${_formatTime(travelMinutes)} · −$staminaCost⚡',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 200, 180, 100),
        ),
      );
    }

    // ─── 10. Сюжетный триггер ───
    await StoryTriggerManager.checkTrigger(context, controller);

    return true;
  }

  /// Чистая валидация перехода.
  @visibleForTesting
  static MoveResult validateMove(
    MapController controller,
    String locationId,
  ) {
    final map = controller.map;
    if (map == null) return MoveResult.noMap;

    final target = map.getById(locationId);
    if (target == null) return MoveResult.notFound;

    if (target.hidden && !controller.isLocationUnlocked(target.id)) {
      return MoveResult.hidden;
    }

    final current = controller.currentLocation;
    if (current != null && !current.isConnectedTo(locationId)) {
      return MoveResult.notConnected;
    }

    return MoveResult.success;
  }

  /// Получить время перехода (в минутах).
  @visibleForTesting
  static int getTravelTime(MapController controller, String locationId) {
    final current = controller.currentLocation;
    if (current == null) return 20;
    return current.connectionMinutesTo(locationId) ?? 20;
  }

  /// Расход стамины на переход.
  @visibleForTesting
  static int computeStaminaCost(int travelMinutes) {
    return (travelMinutes / 10).round().clamp(2, 20);
  }

  static String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes мин';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }
}