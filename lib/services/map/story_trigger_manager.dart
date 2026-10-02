import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/map_controller.dart';
import 'package:dark_hours/services/save/save_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';
import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/models/story/story_node.dart';
import 'package:dark_hours/screens/gameplay/story_screen.dart';

/// Управляет сюжетными триггерами на карте.
///
/// Что делает:
/// 1. Проверяет, есть ли в текущей локации сюжетный триггер.
/// 2. Проверяет условия: глава, персонаж, "один раз".
/// 3. Если да — показывает диалог «Сюжетное событие».
/// 4. Если игрок согласен — открывает StoryScreen.
/// 5. После возвращения — перечитывает сохранение.
class StoryTriggerManager {
  /// Проверить триггер в текущей локации.
  ///
  /// Если триггер сработал — открывает StoryScreen и ждёт возвращения.
  static Future<void> checkTrigger(
    BuildContext context,
    MapController controller,
  ) async {
    final loc = controller.currentLocation;
    if (loc == null) return;

    // ─── 1. Есть ли в локации сюжетный триггер ───
    if (loc.storyNode == null) return;

    // ─── 2. Проверка условий (глава, персонаж, "один раз") ───
    if (!loc.canTriggerStory(
      currentChapter: controller.chapter,
      currentCharacter: controller.characterId,
      triggeredNodes: controller.flags,
    )) {
      return;
    }

    // ─── 3. Загружаем сюжет и проверяем ноду ───
    final story = await Story.load(
      controller.characterId,
      chapter: controller.chapter,
    );
    if (story == null) return;

    final node = story.getNode(loc.storyNode!);
    if (node == null) {
      debugPrint(
        '⚠️ StoryTriggerManager: нода "${loc.storyNode}" не найдена '
        'в сюжете ${controller.characterId}/chapter_${controller.chapter}',
      );
      return;
    }

    // ─── 4. Отмечаем триггер как сработавший ───
    controller.setFlag(loc.storyNode!);

    // ─── 5. Автосохранение ───
    await controller.save();

    if (!context.mounted) return;

    // ─── 6. Диалог «Сюжетное событие» ───
    final proceed = await _showStoryDialog(context, loc.name);
    if (proceed != true || !context.mounted) return;

    // ─── 7. Создаём SaveData для StoryScreen ───
    final saveForStory = _buildSaveForStory(controller, loc.storyNode!);

    await SaveManager.save(saveForStory);

    if (!context.mounted) return;

    // ─── 8. Открываем StoryScreen ───
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryScreen(
          characterId: controller.characterId,
          characterName: controller.characterName,
          resumeFrom: saveForStory,
        ),
      ),
    );

    // ─── 9. После возвращения — перечитываем сохранение ───
    await controller.reloadFromSave();
  }

  // ═══════════════════════════════════════════════════════════
  // ВНУТРЕННИЕ МЕТОДЫ
  // ═══════════════════════════════════════════════════════════

  /// Показать диалог перед открытием StoryScreen.
  ///
  /// Возвращает `true`, если игрок нажал «ПРОДОЛЖИТЬ».
  static Future<bool?> _showStoryDialog(
    BuildContext context,
    String locationName,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
        title: const Text(
          '📖 СЮЖЕТНОЕ СОБЫТИЕ',
          style: TextStyle(
            color: Color.fromARGB(255, 200, 180, 100),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        content: Text(
          '$locationName — здесь тебя ждёт важная встреча.',
          style: TextStyle(color: Colors.grey[300], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService.playClick();
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'ПРОДОЛЖИТЬ',
              style: TextStyle(
                color: Color.fromARGB(255, 200, 180, 100),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Собрать SaveData для открытия StoryScreen.
  ///
  /// StoryScreen не знает о MapController — он работает с SaveData.
  /// Поэтому мы собираем snapshot текущего состояния.
  static SaveData _buildSaveForStory(
    MapController controller,
    String nodeId,
  ) {
    return SaveData(
      characterId: controller.characterId,
      characterName: controller.characterName,
      currentNodeId: nodeId,
      currentLocationId: controller.map?.currentLocationId ?? 'home_boris',
      onMap: false,
      hunger: controller.hunger,
      thirst: controller.thirst,
      health: controller.health,
      sanity: controller.sanity,
      stamina: controller.stamina,
      fatigue: controller.fatigue,
      timeMinutes: controller.gameTime.totalMinutes,
      chapter: controller.chapter,
      history: controller.flags.toList(),
      inventoryItems: controller.inventory.toJson(),
      equipmentItems: controller.equipment.toJson(),
      activeConditions: controller.activeConditions
          .map((ac) => {
                'id': ac.condition.id,
                'daysRemaining': ac.daysRemaining,
              })
          .toList(),
      searchedCounts: controller.searchedCounts,
      unlockedLocations: controller.unlockedLocations.toList(),
      savedAt: DateTime.now(),
    );
  }
}