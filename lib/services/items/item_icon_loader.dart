import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Загрузчик иконок предметов.
///
/// Логика:
/// - При старте приложения сканирует `assets/images/items/` и
///   строит карту `itemId → путь к PNG`.
/// - При запросе иконки:
///   - Если PNG есть — возвращает `Image.asset`.
///   - Если нет — возвращает эмодзи (fallback).
///
/// Работает для **всех** категорий: weapons, armor, consumables,
/// tools, resources. Даже если PNG пока только для оружия —
/// остальные предметы продолжат работать через эмодзи.
///
/// Использование:
/// ```dart
/// // В main.dart:
/// await ItemIconLoader.init();
///
/// // В UI:
/// ItemIconLoader.buildIcon(
///   itemId: 'kitchen_knife',
///   fallbackEmoji: '🔪',
///   size: 32,
/// );
/// ```
class ItemIconLoader {
  ItemIconLoader._();

  /// Кеш: `itemId` → путь к PNG.
  ///
  /// Пример: `{ "kitchen_knife": "assets/images/items/weapons/kitchen_knife.png" }`.
  static final Map<String, String> _pngCache = {};

  /// Флаг инициализации.
  static bool _isInitialized = false;

  /// Инициализация — сканирует assets и заполняет кеш.
  ///
  /// Вызывается один раз при старте приложения.
  /// Повторные вызовы безопасны — ничего не делают.
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      int found = 0;

      for (final path in allAssets) {
        // Интересуют только PNG в assets/images/items/.
        if (!path.startsWith('assets/images/items/')) continue;
        if (!path.endsWith('.png')) continue;

        // assets/images/items/weapons/kitchen_knife.png
        // → fileName = "kitchen_knife.png"
        // → id = "kitchen_knife"
        final fileName = path.split('/').last;
        final id = fileName.substring(0, fileName.length - 4);

        // Если два PNG с одним id в разных категориях — берём первый.
        // На практике такого быть не должно.
        _pngCache[id] = path;
        found++;
      }

      _isInitialized = true;
      debugPrint('🖼️ ItemIconLoader: загружено $found иконок');
    } catch (e, stackTrace) {
      debugPrint('❌ ItemIconLoader: ошибка инициализации — $e');
      debugPrint('$stackTrace');
      _isInitialized = true; // всё равно помечаем — работаем через fallback
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ПУБЛИЧНЫЙ API
  // ═══════════════════════════════════════════════════════════

  /// Есть ли PNG для предмета.
  static bool hasPng(String itemId) {
    return _pngCache.containsKey(itemId);
  }

  /// Путь к PNG для предмета (или null).
  static String? getPngPath(String itemId) {
    return _pngCache[itemId];
  }

  /// Собрать виджет иконки.
  ///
  /// - [itemId] — ID предмета (должен совпадать с именем PNG без .png).
  /// - [fallbackEmoji] — эмодзи, если PNG нет.
  /// - [size] — размер иконки в пикселях (ширина = высота).
  /// - [fit] — как вписывать картинку (по умолчанию `contain`).
  /// - [color] — если задан, применяется как ColorFilter к PNG (для тонирования).
  ///
  /// Возвращает либо `Image.asset`, либо `Text` с эмодзи.
  static Widget buildIcon({
    required String itemId,
    required String fallbackEmoji,
    double size = 32,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    final pngPath = _pngCache[itemId];

    if (pngPath == null) {
      return _buildEmojiFallback(fallbackEmoji, size, color);
    }

    return Image.asset(
      pngPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Если PNG не загрузился (битый файл, удалён из assets) —
        // откатываемся на эмодзи.
        debugPrint('⚠️ ItemIconLoader: не удалось загрузить $pngPath — $error');
        return _buildEmojiFallback(fallbackEmoji, size, color);
      },
    );
  }

  /// Эмодзи-фолбэк.
  static Widget _buildEmojiFallback(String emoji, double size, Color? color) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: size * 0.8,
            color: color,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ДИАГНОСТИКА И ТЕСТЫ
  // ═══════════════════════════════════════════════════════════

  /// Сколько иконок загружено.
  static int get loadedCount => _pngCache.length;

  /// Все ID предметов, для которых есть PNG.
  static Set<String> get availableIds => _pngCache.keys.toSet();

  /// Список всех путей к PNG (для отладки).
  static List<String> get allPaths =>
      _pngCache.values.toList()..sort();

  /// Очистить кеш (для тестов).
  @visibleForTesting
  static void clearCache() {
    _pngCache.clear();
    _isInitialized = false;
  }

  /// Добавить путь вручную (для тестов).
  @visibleForTesting
  static void registerForTest(String itemId, String path) {
    _pngCache[itemId] = path;
  }
}