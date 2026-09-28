import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/achievement_manager.dart';
import '../services/run_tracker.dart';
import '../widgets/achievement_notifier.dart';

class AchievementChecker {
  /// Проверить достижения после действия
  /// Возвращает список новых достижений
  static Future<List<Achievement>> check({
    required BuildContext? context,
    required String characterId,
    required int day,
    required int inventorySize,
    required RunTracker tracker,
    int sanityDays = 0,
    bool? noCombat,
    bool? noDamage,
    bool? noDefeats,
  }) async {
    final stats = await AchievementManager.loadStats();

    final newUnlocked = await AchievementManager.runCheck(
      stats: stats,
      currentDay: day,
      currentKills: tracker.kills,
      currentInventorySize: inventorySize,
      currentCraftedCount: tracker.craftedCount,
      currentMedicineUsed: tracker.medicineUsed,
      currentSanityDays: sanityDays,
      currentNights: tracker.nightsSurvived,
      currentDefeats: tracker.defeats,
      noCombat: noCombat ?? !tracker.hadCombat,
      noDamage: noDamage ?? !tracker.hadDamage,
      noDefeats: noDefeats ?? (tracker.defeats == 0),
      characterId: characterId,
      alchemistCrafted: tracker.alchemistCrafted,
    );

    if (newUnlocked.isNotEmpty && context != null && context.mounted) {
      await AchievementNotifier.showAll(context, newUnlocked);
    }

    return newUnlocked;
  }
}