import 'package:flutter/material.dart';
import 'package:dark_hours/models/progress/achievement.dart';
import 'achievement_popup.dart';

/// Показывает всплывающие попапы для достижений.
///
/// **Использование:**
/// ```dart
/// _achievementSub = AchievementManager.unlockStream.listen((ach) {
///   AchievementNotifier.showPopup(context, ach);
/// });
/// ```
class AchievementNotifier {
  AchievementNotifier._();

  /// Показать попап одного достижения.
  ///
  /// Ждёт, пока игрок закроет попап (нажмёт на него),
  /// потом возвращает управление.
  static Future<void> showPopup(
    BuildContext context,
    Achievement achievement,
  ) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => AchievementPopup(
        achievement: achievement,
        onClose: () {},
      ),
    );
  }

  /// Показать несколько попапов по очереди.
  ///
  /// Оставлено для обратной совместимости. Обычно не нужно —
  /// стрим вызывает `showPopup` по одному достижению.
  static Future<void> showAll(
    BuildContext context,
    List<Achievement> achievements,
  ) async {
    for (final a in achievements) {
      if (!context.mounted) return;
      await showPopup(context, a);
    }
  }
}