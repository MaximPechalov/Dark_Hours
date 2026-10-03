#!/usr/bin/env python3
"""
Скрипт для вырезания фона с иконок оружия.

Что делает:
1. Читает все JPEG из raw_weapons/.
2. Определяет фон (белый, чёрный, серый, шахматный).
3. Удаляет фон через flood fill от краёв картинки.
4. Сохраняет PNG с прозрачным фоном в assets/images/items/weapons/.

Запуск:
    pip install Pillow numpy
    python tool/cut_weapon_backgrounds.py
"""

import os
import sys
from collections import deque, Counter

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("❌ Установи зависимости: pip install Pillow numpy")
    sys.exit(1)

# ═══════════════════════════════════════════════════════════
# НАСТРОЙКИ
# ═══════════════════════════════════════════════════════════

SRC_DIR = "raw_weapons"
DST_DIR = "assets/images/items/weapons"

# Порог "похожести" пикселя на фон (0-255).
# 30 — баланс. Если фон остаётся — увеличь. Если ест оружие — уменьши.
TOLERANCE = 35

# Сглаживать ли края (мягкая альфа).
SMOOTH_EDGES = True

# ═══════════════════════════════════════════════════════════
# ЛОГИКА
# ═══════════════════════════════════════════════════════════


def is_similar(pixel, target, tolerance):
    """Проверка: пиксель похож на target?"""
    return (
        abs(int(pixel[0]) - int(target[0])) <= tolerance
        and abs(int(pixel[1]) - int(target[1])) <= tolerance
        and abs(int(pixel[2]) - int(target[2])) <= tolerance
    )


def detect_background_colors(img, tolerance):
    """
    Определить цвета фона по краям картинки.

    Возвращает список цветов — потому что шахматный фон
    состоит из двух цветов (белый + серый).
    """
    w, h = img.size
    pixels = img.load()

    # Собираем пиксели по краям (толщиной 2 пикселя).
    edge_pixels = []
    for x in range(w):
        edge_pixels.append(pixels[x, 0])
        edge_pixels.append(pixels[x, 1])
        edge_pixels.append(pixels[x, h - 1])
        edge_pixels.append(pixels[x, h - 2])
    for y in range(h):
        edge_pixels.append(pixels[0, y])
        edge_pixels.append(pixels[1, y])
        edge_pixels.append(pixels[w - 1, y])
        edge_pixels.append(pixels[w - 2, y])

    # Округляем до 10-х и считаем частоту.
    rounded = [
        (c[0] // 10 * 10, c[1] // 10 * 10, c[2] // 10 * 10)
        for c in edge_pixels
    ]
    counter = Counter(rounded)

    # Берём 1-3 самых частых цвета. Если второй цвет
    # встречается больше 20% от первого — это шахматка.
    most_common = counter.most_common(3)
    if not most_common:
        return [(255, 255, 255)]

    primary = most_common[0]
    colors = [primary[0]]

    if len(most_common) > 1:
        secondary = most_common[1]
        # Если второй цвет встречается часто — добавляем.
        if secondary[1] > primary[1] * 0.2:
            colors.append(secondary[0])

    return colors


def flood_fill_transparent(img, bg_colors, tolerance):
    """
    Удаляет фон через flood fill от краёв.

    Работает с несколькими цветами фона (для шахматки).
    Внутренние пиксели, похожие на фон, остаются — они часть оружия.
    """
    w, h = img.size
    img = img.convert("RGBA")
    pixels = img.load()

    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    # Все пиксели на границе — стартовые.
    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    while queue:
        x, y = queue.popleft()

        if x < 0 or x >= w or y < 0 or y >= h:
            continue
        if visited[y, x]:
            continue

        pixel = pixels[x, y]

        # Проверяем: похож ли пиксель на ЛЮБОЙ из цветов фона.
        is_bg = False
        for bg_color in bg_colors:
            if is_similar(pixel, bg_color, tolerance):
                is_bg = True
                break

        if not is_bg:
            continue

        visited[y, x] = True
        pixels[x, y] = (pixel[0], pixel[1], pixel[2], 0)

        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))

    return img


def smooth_alpha_edges(img):
    """
    Сглаживает края: пиксели, граничащие с прозрачными,
    получают частичную альфу.
    """
    w, h = img.size
    img = img.convert("RGBA")
    pixels = img.load()

    new_alpha = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue

            # Смотрим на соседей.
            transparent_neighbors = 0
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    if pixels[nx, ny][3] == 0:
                        transparent_neighbors += 1

            if transparent_neighbors > 0:
                # Край — мягкая альфа.
                new_alpha[(x, y)] = max(100, 255 - transparent_neighbors * 60)

    for (x, y), new_a in new_alpha.items():
        r, g, b, _ = pixels[x, y]
        pixels[x, y] = (r, g, b, new_a)

    return img


def process_image(src_path, dst_path):
    """Обработать одну картинку."""
    img = Image.open(src_path)

    # Если уже PNG с альфой — не трогаем.
    if img.mode == "RGBA":
        alpha = img.split()[3]
        if alpha.getextrema()[0] < 255:
            print(f"    ✅ Уже с прозрачностью — копируем как есть")
            img.save(dst_path, "PNG", optimize=True)
            return True

    img = img.convert("RGB")

    # Определяем цвета фона.
    bg_colors = detect_background_colors(img, TOLERANCE)
    print(f"    🎨 Фон: {bg_colors}")

    # Удаляем фон.
    img = flood_fill_transparent(img, bg_colors, TOLERANCE)

    # Сглаживаем края.
    if SMOOTH_EDGES:
        img = smooth_alpha_edges(img)

    # Сохраняем.
    img.save(dst_path, "PNG", optimize=True)
    print(f"    💾 → {dst_path}")
    return True


def main():
    if not os.path.isdir(SRC_DIR):
        print(f"❌ Папка {SRC_DIR} не найдена.")
        print(f"   Создай её и положи туда исходные JPEG.")
        return

    os.makedirs(DST_DIR, exist_ok=True)

    files = sorted([
        f for f in os.listdir(SRC_DIR)
        if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp"))
    ])

    if not files:
        print(f"❌ В папке {SRC_DIR} нет картинок.")
        return

    print(f"🔪 Найдено {len(files)} картинок")
    print(f"📁 Источник:     {SRC_DIR}")
    print(f"📁 Назначение:   {DST_DIR}")
    print(f"⚙️  Tolerance:    {TOLERANCE}")
    print(f"⚙️  Сглаживание:  {SMOOTH_EDGES}")
    print()

    success = 0
    for filename in files:
        src = os.path.join(SRC_DIR, filename)
        name = os.path.splitext(filename)[0]
        dst = os.path.join(DST_DIR, f"{name}.png")

        print(f"  📷 {filename}")
        try:
            if process_image(src, dst):
                success += 1
        except Exception as e:
            print(f"    ❌ Ошибка: {e}")

    print()
    print(f"✅ Готово: {success} из {len(files)}")


if __name__ == "__main__":
    main()