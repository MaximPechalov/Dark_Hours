// lib/services/map/movement_manager.dart

import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/story_trigger_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/utils/time_format.dart';
import 'package:dark_hours/constants/game_constants.dart';

/// Результат попытки перейти в локацию.
enum MoveResult {
  success,
  noMap,
  notFound,
  hidden,
  notConnected,
  notAvailableInChapter,
}

/// Управляет перемещением между локациями.
class MovementManager {
  static Future<bool> move(
    BuildContext context,
    MapController controller,
    String locationId,
  ) async {
    final validation = validateMove(controller, locationId);
    if (validation != MoveResult.success) {
      debugPrint('⚠️ MovementManager: переход отклонён — $validation');

      // Специальное сообщение для не-доступных в главе
      if (validation == MoveResult.notAvailableInChapter && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚧 Туда пока не пройти. Нужно время.'),
            backgroundColor: Color.fromARGB(255, 100, 100, 100),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    final map = controller.map!;
    final target = map.getById(locationId)!;
    final current = controller.currentLocation;

    int travelMinutes = GameConstants.moveTimeMinutes;
    if (current != null) {
      final minutes = current.connectionMinutesTo(locationId);
      if (minutes != null) {
        travelMinutes = minutes;
      }
    }

    // Стоимость стамины зависит от endurance.
    final staminaCost = computeStaminaCost(
      travelMinutes,
      controller.endurance,
    );

    controller.setStamina(controller.stamina - staminaCost);

    AudioService.playClick();

    await controller.advanceTime(travelMinutes);

    map.moveTo(locationId);

    controller.scoutLocation(locationId);
    controller.discoverRegion(target.region);

    for (final conn in target.connections) {
      controller.scoutedLocations.add(conn.targetId);
    }

    controller.refresh();

    final ambiencePath = AudioService.ambienceForLocation(
      locationId: target.id,
      type: target.type,
      region: target.region,
      dangerLevel: target.dangerLevel,
    );
    if (ambiencePath != null) {
      await AudioService.playAmbience(ambiencePath);
    }

    await controller.save();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Переход: ${target.name} · ${TimeFormat.duration(travelMinutes)} · −$staminaCost⚡',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 200, 180, 100),
        ),
      );
    }

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

    // Проверка главы.
    if (!target.isAvailableAt(controller.chapter)) {
      return MoveResult.notAvailableInChapter;
    }

    if (target.hidden && !controller.isLocationUnlocked(target.id)) {
      return MoveResult.hidden;
    }

    final current = controller.currentLocation;
    if (current != null && !current.isConnectedTo(locationId)) {
      return MoveResult.notConnected;
    }

    return MoveResult.success;
  }

  @visibleForTesting
  static int getTravelTime(MapController controller, String locationId) {
    final current = controller.currentLocation;
    if (current == null) return GameConstants.moveTimeMinutes;
    return current.connectionMinutesTo(locationId) ??
        GameConstants.moveTimeMinutes;
  }

  /// Стоимость стамины за переход.
  ///
  /// Базовая формула: `travelMinutes / 10`, клампится в [2, 20].
  /// Затем умножается на `enduranceMoveMultiplier(endurance)`:
  /// - endurance 9 → множитель 0.80 → на 20% дешевле
  /// - endurance 5 → множитель 1.00 → базово
  /// - endurance 3 → множитель 1.10 → на 10% дороже
  ///
  /// Возвращает минимум 1 (нельзя сделать переход бесплатным).
  @visibleForTesting
  static int computeStaminaCost(int travelMinutes, int endurance) {
    final baseCost = (travelMinutes / 10).round().clamp(2, 20);
    final multiplier = GameConstants.enduranceMoveMultiplier(endurance);
    final adjusted = (baseCost * multiplier).round();
    return adjusted < 1 ? 1 : adjusted;
  }
}