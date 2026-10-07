import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dark_hours/models/progress/achievement.dart';
import 'package:dark_hours/models/progress/player_stats.dart';
import 'package:dark_hours/services/progress/run_tracker.dart';

/// Менеджер достижений.
///
/// **Архитектура:**
/// - `AchievementManager` — чистая логика, работает без BuildContext.
/// - Когда достижение разблокировано — оно **пушится в `unlockStream`**.
/// - UI (MapScreen, StoryScreen) подписывается на поток и показывает попапы.
class AchievementManager {
  AchievementManager._();

  static const String _statsKey = 'dark_hours_stats';
  static const String _achievementsKey = 'dark_hours_achievements';

  /// Версия схемы сохранения.
  ///
  /// Меняется при несовместимых изменениях в логике достижений.
  /// При несовпадении — сбрасываются некоторые достижения.
  ///
  /// v1: до Streams-рефакторинга. `survived_1_day` и `*_master`
  ///     могли открываться ложно.
  /// v2: правильно — `survived_X_days` через `nightsPassed`,
  ///     `*_master` через `completedChapters`.
  static const int _schemaVersion = 2;
  static const String _schemaVersionKey = 'achievement_schema_version';

  /// Достижения, которые надо сбросить при миграции v1 → v2.
  ///
  /// Они могли быть открыты **ошибочно** — из-за старой логики.
  static const List<String> _migrationV2Resets = [
    'survived_1_day',
    'survived_7_days',
    'survived_30_days',
    'boris_master',
    'alina_master',
    'ivan_master',
    'andrey_master',
    'darya_master',
  ];

  static List<Achievement>? _allAchievements;
  static PlayerStats? _cachedStats;

  /// Поток новых разблокированных достижений.
  ///
  /// UI подписывается и показывает попапы.
  /// **Broadcast** — чтобы несколько подписчиков могли слушать.
  static final StreamController<Achievement> _unlockController =
      StreamController<Achievement>.broadcast();

  /// Стрим для подписки на разблокировку достижений.
  static Stream<Achievement> get unlockStream => _unlockController.stream;

  // ═══════════════════════════════════════════════════════════
  // ЗАГРУЗКА / СОХРАНЕНИЕ
  // ═══════════════════════════════════════════════════════════

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
        await prefs.setInt(_schemaVersionKey, _schemaVersion);
        return _cachedStats!;
      }

      final json = jsonDecode(jsonString);
      _cachedStats = PlayerStats.fromJson(json);

      // Миграция схемы.
      await _migrateIfNeeded(prefs);

      return _cachedStats!;
    } catch (e) {
      _cachedStats = PlayerStats();
      return _cachedStats!;
    }
  }

  /// Миграция старого сохранения.
  ///
  /// Если версия схемы < текущей — сбрасываем проблемные достижения,
  /// чтобы они разблокировались заново по правильной логике.
  static Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    final savedVersion = prefs.getInt(_schemaVersionKey) ?? 1;

    if (savedVersion >= _schemaVersion) return;

    debugPrint('🔧 AchievementManager: миграция схемы '
        'v$savedVersion → v$_schemaVersion');

    // Сбрасываем "проблемные" достижения.
    if (_cachedStats != null) {
      for (final id in _migrationV2Resets) {
        _cachedStats!.unlockedAchievements.remove(id);
      }
      await saveStats(_cachedStats!);
    }

    await prefs.setInt(_schemaVersionKey, _schemaVersion);
    debugPrint('✅ AchievementManager: миграция завершена');
  }

  static Future<void> saveStats(PlayerStats stats) async {
    _cachedStats = stats;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(stats.toJson());
    await prefs.setString(_statsKey, jsonString);
    await prefs.setInt(_schemaVersionKey, _schemaVersion);
  }

  // ═══════════════════════════════════════════════════════════
  // ГЛАВНЫЙ МЕТОД — ПРОВЕРКА БЕЗ CONTEXT
  // ═══════════════════════════════════════════════════════════

  /// Проверить все достижения.
  ///
  /// **Не требует BuildContext.** Разблокированные достижения
  /// пушатся в `unlockStream` — UI подписан и покажет попапы.
  ///
  /// Возвращает список **новых** разблокированных достижений.
  static Future<List<Achievement>> unlockAll({
    required String characterId,
    required RunTracker tracker,
    required int day,
    required int inventorySize,
    int sanityDays = 0,
    bool? noCombat,
    bool? noDamage,
    bool? noDefeats,
  }) async {
    final all = await loadAll();
    final stats = await loadStats();
    final newUnlocked = <Achievement>[];

    // Игрок играл этим персонажем
    stats.playedCharacters.add(characterId);

    for (final achievement in all) {
      if (stats.unlockedAchievements.contains(achievement.id)) continue;

      final shouldUnlock = _shouldUnlock(
        achievement: achievement,
        stats: stats,
        tracker: tracker,
        day: day,
        inventorySize: inventorySize,
        sanityDays: sanityDays,
        noCombat: noCombat,
        noDamage: noDamage,
        noDefeats: noDefeats,
      );

      if (shouldUnlock) {
        stats.unlockedAchievements.add(achievement.id);
        newUnlocked.add(achievement);

        if (!_unlockController.isClosed) {
          _unlockController.add(achievement);
        }
      }
    }

    if (newUnlocked.isNotEmpty) {
      await saveStats(stats);
    }

    return newUnlocked;
  }

  /// Чистая логика: должно ли открыться это достижение?
  static bool _shouldUnlock({
    required Achievement achievement,
    required PlayerStats stats,
    required RunTracker tracker,
    required int day,
    required int inventorySize,
    required int sanityDays,
    required bool? noCombat,
    required bool? noDamage,
    required bool? noDefeats,
  }) {
    switch (achievement.id) {
      // === БОЙ ===
      case 'first_blood':
        return tracker.kills >= 1;
      case 'sharp_shooter':
        return tracker.kills >= 5;
      case 'phoenix':
        return tracker.defeats >= 5;
      case 'scarred':
        return stats.totalDefeats >= 10;
      case 'no_damage':
        return noDamage ?? false;
      case 'no_defeats':
        return noDefeats ?? false;
      case 'pacifist':
        return noCombat ?? false;

      // === ВЫЖИВАНИЕ ===
      //
      // "Проживи N дней" = "переживи N смен дня".
      // Это правильнее, чем day >= N: день начинается с 1,
      // поэтому day >= 1 срабатывает сразу.
      case 'survived_1_day':
        return tracker.nightsPassed >= 1;
      case 'survived_7_days':
        return tracker.nightsPassed >= 7;
      case 'survived_30_days':
        return tracker.nightsPassed >= 30;
      case 'night_owl':
        return tracker.nightsSurvived >= 10;
      case 'iron_will':
        return sanityDays >= 3;

      // === КРАФТ / ДОБЫЧА ===
      case 'master_crafter':
        return tracker.craftedCount >= 10;
      case 'alchemist':
        return tracker.alchemistCrafted;
      case 'hoarder':
        return inventorySize >= 20;

      // === МЕДИЦИНА ===
      case 'doctor':
        return tracker.medicineUsed >= 10;
      case 'survived_infection':
        return stats.totalInfections >= 3;

      // === СЮЖЕТ ===
      //
      // all_characters: просто поиграть за всех 5.
      case 'all_characters':
        return stats.playedCharacters.length >= 5;

      // *_master: требуют ЗАВЕРШЕНИЯ главы за персонажа.
      case 'boris_master':
        return stats.completedChapters.contains('boris_ch1');
      case 'alina_master':
        return stats.completedChapters.contains('alina_ch1');
      case 'ivan_master':
        return stats.completedChapters.contains('ivan_ch1');
      case 'andrey_master':
        return stats.completedChapters.contains('andrey_ch1');
      case 'darya_master':
        return stats.completedChapters.contains('darya_ch1');

      case 'generous':
        return stats.totalItemsGivenToSurvivors >= 5;

      // === ОТДЕЛЬНЫЕ (вручную) ===
      case 'reached_station':
        return false; // вызывается через unlock()

      default:
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // РУЧНАЯ РАЗБЛОКИРОВКА
  // ═══════════════════════════════════════════════════════════

  /// Разблокировать конкретное достижение по ID.
  static Future<Achievement?> unlock(String achievementId) async {
    final all = await loadAll();
    final stats = await loadStats();

    if (stats.unlockedAchievements.contains(achievementId)) return null;

    try {
      final achievement = all.firstWhere((a) => a.id == achievementId);
      stats.unlockedAchievements.add(achievementId);
      await saveStats(stats);

      if (!_unlockController.isClosed) {
        _unlockController.add(achievement);
      }

      return achievement;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // УТИЛИТЫ
  // ═══════════════════════════════════════════════════════════

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

  /// Полный сброс: удаляет всю статистику и достижения.
  ///
  /// **Осторожно:** после сброса игрок теряет всё.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
    await prefs.remove(_achievementsKey);
    await prefs.remove(_schemaVersionKey);
    _cachedStats = null;
  }

  // ═══════════════════════════════════════════════════════════
  // ТЕСТИРОВАНИЕ
  // ═══════════════════════════════════════════════════════════

  /// Закрыть стрим (для тестов).
  @visibleForTesting
  static Future<void> disposeStream() async {
    if (!_unlockController.isClosed) {
      await _unlockController.close();
    }
  }
}