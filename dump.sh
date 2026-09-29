#!/bin/bash
# dump.sh — собирает весь проект в один .md для анализа

OUT="project_dump.md"

echo "# PROJECT DUMP" > "$OUT"
echo "" >> "$OUT"
echo "**Generated:** $(date)" >> "$OUT"
echo "" >> "$OUT"

# 1. СТРУКТУРА
echo "## 📁 STRUCTURE" >> "$OUT"
echo '```text' >> "$OUT"
if command -v tree &> /dev/null; then
  tree -a -I '.git|build|.dart_tool|node_modules|.idea|*.lock' >> "$OUT"
else
  find . -type f \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    -not -path "./.dart_tool/*" \
    -not -path "./node_modules/*" \
    | sort >> "$OUT"
fi
echo '```' >> "$OUT"
echo "" >> "$OUT"

# 2. ФАЙЛЫ
echo "## 📄 FILES" >> "$OUT"
echo "" >> "$OUT"

find . -type f \
  -not -path "./.git/*" \
  -not -path "./build/*" \
  -not -path "./.dart_tool/*" \
  -not -path "./node_modules/*" \
  -not -path "./.idea/*" \
  -not -name "*.lock" \
  -not -name "project_dump.md" \
  | sort | while read -r f; do
    
    ext="${f##*.}"
    case "$ext" in
      json) lang="json" ;;
      dart) lang="dart" ;;
      md)   lang="markdown" ;;
      yaml|yml) lang="yaml" ;;
      sh)   lang="bash" ;;
      txt)  lang="text" ;;
      *)    lang="" ;;
    esac

    echo "### 📄 \`$f\`" >> "$OUT"
    echo '```'"$lang" >> "$OUT"
    cat "$f" >> "$OUT"
    echo "" >> "$OUT"
    echo '```' >> "$OUT"
    echo "" >> "$OUT"
done

# размер
SIZE=$(du -h "$OUT" | cut -f1)
echo "" >> "$OUT"
echo "**Total size:** $SIZE" >> "$OUT"

echo "✅ Готово: $OUT ($SIZE)"