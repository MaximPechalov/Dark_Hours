#!/bin/bash
# mark_future_chapters.sh — помечает регионы как доступные со 2+ главы
# Запуск из корня: ./mark_future_chapters.sh

set -e

echo "🔧 Помечаем будущие регионы..."
echo ""

# ═══════════════════════════════════════════════════════════
# forest, highway, underground → глава 2
# ═══════════════════════════════════════════════════════════

for file in \
  "assets/data/locations/forest.json" \
  "assets/data/locations/highway.json" \
  "assets/data/locations/underground.json"
do
  if [ ! -f "$file" ]; then
    echo "   ⚠️  $file — не найден"
    continue
  fi

  python3 << PYEOF
import json

path = "$file"
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

for loc in data.get('locations', []):
    loc['is_available_from_chapter'] = 2

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"   ✅ $file")
PYEOF
done

echo ""

# ═══════════════════════════════════════════════════════════
# north → глава 4
# ═══════════════════════════════════════════════════════════

for file in "assets/data/locations/north.json"
do
  if [ ! -f "$file" ]; then
    echo "   ⚠️  $file — не найден"
    continue
  fi

  python3 << PYEOF
import json

path = "$file"
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

for loc in data.get('locations', []):
    loc['is_available_from_chapter'] = 4

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"   ✅ $file")
PYEOF
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Патч завершён!"
echo ""
echo "Проверь:"
echo "  dart run tool/validate.dart 2>&1 | tail -10"