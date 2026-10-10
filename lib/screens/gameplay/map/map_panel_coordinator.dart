// lib/screens/gameplay/map/map_panel_coordinator.dart
//
// (исправленная версия — без Proxy-обёрток)

import 'package:flutter/material.dart';

import 'package:dark_hours/services/map/death_manager.dart';
import 'package:dark_hours/services/map/story_trigger_manager.dart';
import 'package:dark_hours/services/map/rest_manager.dart';
import 'package:dark_hours/services/map/search_manager.dart';
import 'package:dark_hours/services/audio/audio_service.dart';

import 'package:dark_hours/models/inventory/inventory_item.dart';
import 'package:dark_hours/models/items/recipe.dart';
import 'package:dark_hours/models/time/rest_action.dart';

import 'package:dark_hours/widgets/panels/craft_panel.dart';
import 'package:dark_hours/widgets/panels/inventory_panel.dart';
import 'package:dark_hours/widgets/panels/equipment_panel.dart';
import 'package:dark_hours/widgets/panels/rest_panel.dart';
import 'package:dark_hours/widgets/effects/floating_effect.dart';

import 'package:dark_hours/screens/gameplay/map/map_screen.dart';

/// Управляет всеми bottom-sheet'ами и действиями через них.
class MapPanelCoordinator {
  final MapScreenState screen;

  MapPanelCoordinator(this.screen);

  // ═══════════════════════════════════════════════════════════
  // ИНВЕНТАРЬ
  // ═══════════════════════════════════════════════════════════

  void showInventory() {
    AudioService.playTap();
    showModalBottomSheet(
      context: screen.context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return InventoryPanel(
            inventory: screen.controller.inventory,
            onUse: (item) {
              useItem(item);
              setSheetState(() {});
              screen.rebuild();
            },
            onEquip: (item) {
              equipItem(item);
              setSheetState(() {});
              screen.rebuild();
            },
            onDrop: (item) {
              dropItem(item);
              setSheetState(() {});
              screen.rebuild();
            },
          );
        },
      ),
    );
  }

  void useItem(InventoryItem item) {
    AudioService.playSuccess();

    screen.controller.applyStatDelta({
      'hunger': item.hungerRestore,
      'thirst': item.thirstRestore,
      'health': item.healthRestore,
      'sanity': item.sanityRestore,
    });

    if (item.id.contains('pill') ||
        item.id.contains('bandage') ||
        item.id == 'first_aid_kit' ||
        item.id == 'herb_medkit' ||
        item.id == 'splint') {
      screen.controller.trackMedicineUsed();
    }

    if (item.hungerRestore > 0) {
      FloatingEffectOverlay.show(
        screen.context,
        '+${item.hungerRestore} 🍞',
        color: Colors.orange,
        icon: Icons.restaurant,
      );
    }
    if (item.thirstRestore > 0) {
      FloatingEffectOverlay.show(
        screen.context,
        '+${item.thirstRestore} 💧',
        color: Colors.blue,
        icon: Icons.water_drop,
      );
    }
    if (item.healthRestore > 0) {
      FloatingEffectOverlay.show(
        screen.context,
        '+${item.healthRestore} ❤️',
        color: Colors.red,
        icon: Icons.favorite,
      );
    }

    final curable = <dynamic>[];
    for (final ac in screen.controller.activeConditions) {
      if (ac.condition.cureItems.contains(item.id)) curable.add(ac);
    }
    for (final ac in curable) {
      screen.controller.activeConditions.remove(ac);
      ScaffoldMessenger.of(screen.context).showSnackBar(
        SnackBar(
          content: Text('Вылечено: ${ac.condition.name}'),
          backgroundColor: Colors.green[700],
        ),
      );
    }

    screen.controller.removeItem(item.id);
    screen.controller.save();
    screen.rebuild();
  }

  void equipItem(InventoryItem item) {
    AudioService.playClick();

    String? slot;
    if (item.sourceType == 'weapon') {
      slot = 'weapon';
    } else if (item.sourceType == 'armor') {
      slot = item.armorSlot;
    }

    if (slot == null) return;

    screen.controller.equipItem(item, slot);
    screen.controller.save();
    screen.rebuild();
  }

  void dropItem(InventoryItem item) {
    AudioService.playClick();
    screen.controller.removeAll(item.id);
    screen.controller.save();
    screen.rebuild();
  }

  // ═══════════════════════════════════════════════════════════
  // ЭКИПИРОВКА
  // ═══════════════════════════════════════════════════════════

  void showEquipment() {
    AudioService.playTap();
    showModalBottomSheet(
      context: screen.context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return EquipmentPanel(
            equipment: screen.controller.equipment,
            onUnequip: (slot) {
              AudioService.playClick();
              screen.controller.unequipItem(slot);
              setSheetState(() {});
              screen.rebuild();
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // КРАФТ
  // ═══════════════════════════════════════════════════════════

  void showCraftPanel() {
    AudioService.playTap();
    showModalBottomSheet(
      context: screen.context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return CraftPanel(
            inventory: screen.controller.inventory,
            intelligence: screen.controller.intelligence,
            strength: screen.controller.strength,
            stamina: screen.controller.stamina,
            recipes: screen.controller.allRecipes,
            onCraft: (recipe) async {
              await craftItem(recipe);
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  Future<void> craftItem(Recipe recipe) async {
    if (screen.controller.stamina < 5) {
      AudioService.playError();
      if (!screen.mounted) return;
      ScaffoldMessenger.of(screen.context).showSnackBar(
        const SnackBar(
          content: Text('❌ Слишком устал для крафта'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (final ing in recipe.ingredients) {
      for (int i = 0; i < ing.count; i++) {
        screen.controller.removeItem(ing.id);
      }
    }

    final resultItem = screen.controller.findItemInCatalog(recipe.resultId);
    if (resultItem != null) {
      screen.controller.addItem(resultItem);
    }

    screen.controller.trackCraft(
      isMolotov: recipe.id == 'molotov_craft',
    );
    screen.controller.applyStatDelta({'stamina': -5, 'fatigue': 5});

    await screen.controller.advanceTime(recipe.timeMinutes);
    await screen.controller.save();

    if (!screen.mounted) return;

    AudioService.playSuccess();
    FloatingEffectOverlay.show(
      screen.context,
      'Создано: ${recipe.resultName}',
      color: const Color.fromARGB(255, 100, 180, 100),
      icon: Icons.build,
    );
    ScaffoldMessenger.of(screen.context).showSnackBar(
      SnackBar(
        content: Text('${recipe.resultIcon} Создано: ${recipe.resultName}'),
        backgroundColor: const Color.fromARGB(255, 100, 180, 100),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ОТДЫХ
  // ═══════════════════════════════════════════════════════════

  void showRestPanel() {
    AudioService.playTap();

    final loc = screen.controller.currentLocation;
    if (loc == null) return;

    final isSafe = loc.dangerLevel <= 3;

    showModalBottomSheet(
      context: screen.context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return RestPanel(
          isSafeLocation: isSafe,
          onRest: (action) async {
            Navigator.pop(bottomSheetContext);
            await executeRest(action);
          },
        );
      },
    );
  }

  Future<void> executeRest(RestAction action) async {
    await RestManager.rest(screen.context, screen.controller, action);

    if (!screen.mounted) return;

    if (DeathManager.checkDeath(screen.controller)) {
      await screen.movementHandler.handleDeath();
      return;
    }

    await DeathManager.checkFatigue(screen.context, screen.controller);
    screen.rebuild();
  }

  // ═══════════════════════════════════════════════════════════
  // ОБЫСК
  // ═══════════════════════════════════════════════════════════

  Future<void> search() async {
    await SearchManager.search(screen.context, screen.controller);

    if (!screen.mounted) return;

    if (DeathManager.checkDeath(screen.controller)) {
      await screen.movementHandler.handleDeath();
      return;
    }

    await DeathManager.checkFatigue(screen.context, screen.controller);
    screen.rebuild();
  }

  // ═══════════════════════════════════════════════════════════
  // СЮЖЕТНЫЙ ТРИГГЕР
  // ═══════════════════════════════════════════════════════════

  Future<void> checkStoryTrigger() async {
    await StoryTriggerManager.checkTrigger(
      screen.context,
      screen.controller,
    );
    screen.rebuild();
  }
}