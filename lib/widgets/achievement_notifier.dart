import 'package:flutter/material.dart';
import '../models/achievement.dart';
import 'achievement_popup.dart';

class AchievementNotifier {
  /// Показать попап достижения
  static void show(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => AchievementPopup(
        achievement: achievement,
        onClose: () {},
      ),
    );
  }

  /// Показать список достижений по очереди
  static Future<void> showAll(
    BuildContext context,
    List<Achievement> achievements,
  ) async {
    for (final a in achievements) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (_) => AchievementPopup(
          achievement: a,
          onClose: () {},
        ),
      );
    }
  }
}