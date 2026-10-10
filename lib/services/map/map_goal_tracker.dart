import 'package:flutter/foundation.dart';

import 'package:dark_hours/models/story/map_goal.dart';
import 'package:dark_hours/services/map/map_controller.dart';

/// Проверяет, выполнена ли цель карты.
class MapGoalTracker {
  final MapGoal goal;
  final MapController controller;
  final int goalStartedAtMinutes;

  const MapGoalTracker({
    required this.goal,
    required this.controller,
    required this.goalStartedAtMinutes,
  });

  /// Проверить, выполнена ли цель **сейчас**.
  bool isComplete() {
    switch (goal.type) {
      case 'reach_location':
        return controller.currentLocation?.id == goal.target;

      case 'find_item':
        return controller.inventory.hasItem(goal.target ?? '');

      case 'survive_night':
        return controller.flags.contains('slept_first_night');

      case 'custom_flag':
        return controller.flags.contains(goal.target ?? '');

      default:
        debugPrint('⚠️ MapGoalTracker: неизвестный тип "${goal.type}"');
        return false;
    }
  }

  /// Проверить, истекло ли время.
  bool isTimedOut() {
    if (!goal.hasTimeLimit) return false;

    final now = controller.gameTime.totalMinutes;
    final elapsed = now - goalStartedAtMinutes;
    return elapsed >= goal.timeLimitMinutes!;
  }

  /// Получить сообщение при завершении.
  String? getCompleteMessage() => goal.onCompleteMessage;

  /// Получить сообщение при истечении времени.
  String? getTimeoutMessage() => goal.onTimeoutMessage;

  /// Получить флаг при истечении времени.
  String? getTimeoutFlag() => goal.onTimeoutFlag;
}