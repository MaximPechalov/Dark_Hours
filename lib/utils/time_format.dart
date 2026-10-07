/// Утилиты для форматирования игрового времени.
///
/// Все функции — чистые. Работают с минутами.
class TimeFormat {
  TimeFormat._(); // нельзя создавать экземпляры

  /// Форматирует длительность в минутах.
  ///
  /// Примеры:
  /// - 5   → "5 мин"
  /// - 45  → "45 мин"
  /// - 60  → "1ч"
  /// - 90  → "1ч 30м"
  /// - 125 → "2ч 5м"
  static String duration(int minutes) {
    if (minutes < 60) return '$minutes мин';

    final h = minutes ~/ 60;
    final m = minutes % 60;

    if (m == 0) return '${h}ч';
    return '${h}ч ${m}м';
  }

  /// Короткий формат — только время дня.
  ///
  /// Примеры:
  /// - 480  → "08:00"
  /// - 845  → "14:05"
  /// - 1380 → "23:00"
  static String clock(int totalMinutes) {
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}