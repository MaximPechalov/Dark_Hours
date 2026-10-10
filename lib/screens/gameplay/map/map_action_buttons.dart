// lib/screens/gameplay/map/map_action_buttons.dart

import 'package:flutter/material.dart';

import 'package:dark_hours/models/world/location.dart';
import 'package:dark_hours/services/progress/achievement_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

import 'package:dark_hours/widgets/effects/shimmer_button.dart';

import 'package:dark_hours/screens/gameplay/map/map_screen.dart';

/// Билдер кнопок нижней панели карты.
///
/// **Ответственности:**
/// - Решить, какие кнопки показывать для текущей локации.
/// - Собрать их в список виджетов.
/// - Вызвать коллбэки через [screen].
class MapActionButtonsBuilder {
  final MapScreenState screen;

  MapActionButtonsBuilder(this.screen);

  // ═══════════════════════════════════════════════════════════
  // ГЛАВНЫЙ МЕТОД
  // ═══════════════════════════════════════════════════════════

  /// Собрать список кнопок для текущей локации.
  List<Widget> build(Location current) {
    final widgets = <Widget>[];

    // 1. Обыск — если есть что искать
    if (_canSearch(current)) {
      widgets.add(_buildSearchButton(current));
      widgets.add(const SizedBox(height: 8));
    }

    // 2. Разведка — если есть что разведать в регионе
    if (screen.movementHandler.canScout(current)) {
      widgets.add(_buildScoutButton());
      widgets.add(const SizedBox(height: 8));
    }

    // 3. Выходы из региона — по одной кнопке на граничную локацию
    final borderLocations = _getBorderLocations(current);
    for (final border in borderLocations) {
      widgets.add(_buildBorderButton(border));
      widgets.add(const SizedBox(height: 8));
    }

    // 4. Сюжетное событие — если триггер готов
    if (_hasStoryTrigger(current)) {
      widgets.add(_buildStoryButton());
      widgets.add(const SizedBox(height: 8));
    }

    // 5. Станция — если это финальная локация
    if (current.isFinal) {
      widgets.add(_buildStationButton());
    }

    return widgets;
  }

  // ═══════════════════════════════════════════════════════════
  // УСЛОВИЯ ПОКАЗА
  // ═══════════════════════════════════════════════════════════

  /// Есть ли в локации что искать?
  bool _canSearch(Location loc) {
    return loc.maxSearches > 0 ||
        loc.lootPool.isNotEmpty ||
        loc.enemies.isNotEmpty ||
        loc.risk != null;
  }

  /// Есть ли сюжетный триггер, который ещё не сработал?
  bool _hasStoryTrigger(Location loc) {
    if (loc.storyNode == null) return false;

    return loc.canTriggerStory(
      currentChapter: screen.controller.chapter,
      currentCharacter: screen.characterId,
      triggeredNodes: screen.controller.flags,
    );
  }

  /// Найти локации соседних регионов, доступные для перехода.
  List<Location> _getBorderLocations(Location current) {
    final result = <Location>[];

    for (final connId in current.connectionIds) {
      final target = screen.controller.map?.getById(connId);
      if (target == null) continue;
      if (target.region == current.region) continue;
      if (!target.isAvailableAt(screen.controller.chapter)) continue;
      if (target.hidden &&
          !screen.controller.isLocationUnlocked(target.id)) {
        continue;
      }
      result.add(target);
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // КНОПКА: ОБЫСК
  // ═══════════════════════════════════════════════════════════

  Widget _buildSearchButton(Location loc) {
    final searched = screen.controller.searchedCounts[loc.id] ?? 0;
    final remaining = loc.maxSearches - searched;

    String label;
    Color color;

    if (loc.maxSearches == 0) {
      label = '🔍  ОСМОТРЕТЬСЯ (${loc.searchTime} мин)';
      color = const Color.fromARGB(255, 100, 150, 200);
    } else if (remaining > 0) {
      label =
          '🔍  ОБЫСКАТЬ · $remaining из ${loc.maxSearches} (${loc.searchTime} мин)';
      color = const Color.fromARGB(255, 100, 150, 200);
    } else {
      label = '🔍  ОСМОТРЕТЬСЯ (${loc.searchTime} мин)';
      color = const Color.fromARGB(255, 150, 100, 100);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          AudioService.playClick();
          screen.panelCoordinator.search();
        },
        icon: const Icon(Icons.search, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // КНОПКА: РАЗВЕДКА
  // ═══════════════════════════════════════════════════════════

  Widget _buildScoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          AudioService.playClick();
          screen.movementHandler.scout();
        },
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text(
          '🔭  РАЗВЕДАТЬ РАЙОН (30 мин)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 100, 130, 180),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // КНОПКА: ВЫХОД ИЗ РЕГИОНА
  // ═══════════════════════════════════════════════════════════

  Widget _buildBorderButton(Location border) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          AudioService.playClick();
          screen.onNodeTap(border);
        },
        icon: const Icon(Icons.exit_to_app, size: 18),
        label: Text(
          '🚪  ВЫЙТИ: ${border.displayScoutedName}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 150, 80, 40),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // КНОПКА: СЮЖЕТНОЕ СОБЫТИЕ
  // ═══════════════════════════════════════════════════════════

  Widget _buildStoryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          AudioService.playClick();
          screen.panelCoordinator.checkStoryTrigger();
        },
        icon: const Icon(Icons.menu_book, size: 18),
        label: const Text(
          '📖  СЮЖЕТНОЕ СОБЫТИЕ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 200, 120, 100),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // КНОПКА: СТАНЦИЯ
  // ═══════════════════════════════════════════════════════════

  Widget _buildStationButton() {
    return SizedBox(
      width: double.infinity,
      child: ShimmerButton(
        text: '🏭  ВОЙТИ НА СТАНЦИЮ',
        icon: Icons.flag,
        onPressed: () async {
          await AchievementManager.unlock('reached_station');
          if (!screen.mounted) return;
          AudioService.playSuccess();
          ScaffoldMessenger.of(screen.context).showSnackBar(
            const SnackBar(
              content: Text('🏭 Ты добрался до станции. Конец пути.'),
              duration: Duration(seconds: 4),
              backgroundColor: Color.fromARGB(255, 200, 180, 100),
            ),
          );
        },
      ),
    );
  }
}