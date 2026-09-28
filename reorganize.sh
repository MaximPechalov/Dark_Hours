#!/bin/bash

echo "📁 Создаём новую структуру папок..."

# Models
mkdir -p lib/models/character
mkdir -p lib/models/inventory
mkdir -p lib/models/items
mkdir -p lib/models/combat
mkdir -p lib/models/conditions
mkdir -p lib/models/world
mkdir -p lib/models/story
mkdir -p lib/models/time
mkdir -p lib/models/progress
mkdir -p lib/models/save

# Services
mkdir -p lib/services/save
mkdir -p lib/services/items
mkdir -p lib/services/conditions
mkdir -p lib/services/time
mkdir -p lib/services/progress

# Screens
mkdir -p lib/screens/main
mkdir -p lib/screens/gameplay
mkdir -p lib/screens/extra

# Widgets
mkdir -p lib/widgets/panels
mkdir -p lib/widgets/cards
mkdir -p lib/widgets/indicators
mkdir -p lib/widgets/effects

echo "📦 Переносим модели..."

# Character
mv lib/models/character.dart lib/models/character/ 2>/dev/null

# Inventory
mv lib/models/inventory.dart lib/models/inventory/ 2>/dev/null
mv lib/models/inventory_item.dart lib/models/inventory/ 2>/dev/null
mv lib/models/equipment.dart lib/models/inventory/ 2>/dev/null

# Items
mv lib/models/weapon.dart lib/models/items/ 2>/dev/null
mv lib/models/tool.dart lib/models/items/ 2>/dev/null
mv lib/models/consumable.dart lib/models/items/ 2>/dev/null
mv lib/models/armor.dart lib/models/items/ 2>/dev/null
mv lib/models/resource.dart lib/models/items/ 2>/dev/null
mv lib/models/recipe.dart lib/models/items/ 2>/dev/null

# Combat
mv lib/models/combat.dart lib/models/combat/ 2>/dev/null

# Conditions
mv lib/models/condition.dart lib/models/conditions/ 2>/dev/null
mv lib/models/active_condition.dart lib/models/conditions/ 2>/dev/null

# World
mv lib/models/location.dart lib/models/world/ 2>/dev/null
mv lib/models/world_map.dart lib/models/world/ 2>/dev/null

# Story
mv lib/models/story_node.dart lib/models/story/ 2>/dev/null

# Time
mv lib/models/game_time.dart lib/models/time/ 2>/dev/null
mv lib/models/rest_action.dart lib/models/time/ 2>/dev/null

# Progress
mv lib/models/achievement.dart lib/models/progress/ 2>/dev/null
mv lib/models/player_stats.dart lib/models/progress/ 2>/dev/null

# Save
mv lib/models/save_data.dart lib/models/save/ 2>/dev/null

echo "📦 Переносим сервисы..."

mv lib/services/save_manager.dart lib/services/save/ 2>/dev/null
mv lib/services/item_loader.dart lib/services/items/ 2>/dev/null
mv lib/services/condition_manager.dart lib/services/conditions/ 2>/dev/null
mv lib/services/time_manager.dart lib/services/time/ 2>/dev/null
mv lib/services/run_tracker.dart lib/services/progress/ 2>/dev/null
mv lib/services/achievement_manager.dart lib/services/progress/ 2>/dev/null
mv lib/services/achievement_checker.dart lib/services/progress/ 2>/dev/null

echo "📦 Переносим экраны..."

mv lib/screens/start_screen.dart lib/screens/main/ 2>/dev/null
mv lib/screens/character_select_screen.dart lib/screens/main/ 2>/dev/null
mv lib/screens/death_screen.dart lib/screens/main/ 2>/dev/null

mv lib/screens/story_screen.dart lib/screens/gameplay/ 2>/dev/null
mv lib/screens/map_screen.dart lib/screens/gameplay/ 2>/dev/null
mv lib/screens/combat_screen.dart lib/screens/gameplay/ 2>/dev/null

mv lib/screens/equipment_test_screen.dart lib/screens/extra/ 2>/dev/null
mv lib/screens/achievements_screen.dart lib/screens/extra/ 2>/dev/null

echo "📦 Переносим виджеты..."

mv lib/widgets/inventory_panel.dart lib/widgets/panels/ 2>/dev/null
mv lib/widgets/equipment_panel.dart lib/widgets/panels/ 2>/dev/null
mv lib/widgets/conditions_panel.dart lib/widgets/panels/ 2>/dev/null
mv lib/widgets/rest_panel.dart lib/widgets/panels/ 2>/dev/null
mv lib/widgets/craft_panel.dart lib/widgets/panels/ 2>/dev/null
mv lib/widgets/penalties_panel.dart lib/widgets/panels/ 2>/dev/null

mv lib/widgets/character_card.dart lib/widgets/cards/ 2>/dev/null
mv lib/widgets/animated_location_card.dart lib/widgets/cards/ 2>/dev/null

mv lib/widgets/time_indicator.dart lib/widgets/indicators/ 2>/dev/null
mv lib/widgets/animated_stat_bar.dart lib/widgets/indicators/ 2>/dev/null

mv lib/widgets/fade_in_text.dart lib/widgets/effects/ 2>/dev/null
mv lib/widgets/floating_effect.dart lib/widgets/effects/ 2>/dev/null
mv lib/widgets/shimmer_button.dart lib/widgets/effects/ 2>/dev/null
mv lib/widgets/shake_widget.dart lib/widgets/effects/ 2>/dev/null
mv lib/widgets/achievement_popup.dart lib/widgets/effects/ 2>/dev/null
mv lib/widgets/achievement_notifier.dart lib/widgets/effects/ 2>/dev/null

echo "✅ Файлы перемещены!"
echo ""
echo "🔧 Теперь нужно исправить импорты в файлах."
echo "Запусти: dart fix_imports.sh (см. следующий шаг)"
