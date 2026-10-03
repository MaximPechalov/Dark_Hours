#!/bin/bash
# patch_warnings.sh — убираем warnings и unnecessary imports
# Запуск из корня: ./patch_warnings.sh

set -e

echo "🔧 Чистим warnings..."

# ═══════════════════════════════════════════════════════════
# 1. search_manager.dart — удалить неиспользуемый импорт
# ═══════════════════════════════════════════════════════════

echo "1️⃣  search_manager.dart — unused import..."

sed -i "/^import 'package:dark_hours\/models\/inventory\/inventory_item.dart';$/d" \
  lib/services/map/search_manager.dart

echo "   ✅ удалили inventory_item.dart"
echo ""

# ═══════════════════════════════════════════════════════════
# 2. Менеджеры — убрать foundation.dart (он в material.dart)
# ═══════════════════════════════════════════════════════════

echo "2️⃣  Менеджеры — убираем foundation.dart (есть в material)..."

for f in \
  lib/services/map/combat_manager.dart \
  lib/services/map/death_manager.dart \
  lib/services/map/map_controller.dart \
  lib/services/map/movement_manager.dart \
  lib/services/map/rest_manager.dart \
  lib/services/map/search_manager.dart
do
  if [ -f "$f" ]; then
    sed -i "/^import 'package:flutter\/foundation.dart' show visibleForTesting;$/d" "$f"
    echo "   ✅ $f"
  fi
done
echo ""

# ═══════════════════════════════════════════════════════════
# 3. test/services/map/map_controller_test.dart — 4 импорта
# ═══════════════════════════════════════════════════════════

echo "3️⃣  map_controller_test.dart — unused imports..."

FILE="test/services/map/map_controller_test.dart"

if [ -f "$FILE" ]; then
  sed -i "/^import 'package:flutter\/foundation.dart' show visibleForTesting;$/d" "$FILE"
  sed -i "/^import 'package:dark_hours\/models\/items\/recipe.dart';$/d" "$FILE"
  sed -i "/^import 'package:dark_hours\/models\/conditions\/active_condition.dart';$/d" "$FILE"
  sed -i "/^import 'package:dark_hours\/models\/time\/game_time.dart';$/d" "$FILE"
  echo "   ✅ удалили 4 ненужных импорта"
fi
echo ""

# ═══════════════════════════════════════════════════════════
# ГОТОВО
# ═══════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "✅ Патч завершён!"
echo ""
echo "Проверь:"
echo "  flutter analyze"
echo "  flutter test"