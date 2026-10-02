#!/bin/bash
# dump.sh v4 — просто и надёжно

OUT="project_dump.md"

# ---------- Исключения (папки) ----------
EXCLUDE_DIRS=(
  ".git" ".idea" ".vscode" ".gradle" "node_modules" ".next"
  "build" "dist" "out" ".dart_tool" ".expo"
  "android/build" "android/app/build" "android/.gradle" "android/.cxx"
  "ios/Pods" "ios/build" "ios/.symlinks"
)

# ---------- Расширения, которые НЕ читаем ----------
BINARY_EXT="mp3 wav ogg flac aac m4a opus mp4 avi mov mkv webm \
png jpg jpeg gif webp bmp ico tiff svg zip rar 7z tar gz bz2 xz \
pdf doc docx xls xlsx ppt pptx exe dll so dylib bin apk aab apks \
dex jar class ttf otf woff woff2 eot lock keystore jks pem p12"

# ---------- Функция: бинарник? ----------
is_binary() {
  local ext="${1##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  for b in $BINARY_EXT; do
    [[ "$ext" == "$b" ]] && return 0
  done
  return 1
}

# ---------- Функция: язык ----------
lang_for() {
  case "${1##*.}" in
    json) echo "json" ;;
    dart) echo "dart" ;;
    js)   echo "javascript" ;;
    ts)   echo "typescript" ;;
    md)   echo "markdown" ;;
    yaml|yml) echo "yaml" ;;
    sh|bash) echo "bash" ;;
    py)   echo "python" ;;
    html) echo "html" ;;
    css)  echo "css" ;;
    xml)  echo "xml" ;;
    gradle) echo "groovy" ;;
    kt)   echo "kotlin" ;;
    java) echo "java" ;;
    txt)  echo "text" ;;
    *)    echo "" ;;
  esac
}

# ---------- Собираем список файлов ----------
FIND_ARGS=(. -type f)
for d in "${EXCLUDE_DIRS[@]}"; do
  FIND_ARGS+=(-not -path "./$d/*")
  FIND_ARGS+=(-not -path "*/$d/*")
done
FIND_ARGS+=(-not -name "project_dump.md")

# ============ СТАРТ ============
echo "🔍 Ищу файлы..."
mapfile -t ALL_FILES < <(find "${FIND_ARGS[@]}" 2>/dev/null | sort)
echo "   Найдено: ${#ALL_FILES[@]} файлов"

if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
  echo "❌ НИЧЕГО НЕ НАЙДЕНО. Проверь, что ты в корне проекта."
  echo "   Текущая папка: $(pwd)"
  echo "   Содержимое:"
  ls -la
  exit 1
fi

{
  echo "# PROJECT DUMP"
  echo ""
  echo "**Generated:** $(date)"
  echo "**Root:** $(pwd)"
  echo "**Files:** ${#ALL_FILES[@]}"
  echo ""

  # ---------- СТРУКТУРА ----------
  echo "## 📁 STRUCTURE"
  echo ""
  echo '```text'
  printf '%s\n' "${ALL_FILES[@]}"
  echo '```'
  echo ""

  # ---------- ТЕКСТ ----------
  echo "## 📄 TEXT FILES"
  echo ""

  TEXT_COUNT=0
  BINARY_COUNT=0
  ARTIFACT_COUNT=0

  for f in "${ALL_FILES[@]}"; do
    ext="${f##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # APK и сборки
    case "$ext" in
      apk|aab|apks|dex|jar|class)
        ARTIFACT_COUNT=$((ARTIFACT_COUNT+1))
        continue
        ;;
    esac

    # бинарники
    if is_binary "$f"; then
      BINARY_COUNT=$((BINARY_COUNT+1))
      continue
    fi

    # слишком большой
    size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
    if (( size > 2097152 )); then
      echo "### 📄 \`$f\` _(пропущен, >2МБ)_"
      echo ""
      continue
    fi

    TEXT_COUNT=$((TEXT_COUNT+1))
    lang=$(lang_for "$f")
    echo "### 📄 \`$f\`"
    echo '```'"$lang"
    cat "$f"
    echo ""
    echo '```'
    echo ""
  done

  # ---------- АРТЕФАКТЫ ----------
  echo "## 📦 BUILD ARTIFACTS"
  echo '```text'
  for f in "${ALL_FILES[@]}"; do
    ext="${f##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    case "$ext" in
      apk|aab|apks|dex|jar|class)
        printf "%-70s %s\n" "$f" "$(du -h "$f" 2>/dev/null | cut -f1)"
        ;;
    esac
  done
  echo '```'
  echo ""

  # ---------- БИНАРНИКИ ----------
  echo "## 🎵 BINARY FILES"
  echo '```text'
  for f in "${ALL_FILES[@]}"; do
    ext="${f##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    case "$ext" in
      apk|aab|apks|dex|jar|class) continue ;;
    esac
    if is_binary "$f"; then
      printf "%-70s %s\n" "$f" "$(du -h "$f" 2>/dev/null | cut -f1)"
    fi
  done
  echo '```'
  echo ""

  # ---------- ИТОГИ ----------
  echo "## 📊 SUMMARY"
  echo ""
  echo "- Всего файлов: **${#ALL_FILES[@]}**"
  echo "- Текстовых (в дампе): **$TEXT_COUNT**"
  echo "- Артефактов: **$ARTIFACT_COUNT**"
  echo "- Бинарников: **$BINARY_COUNT**"
  echo "- Дамп: **$(du -h "$OUT" 2>/dev/null | cut -f1)**"
  echo ""

} > "$OUT"

echo "✅ Готово: $OUT ($(du -h "$OUT" | cut -f1))"
echo ""
echo "Проверка:"
echo "  grep -c '### 📄' $OUT    # сколько файлов с содержимым"
echo "  head -n 40 $OUT"
echo "  tail -n 20 $OUT"