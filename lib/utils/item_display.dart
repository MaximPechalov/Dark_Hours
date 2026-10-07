import 'package:flutter/material.dart';

/// Утилиты для отображения предметов в UI.
///
/// Все функции — чистые, без побочных эффектов. Не зависят ни от чего,
/// кроме переданного значения.
///
/// Использование:
/// ```dart
/// Text(
///   ItemDisplay.rarityName(item.rarity),
///   style: TextStyle(color: ItemDisplay.rarityColor(item.rarity)),
/// )
/// ```
class ItemDisplay {
  ItemDisplay._(); // нельзя создавать экземпляры

  // ═══════════════════════════════════════════════════════════
  // РЕДКОСТЬ
  // ═══════════════════════════════════════════════════════════

  /// Цвет по редкости предмета.
  ///
  /// Используется для обводки, текста, подсветки.
  static Color rarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return const Color.fromARGB(255, 150, 150, 150);
      case 'uncommon':
        return const Color.fromARGB(255, 100, 200, 100);
      case 'rare':
        return const Color.fromARGB(255, 100, 150, 255);
      case 'epic':
        return const Color.fromARGB(255, 200, 100, 255);
      case 'legendary':
        return const Color.fromARGB(255, 255, 200, 50);
      default:
        return Colors.white;
    }
  }

  /// Русское название редкости.
  static String rarityName(String rarity) {
    switch (rarity) {
      case 'common':
        return 'Обычное';
      case 'uncommon':
        return 'Необычное';
      case 'rare':
        return 'Редкое';
      case 'epic':
        return 'Эпическое';
      case 'legendary':
        return 'Легендарное';
      default:
        return rarity;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ТИП УРОНА
  // ═══════════════════════════════════════════════════════════

  /// Русское название типа урона.
  static String damageTypeName(String damageType) {
    switch (damageType) {
      case 'cutting':
        return 'режущий';
      case 'blunt':
        return 'дробящий';
      case 'piercing':
        return 'колющий';
      case 'firearm':
        return 'огнестрельный';
      default:
        return damageType;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // СЛОТЫ ЭКИПИРОВКИ
  // ═══════════════════════════════════════════════════════════

  /// Русское название слота экипировки.
  static String slotName(String slot) {
    switch (slot) {
      case 'weapon':
        return 'Оружие';
      case 'head':
        return 'Голова';
      case 'body':
        return 'Тело';
      case 'hands':
        return 'Руки';
      case 'feet':
        return 'Ноги';
      case 'backpack':
        return 'Рюкзак';
      default:
        return slot;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // СОПРОТИВЛЕНИЯ
  // ═══════════════════════════════════════════════════════════

  /// Русское название сопротивления (для брони).
  static String resistanceName(String key) {
    switch (key) {
      case 'cutting':
        return 'Режущий';
      case 'blunt':
        return 'Дробящий';
      case 'piercing':
        return 'Колющий';
      case 'firearm':
        return 'Огнестрельный';
      default:
        return key;
    }
  }
}