#!/bin/bash
# patch_analyze.sh — чистка warnings после рефакторинга
# Запуск из корня проекта: ./patch_analyze.sh

set -e

echo "🔧 Патч analyze warnings..."
echo ""

# ═══════════════════════════════════════════════════════════
# 1. notifyListeners() → refresh() в менеджерах
# ═══════════════════════════════════════════════════════════

echo "1️⃣  Замена notifyListeners() → refresh() в менеджерах..."

FILES=(
  "lib/services/map/death_manager.dart"
  "lib/services/map/movement_manager.dart"
  "lib/services/map/search_manager.dart"
  "lib/services/map/combat_manager.dart"
  "lib/services/map/rest_manager.dart"
)

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    # Заменяем только вызовы controller.notifyListeners()
    sed -i 's/controller\.notifyListeners()/controller.refresh()/g' "$f"
    echo "   ✅ $f"
  else
    echo "   ⚠️  $f — не найден"
  fi
done

echo ""

# ═══════════════════════════════════════════════════════════
# 2. Unused imports в lib/
# ═══════════════════════════════════════════════════════════

echo "2️⃣  Удаление unused imports в lib/..."

# condition_manager.dart:4 — inventory.dart
sed -i "/^import 'package:dark_hours\/models\/inventory\/inventory.dart';$/d" \
  lib/services/conditions/condition_manager.dart

# search_manager.dart:12 — inventory_item.dart
sed -i "/^import 'package:dark_hours\/models\/inventory\/inventory_item.dart';$/d" \
  lib/services/map/search_manager.dart

echo "   ✅ condition_manager.dart"
echo "   ✅ search_manager.dart"
echo ""

# ═══════════════════════════════════════════════════════════
# 3. Unused variables в lib/ и tool/
# ═══════════════════════════════════════════════════════════

echo "3️⃣  Удаление unused variables..."

# map_controller.dart:342 — phaseAfter не используется
# Заменяем блок с phaseAfter на упрощённый
sed -i 's/^    final phaseAfter = gameTime\.phase;$//' \
  lib/services/map/map_controller.dart

# shake_widget.dart:23 — _rng не используется
sed -i '/final Random _rng = Random();/d' \
  lib/widgets/effects/shake_widget.dart
# Убираем import 'dart:math' если он больше нигде не нужен в этом файле
# (shake_widget использует sin, поэтому import нужен — НЕ удаляем)

# validate.dart:227 — endings не используется
sed -i '/final endings = (meta\[.endings.\] as List? ?? \[\])\.cast<Map<String, dynamic>>();/d' \
  tool/validate.dart

echo "   ✅ map_controller.dart (phaseAfter)"
echo "   ✅ shake_widget.dart (_rng)"
echo "   ✅ tool/validate.dart (endings)"
echo ""

# ═══════════════════════════════════════════════════════════
# 4. Unused imports в тестах
# ═══════════════════════════════════════════════════════════

echo "4️⃣  Удаление unused imports в тестах..."

# test/services/item_loader_test.dart:1 — flutter/services.dart
sed -i "/^import 'package:flutter\/services\.dart';$/d" \
  test/services/item_loader_test.dart

# test/widgets/smoke_test.dart:1 — flutter/material.dart
sed -i "/^import 'package:flutter\/material\.dart';$/d" \
  test/widgets/smoke_test.dart

echo "   ✅ item_loader_test.dart"
echo "   ✅ smoke_test.dart"
echo ""

# ═══════════════════════════════════════════════════════════
# 5. Unused variables в story_loader_test.dart
# ═══════════════════════════════════════════════════════════

echo "5️⃣  Чистка story_loader_test.dart..."

# Удаляем блок с неиспользуемыми переменными totalFromActs и path
# (они внутри группы 'нет дубликатов нод')
python3 << 'PYEOF'
import re

path = 'test/story/story_loader_test.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Убираем объявления неиспользуемых переменных
content = content.replace(
    "        // Считаем ноды по id в каждом акте отдельно\n"
    "        final Map<String, int> totalFromActs = {};\n"
    "        final storyDir = 'assets/data/story/$char/chapter_1';\n",
    ""
)

# Убираем цикл, где используется path
content = content.replace(
    "        for (final act in story.acts) {\n"
    "          final path = '$storyDir/${act.file}';\n"
    "          try {\n"
    "            // Читаем файл напрямую — используем loadString\n"
    "            final actStory = await Story.loadFor(char);\n"
    "            // Проверка: количество нод в story.nodes должно быть\n"
    "            // >= чем в одном акте (это уже косвенно)\n"
    "            expect(actStory, isNotNull);\n"
    "          } catch (_) {}\n"
    "        }\n\n",
    ""
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("   ✅ story_loader_test.dart")
PYEOF

echo ""

# ═══════════════════════════════════════════════════════════
# 6. Мелочи: equipment_panel, craft_panel, map_controller
# ═══════════════════════════════════════════════════════════

echo "6️⃣  Мелкие info..."

# equipment_panel.dart:206 — лишний !
sed -i 's/onUnequip!(slotKey);/onUnequip(slotKey);/g' \
  lib/widgets/panels/equipment_panel.dart

# craft_panel.dart:371 — лишние { } в интерполяции
sed -i 's/'\''${ing\.count}/'\''$ing.count/g' \
  lib/widgets/panels/craft_panel.dart

echo "   ✅ equipment_panel.dart"
echo "   ✅ craft_panel.dart"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "✅ Патч завершён!"
echo ""
echo "Проверь результат:"
echo "  flutter analyze"
echo "  flutter test"