import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/player_stats.dart';

class AchievementManager {
  static const String _statsKey = 'dark_hours_stats';
  static const String _achievementsKey = 'dark_hours_achievements';

  static List<Achievement>? _allAchievements;
  static PlayerStats? _cachedStats;

  static Future<List<Achievement>> loadAll() async {
    if (_allAchievements != null) return _allAchievements!;
    _allAchievements = await Achievement.loadAll();
    return _allAchievements!;
  }

  static Future<PlayerStats> loadStats() async {
    if (_cachedStats != null) return _cachedStats!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_statsKey);
      if (jsonString == null) {
        _cachedStats = PlayerStats();
        return _cachedStats!;
      }
      final json = jsonDecode(jsonString);
      _cachedStats = PlayerStats.fromJson(json);
      return _cachedStats!;
    } catch (e) {
      _cachedStats = PlayerStats();
      return _cachedStats!;
    }
  }

  static Future<void> saveStats(PlayerStats stats) async {
    _cachedStats = stats;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(stats.toJson());
    await prefs.setString(_statsKey, jsonString);
  }

  /// Главный метод — проверить все достижения
  /// Возвращает список НОВЫХ разблокированных
  static Future<List<Achievement>> runCheck({
    required PlayerStats stats,
    required int currentDay,
    required int currentKills,
    required int currentInventorySize,
    required int currentCraftedCount,
    required int currentMedicineUsed,
    required int currentSanityDays,
    required int currentNights,
    required int currentDefeats,
    required bool noCombat,
    required bool noDamage,
    required bool noDefeats,
    required String characterId,
    required bool alchemistCrafted,
  }) async {
    final all = await loadAll();
    final newUnlocked = <Achievement>[];

    // Игрок играл этим персонажем
    stats.playedCharacters.add(characterId);

    for (final achievement in all) {
      if (stats.unlockedAchievements.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'first_blood':
          shouldUnlock = currentKills >= 1;
          break;
        case 'pacifist':
          // Проверяется отдельно при выходе с главы (флаг noCombat)
          break;
        case 'survived_1_day':
          shouldUnlock = currentDay >= 1;
          break;
        case 'survived_7_days':
          shouldUnlock = currentDay >= 7;
          break;
        case 'survived_30_days':
          shouldUnlock = currentDay >= 30;
          break;
        case 'reached_station':
          // Отдельно — при финале
          break;
        case 'master_crafter':
          shouldUnlock = currentCraftedCount >= 10;
          break;
        case 'alchemist':
          shouldUnlock = alchemistCrafted;
          break;
        case 'hoarder':
          shouldUnlock = currentInventorySize >= 20;
          break;
        case 'sharp_shooter':
          shouldUnlock = currentKills >= 5;
          break;
        case 'iron_will':
          shouldUnlock = currentSanityDays >= 3;
          break;
        case 'doctor':
          shouldUnlock = currentMedicineUsed >= 10;
          break;
        case 'survived_infection':
          shouldUnlock = stats.totalInfections >= 3;
          break;
        case 'all_characters':
          shouldUnlock = stats.playedCharacters.length >= 5;
          break;
        case 'boris_master':
          shouldUnlock = stats.playedCharacters.contains('boris');
          break;
        case 'alina_master':
          shouldUnlock = stats.playedCharacters.contains('alina');
          break;
        case 'ivan_master':
          shouldUnlock = stats.playedCharacters.contains('ivan');
          break;
        case 'andrey_master':
          shouldUnlock = stats.playedCharacters.contains('andrey');
          break;
        case 'darya_master':
          shouldUnlock = stats.playedCharacters.contains('darya');
          break;
        case 'no_damage':
          shouldUnlock = noDamage;
          break;
        case 'night_owl':
          shouldUnlock = currentNights >= 10;
          break;
        case 'generous':
          shouldUnlock = stats.totalItemsGivenToSurvivors >= 5;
          break;

        // ===== НОВЫЕ ДОСТИЖЕНИЯ (после этапа B) =====
        case 'phoenix':
          shouldUnlock = currentDefeats >= 5;
          break;
        case 'scarred':
          shouldUnlock = stats.totalDefeats >= 10;
          break;
        case 'no_defeats':
          shouldUnlock = noDefeats;
          break;
      }

      if (shouldUnlock) {
        stats.unlockedAchievements.add(achievement.id);
        newUnlocked.add(achievement);
      }
    }

    if (newUnlocked.isNotEmpty || currentDay > 0) {
      await saveStats(stats);
    }

    return newUnlocked;
  }

  /// Разблокировать конкретное достижение по ID
  static Future<Achievement?> unlock(String achievementId) async {
    final all = await loadAll();
    final stats = await loadStats();

    if (stats.unlockedAchievements.contains(achievementId)) return null;

    try {
      final achievement = all.firstWhere((a) => a.id == achievementId);
      stats.unlockedAchievements.add(achievementId);
      await saveStats(stats);
      return achievement;
    } catch (e) {
      return null;
    }
  }

  static Future<int> getTotalPoints() async {
    final stats = await loadStats();
    final all = await loadAll();

    int total = 0;
    for (final a in all) {
      if (stats.unlockedAchievements.contains(a.id)) {
        total += a.points;
      }
    }
    return total;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
    await prefs.remove(_achievementsKey);
    _cachedStats = null;
  }
}