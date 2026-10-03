import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/map/story_trigger_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/constants/game_constants.dart';

/// Результат попытки перейти в локацию.
enum MoveResult {
  /// Переход возможен (или уже выполнен).
  success,

  /// Карта не загружена.
  noMap,

  /// Локация с таким id не найдена.
  notFound,

  /// Локация скрытая и ещё не открыта.
  hidden,
}

/// Управляет перемещением между локациями.
///
/// Что делает:
/// 1. Проверяет, что локация существует и доступна.
/// 2. Списывает стамину за переход.
/// 3. Продвигает игровое время.
/// 4. Меняет текущую локацию в MapController.
/// 5. Запускает ambience новой локации.
/// 6. Автосохраняет.
/// 7. Проверяет сюжетные триггеры.
class MovementManager {
  /// Перейти в локацию по ID.
  ///
  /// Возвращает `true`, если переход удался.
  static Future<bool> move(
    BuildContext context,
    MapController controller,
    String locationId,
  ) async {
    // ─── 1. Валидация ───
    final validation = validateMove(controller, locationId);
    if (validation != MoveResult.success) {
      debugPrint('⚠️ MovementManager: переход отклонён — $validation');
      return false;
    }

    final map = controller.map!;
    final target = map.getById(locationId)!;

    // ─── 2. Звук клика ───
    AudioService.playClick();

    // ─── 3. Списываем стамину ───
    controller.setStamina(
      controller.stamina - GameConstants.moveStaminaCost,
    );

    // ─── 4. Продвигаем время ───
    await controller.advanceTime(GameConstants.moveTimeMinutes);

    // ─── 5. Меняем локацию ───
    map.moveTo(locationId);
    controller.refresh();

    // ─── 6. Ambience новой локации ───
    final ambiencePath = AudioService.ambienceForLocation(
      locationId: target.id,
      type: target.type,
      region: target.region,
      dangerLevel: target.dangerLevel,
    );
    if (ambiencePath != null) {
      await AudioService.playAmbience(ambiencePath);
    }

    // ─── 7. Автосохранение ───
    await controller.save();

    // ─── 8. Снекбар ───
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Переход: ${target.name}'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color.fromARGB(255, 200, 180, 100),
        ),
      );
    }

    // ─── 9. Проверка сюжетного триггера ───
    await StoryTriggerManager.checkTrigger(context, controller);

    return true;
  }

  /// Чистая валидация перехода — БЕЗ UI.
  ///
  /// Возвращает:
  /// - `success` — переход можно выполнить.
  /// - `noMap` — карта не загружена.
  /// - `notFound` — локация с таким id не существует.
  /// - `hidden` — локация скрытая и ещё не открыта.
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

    return MoveResult.success;
  }
}