#!/bin/bash
# convert_audio.sh — конвертация аудио для Тёмных часов.
# Запуск: bash convert_audio.sh

set -e

echo "🎵 Конвертация аудио..."
echo ""

# ═══════════════════════════════════════════════════════════
# AMBIENCE (фон локаций) — 96 kbps Opus
# ═══════════════════════════════════════════════════════════

echo "📁 Ambience → ambience_new/"
echo "───────────────────────────────"

declare -A AMBIENCE_FILES=(
  ["forest"]="wav"
  ["hospital"]="mp3"
  ["street_center"]="wav"
  ["street_south"]="wav"
  ["supermarket"]="wav"
  ["tunnel"]="wav"
)

for name in "${!AMBIENCE_FILES[@]}"; do
  ext="${AMBIENCE_FILES[$name]}"
  input="assets/audio/ambience/${name}.${ext}"
  output="assets/audio/ambience_new/${name}.ogg"

  if [ ! -f "$input" ]; then
    echo "  ⚠️  Пропуск: $input не найден"
    continue
  fi

  echo "  🔄 $name.${ext} → $name.ogg"

  ffmpeg -y -i "$input" \
    -c:a libopus -b:a 96k -vbr on -application audio \
    "$output" 2>/dev/null

  size_in=$(du -h "$input" | cut -f1)
  size_out=$(du -h "$output" | cut -f1)
  echo "     $size_in → $size_out"
done

echo ""

# ═══════════════════════════════════════════════════════════
# MUSIC (музыка) — 128 kbps Opus
# ═══════════════════════════════════════════════════════════

echo "📁 Music → music_new/"
echo "───────────────────────────────"

declare -A MUSIC_FILES=(
  ["combat_theme"]="ogg"
  ["ending_theme"]="ogg"
  ["map_theme"]="ogg"
  ["menu_theme"]="mp3"
  ["story_theme"]="ogg"
)

for name in "${!MUSIC_FILES[@]}"; do
  ext="${MUSIC_FILES[$name]}"
  input="assets/audio/music/${name}.${ext}"
  output="assets/audio/music_new/${name}.ogg"

  if [ ! -f "$input" ]; then
    echo "  ⚠️  Пропуск: $input не найден"
    continue
  fi

  echo "  🔄 $name.${ext} → $name.ogg"

  ffmpeg -y -i "$input" \
    -c:a libopus -b:a 128k -vbr on -application audio \
    "$output" 2>/dev/null

  size_in=$(du -h "$input" | cut -f1)
  size_out=$(du -h "$output" | cut -f1)
  echo "     $size_in → $size_out"
done

echo ""

# ═══════════════════════════════════════════════════════════
# ИТОГ
# ═══════════════════════════════════════════════════════════

echo "═══════════════════════════════════════"
echo "✅ Готово!"
echo ""
echo "Итоговые размеры:"
du -sh assets/audio/ambience_new/
du -sh assets/audio/music_new/
echo ""
echo "Проверь звучание в игре, потом — заменяй:"
echo "  rm -rf assets/audio/ambience/"
echo "  rm -rf assets/audio/music/"
echo "  mv assets/audio/ambience_new assets/audio/ambience"
echo "  mv assets/audio/music_new assets/audio/music"