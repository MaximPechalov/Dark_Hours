#!/bin/bash
# optimize_icons.sh — ресайз + сжатие PNG-иконок предметов.
# Запуск: bash optimize_icons.sh
#
# Что делает:
#   1. Идёт по трём папкам: weapons/, tools/, resources/
#   2. Для каждой PNG:
#      - Ресайз до 192x256 (сохраняет пропорции 3:4)
#      - Сжатие через pngquant (256 цветов, без потери видимого качества)
#   3. Сохраняет результат в _optimized/ рядом с оригиналом
#   4. Показывает вес до/после

set -e

TARGET_W=192
TARGET_H=256
QUALITY="70-90"

echo "🎨 Оптимизация иконок..."
echo ""

# ═══════════════════════════════════════════════════════════
# ФУНКЦИЯ ОБРАБОТКИ ОДНОЙ ПАПКИ
# ═══════════════════════════════════════════════════════════

optimize_folder() {
  local folder="$1"
  local name=$(basename "$folder")
  local out_folder="${folder%/}_optimized"

  echo "📁 $name/"
  echo "───────────────────────────────"

  if [ ! -d "$folder" ]; then
    echo "  ⚠️  Папка не найдена: $folder"
    return
  fi

  mkdir -p "$out_folder"

  local total_in=0
  local total_out=0
  local count=0

  for input in "$folder"/*.png; do
    if [ ! -f "$input" ]; then
      continue
    fi

    local filename=$(basename "$input")
    local output="$out_folder/$filename"

    # Ресайз + сжатие в один проход.
    # convert делает ресайз, pngquant сжимает через pipe.
    convert "$input" \
      -resize "${TARGET_W}x${TARGET_H}>" \
      -strip \
      png:- | pngquant --quality="$QUALITY" --speed 1 --strip - > "$output"

    # Размеры
    local size_in=$(stat -c%s "$input")
    local size_out=$(stat -c%s "$output")

    total_in=$((total_in + size_in))
    total_out=$((total_out + size_out))
    count=$((count + 1))

    local in_h=$(numfmt --to=iec --suffix=B "$size_in" 2>/dev/null || echo "${size_in}B")
    local out_h=$(numfmt --to=iec --suffix=B "$size_out" 2>/dev/null || echo "${size_out}B")

    printf "  %-30s %8s → %8s\n" "$filename" "$in_h" "$out_h"
  done

  local in_total_h=$(numfmt --to=iec --suffix=B "$total_in" 2>/dev/null || echo "${total_in}B")
  local out_total_h=$(numfmt --to=iec --suffix=B "$total_out" 2>/dev/null || echo "${total_out}B")

  echo ""
  echo "  ✅ $name: $in_total_h → $out_total_h  ($count файлов)"
  echo ""
}

# ═══════════════════════════════════════════════════════════
# ЗАПУСК
# ═══════════════════════════════════════════════════════════

optimize_folder "assets/images/items/weapons"
optimize_folder "assets/images/items/tools"
optimize_folder "assets/images/items/resources"

# ═══════════════════════════════════════════════════════════
# ИТОГ
# ═══════════════════════════════════════════════════════════

echo "═══════════════════════════════════════"
echo "✅ Готово!"
echo ""
echo "Итоговые размеры:"
du -sh assets/images/items/weapons_optimized/ 2>/dev/null
du -sh assets/images/items/tools_optimized/ 2>/dev/null
du -sh assets/images/items/resources_optimized/ 2>/dev/null
echo ""
echo "Проверь глазами 2-3 иконки:"
echo "  ls -lh assets/images/items/weapons_optimized/"