import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dark_hours/models/world/region_layout.dart';
import 'package:dark_hours/screens/gameplay/widgets/region_map_painter.dart';

/// Кеш фоновых изображений регионов.
///
/// **Логика работы:**
/// 1. При первом запросе региона — пробует загрузить PNG из
///    `assets/images/regions/{regionId}.png`.
/// 2. Если файла нет — рендерит фон через [RegionMapPainter]
///    в `ui.Image` один раз.
/// 3. Кеширует результат в памяти.
/// 4. Возвращает `ui.Image` для отрисовки через `RawImage`.
///
/// **LRU-кеш:**
/// Хранится не больше [maxCached] регионов одновременно.
/// При превышении — самый старый выгружается (`dispose()` + удаление).
/// Это критично на слабых устройствах: 1 регион = ~3.8 MB,
/// 6 регионов = ~23 MB — потенциальный OOM.
///
/// Почему [maxCached] = 2:
/// При переходе A → B нужны оба региона — игрок может
/// вернуться назад в течение секунды. Один — мало,
/// три и больше — избыточно (~12 MB).
class RegionBackgroundCache {
  RegionBackgroundCache._();

  /// Размер рендера (логические пиксели).
  static const Size _defaultSize = Size(800, 1200);

  /// Максимальное количество регионов в кеше.
  static const int maxCached = 2;

  /// LRU-кеш: `regionId` → готовая картинка.
  ///
  /// `LinkedHashMap` сохраняет порядок вставки — используем это
  /// для реализации LRU: свежие элементы в конце, старые — в начале.
  static final LinkedHashMap<String, ui.Image> _cache = LinkedHashMap();

  /// Кеш "загружается сейчас" — чтобы не запускать загрузку дважды.
  static final Map<String, Future<ui.Image?>> _pending = {};

  /// Получить фон региона.
  static Future<ui.Image?> get({
    required String regionId,
    required RegionLayout layout,
  }) async {
    // 1. Уже в кеше — обновляем позицию и возвращаем.
    if (_cache.containsKey(regionId)) {
      final image = _cache.remove(regionId)!;
      _cache[regionId] = image; // перемещаем в конец (recently used)
      return image;
    }

    // 2. Загрузка уже идёт — ждём её.
    if (_pending.containsKey(regionId)) {
      return _pending[regionId];
    }

    // 3. Запускаем загрузку.
    final future = _loadOrGenerate(regionId, layout);
    _pending[regionId] = future;

    try {
      final image = await future;
      if (image != null) {
        _put(regionId, image);
      }
      return image;
    } finally {
      _pending.remove(regionId);
    }
  }

  /// Положить регион в кеш с соблюдением LRU-лимита.
  static void _put(String regionId, ui.Image image) {
    // Если регион уже в кеше — сначала удаляем старую запись.
    if (_cache.containsKey(regionId)) {
      _cache.remove(regionId)?.dispose();
    }

    _cache[regionId] = image;

    // Если превысили лимит — выгружаем самый старый.
    while (_cache.length > maxCached) {
      final oldestKey = _cache.keys.first;
      final oldestImage = _cache.remove(oldestKey);
      oldestImage?.dispose();
      debugPrint('🗑️ RegionBackgroundCache: выгружен "$oldestKey" (LRU)');
    }
  }

  /// Загрузить PNG из assets или сгенерировать картинку.
  static Future<ui.Image?> _loadOrGenerate(
    String regionId,
    RegionLayout layout,
  ) async {
    // ─── Попытка загрузить PNG из assets ───
    final assetPath = 'assets/images/regions/$regionId.png';
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      debugPrint('🖼️ RegionBackgroundCache: загружен $assetPath '
          '(${frame.image.width}×${frame.image.height})');
      return frame.image;
    } catch (e) {
      // Файла нет — это нормально, генерируем.
      debugPrint('🖼️ RegionBackgroundCache: $assetPath не найден, '
          'генерирую для $regionId');
    }

    // ─── Генерация через RegionMapPainter ───
    return _generateFromPainter(regionId, layout);
  }

  /// Сгенерировать картинку через [RegionMapPainter].
  static Future<ui.Image?> _generateFromPainter(
    String regionId,
    RegionLayout layout,
  ) async {
    try {
      final size = layout.logicalSize;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Ограничиваем область рисования.
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

      // Рисуем фон через существующий painter.
      final painter = RegionMapPainter(layout: layout);
      painter.paint(canvas, size);

      // Завершаем запись.
      final picture = recorder.endRecording();

      // Конвертируем в картинку.
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      // Освобождаем picture — она больше не нужна.
      picture.dispose();

      debugPrint('🖼️ RegionBackgroundCache: сгенерирован $regionId '
          '(${image.width}×${image.height})');

      return image;
    } catch (e, stackTrace) {
      debugPrint('❌ RegionBackgroundCache: ошибка генерации '
          '$regionId — $e');
      debugPrint('$stackTrace');
      return null;
    }
  }

  /// Удалить конкретный регион из кеша.
  static void evict(String regionId) {
    _cache.remove(regionId)?.dispose();
    _pending.remove(regionId);
  }

  /// Очистить весь кеш (для тестов или при выходе из игры).
  static void clear() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _pending.clear();
  }

  // ═══════════════════════════════════════════════════════════
  // ТЕСТИРОВАНИЕ И ДИАГНОСТИКА
  // ═══════════════════════════════════════════════════════════

  /// Проверить, закеширован ли регион.
  @visibleForTesting
  static bool isCached(String regionId) {
    return _cache.containsKey(regionId);
  }

  /// Размер кеша (для диагностики).
  @visibleForTesting
  static int get cacheSize => _cache.length;

  /// Список ID регионов в кеше, в порядке от старых к свежим.
  @visibleForTesting
  static List<String> get cachedRegionIds => _cache.keys.toList();

  /// Размер по умолчанию.
  static Size get defaultSize => _defaultSize;
}