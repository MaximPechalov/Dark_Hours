#!/bin/bash

echo "🔧 Исправляем импорты..."

# В файлах пакета `lib/` меняем пути

# Модели
find lib -type f -name "*.dart" -exec sed -i \
  -e "s|'../models/character.dart'|'../models/character/character.dart'|g" \
  -e "s|'../models/inventory.dart'|'../models/inventory/inventory.dart'|g" \
  -e "s|'../models/inventory_item.dart'|'../models/inventory/inventory_item.dart'|g" \
  -e "s|'../models/equipment.dart'|'../models/inventory/equipment.dart'|g" \
  -e "s|'../models/weapon.dart'|'../models/items/weapon.dart'|g" \
  -e "s|'../models/tool.dart'|'../models/items/tool.dart'|g" \
  -e "s|'../models/consumable.dart'|'../models/items/consumable.dart'|g" \
  -e "s|'../models/armor.dart'|'../models/items/armor.dart'|g" \
  -e "s|'../models/resource.dart'|'../models/items/resource.dart'|g" \
  -e "s|'../models/recipe.dart'|'../models/items/recipe.dart'|g" \
  -e "s|'../models/combat.dart'|'../models/combat/combat.dart'|g" \
  -e "s|'../models/condition.dart'|'../models/conditions/condition.dart'|g" \
  -e "s|'../models/active_condition.dart'|'../models/conditions/active_condition.dart'|g" \
  -e "s|'../models/location.dart'|'../models/world/location.dart'|g" \
  -e "s|'../models/world_map.dart'|'../models/world/world_map.dart'|g" \
  -e "s|'../models/story_node.dart'|'../models/story/story_node.dart'|g" \
  -e "s|'../models/game_time.dart'|'../models/time/game_time.dart'|g" \
  -e "s|'../models/rest_action.dart'|'../models/time/rest_action.dart'|g" \
  -e "s|'../models/achievement.dart'|'../models/progress/achievement.dart'|g" \
  -e "s|'../models/player_stats.dart'|'../models/progress/player_stats.dart'|g" \
  -e "s|'../models/save_data.dart'|'../models/save/save_data.dart'|g" \
  {} \;

# Сервисы
find lib -type f -name "*.dart" -exec sed -i \
  -e "s|'../services/save_manager.dart'|'../services/save/save_manager.dart'|g" \
  -e "s|'../services/item_loader.dart'|'../services/items/item_loader.dart'|g" \
  -e "s|'../services/condition_manager.dart'|'../services/conditions/condition_manager.dart'|g" \
  -e "s|'../services/time_manager.dart'|'../services/time/time_manager.dart'|g" \
  -e "s|'../services/run_tracker.dart'|'../services/progress/run_tracker.dart'|g" \
  -e "s|'../services/achievement_manager.dart'|'../services/progress/achievement_manager.dart'|g" \
  -e "s|'../services/achievement_checker.dart'|'../services/progress/achievement_checker.dart'|g" \
  {} \;

# Скрины
find lib -type f -name "*.dart" -exec sed -i \
  -e "s|'start_screen.dart'|'../main/start_screen.dart'|g" \
  -e "s|'character_select_screen.dart'|'../main/character_select_screen.dart'|g" \
  -e "s|'death_screen.dart'|'../main/death_screen.dart'|g" \
  -e "s|'story_screen.dart'|'../gameplay/story_screen.dart'|g" \
  -e "s|'map_screen.dart'|'../gameplay/map_screen.dart'|g" \
  -e "s|'combat_screen.dart'|'../gameplay/combat_screen.dart'|g" \
  -e "s|'equipment_test_screen.dart'|'../extra/equipment_test_screen.dart'|g" \
  -e "s|'achievements_screen.dart'|'../extra/achievements_screen.dart'|g" \
  {} \;

# Виджеты
find lib -type f -name "*.dart" -exec sed -i \
  -e "s|'../widgets/inventory_panel.dart'|'../widgets/panels/inventory_panel.dart'|g" \
  -e "s|'../widgets/equipment_panel.dart'|'../widgets/panels/equipment_panel.dart'|g" \
  -e "s|'../widgets/conditions_panel.dart'|'../widgets/panels/conditions_panel.dart'|g" \
  -e "s|'../widgets/rest_panel.dart'|'../widgets/panels/rest_panel.dart'|g" \
  -e "s|'../widgets/craft_panel.dart'|'../widgets/panels/craft_panel.dart'|g" \
  -e "s|'../widgets/penalties_panel.dart'|'../widgets/panels/penalties_panel.dart'|g" \
  -e "s|'../widgets/character_card.dart'|'../widgets/cards/character_card.dart'|g" \
  -e "s|'../widgets/animated_location_card.dart'|'../widgets/cards/animated_location_card.dart'|g" \
  -e "s|'../widgets/time_indicator.dart'|'../widgets/indicators/time_indicator.dart'|g" \
  -e "s|'../widgets/animated_stat_bar.dart'|'../widgets/indicators/animated_stat_bar.dart'|g" \
  -e "s|'../widgets/fade_in_text.dart'|'../widgets/effects/fade_in_text.dart'|g" \
  -e "s|'../widgets/floating_effect.dart'|'../widgets/effects/floating_effect.dart'|g" \
  -e "s|'../widgets/shimmer_button.dart'|'../widgets/effects/shimmer_button.dart'|g" \
  -e "s|'../widgets/shake_widget.dart'|'../widgets/effects/shake_widget.dart'|g" \
  -e "s|'../widgets/achievement_popup.dart'|'../widgets/effects/achievement_popup.dart'|g" \
  -e "s|'../widgets/achievement_notifier.dart'|'../widgets/effects/achievement_notifier.dart'|g" \
  {} \;

# Пути к экранам из main.dart
sed -i "s|'screens/start_screen.dart'|'screens/main/start_screen.dart'|g" lib/main.dart

echo "✅ Импорты исправлены!"
